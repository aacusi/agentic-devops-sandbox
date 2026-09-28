# infra/terraform/modules/

Intentionally empty.

A module earns its existence at the second or third copy-paste, not before.
Extracting modules from a configuration that has one caller adds indirection and
teaches nothing — you end up reading two files to understand one resource.

Likely first candidates, once phases 3-5 create real resources:

| Module | Extract when |
|--------|--------------|
| `kind-cluster` | A second local cluster is needed (e.g. a "staging" kind cluster) |
| `argocd` | Argo CD is installed into more than one cluster |
| `app-namespace` | The namespace + quota + limit-range pattern repeats per app |

When one is added: `modules/<name>/{main,variables,outputs,versions}.tf` plus a
`README.md` documenting inputs, outputs and an example call.
