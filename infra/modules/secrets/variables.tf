variable "project_id" {
  type        = string
  description = "GCP project ID for the secrets module."
}

variable "environment" {
  type        = string
  description = "Environment name for the secrets module."
  validation {
    condition     = contains(["dev", "stg", "uat", "prod"], var.environment)
    error_message = "Environment must be one of dev, stg, uat, or prod."
  }
}

variable "secret_ids" {
  type        = set(string)
  description = "Secret IDs that Phase 03 will manage."
  default     = []
}

variable "labels" {
  type        = map(string)
  description = "Common labels applied to secret resources."
  default     = {}
}

variable "enable_workload_identity" {
  type        = bool
  description = "Enable Workload Identity bindings between Kubernetes service accounts and GCP service accounts."
  default     = true
}

variable "service_accounts" {
  type = map(object({
    account_id                 = optional(string)
    display_name               = string
    description                = string
    kubernetes_namespace       = string
    kubernetes_service_account = string
    project_roles              = set(string)
  }))
  description = "Per-service GCP service accounts and their least-privilege project roles."
  validation {
    condition = alltrue([
      for config in values(var.service_accounts) :
      !contains(config.project_roles, "roles/editor") && !contains(config.project_roles, "roles/owner")
    ])
    error_message = "Do not grant roles/editor or roles/owner to service accounts."
  }
}

variable "secrets" {
  type = map(object({
    owner_service = string
    accessors     = set(string)
  }))
  description = "Secret definitions without values. Values must be added outside Terraform."
  validation {
    condition = alltrue([
      for secret in values(var.secrets) :
      contains(keys(var.service_accounts), secret.owner_service)
    ])
    error_message = "Each secret owner_service must match a declared service account key."
  }
}

variable "secret_admin_members" {
  type        = map(string)
  description = "Optional human or CI members that can administer individual secrets."
  default     = {}
}
