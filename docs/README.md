# docs/

```
docs/
├── phases/           what we are building, phase by phase
├── decisions/        ADRs — why we built it that way
├── runbooks/         how to recover when it breaks
└── learning-notes/   your own notes
```

## Why this exists in phase 1

An agent starts every session with no memory of the last one. The repository *is*
its memory. A decision that lives only in a chat transcript will be re-litigated,
or silently reversed, in the next session. A decision written to
`docs/decisions/` will not.

That makes these docs load-bearing, not ceremony.

## phases/

One document per phase: scope, non-goals, file list, acceptance criteria,
rollback, assumptions. Written **before** the work, reviewed, then updated to
record what was actually built.

Start at [phase-roadmap.md](phases/phase-roadmap.md).

## decisions/

Architecture Decision Records, numbered, immutable once accepted. To change a
decision, write a new ADR that supersedes the old one — do not edit history.

| ADR | Decision |
|---|---|
| [0001](decisions/0001-monorepo.md) | Single repository with a splittable internal boundary |
| [0002](decisions/0002-kind-over-docker-desktop.md) | kind for the local cluster |
| [0003](decisions/0003-kustomize-over-helm.md) | Kustomize first, Helm later |
| [0004](decisions/0004-terraform-argocd-ownership-boundary.md) | Terraform owns infrastructure, Argo CD owns applications |
| [0005](decisions/0005-local-terraform-state.md) | Local Terraform state, zero cloud providers |
| [0006](decisions/0006-python-fastapi-sample-app.md) | Python + FastAPI for the sample app |

Format: Context → Decision → Rationale → Consequences (good **and** bad) →
Revisit when. Keep them short; an ADR nobody reads is worse than no ADR.

## runbooks/

Recovery procedures, written the first time something breaks. Empty until phase 3,
because nothing can break yet.

## learning-notes/

Yours. Not maintained by the agent.
