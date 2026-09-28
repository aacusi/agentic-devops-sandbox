# Agentic DevOps Sandbox — one vocabulary for humans and agents.
#
# Every task in this repo has a make target. If you find yourself typing a long
# command by hand, it belongs here instead: agents make fewer mistakes when there
# is exactly one documented way to do a thing.
#
# Targets are grouped by phase. Later phases fail loudly until they are built.
# Note there is deliberately NO working `terraform apply` target — see tf-apply.

SHELL := /bin/bash
.DEFAULT_GOAL := help

APP_NAME  := hello-devops
APP_DIR   := apps/$(APP_NAME)
VERSION   := $(shell awk -F'"' '/^version = /{print $$2; exit}' $(APP_DIR)/pyproject.toml)
IMAGE     := $(APP_NAME):$(VERSION)

VENV      := $(APP_DIR)/.venv
PY        := $(VENV)/bin/python
PIP       := $(VENV)/bin/pip

TF_DIR    := infra/terraform/environments/local
KIND_CFG  := clusters/kind/kind-config.yaml
K8S_OVER  := k8s/$(APP_NAME)/overlays/local

.PHONY: help preflight install run test lint fmt clean version \
        docker-build docker-run \
        tf-fmt tf-init tf-validate tf-plan tf-apply \
        cluster-up cluster-down cluster-context \
        k8s-build k8s-validate

## ----------------------------------------------------------------------------
## General
## ----------------------------------------------------------------------------

help: ## Show this help
	@echo "Agentic DevOps Sandbox — available targets"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Current app version: $(VERSION)  (image would be $(IMAGE))"

version: ## Print the application version
	@echo $(VERSION)

preflight: ## Read-only: show tool versions and the current kube context
	@bash scripts/preflight.sh

clean: ## Remove local build artefacts and the virtualenv
	rm -rf $(VENV) $(APP_DIR)/src/*.egg-info $(APP_DIR)/.pytest_cache \
	       $(APP_DIR)/.ruff_cache
	find . -type d -name __pycache__ -prune -exec rm -rf {} +

## ----------------------------------------------------------------------------
## Phase 1 — application on the laptop
## ----------------------------------------------------------------------------

install: ## Create a virtualenv and install the app with dev dependencies
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -e "$(APP_DIR)[dev]"

run: ## Run the app locally on http://localhost:8000
	APP_ENV=local APP_VERSION=$(VERSION) \
		$(VENV)/bin/uvicorn hello_devops.main:app --host 127.0.0.1 --port 8000 --reload

test: ## Run the test suite
	cd $(APP_DIR) && ../../$(VENV)/bin/pytest -q

lint: ## Lint and check formatting (no changes made)
	$(VENV)/bin/ruff check $(APP_DIR)
	$(VENV)/bin/ruff format --check $(APP_DIR)

fmt: ## Auto-format the Python code
	$(VENV)/bin/ruff format $(APP_DIR)
	$(VENV)/bin/ruff check --fix $(APP_DIR)

## ----------------------------------------------------------------------------
## Phase 2 — Docker (artifacts exist; nothing has been built yet)
## ----------------------------------------------------------------------------

docker-build: ## Build the container image (phase 2)
	docker build -t $(IMAGE) --build-arg APP_VERSION=$(VERSION) $(APP_DIR)

docker-run: ## Run the container on http://localhost:8000 (phase 2)
	docker run --rm -p 8000:8000 -e APP_ENV=docker $(IMAGE)

## ----------------------------------------------------------------------------
## Phase 3 — Terraform (LOCAL state only) and the kind cluster
## ----------------------------------------------------------------------------

tf-fmt: ## Format Terraform files
	terraform -chdir=$(TF_DIR) fmt -recursive

tf-init: ## Initialise Terraform with the local backend
	terraform -chdir=$(TF_DIR) init

tf-validate: ## Validate the Terraform configuration
	terraform -chdir=$(TF_DIR) validate

tf-plan: ## Show what Terraform would change (safe, read-only)
	terraform -chdir=$(TF_DIR) plan

tf-apply: ## Intentionally blocked — apply requires explicit human approval
	@echo "REFUSED: 'terraform apply' must never be run by automation in this repo."
	@echo ""
	@echo "  1. Review the plan:  make tf-plan"
	@echo "  2. If you approve, run it yourself:"
	@echo "       terraform -chdir=$(TF_DIR) apply"
	@echo ""
	@echo "See CLAUDE.md > Terraform Rules."
	@exit 1

cluster-context: ## Fail unless the current kube context is a local one
	@bash scripts/guard-context.sh

cluster-up: ## Create the local kind cluster (phase 3 — not implemented yet)
	@echo "Not implemented until phase 3."
	@echo "Planned: the kind cluster is created by Terraform, not by this target."
	@echo "Topology lives in $(KIND_CFG)."
	@exit 1

cluster-down: ## Delete the local kind cluster (phase 3 — needs human approval)
	@echo "Not implemented. Deleting a cluster is destructive and must be run by a human:"
	@echo "    kind delete cluster --name agentic-sandbox"
	@exit 1

## ----------------------------------------------------------------------------
## Phase 4 — Kubernetes manifests
## ----------------------------------------------------------------------------

k8s-build: ## Render the local Kustomize overlay to stdout (no cluster needed)
	kubectl kustomize $(K8S_OVER)

k8s-validate: ## Render and server-side dry-run the overlay (requires a local cluster)
	@bash scripts/guard-context.sh
	kubectl apply -k $(K8S_OVER) --dry-run=server
