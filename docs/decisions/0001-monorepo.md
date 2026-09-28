# ADR-0001: Single repository, with a splittable internal boundary

- **Status:** accepted
- **Date:** 2026-09-02
- **Phase:** 1

## Context

The canonical GitOps setup uses at least two repositories: one for application
source, one for deployment manifests. This keeps CI (which builds images) from
fighting with Argo CD (which reads manifests), and stops a manifest bump from
triggering an application rebuild.

That separation is correct at scale. It also triples the number of places to look
while learning, and makes every early experiment a cross-repo change.

## Decision

One repository, with a strict internal boundary:

| Directory | Contains | Consumed by |
|---|---|---|
| `apps/` | source, tests, Dockerfile | CI (phase 6) |
| `k8s/` | Kustomize bases and overlays | Argo CD (phase 5) |
| `gitops/` | Argo CD Applications and install config | Argo CD (phase 5) |
| `infra/` | Terraform | a human running `apply` |

No file crosses those boundaries. `apps/` never contains a manifest; `k8s/` never
contains source.

## Consequences

Good:

- One clone, one `git log`, one PR per change while learning.
- The boundary is still taught and enforced by convention.
- Splitting later is mechanical: `git filter-repo --path k8s --path gitops` into a
  new repo, then update the Argo CD `Application.spec.source.repoURL`.

Bad:

- Phase 6 CI must use path filters, or every manifest edit rebuilds the image.
- The CI write-back loop (build → update manifest → retrigger CI) is a real risk
  in a monorepo. Mitigation is to promote via a PR rather than a push, decided in
  phase 6.

## Revisit when

Phase 6, when CI starts writing image tags back to the repository. If path filters
and PR-based promotion feel like fighting the tool, split it.
