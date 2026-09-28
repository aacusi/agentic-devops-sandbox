# gitops/applications/

Argo CD `Application` manifests. Empty until phase 5.

Planned contents:

| File | Purpose |
|------|---------|
| `root-app.yaml` | The app-of-apps root. The **only** manifest ever applied by hand. It watches this directory and creates everything else. |
| `hello-devops.yaml` | Points at `k8s/hello-devops/overlays/local` |

## Shape of the hello-devops Application (phase 5)

```yaml
# NOT YET VALID — repoURL depends on the Git-origin decision in gitops/README.md
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hello-devops
  namespace: argocd
spec:
  project: sandbox
  source:
    repoURL: <decided at end of phase 4>
    targetRevision: main
    path: k8s/hello-devops/overlays/local
  destination:
    server: https://kubernetes.default.svc
    namespace: hello-devops
  syncPolicy: {}        # manual first; automated/prune/selfHeal added one at a time
```

Once the root app exists, **adding an application means adding a file here**. No
`kubectl apply`, no console, no exceptions. That is the whole point of GitOps: the
repository is the intended state, and anything else is drift.
