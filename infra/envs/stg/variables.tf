variable "project_id" {
  type        = string
  description = "GCP project ID for the stg environment."
}

variable "environment" {
  type        = string
  description = "Environment name for this root."
  default     = "stg"
  validation {
    condition     = var.environment == "stg"
    error_message = "The stg root must use environment = stg."
  }
}

variable "region" {
  type        = string
  description = "Primary GCP region for the stg environment."
  default     = "us-central1"
}

variable "owner" {
  type        = string
  description = "Owner label applied to resources."
}

variable "cost_center" {
  type        = string
  description = "Cost center label applied to resources."
}

variable "db_instance_tier" {
  type        = string
  description = "Future Cloud SQL tier for this environment."
  default     = "db-f1-micro"
}

variable "secret_ids" {
  type        = set(string)
  description = "Future Secret Manager secret IDs for this environment."
  default     = []
}

variable "secret_admin_members" {
  type        = map(string)
  description = "Optional human or CI identities that can administer specific secrets."
  default     = {}
}
