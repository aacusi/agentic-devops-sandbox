# docs/runbooks/

Recovery procedures. Empty until phase 3 — nothing can break yet.

Write a runbook the **first** time something goes wrong, while the fix is still
fresh. The second occurrence is the one that wastes an afternoon.

## Expected runbooks

| Runbook | Phase | Problem it solves |
|---|---|---|
| `reset-cluster.md` | 3 | kind cluster wedged; how to delete and rebuild from Terraform |
| `image-not-found.md` | 4 | `ErrImagePull` / `ImagePullBackOff` because the image was never `kind load`ed |
| `pod-not-ready.md` | 4 | Readiness probe failing; reading `kubectl describe` and container logs |
| `argocd-out-of-sync.md` | 5 | An Application stuck OutOfSync or Progressing forever |
| `argocd-login.md` | 5 | Retrieving and rotating the initial admin password |
| `terraform-state-recovery.md` | 3 | Local state lost or corrupted; when to just rebuild the cluster |
| `port-80-in-use.md` | 3 | kind cluster creation failing on the host port bind |

## Format

Symptom (what you actually see) → Diagnosis commands (read-only) → Fix →
Prevention. Mark any destructive step clearly and require a human to run it.
