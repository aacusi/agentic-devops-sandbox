#!/usr/bin/env bash
#
# preflight.sh — read-only environment report.
#
# Prints the versions of the tools this sandbox uses and the current Kubernetes
# context. Changes nothing, creates nothing, contacts no cloud provider.
# Deliberately never invokes the AWS CLI or reads any credential file.
#
# Missing tools are reported, not treated as errors: each phase introduces more.

set -uo pipefail

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
dim() { printf '\033[2m%s\033[0m\n' "$1"; }

report() {
  local name="$1"
  shift
  if command -v "$name" >/dev/null 2>&1; then
    printf '  %-12s %s\n' "$name" "$("$@" 2>&1 | head -n 1)"
  else
    printf '  %-12s %s\n' "$name" "not installed"
  fi
}

bold "Agentic DevOps Sandbox — preflight"
echo
dim "Repository"
printf '  %-12s %s\n' "path" "$(pwd)"
if command -v git >/dev/null 2>&1; then
  printf '  %-12s %s\n' "branch" "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'not a git repo')"
  printf '  %-12s %s\n' "dirty" "$(test -n "$(git status --porcelain 2>/dev/null)" && echo yes || echo no)"
fi

echo
dim "Phase 1 tools"
report git git --version
report python3 python3 --version
report make make --version

echo
dim "Phase 2-5 tools"
report docker docker --version
report kind kind --version
report kubectl kubectl version --client
report terraform terraform version
report kustomize kustomize version
report argocd argocd version --client

echo
dim "Kubernetes context (read-only)"
if command -v kubectl >/dev/null 2>&1; then
  ctx="$(kubectl config current-context 2>/dev/null || true)"
  if [[ -z "$ctx" ]]; then
    printf '  %-12s %s\n' "context" "none configured"
  else
    printf '  %-12s %s\n' "context" "$ctx"
    if [[ "$ctx" == kind-* || "$ctx" == "docker-desktop" ]]; then
      printf '  %-12s %s\n' "verdict" "local — safe"
    else
      printf '  %-12s %s\n' "verdict" "NOT a recognised local context — do not apply anything"
    fi
  fi
else
  printf '  %-12s %s\n' "context" "kubectl not installed"
fi

echo
dim "Docker daemon (read-only)"
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    printf '  %-12s %s\n' "daemon" "running"
  else
    printf '  %-12s %s\n' "daemon" "not running"
  fi
else
  printf '  %-12s %s\n' "daemon" "docker not installed"
fi

echo
dim "Cloud access"
printf '  %-12s %s\n' "aws" "intentionally not checked — this sandbox has zero AWS access"
echo
