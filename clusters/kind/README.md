# clusters/kind/

Topology of the local Kubernetes cluster. **No cluster exists yet** — this is
declarative data that phase 3 will hand to Terraform.

| File | Purpose |
|------|---------|
| `kind-config.yaml` | 1 control plane + 2 workers, pinned node image, host ports 80/443 published for ingress |

## Why kind rather than Docker Desktop's Kubernetes

| | kind | Docker Desktop k8s |
|---|---|---|
| Config as code | yes | no |
| Disposable / recreatable | yes, in ~1 minute | it is a singleton |
| Multi-node | yes | no |
| Matches CI | yes — same tool runs in GitHub Actions | no |

Being able to destroy and recreate the cluster is what makes this a *sandbox*.
See [ADR-0002](../../docs/decisions/0002-kind-over-docker-desktop.md).

## Facts worth internalising before phase 3

1. **kind nodes are Docker containers.** `docker ps` will show them. A cluster
   "reboot" is a container restart.
2. **kind nodes cannot see your local Docker images.** Images must be side-loaded:
   `kind load docker-image hello-devops:0.1.0 --name agentic-sandbox`. This is why
   the Deployment uses `imagePullPolicy: IfNotPresent` and never `:latest`. A real
   registry arrives in phase 6.
3. **The context is `kind-<name>`**, i.e. `kind-agentic-sandbox`. Every
   cluster-touching make target checks this via `scripts/guard-context.sh`.
4. **Host ports 80/443 must be free** on your machine, or cluster creation fails
   with a bind error.
5. **Deleting the cluster is destructive and human-only:**
   `kind delete cluster --name agentic-sandbox`. It is not scripted here.

## Resource budget

Roughly 3 nodes + ingress + Argo CD + the app ≈ 4-6 GB RAM in Docker Desktop.
If Docker Desktop is capped lower, raise its memory limit before phase 3 or drop
`worker_count` to 1.
