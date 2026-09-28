# infra/terraform/

Infrastructure as code for the sandbox. **Local state only. No cloud providers.
No credentials. Nothing has been applied.**

```
infra/terraform/
├── environments/
│   └── local/                  the only root module — kind + namespaces + Argo CD install
│       ├── versions.tf         required_version, LOCAL backend, no providers yet
│       ├── main.tf             locals + the phase 3/5 plan (zero resources today)
│       ├── variables.tf        inputs, with validation guardrails
│       ├── outputs.tf          computed from locals only
│       ├── terraform.tfvars.example
│       └── .gitignore          state, tfvars, plans
└── modules/                    reusable modules — empty until there is repetition
```

## What this module will own

| Owned by Terraform | Owned by Argo CD |
|---|---|
| The kind cluster | Application Deployments |
| Namespaces (`hello-devops`, `argocd`) | Services, ConfigMaps, Ingresses for apps |
| ingress-nginx | Anything under `k8s/` |
| The Argo CD **installation** | Argo CD `Application` objects |

Two controllers managing the same object is a fight neither wins: Terraform
reverts it to state, Argo CD reverts it to Git, forever. The boundary above is
recorded in [ADR-0004](../../docs/decisions/0004-terraform-argocd-ownership-boundary.md).

## The safe loop (phase 1 exercise)

```bash
make tf-fmt        # terraform fmt -recursive
make tf-init       # downloads nothing — there are no providers yet
make tf-validate   # syntax + type checking
make tf-plan       # expect: "No changes. Your infrastructure matches the configuration."
```

Because this module declares zero providers and zero resources, all four commands
are provably incapable of creating, modifying or contacting anything.

## `terraform apply`

`make tf-apply` **deliberately fails**. Applying is a human action in this repo:

```bash
make tf-plan                                        # review it properly
terraform -chdir=infra/terraform/environments/local apply   # only you run this
```

See CLAUDE.md → Terraform Rules.

## State

Written to `environments/local/terraform.tfstate` on this laptop, gitignored in
two places. State files contain resource attributes in plaintext, which is why
they are treated as sensitive even when the resources are not.

Remote state (S3 + DynamoDB locking) is a phase 7 topic, and only ever against a
dedicated sandbox AWS account with explicit approval per the CLAUDE.md checklist.
See [ADR-0005](../../docs/decisions/0005-local-terraform-state.md).

## Rules for this directory

1. Never add an `aws` provider to `environments/local/`. AWS gets its own
   environment directory, its own state and its own approval gate.
2. Pin every provider and every image tag.
3. No secrets in variables, outputs or tfvars.
4. `terraform fmt` and `terraform validate` before every commit.
