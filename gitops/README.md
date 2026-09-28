# gitops/

Argo CD configuration. **Phase 5. Nothing here is functional yet** — the
directories and this document exist so the shape of the system is visible now, and
so there is exactly one obvious place for each future file.

```
gitops/
├── argocd/
│   ├── install/        how Argo CD itself is installed (bootstrap, Helm values)
│   └── projects/       AppProject definitions — the blast-radius fence
└── applications/       Argo CD Application manifests (app-of-apps)
```

## The intended model

```
you edit k8s/hello-devops/overlays/local/kustomization.yaml
  -> commit
  -> push to the Git origin Argo CD watches
  -> Argo CD detects drift between Git and the cluster
  -> Argo CD syncs
  -> pods roll
```

Argo CD becomes **the only thing that writes application state to the cluster**.
That is what makes agent-driven operations auditable: every change is a commit
with an author, a diff and a revert.

## Bootstrap order (phase 5)

1. Terraform installs Argo CD into the `argocd` namespace (pinned chart version).
2. Apply **one** manifest by hand: `applications/root-app.yaml` — the app-of-apps
   root, pointing at `gitops/applications/`.
3. From then on, adding an application means adding a file. Nothing else is ever
   applied manually.

## Open decision: which Git origin does Argo CD read?

This is the one genuine unknown in the plan, and it must be settled before
phase 5 starts. Argo CD runs *inside* the cluster and clones from a URL it can
reach over the network — it cannot read a path on your laptop, and `file://` is
not supported.

| Option | Stays fully offline | Cost |
|---|---|---|
| **A.** Run Gitea in the kind cluster as the origin; push to it from the laptop | yes | one extra component to learn |
| **B.** Bring GitHub forward to phase 5 and use a private repo | no | breaks the "zero external services" property |
| **C.** Sidecar that syncs a host path into the repo server | yes | fragile, non-standard, teaches bad habits |

Recommendation: **A (Gitea)**, because it preserves the offline guarantee and
teaches the real lesson — Argo CD's contract is "a reachable Git remote", not
"GitHub". To be confirmed at the end of phase 4 and recorded as an ADR.

## Sync policy: start manual

Phase 5 will enable, in this order, each as a separate deliberate step:

1. **Manual sync.** You click sync and watch what happens.
2. **`automated: {}`** — Argo CD syncs new commits on its own.
3. **`prune: true`** — deleting a file deletes the resource.
4. **`selfHeal: true`** — `kubectl edit` gets reverted within seconds.

Turning all four on at once is how people learn to distrust GitOps. Enabling them
one at a time is how you learn what each one actually does.

## Rules

1. No secrets in this directory, ever. Argo CD credentials are created out-of-band
   in phase 5; sealed secrets or SOPS arrive in phase 6.
2. Every `Application` belongs to an `AppProject` that restricts which namespaces
   and resource kinds it may touch. The default project allows everything, which
   is fine for a demo and wrong as a habit.
3. Argo CD never manages the resources Terraform owns (ADR-0004).
