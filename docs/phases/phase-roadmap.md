# Phase roadmap

One phase at a time. Each phase is designed, reviewed, built, then reviewed again
before the next begins. Nothing from a later phase is built early.

| Phase | Introduces | Done when | Approval gate |
|---|---|---|---|
| **1. Foundation** | Git conventions, Python 3.12 + FastAPI, pytest, ruff, Make, Claude Code guardrails, scaffolding for phases 2-6 | `make test`, `make lint` pass; app serves on `localhost:8000` | Commit approval |
| **2. Containerisation** | Docker, multi-stage build, non-root, digest-pinned base, `.dockerignore`, optional Trivy scan | `make docker-run` serves the app from a container | First `docker build` / `docker run` |
| **3. Local cluster + Terraform** | kind, kubectl, Terraform with **local state**, `tehcyx/kind` + `kubernetes` providers | A kind cluster and namespaces created by Terraform | Reviewed plan; **human** runs `apply` |
| **4. Kubernetes + Kustomize** | Deployments, probes, resources, ConfigMaps, `kind load`, ingress-nginx | App reachable at `http://localhost`; rolling update observable | Approve first cluster apply |
| **5. Argo CD + GitOps** | Argo CD, AppProject, app-of-apps, sync waves, drift detection | A committed YAML change rolls the app with no `kubectl` | Approve install; approve each of automated/prune/selfHeal |
| **6. GitHub + CI/CD + registry** | Git remote, GitHub Actions, GHCR, digest pinning, PR-based promotion | Push → CI → image → manifest PR → Argo CD sync | Approve first push to a remote |
| **7. AWS sandbox** | Dedicated sandbox account, S3+DynamoDB state, GitHub OIDC, ECR, EKS | Same app on EKS via the same GitOps repo | Full CLAUDE.md AWS checklist, every operation |

**Phases 1-5 are entirely offline** apart from downloading packages and base
images. Phase 6 is the first phase that writes to an external service. Phase 7 is
the first phase that touches a cloud account — and only a dedicated sandbox one.

## Phase entry/exit rules

Before starting a phase:
1. Write `docs/phases/phase-NN-<name>.md`: scope, non-goals, file list, acceptance
   criteria, rollback.
2. Get it reviewed.

Before closing a phase:
1. Acceptance criteria demonstrably met.
2. Any decision made along the way recorded as an ADR in `docs/decisions/`.
3. A runbook written for anything that can get stuck (`docs/runbooks/`).
4. `git status` clean, no secrets, no state files.

## Decisions deferred on purpose

| Decision | Decide by | Notes |
|---|---|---|
| Which Git origin Argo CD reads (Gitea in-cluster vs GitHub) | End of phase 4 | See `gitops/README.md`. Recommendation: Gitea, to keep phases 1-5 offline |
| Secrets management (SOPS vs Sealed Secrets) | Phase 6 | Do not invent a secrets story before there is a secret |
| Helm alongside Kustomize | Phase 6+ | Kustomize first while learning k8s primitives (ADR-0003) |
| Splitting into app repo + GitOps repo | Phase 6 | Directory boundaries already make this a mechanical change (ADR-0001) |
