#!/usr/bin/env bash
#
# guard-context.sh — refuse to continue unless kubectl points at THE local
# sandbox cluster belonging to this repository.
#
# Called by every Makefile target that touches Kubernetes.
#
# Two independent gates, checked in this order:
#
#   1. LOCALITY — the context must be a recognisably local cluster. This is the
#      gate that stops a manifest intended for a laptop from landing on a real
#      cluster, and it is deliberately NOT overridable.
#
#   2. IDENTITY — the context must be the one this repo expects. Overridable via
#      ALLOWED_CONTEXTS, because "I have a second local cluster on purpose" is a
#      legitimate situation; "I applied to the wrong local cluster without
#      noticing" is not.
#
# Gate 2 exists because gate 1 on its own accepts EVERY kind-* context. A stray
# cluster such as kind-devops-lab passes the locality check while having nothing
# to do with this project, so applying to it would be a silent mistake rather
# than a loud one. Loud is the entire point of this script.
#
# EXPECTED_CONTEXT must stay in sync with kind-<var.cluster_name> from
# infra/terraform/environments/local/variables.tf — Terraform is the source of
# truth for the cluster name (see main.tf's local.kube_context).
#
# Usage:
#   ./guard-context.sh
#   EXPECTED_CONTEXT=kind-something-else ./guard-context.sh
#   ALLOWED_CONTEXTS="kind-agentic-sandbox docker-desktop" ./guard-context.sh

set -euo pipefail

# The context this repository expects. Change this only alongside var.cluster_name.
EXPECTED_CONTEXT="${EXPECTED_CONTEXT:-kind-agentic-sandbox}"

# Extra contexts the operator explicitly vouches for, space-separated.
ALLOWED_CONTEXTS="${ALLOWED_CONTEXTS:-}"

# Gate 1 patterns. Anything not matching these cannot be a laptop cluster.
LOCAL_PREFIXES=("kind-")
LOCAL_EXACT=("docker-desktop" "minikube" "rancher-desktop")

if ! command -v kubectl >/dev/null 2>&1; then
  echo "guard-context: kubectl is not installed — nothing to guard (phase 3+)." >&2
  exit 1
fi

ctx="$(kubectl config current-context 2>/dev/null || true)"

if [[ -z "$ctx" ]]; then
  echo "guard-context: no current kubectl context. Refusing to continue." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Gate 1: is this context local at all?
# ---------------------------------------------------------------------------
is_local=false

for prefix in "${LOCAL_PREFIXES[@]}"; do
  [[ "$ctx" == "$prefix"* ]] && is_local=true
done

for exact in "${LOCAL_EXACT[@]}"; do
  [[ "$ctx" == "$exact" ]] && is_local=true
done

if [[ "$is_local" != true ]]; then
  cat >&2 <<EOF
guard-context: REFUSING TO CONTINUE — CONTEXT IS NOT LOCAL

  current context : $ctx
  recognised local: kind-*, docker-desktop, minikube, rancher-desktop

This context is not a recognised local sandbox cluster and may be a real one.
This check cannot be overridden. Switch context first:

  kubectl config get-contexts
  kubectl config use-context $EXPECTED_CONTEXT

EOF
  exit 1
fi

# ---------------------------------------------------------------------------
# Gate 2: is it the RIGHT local context?
# ---------------------------------------------------------------------------
allowed=("$EXPECTED_CONTEXT")

if [[ -n "$ALLOWED_CONTEXTS" ]]; then
  # shellcheck disable=SC2206 # deliberate word-splitting of a space-separated list
  allowed+=($ALLOWED_CONTEXTS)
fi

is_expected=false

for candidate in "${allowed[@]}"; do
  [[ "$ctx" == "$candidate" ]] && is_expected=true
done

if [[ "$is_expected" != true ]]; then
  cat >&2 <<EOF
guard-context: REFUSING TO CONTINUE — WRONG LOCAL CLUSTER

  current context : $ctx
  expected        : $EXPECTED_CONTEXT
  also allowed    : ${ALLOWED_CONTEXTS:-<none>}

'$ctx' looks local, but it is not the cluster this repository manages. Applying
here would put this project's resources on an unrelated cluster.

Switch to the expected context:

  kubectl config use-context $EXPECTED_CONTEXT

If '$ctx' really is a local cluster you intend to target, vouch for it explicitly:

  ALLOWED_CONTEXTS="$ctx" <your command>

EOF
  exit 1
fi

echo "guard-context: OK — context '$ctx' is local and is the expected sandbox cluster."
