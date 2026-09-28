# gitops/argocd/install/

How Argo CD itself gets installed. Empty until phase 5.

Planned contents:

| File | Purpose |
|------|---------|
| `values-local.yaml` | Helm values for the `argo-cd` chart, tuned for a laptop: single replica per component, `server.extraArgs: [--insecure]` (no TLS termination inside kind), modest resource requests |
| `README.md` | this file |

## Chicken-and-egg

Argo CD cannot install itself via GitOps. Something outside the cluster has to
create it first. In this repo Terraform does it (`helm_release.argocd`, pinned to
`var.argocd_chart_version`), which keeps installation in the same place as the
cluster and namespaces it depends on.

Self-management — Argo CD managing its own manifests once running — is a genuinely
useful pattern and a genuinely good way to lock yourself out of your own cluster.
Not in scope.

## Access after install (phase 5)

```bash
kubectl -n argocd get pods
kubectl -n argocd port-forward svc/argocd-server 8080:80
# initial admin password:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

That password is a real credential: read it when needed, never commit it, and
rotate it once you have logged in.
