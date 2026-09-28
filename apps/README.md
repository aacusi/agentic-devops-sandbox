# apps/

Application source code. One directory per application, self-contained: its own
dependencies, tests, `Dockerfile` and `README.md`.

| App | Language | Purpose |
|-----|----------|---------|
| `hello-devops` | Python 3.12 / FastAPI | The single workload carried end-to-end through every phase |

## Boundary

`apps/` contains **what to build**. It does not contain **how to deploy**:

- Kubernetes manifests live in `k8s/`
- Argo CD `Application` definitions live in `gitops/`
- Cluster and platform resources live in `infra/terraform/`

Keeping these separate is what makes it possible to split this monorepo into an
app repo and a GitOps repo later without rewriting anything
(see [ADR-0001](../docs/decisions/0001-monorepo.md)).

## Adding an application later

1. Create `apps/<name>/` with source, tests, `Dockerfile`, `README.md`.
2. Add `k8s/<name>/base` + `overlays/local`.
3. Add `gitops/applications/<name>.yaml`.
4. Add make targets if the toolchain differs.
