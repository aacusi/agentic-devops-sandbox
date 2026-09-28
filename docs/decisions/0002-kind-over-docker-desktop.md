# ADR-0002: kind for the local Kubernetes cluster

- **Status:** accepted
- **Date:** 2026-09-02
- **Phase:** 1 (decision), 3 (implementation)

## Context

Options for local Kubernetes on macOS: Docker Desktop's built-in cluster, kind,
minikube, k3d, Rancher Desktop, Colima. All can run the workload. They differ in
how well they support *learning by destroying things*.

## Decision

**kind** (Kubernetes in Docker), created by Terraform, topology declared in
`clusters/kind/kind-config.yaml`.

| | kind | Docker Desktop k8s | minikube |
|---|---|---|---|
| Topology as code | yes | no | partial |
| Recreatable in ~1 min | yes | it is a singleton | slower |
| Multi-node | yes | no | with effort |
| Runs identically in CI | yes | no | awkward |
| Terraform provider | `tehcyx/kind` | none | none |

The deciding factor is disposability. A cluster you can delete and rebuild in a
minute is one you will actually experiment on; a singleton you are afraid to break
is not a sandbox.

Multi-node matters more than it looks: with a single node, scheduling, node
selectors, anti-affinity and `NODE_NAME` in the downward API are all no-ops.

## Consequences

Good:

- `kind delete cluster` + `terraform apply` is a complete reset.
- The same tool runs in GitHub Actions, so a phase 6 e2e job is nearly free.
- Terraform gets a real resource to manage from phase 3.

Bad:

- **kind nodes cannot see local Docker images.** Images must be side-loaded with
  `kind load docker-image`. This is genuinely confusing the first time; it is also
  a useful lesson about registries, and it goes away in phase 6.
- Ingress requires `extraPortMappings` plus the `ingress-ready=true` node label,
  which must be set at cluster creation time — changing your mind means recreating
  the cluster.
- 3 nodes + Argo CD ≈ 4-6 GB RAM. Docker Desktop's memory limit may need raising.

## Revisit when

The laptop struggles. First lever is `worker_count = 1`, not switching tools.
