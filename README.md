# Agentic DevOps Sandbox

A **local-only** learning environment for practising agentic DevOps: Claude Code driving
Git → Terraform → Docker → Kubernetes (kind) → Argo CD → a GitOps-managed application.

> **This repository has ZERO cloud access by design.**
> No AWS. No credentials. No remote state. No production anything.
> See [CLAUDE.md](CLAUDE.md) for the safety rules that govern all work here.

---

## Current status

| Phase | Name | Status |
|-------|------|--------|
| 1 | Foundation — repo structure, sample app, guardrails | **complete** |
| 2 | Containerisation — Docker build & run | not started |
| 3 | Local cluster — kind + Terraform (local state) | not started |
| 4 | Kubernetes — Kustomize, probes, ingress | not started |
| 5 | GitOps — Argo CD | not started |
| 6 | GitHub + Actions + registry | not started |
| 7 | AWS **sandbox** account (dedicated, never production) | not started |

Full detail: [docs/phases/phase-roadmap.md](docs/phases/phase-roadmap.md)

Phase 1 scaffolds the artifacts that later phases will use (`Dockerfile`, Kubernetes
manifests, Terraform root module) but **runs none of them**. Nothing in this repository
has been built, applied, or deployed yet.

---

## Target architecture

```
Claude Code
    |
    v
  Git  ---------------------------> GitHub (phase 6)
    |
    v
Terraform (local state)  ---> kind cluster + namespaces + Argo CD install
    |
    v
Docker image (hello-devops)
    |
    v
kind Kubernetes cluster
    |
    v
Argo CD  <--- watches gitops/ + k8s/
    |
    v
hello-devops running locally at http://localhost
```

**The rule that makes this safe:** Git is the only write path to the cluster.
Claude Code proposes file changes; a human approves; Argo CD applies.

---

## Quickstart (Phase 1 — laptop only, no containers)

```bash
make help              # list every available target
make preflight         # read-only: tool versions + current kube context
make install           # create .venv and install the app + dev tools
make test              # pytest
make lint              # ruff
make run               # serve the app on http://localhost:8000
```

Then open <http://localhost:8000> — the page reports the app version, environment and
hostname. Those three values are how you will *see* a GitOps rollout happen in Phase 5.

Endpoints:

| Path | Purpose |
|------|---------|
| `/` | Human-readable status page |
| `/healthz` | Liveness probe — is the process alive? |
| `/readyz` | Readiness probe — should it receive traffic? |
| `/version` | Just the version string |
| `/api/info` | JSON: version, env, pod name, node name, hostname |

---

## Repository layout

```
.
├── CLAUDE.md              Agent contract: safety rules and approval gates
├── Makefile               Single vocabulary for humans and agents
├── .claude/               Claude Code guardrails (permissions + deny hook)
├── apps/hello-devops/     The sample application (+ Dockerfile, phase 2)
├── infra/terraform/       Terraform root module — LOCAL state only
├── clusters/kind/         kind cluster topology (phase 3)
├── k8s/hello-devops/      Kustomize base + local overlay (phase 4)
├── gitops/                Argo CD install + Application manifests (phase 5)
├── scripts/               preflight and kube-context guard
├── docs/                  Phase designs, ADRs, runbooks, learning notes
└── .github/workflows/     CI (phase 6, intentionally empty)
```

Each directory has its own `README.md` explaining what it is for and which phase
brings it to life.

---

## Safety model

Four layers, deliberately redundant:

1. **[CLAUDE.md](CLAUDE.md)** — the written contract, loaded into every Claude Code session.
2. **[.claude/settings.json](.claude/settings.json)** — harness-enforced permissions.
   Read-only inspection is allowed; `aws`, `terraform apply`, `kubectl delete` are denied.
3. **[.claude/hooks/deny-dangerous-commands.py](.claude/hooks/deny-dangerous-commands.py)** —
   a `PreToolUse` hook that blocks dangerous shell commands regardless of what the model
   intends. Enforcement independent of model reasoning.
4. **[scripts/guard-context.sh](scripts/guard-context.sh)** — every cluster-touching
   Makefile target refuses to run unless the current kube context is local.

Anything genuinely destructive is proposed by the agent and executed by you.

---

## Conventions

- **Never `:latest`.** Images are tagged with a semver or Git SHA so a rollout is a real
  diff and a rollback is a real revert.
- **Terraform owns infrastructure; Argo CD owns applications.** They never manage the
  same object. See [ADR-0004](docs/decisions/0004-terraform-argocd-ownership-boundary.md).
- **Plain YAML over templating** while learning — Kustomize now, Helm later.
  See [ADR-0003](docs/decisions/0003-kustomize-over-helm.md).
- **Local Terraform state, gitignored, never committed.**
  See [ADR-0005](docs/decisions/0005-local-terraform-state.md).
