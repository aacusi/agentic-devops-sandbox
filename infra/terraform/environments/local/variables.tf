# Inputs for the local sandbox environment.
#
# Every variable has a default so `terraform plan` runs with no tfvars file. The
# validation blocks are guardrails, not decoration: they make it impossible for
# this root module to be pointed at anything that is not a local sandbox.

variable "environment" {
  description = "Environment name. This root module accepts only 'local'."
  type        = string
  default     = "local"

  validation {
    condition     = var.environment == "local"
    error_message = "This root module is local-only. Non-local environments require a separate directory, separate state and explicit human approval."
  }
}

variable "cluster_name" {
  description = "Name of the kind cluster. The kubectl context becomes 'kind-<cluster_name>'."
  type        = string
  default     = "agentic-sandbox"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}[a-z0-9]$", var.cluster_name))
    error_message = "cluster_name must be lowercase alphanumeric with hyphens, 3-32 characters."
  }
}

variable "kind_node_image" {
  description = "kind node image, pinned by tag. Determines the Kubernetes version. Used from phase 3."
  type        = string
  default     = "kindest/node:v1.31.0"

  validation {
    condition     = can(regex("^kindest/node:v[0-9]+\\.[0-9]+\\.[0-9]+", var.kind_node_image))
    error_message = "kind_node_image must be a pinned kindest/node image, e.g. kindest/node:v1.31.0."
  }
}

variable "worker_count" {
  description = "Number of kind worker nodes. Kept small: this runs on a laptop."
  type        = number
  default     = 2

  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 3
    error_message = "worker_count must be between 1 and 3 to stay within laptop resources."
  }
}

variable "app_namespace" {
  description = "Namespace for the sample application. Created by Terraform, populated by Argo CD."
  type        = string
  default     = "hello-devops"
}

variable "argocd_namespace" {
  description = "Namespace Argo CD is installed into. Used from phase 5."
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Pinned Argo CD Helm chart version. Used from phase 5."
  type        = string
  default     = "7.7.11"
}
