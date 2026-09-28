# ADR-0004: Terraform owns infrastructure, Argo CD owns applications

- **Status:** accepted
- **Date:** 2026-09-02
- **Phase:** 1 (decision), 3-5 (implementation)

## Context

Terraform's `kubernetes` provider and Argo CD can both manage Kubernetes objects.
If both manage the same object, they fight forever: Terraform reverts it to match
state, Argo CD reverts it to match Git, and each reconciliation triggers the other.
Nobody wins and the symptom (a resource that keeps flapping) is confusing to
diagnose.

## Decision

A hard, non-overlapping split.

**Terraform owns** (things that must exist before GitOps can work):

- the kind cluster
- namespaces: `hello-devops`, `argocd`
- ingress-nginx
- the Argo CD **installation** (`helm_release`, pinned chart version)

**Argo CD owns** (everything application-shaped):

- all resources rendered from `k8s/**`
- Deployments, Services, ConfigMaps, Ingresses belonging to applications
- Argo CD `Application` and `AppProject` objects, via the app-of-apps root

Neither ever manages an object the other manages. In particular: the `Namespace`
object is Terraform's, so `k8s/hello-devops/overlays/local` sets `namespace:` but
never contains a `Namespace` resource, and the Argo CD Application will **not**
set `CreateNamespace=true`.

## Rationale

The split follows lifecycle, not technology. Cluster and platform components
change rarely, need ordering, and are dangerous to reconcile automatically —
Terraform's plan/approve/apply model fits. Application manifests change constantly
and benefit from continuous reconciliation — Argo CD's model fits.

It also keeps the bootstrap acyclic: Terraform creates the cluster, then the
namespaces, then Argo CD. Argo CD cannot create the cluster it runs on.

## Consequences

Good: no controller fights; one obvious owner for every object; the bootstrap
order is explicit and re-runnable.

Bad:

- Two tools to learn simultaneously, and the boundary must be remembered on every
  new resource. The test is one question: *does this exist before Argo CD does?*
- Namespace changes (quotas, limit ranges) require a Terraform apply, which is
  slower than a commit. Accepted deliberately: those are platform changes.
- Argo CD's `Application` objects are created by Argo CD itself (app-of-apps)
  rather than Terraform, so exactly one manifest is applied by hand in phase 5.

## Revisit when

Never for the app/infra line. Possibly for ingress-nginx, which could reasonably
move to Argo CD once the GitOps loop is trusted — but only with an explicit ADR.
