# ADR-0005: Local Terraform state, and zero cloud providers

- **Status:** accepted
- **Date:** 2026-09-02
- **Phase:** 1

## Context

This is a learning sandbox on one laptop, with one operator, and — critically —
an agent participating in the workflow. CLAUDE.md mandates zero AWS access at this
stage.

Remote state (S3 + DynamoDB locking) exists to solve problems this project does
not have: concurrent operators, state durability across machines, CI needing
access. It would require creating cloud resources and configuring credentials
before a single line of Terraform does anything useful.

## Decision

1. **Local backend**, explicitly declared:
   `backend "local" { path = "terraform.tfstate" }`.
2. **No provider blocks at all in phase 1.** With zero providers, `terraform init`
   downloads nothing and `plan` is structurally incapable of contacting anything.
3. **No `aws` provider in `environments/local/`, ever.** When AWS arrives in
   phase 7 it gets its own environment directory, its own state and its own
   approval gate.
4. **State is gitignored in two places** — the root `.gitignore` and
   `infra/terraform/environments/local/.gitignore`.
5. **`var.environment` is validated to equal `"local"`**, so this root module
   cannot be repurposed by accident.

## Rationale

State files contain resource attributes in plaintext, including values marked
sensitive in the configuration. Treating `terraform.tfstate` as a credential from
day one — before any real resource exists — means the habit is in place before it
matters.

Declaring the local backend explicitly rather than relying on the default makes
the choice visible in code review. Someone changing it has to change a line
somebody will notice.

## Consequences

Good:

- Phase 1 is provably offline: no providers, no network, no credentials.
- `terraform destroy` at worst loses a laptop cluster that can be rebuilt.
- Nothing to pay for, nothing to leak.

Bad:

- State lives on one machine, unversioned. If it is lost, the kind cluster must be
  deleted and recreated (cheap, ~1 minute).
- No locking. Irrelevant with one operator; would be dangerous with two.
- CI cannot run `terraform apply`. That is a feature here, not a limitation.

## Revisit when

Phase 7, and only for a new `environments/sandbox-aws/` directory with its own
remote state. `environments/local/` keeps its local backend permanently.
