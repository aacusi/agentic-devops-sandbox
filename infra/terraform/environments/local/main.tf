# Local sandbox root module.
#
# PHASE 3: this module creates a local kind cluster and the namespaces that must
# exist before anything can be deployed into it. Nothing here touches a cloud
# account, and `terraform apply` must still be run by a human — see CLAUDE.md and
# the deliberately-broken `make tf-apply` target.
#
# Ownership boundary (ADR-0004): this module owns the cluster, the namespaces and
# (from phase 5) the Argo CD *installation*. It never owns application workloads —
# those belong to Argo CD, driven from k8s/ and gitops/. Two controllers managing
# one object is a fight neither wins.

locals {
  # Naming and tagging convention, defined once and reused by every future
  # resource so that everything this sandbox creates is obviously identifiable.
  name_prefix = "${var.environment}-${var.cluster_name}"

  # kubectl context that kind will create. Cross-checked by
  # scripts/guard-context.sh before anything is applied to a cluster.
  kube_context = "kind-${var.cluster_name}"

  common_labels = {
    "app.kubernetes.io/part-of"    = "agentic-devops-sandbox"
    "app.kubernetes.io/managed-by" = "terraform"
    "sandbox.local/environment"    = var.environment
  }
}

# ---------------------------------------------------------------------------
# Providers
# ---------------------------------------------------------------------------

# The kind provider needs no configuration: it drives the local Docker daemon,
# which is why this module cannot reach anything remote even by accident.
provider "kind" {}

# Configured from the cluster resource's own outputs rather than from a
# kubeconfig file on disk. This matters for correctness: it makes the namespaces
# depend on the cluster implicitly, and it means this module never depends on
# whatever context happens to be selected in ~/.kube/config.
provider "kubernetes" {
  host                   = kind_cluster.this.endpoint
  client_certificate     = kind_cluster.this.client_certificate
  client_key             = kind_cluster.this.client_key
  cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
}

# Same credentials, same reasoning as the kubernetes provider above: fed from the
# cluster resource rather than from a kubeconfig, so Helm can only ever talk to
# the cluster this module just created. It cannot follow whatever context happens
# to be selected in ~/.kube/config.
provider "helm" {
  kubernetes {
    host                   = kind_cluster.this.endpoint
    client_certificate     = kind_cluster.this.client_certificate
    client_key             = kind_cluster.this.client_key
    cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
  }
}

# ---------------------------------------------------------------------------
# The cluster
# ---------------------------------------------------------------------------
#
# TOPOLOGY DUPLICATION — READ THIS BEFORE EDITING.
#
# clusters/kind/kind-config.yaml describes this same topology in kind's own YAML
# format. It is NOT read by Terraform: the tehcyx/kind provider accepts topology
# only as an HCL `kind_config` block and offers no "config file" argument, so the
# YAML cannot be the source of truth while Terraform owns the cluster.
#
# Terraform is therefore authoritative. The YAML remains useful as the documented
# fallback for `kind create cluster --config clusters/kind/kind-config.yaml` when
# you want a cluster without Terraform. Change one, change the other.
#
# Node count comes from var.worker_count (ADR-0002: "first lever is worker_count
# = 1", not switching tools), and the Kubernetes version from var.kind_node_image.
resource "kind_cluster" "this" {
  name = var.cluster_name

  # Applies to every node that does not override it.
  node_image = var.kind_node_image

  # Block until the control plane is actually serving, so that the namespaces
  # below are not attempted against a half-built API server.
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # ----------------------------------------------------------------
    # Control plane. Also carries the ingress controller, which is why it
    # publishes ports 80/443 to the host.
    # ----------------------------------------------------------------
    node {
      role  = "control-plane"
      image = var.kind_node_image

      # This label is what the ingress-nginx kind manifest's nodeSelector looks
      # for. It can only be set at creation time — changing your mind about
      # ingress means recreating the cluster (ADR-0002).
      kubeadm_config_patches = [
        <<-PATCH
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
        PATCH
      ]

      # Host port -> node port mapping. This is what makes the app reachable at
      # http://localhost instead of requiring `kubectl port-forward`.
      #
      # Host ports 80 and 443 must be free when this is applied, or cluster
      # creation fails.
      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }

    # ----------------------------------------------------------------
    # Workers. Enough for the scheduler to make real placement decisions and for
    # pod anti-affinity / rolling updates to be meaningful. With a single node,
    # scheduling and NODE_NAME in the downward API are all no-ops.
    # ----------------------------------------------------------------
    dynamic "node" {
      for_each = range(var.worker_count)

      content {
        role  = "worker"
        image = var.kind_node_image
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Namespaces
# ---------------------------------------------------------------------------
#
# Terraform owns namespaces, not the Kustomize overlay (ADR-0004). This is why
# k8s/hello-devops/overlays/local sets `namespace:` but never creates it — and why
# applying those manifests before this module fails with "namespaces not found".

resource "kubernetes_namespace" "app" {
  metadata {
    name   = var.app_namespace
    labels = local.common_labels
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name   = var.argocd_namespace
    labels = local.common_labels
  }
}

# ---------------------------------------------------------------------------
# Argo CD (phase 5)
# ---------------------------------------------------------------------------
#
# The chicken-and-egg resource: Argo CD cannot install itself via GitOps, so
# something outside the cluster has to create it. That something is this, which
# keeps the installation in the same place — and under the same plan/approve/apply
# gate — as the cluster and namespace it depends on.
#
# The ownership line (ADR-0004) runs exactly here. Terraform owns *Argo CD*;
# Argo CD owns everything Argo CD deploys. This resource must therefore never
# grow to manage Application or AppProject objects: those are files in
# gitops/applications/ and gitops/argocd/projects/, applied by the app-of-apps
# root, not by Terraform.
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  # Pinned, never a range. An unpinned platform component means the cluster
  # changes underneath you on an unrelated `apply`.
  version = var.argocd_chart_version

  # The namespace this module already created above. The implicit dependency on
  # kubernetes_namespace.argocd is the point of writing it this way rather than
  # hardcoding "argocd".
  namespace = kubernetes_namespace.argocd.metadata[0].name

  # Never true. The namespace is Terraform's (ADR-0004) and already exists; this
  # would create a second, chart-owned one and put two owners on one object.
  create_namespace = false

  # Laptop-tuned values: one replica per component, ClusterIP only, no ingress,
  # no TLS, no credentials. Read gitops/argocd/install/values-local.yaml — it is
  # the interesting half of this resource.
  #
  # path.module keeps this correct regardless of where terraform is invoked from,
  # which matters because the Makefile drives it with `-chdir`.
  values = [
    file("${path.module}/../../../../gitops/argocd/install/values-local.yaml")
  ]

  # Block until the pods are actually Ready, so that a successful apply means a
  # working Argo CD rather than a created release.
  wait = true

  # Generous: the first install pulls ~400MB of images on a laptop, and the
  # default 300s is a routine false failure.
  timeout = 900

  # Surface the reason on failure instead of leaving a half-installed release.
  atomic          = true
  cleanup_on_fail = true
}
