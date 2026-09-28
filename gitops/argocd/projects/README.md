# gitops/argocd/projects/

Argo CD `AppProject` definitions. Empty until phase 5.

An `AppProject` is the blast-radius fence around a set of Applications. It
restricts:

- **source repos** — which Git URLs Applications may deploy from
- **destinations** — which cluster + namespaces they may deploy to
- **allowed resource kinds** — cluster-scoped and namespace-scoped whitelists

Planned: `sandbox.yaml`, permitting only the sandbox repo, only the in-cluster
destination, and only the `hello-devops` namespace.

Using the built-in `default` project is the easy path and it allows everything,
everywhere. Fine for a five-minute demo; a bad habit to build, and the exact habit
that turns an agent mistake into a cluster-wide incident.
