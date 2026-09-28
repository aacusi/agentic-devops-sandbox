# ADR-0006: Python + FastAPI for the sample application

- **Status:** accepted (assumption — flagged for confirmation)
- **Date:** 2026-09-02
- **Phase:** 1

## Context

The sample application is a prop. Its only job is to be deployed, rolled,
observed and rolled back. The interesting engineering in this project is in the
pipeline, not the app.

The design question was Python/FastAPI vs Go. This was raised as an open question
and not answered before implementation began, so Python was chosen and recorded
here as an explicit, cheap-to-reverse assumption.

## Decision

Python 3.12 + FastAPI, ~150 lines, exposing `/`, `/healthz`, `/readyz`,
`/version`, `/api/info`.

## Rationale

| | Python/FastAPI | Go |
|---|---|---|
| Readable/modifiable without a detour | yes | yes if you know Go |
| Final image size | ~150 MB | ~15 MB |
| Multi-stage build lesson | moderate | excellent (scratch/distroless) |
| Startup time | ~1 s | ~10 ms |
| Probe/OpenAPI ergonomics | excellent | fine |

Python wins on "you can change it without thinking about it", which matters when
the app is a prop. Go wins on image size and on making the multi-stage build
lesson vivid.

Two things partially recover Go's advantage without switching: the Dockerfile is
already multi-stage with a non-root runtime user, and phase 2 can compare image
sizes explicitly as a teaching exercise.

## Consequences

Good:

- Trivial to modify when you want to see a version bump roll through the pipeline.
- FastAPI makes the liveness/readiness distinction easy to implement properly,
  which is the one piece of real engineering the app needs.
- Tests and lint give phase 6 CI something real to run.

Bad:

- ~150 MB image means slower `kind load` than a Go binary would.
- Slower startup makes the `startupProbe` genuinely necessary — arguably a feature,
  since it forces the probe triad to be understood.
- A Python runtime carries more CVEs to triage than a static binary. Relevant when
  Trivy is added in phase 2.

## Revisit when

Now, if you would rather learn Go: the swap touches only `apps/hello-devops/` and
nothing else in the repository. After phase 2 the cost rises slightly (image tags,
CI), but it never becomes expensive.
