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
