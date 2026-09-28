#!/usr/bin/env python3
"""PreToolUse hook: block dangerous shell commands in this sandbox.

Why this exists in addition to the deny list in settings.json:

  * settings.json patterns match the *start* of a command. This catches the same
    commands anywhere in a pipeline, a subshell, or after `&&`.
  * It is enforcement that does not depend on the model's judgement. The rules in
    CLAUDE.md describe intent; this refuses regardless of intent.

Contract with Claude Code:
  stdin  : JSON with {"tool_name": ..., "tool_input": {"command": ...}}
  exit 0 : allow
  exit 2 : block, and show stderr to the model

Fails OPEN on unexpected input (exit 0). A hook that breaks every Bash call
because of a parsing edge case is worse than no hook; the settings.json deny list
and CLAUDE.md remain in force underneath it.

To disable temporarily, remove the hooks block from .claude/settings.json.
"""

from __future__ import annotations

import json
import re
import sys

# (pattern, reason). Patterns are matched case-insensitively against the whole
# command string, so they also catch usage inside pipelines and after && or ;.
RULES: list[tuple[str, str]] = [
    # --- Cloud access: this sandbox has none, at any stage ---------------------
    (
        r"(^|[\s;&|(`])aws2?(\s|$)",
        "The AWS CLI must not be used. This sandbox operates with ZERO AWS access "
        "(CLAUDE.md > AWS Safety).",
    ),
    (
        r"(^|[\s;&|(`])(eksctl|awslocal|sam|cdk)(\s|$)",
        "AWS-adjacent tooling is out of scope until a dedicated sandbox account "
        "exists (phase 7).",
    ),
    (
        r"\.aws/(credentials|config)|aws\s+configure|AWS_SECRET_ACCESS_KEY|AWS_ACCESS_KEY_ID",
        "Reading, writing or exporting AWS credentials is forbidden in this repository.",
    ),
    (
        r"(^|[\s;&|(`])(gcloud|az|doctl)(\s|$)",
        "No cloud provider CLIs. This sandbox is local-only.",
    ),
    # --- Terraform: apply is a human action -----------------------------------
    (
        r"terraform(\s+-chdir=\S+)?\s+(apply|destroy|import|force-unlock)",
        "terraform apply/destroy/import must be run by a human after reviewing a plan "
        "(CLAUDE.md > Terraform Rules). Use `make tf-plan`, then run it yourself.",
    ),
    (
        r"terraform(\s+-chdir=\S+)?\s+state\s+(rm|push|replace-provider)",
        "Mutating Terraform state is destructive and human-only.",
    ),
    # --- Kubernetes: destructive and out-of-band changes ----------------------
    (
        r"kubectl\s+(\S+\s+)*?(delete|drain|cordon|uncordon|taint)(\s|$)",
        "Destructive kubectl operations require explicit human approval "
        "(CLAUDE.md > Kubernetes Rules).",
    ),
    (
        r"kubectl\s+(\S+\s+)*?(edit|patch|replace|scale|rollout\s+undo)(\s|$)",
        "Do not change the cluster out-of-band. Change the manifest in k8s/, commit, "
        "and let Argo CD apply it (CLAUDE.md > GitOps Rules).",
    ),
    (
        r"kind\s+delete",
        "Deleting the kind cluster is destructive and human-only. See "
        "docs/runbooks/reset-cluster.md.",
    ),
    # --- Docker: destructive cleanup ------------------------------------------
    (
        r"docker\s+(system|volume|image|network|builder)\s+prune",
        "docker prune can delete resources unrelated to this sandbox. Human-only.",
    ),
    (
        r"docker\s+(rm|rmi)\s",
        "Removing containers or images requires human approval — kind nodes are "
        "containers, and one of these can destroy the cluster.",
    ),
    # --- Git / GitHub: no remotes exist yet -----------------------------------
    (
        r"git\s+push",
        "There is no remote yet, and pushing is an outward-facing action. "
        "GitHub arrives in phase 6, with approval.",
    ),
    (
        r"git\s+(reset\s+--hard|clean\s+-[a-z]*f)",
        "This discards uncommitted work. Ask the human to run it.",
    ),
    (
        r"gh\s+(repo\s+create|secret|auth\s+login)",
        "Creating remote repositories or secrets is an outward-facing action "
        "requiring approval (phase 6).",
    ),
    # --- Blunt instruments ----------------------------------------------------
    (
        r"rm\s+-[a-z]*r[a-z]*f?\s+(/|~|\$HOME)",
        "Recursive deletion outside the project directory is never appropriate here.",
    ),
    (
        r"(^|[\s;&|(`])(curl|wget)\s[^|]*\|\s*(sudo\s+)?(bash|sh|zsh)",
        "Piping a downloaded script into a shell installs unreviewed code. "
        "Install tools yourself via a package manager.",
    ),
    (
        r"(^|[\s;&|(`])sudo(\s|$)",
        "Nothing in this sandbox needs root. If it seems to, something is wrong.",
    ),
]

COMPILED = [(re.compile(pattern, re.IGNORECASE), reason) for pattern, reason in RULES]


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0  # fail open — see module docstring

    if payload.get("tool_name") != "Bash":
        return 0

    command = (payload.get("tool_input") or {}).get("command")
    if not isinstance(command, str) or not command.strip():
        return 0

    for pattern, reason in COMPILED:
        if pattern.search(command):
            print(
                "BLOCKED by .claude/hooks/deny-dangerous-commands.py\n\n"
                f"  command : {command.strip()}\n"
                f"  matched : {pattern.pattern}\n"
                f"  reason  : {reason}\n\n"
                "Explain what you wanted to do and why, and ask the human to run it.",
                file=sys.stderr,
            )
            return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
