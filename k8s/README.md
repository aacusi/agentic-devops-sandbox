# k8s/

Kubernetes manifests, managed with **Kustomize** (plain YAML, no templating —
see [ADR-0003](../docs/decisions/0003-kustomize-over-helm.md)).

**Nothing here has been applied to any cluster.** There is no cluster yet.

```
k8s/hello-devops/
├── base/                    environment-agnostic
│   ├── deployment.yaml      probes, security context, resources, downward API
│   ├── service.yaml         ClusterIP
│   └── kustomization.yaml
└── overlays/
    └── local/               kind-specific
        └── kustomization.yaml   namespace, replicas, image tag, ConfigMap
```

## Base vs overlay

The base contains nothing you would want to vary between environments — no
namespace, no image tag, no replica count worth tuning. The overlay supplies all
four variables that actually differ:

| Set in the local overlay | Value | Why it lives there |
|---|---|---|
| `namespace` | `hello-devops` | The namespace *object* is created by Terraform (ADR-0004); this only places resources into it |
| `replicas` | 2 | Enough to make a rolling update observable |
| image tag | `0.1.0` | Immutable tag — phase 6 replaces it with a digest written by CI |
| `APP_ENV`, `LOG_LEVEL` | ConfigMap literals | Hashed name, so a config change causes a real rollout |

## Render it locally (no cluster required)

```bash
make k8s-build      # kubectl kustomize k8s/hello-devops/overlays/local
```

This is worth doing before every commit: it is the cheapest way to see exactly
what would hit the API server.

## What is deliberately missing

| Missing | Arrives in |
|---|---|
| `Namespace` object | Phase 3, created by Terraform |
| `Ingress` | Phase 4, once ingress-nginx is installed in kind |
| `HorizontalPodAutoscaler` | Later — needs metrics-server |
| `NetworkPolicy` | Later |
| Secrets of any kind | Phase 6 at the earliest (SOPS or Sealed Secrets). No secret will ever be committed in plaintext |

## Rules

1. **Never `kubectl edit`.** From phase 5 onward Argo CD reverts it, and pretending
   otherwise teaches the wrong reflex. Change the file, commit, sync.
2. **Never `:latest`.** An immutable tag is what makes a rollback a `git revert`.
3. Every workload keeps its resource requests/limits, probes and security context.
   These are the parts people skip and then regret.
