terraform {
  required_version = ">= 1.6.0"

  # LOCAL BACKEND ONLY.
  #
  # State is written to ./terraform.tfstate on this laptop and is gitignored,
  # because state files contain resource attributes in plaintext. There is no S3
  # bucket, no DynamoDB lock table and no cloud credential anywhere in this
  # configuration — see ADR-0005.
  #
  # Remote state is a phase 7 concern, and only against a dedicated sandbox
  # cloud environment.
  backend "local" {
    path = "terraform.tfstate"
  }

  # Phase 3 providers, all version-pinned.
  #
  # `kind` creates the cluster; `kubernetes` creates only the namespaces the
  # cluster must have before Argo CD and the app can be deployed into it. Per
  # ADR-0004 this module never manages application workloads — those belong to
  # Argo CD, driven from k8s/ and gitops/.
  #
  # `helm` arrived in phase 5, for the Argo CD installation only. It installs
  # exactly one chart — argo-cd, pinned to var.argocd_chart_version — and per
  # ADR-0004 it will never be used for an application workload.
  #
  # There will never be a cloud provider in this root module. When cloud access
  # arrives in phase 7 it gets its own environment directory, its own state, and
  # its own approval gate.
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.9"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
  }
}
