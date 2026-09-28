# .github/workflows/

Intentionally empty. CI arrives in **phase 6**, together with the first Git remote.

This directory exists now so that the eventual location is unambiguous, and so
that adding CI is a matter of dropping in a file rather than restructuring.

## Planned workflows

| Workflow | Trigger | Does |
|---|---|---|
| `ci.yaml` | PR + push | `ruff check`, `ruff format --check`, `pytest`, `terraform fmt -check`, `terraform validate`, `kubectl kustomize` render, secret scan |
| `build.yaml` | push to `main` | Build the image, tag with the Git SHA, push to GHCR, output the digest |
| `promote.yaml` | after `build` | Open a PR updating the image digest in `k8s/.../overlays/local` |
| `kind-e2e.yaml` | PR (optional) | Create a kind cluster in CI, apply the overlay, curl `/readyz` |

## Two things to get right in phase 6

**1. No long-lived cloud credentials.** When AWS eventually appears (phase 7),
Actions authenticates via GitHub OIDC and assumes a role in the *sandbox* account.
No access keys in repository secrets. Ever.

**2. Do not create a CI loop.** `promote.yaml` writes to the repo, which can
retrigger CI, which writes again. Mitigations, to be decided in phase 6:
open a PR rather than pushing to `main` (preferred — it keeps a human in the
approval path), `[skip ci]` on the promotion commit, or path filters that exclude
`k8s/**` from `build.yaml`.

## Claude Code in CI

Phase 6 can also run Claude Code as a PR reviewer, which is where an agent is
genuinely useful: reviewing a GitOps diff *before* Argo CD applies it, against a
checklist (immutable tags, resource limits, probes, no plaintext secrets, no
privileged containers).
