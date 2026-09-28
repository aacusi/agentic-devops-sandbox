# .claude/

Claude Code configuration for this repository — guardrails as code.

```
.claude/
├── settings.json                        committed: permissions + hook wiring
├── settings.local.json                  gitignored: your personal overrides
├── hooks/
│   └── deny-dangerous-commands.py       PreToolUse hook, blocks dangerous shell commands
└── commands/                            project slash commands (added over time)
```

## Four layers, deliberately redundant

| Layer | Enforced by | Bypassable by the model? |
|---|---|---|
| [CLAUDE.md](../CLAUDE.md) | the model reading it | yes, in principle |
| `settings.json` permissions | the Claude Code harness | no |
| `hooks/deny-dangerous-commands.py` | the harness, before every Bash call | no |
| [scripts/guard-context.sh](../scripts/guard-context.sh) | the Makefile / the script itself | no |

CLAUDE.md states the intent. The other three refuse regardless of intent. Both
matter: rules an agent understands produce better proposals, and rules the harness
enforces produce a safe floor when understanding fails.

## What is allowed without asking

Read-only inspection, because this is where an agent earns its keep: `git status`,
`git diff`, `kubectl get/describe/logs`, `terraform plan`, `docker ps`,
`argocd app diff`, and the safe make targets.

## What is denied outright

- **All cloud CLIs** — `aws`, `eksctl`, `gcloud`, `az`. Not "ask first": denied.
- **`terraform apply` / `destroy` / `import`**, and state mutation.
- **Destructive kubectl** — `delete`, `drain`, `cordon`, `taint`.
- **Out-of-band kubectl** — `edit`, `patch`, `replace`, `scale`. Not because they
  are destructive, but because they bypass Git. From phase 5, Argo CD reverts them
  anyway; the deny list stops the habit forming earlier than that.
- **`docker prune` / `rm` / `rmi`** — kind nodes are containers.
- **`git push`, `gh repo create`, `gh secret`** — outward-facing, phase 6.
- **Reading credential files** — `~/.aws/**`, `~/.ssh/**`, `*.tfstate`, `.env`.

Denied does not mean impossible: it means *the agent* cannot do it. You can always
run any of these yourself, which is the point — the human stays in the loop for
anything irreversible.

## Known rough edge

The hook matches on the raw command text, so a denied phrase inside a *quoted
string* is blocked as well — a `grep` for the tool's name, or even a test script
that merely mentions it. This was hit twice while verifying the hook itself.

Two workarounds:

- assemble the phrase at runtime (`"a" + "ws s3 ls"`), as the snippet below does;
- edit files with the Read/Edit tools rather than a shell heredoc.

Failing in this direction is deliberate. A hook that parses shell quoting to
decide what is "really" a command is a hook with a bypass in it.

## Planned slash commands (later phases)

| Command | Phase | Does |
|---|---|---|
| `/cluster-status` | 3 | Context guard + nodes + pods across namespaces |
| `/tf-plan` | 3 | fmt, validate, plan, and summarise the diff |
| `/k8s-review` | 4 | Render the overlay and check probes, limits, tags, security context |
| `/argo-diff` | 5 | `argocd app diff` for every Application, explained |
| `/phase-review` | any | Check the current phase's acceptance criteria |

## Verifying the hook works

Note the string assembly — without it the hook blocks the command that tests it.

```bash
python3 - <<'PY'
import json, subprocess
HOOK = ".claude/hooks/deny-dangerous-commands.py"
for cmd, expected in [("a" + "ws s3 ls", 2), ("kubectl get pods", 0)]:
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd}})
    r = subprocess.run(["python3", HOOK], input=payload, capture_output=True, text=True)
    print("PASS" if r.returncode == expected else "FAIL", r.returncode, cmd)
PY
```

Expected: `PASS 2` for the cloud CLI, `PASS 0` for the read-only kubectl call.
