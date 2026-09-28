# Phase 1 — Foundation

**Status:** built, awaiting review
**Date:** 2026-09-02

## Goal

Establish the repository structure, conventions and guardrails, plus one small
application that later phases will carry through Docker → kind → Argo CD.

## Scope

In scope:

- Directory structure for all seven phases, each directory documented
- `hello-devops`: FastAPI app with liveness/readiness probes and identity reporting
- Tests and linting that phase 6 CI can run unchanged
- A `Dockerfile` (written, **not built**)
- Kubernetes base + local overlay (written, **not applied**)
- A Terraform root module with a local backend (written, **not initialised**)
- Claude Code guardrails: permissions and a deny hook
- `Makefile`, `.gitignore`, ADRs, roadmap

Explicitly **not** in scope:

- Running anything: no `docker build`, no `kind create`, no `terraform init`,
  no `kubectl`, no `git commit`
- Any AWS interaction, credential, or CLI invocation
- Installing software
- Ingress, HPA, NetworkPolicy, secrets, Argo CD manifests

## What was built

| Area | Files |
|---|---|
| Root | `README.md`, `Makefile`, `.gitignore`, `.editorconfig`, `.gitattributes` |
| Guardrails | `.claude/settings.json`, `.claude/hooks/deny-dangerous-commands.py`, `scripts/guard-context.sh`, `scripts/preflight.sh` |
| Application | `apps/hello-devops/` — `pyproject.toml`, `src/hello_devops/{__init__,config,main}.py`, `tests/test_main.py`, `Dockerfile`, `.dockerignore`, `README.md` |
| Kubernetes | `k8s/hello-devops/base/{deployment,service,kustomization}.yaml`, `overlays/local/kustomization.yaml` |
| Terraform | `infra/terraform/environments/local/{versions,main,variables,outputs}.tf`, `terraform.tfvars.example`, `.gitignore` |
| Cluster | `clusters/kind/kind-config.yaml` |
| GitOps | `gitops/**/README.md` (placeholders for phase 5) |
| Docs | `docs/phases/`, `docs/decisions/0001`-`0006`, `docs/runbooks/`, `docs/learning-notes/` |

## Acceptance criteria

Run these yourself — none have been run on your behalf.

| # | Check | Command | Expected |
|---|---|---|---|
| 1 | Preflight is read-only and honest | `make preflight` | Tool versions + kube context; no mutations |
| 2 | App installs | `make install` | Virtualenv at `apps/hello-devops/.venv` |
| 3 | Tests pass | `make test` | 6 passed |
| 4 | Lint passes | `make lint` | No findings |
| 5 | App serves | `make run` → <http://localhost:8000> | Status page with version `0.1.0`, env `local`, your hostname |
| 6 | Probes behave | `curl -i localhost:8000/readyz` | `200 ready` |
| 7 | Manifests render | `make k8s-build` | 2 replicas, namespace `hello-devops`, image `hello-devops:0.1.0`, hashed ConfigMap name |
| 8 | Terraform is inert | `make tf-init && make tf-validate && make tf-plan` | "No changes"; no providers downloaded |
| 9 | Apply is blocked | `make tf-apply` | Refuses, exit 1 |
| 10 | Nothing sensitive staged | `git status --porcelain` | No `.venv`, no `*.tfstate`, no credentials |

Criteria 2-8 require tools that may not be installed yet; a missing tool is a
phase-2/3 prerequisite, not a phase-1 failure.

## Rollback

Nothing outside this repository was touched. `git clean -fd` (nothing is committed
yet) removes every file created in this phase.

## Follow-ups

- Confirm the two assumptions marked **A1** (app language) and **A2** (Kubernetes
  version) below still suit you.
- Decide the Argo CD Git origin by the end of phase 4 (`gitops/README.md`).
- Pin the Docker base image by digest in phase 2.
- Add a `.python-version` or `uv` lock if reproducible dev environments become
  a problem.

## Assumptions made

| # | Assumption | Reversibility |
|---|---|---|
| A1 | Python 3.12 + FastAPI for the sample app (ADR-0006) | Cheap — the app is ~150 lines; swapping to Go changes only `apps/` and the Dockerfile |
| A2 | Kubernetes v1.31 via `kindest/node:v1.31.0` | One-line change in two files |
| A3 | Cluster name `agentic-sandbox`, context `kind-agentic-sandbox` | Variable |
| A4 | Namespace `hello-devops`, Argo CD namespace `argocd` | Variable |
| A5 | Kustomize, not Helm (ADR-0003) | Helm can be added later without removing Kustomize |
| A6 | Monorepo now, splittable later (ADR-0001) | Mechanical `git filter-repo` |
| A7 | Claude Code guardrails belong in phase 1, before anything can execute | Delete `.claude/settings.json` and the hook to revert |
| A8 | Semver image tags starting at `0.1.0`; Git SHA/digest from phase 6 | Convention only |
