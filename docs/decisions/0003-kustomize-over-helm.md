# ADR-0003: Kustomize first, Helm later

- **Status:** accepted
- **Date:** 2026-09-02
- **Phase:** 1 (decision), 4 (implementation)

## Context

Two mainstream ways to vary Kubernetes manifests per environment: Helm (Go
templates + values) and Kustomize (plain YAML + declarative overlays). Argo CD
supports both natively.

The goal of phases 3-5 is understanding what Kubernetes actually does. Anything
that stands between you and the object that reaches the API server works against
that.

## Decision

**Kustomize** for the sandbox application. Helm is used only for installing
third-party components (Argo CD, ingress-nginx) where an upstream chart exists.

## Rationale

- A Kustomize base is a valid manifest. You can read `deployment.yaml` and know
  exactly what it means, with no mental template rendering.
- `kubectl kustomize <overlay>` shows the exact final object with no cluster and
  no tooling beyond kubectl. That feedback loop is the fastest way to learn.
- Debugging Helm means debugging YAML-inside-Go-templates-with-whitespace-control,
  which teaches you about Helm, not about Kubernetes.
- `configMapGenerator`'s content hashing solves a real problem for free: a
  ConfigMap change produces a new name, which forces a rollout. Doing this in Helm
  requires a checksum annotation you have to remember to add.

Helm's genuine advantages — packaging, distribution, versioned releases,
`helm rollback` — matter when you are shipping software to other people. That is
not what this repository does.

## Consequences

Good: plain YAML, trivial diffs, no templating layer, native Argo CD support.

Bad:

- Kustomize is weaker at genuine parameterisation. A dozen environments would hurt;
  we have one.
- Two tools in the repo (Kustomize for our app, Helm for vendor components). This
  is the normal state of affairs in real clusters, so it is worth being used to.
- Overlay-heavy setups become hard to follow past ~3 levels. Cap at base + one
  overlay per environment.

## Revisit when

Phase 6+, if the app needs to be packaged for others, or if a third environment
introduces real parameterisation pressure.
