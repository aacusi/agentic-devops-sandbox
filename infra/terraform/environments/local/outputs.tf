# Outputs are the module's contract: what the next phase, and the human running
# it, need to know.
#
# Deliberately absent: kind_cluster.this.kubeconfig, .client_key and
# .client_certificate. They are credentials. They already live in state (which is
# why state is gitignored — ADR-0005); echoing them to a terminal or a CI log as
# well would be a second, avoidable exposure.

output "environment" {
  description = "Environment name (always 'local' in this root module)."
  value       = var.environment
}

output "cluster_name" {
  description = "Name of the kind cluster this module manages."
  value       = var.cluster_name
}

output "kube_context" {
  description = "kubectl context kind creates. Verify with scripts/guard-context.sh before applying anything."
  value       = local.kube_context
}

output "cluster_endpoint" {
  description = "API server address. Always a loopback address: this cluster is not reachable from anywhere else."
  value       = kind_cluster.this.endpoint
}

output "node_count" {
  description = "Total nodes: one control-plane plus var.worker_count workers."
  value       = 1 + var.worker_count
}

output "kubernetes_version" {
  description = "Kubernetes version, determined by the pinned kind node image."
  value       = var.kind_node_image
}

output "app_namespace" {
  description = "Namespace the sample application is deployed into, created by this module."
  value       = kubernetes_namespace.app.metadata[0].name
}

output "argocd_namespace" {
  description = "Namespace Argo CD is installed into, created by this module."
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "name_prefix" {
  description = "Naming convention prefix for resources created by this module."
  value       = local.name_prefix
}

output "common_labels" {
  description = "Labels every resource created by this module carries."
  value       = local.common_labels
}

output "argocd_chart_version" {
  description = "Pinned argo-cd Helm chart version actually installed."
  value       = helm_release.argocd.version
}

output "argocd_app_version" {
  description = "Argo CD application version delivered by the pinned chart."
  value       = helm_release.argocd.metadata[0].app_version
}

output "argocd_access" {
  description = "How to reach the Argo CD UI. ClusterIP only — a port-forward is the only route in."
  value       = "kubectl -n ${var.argocd_namespace} port-forward svc/argocd-server 8080:80  # then http://localhost:8080"
}

output "phase_status" {
  description = "Human-readable reminder of what this module currently manages."
  value       = "phase 5 — manages the kind cluster, the ${var.app_namespace} / ${var.argocd_namespace} namespaces, and the Argo CD installation (chart ${var.argocd_chart_version}). Application/AppProject objects belong to Argo CD, not here (ADR-0004)."
}
