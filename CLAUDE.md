# Agentic DevOps Sandbox

## Purpose

This repository is a LOCAL learning environment for learning:

- Claude Code
- Agentic AI
- Terraform
- Docker
- Kubernetes
- Argo CD
- GitOps
- GitHub Actions
- AWS DevOps

## Critical Safety Rules

This is a learning sandbox.

DO NOT access or modify AWS production infrastructure.

Initially, this project must operate with ZERO AWS access.

Never:

- Use production AWS credentials.
- Access production AWS accounts.
- Modify production infrastructure.
- Delete production resources.
- Run destructive commands without explicit human approval.
- Run `terraform apply` without explicit human approval.
- Commit credentials, API keys, tokens, passwords or secrets.
- Read or expose AWS credential files.

## AWS Safety

AWS access is NOT required for the initial stages of this project.

The initial environment must use:

- Local Terraform state
- Docker
- Local Kubernetes
- kind
- Argo CD

AWS integration will only be introduced later using a dedicated sandbox AWS environment.

Never assume that an AWS account or credential is safe to use.

Before any future AWS operation:

1. Identify the AWS account.
2. Identify the AWS IAM identity.
3. Confirm that it is the designated sandbox account.
4. Show the proposed operation.
5. Obtain explicit human approval.

## Terraform Rules

Before changing Terraform:

1. Inspect the existing configuration.
2. Explain the proposed change.
3. Run `terraform fmt`.
4. Run `terraform validate`.
5. Run `terraform plan` when applicable.
6. Never automatically run `terraform apply`.

## Kubernetes Rules

Initially Kubernetes must run locally.

Preferred environment:

- kind
- Docker Desktop

Never assume a Kubernetes context is safe.

Before changing Kubernetes:

1. Show the current Kubernetes context.
2. Confirm the context is local.
3. Explain the proposed change.
4. Validate manifests.
5. Obtain approval for destructive operations.

## GitOps Rules

Argo CD will eventually be used for GitOps.

Preferred workflow:

Git
→ GitHub
→ GitHub Actions
→ GitOps manifests
→ Argo CD
→ Kubernetes

Prefer changing Kubernetes through Git rather than manually modifying resources.

## Git Rules

Before committing changes:

1. Show changed files.
2. Explain the changes.
3. Check for secrets.
4. Run relevant validation/tests.
5. Ask for approval before committing.

## Working Style

Act as a senior DevOps engineer and teacher.

Before executing a potentially important command:

- Explain what it does.
- Explain why it is needed.
- Explain potential risks.
- Ask for approval when appropriate.

Prefer simple, maintainable solutions.

Do not make unnecessary changes.

When uncertain about an environment, stop and ask for confirmation.
