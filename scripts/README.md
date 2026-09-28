# scripts/

Small, dependency-free shell helpers. Everything here is safe to read and safe to run:
no script in this directory mutates infrastructure.

| Script | Purpose | Safe? |
|--------|---------|-------|
| `preflight.sh` | Reports tool versions, git state, kube context and Docker daemon status. Never touches AWS. | Read-only |
| `guard-context.sh` | Exits non-zero unless the current kubectl context is a local cluster (`kind-*`, `docker-desktop`, `minikube`, `rancher-desktop`). | Read-only |

Rules for anything added here:

1. No script may create cloud resources or read credential files.
2. Destructive operations belong in a documented runbook for a human to run, not in a script.
3. `set -euo pipefail` at the top, and a comment block explaining the failure it prevents.
