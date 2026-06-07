variable "project_id" {
  type        = string
  description = "GCP project ID used for the bootstrap state bucket."
}

variable "region" {
  type        = string
  description = "Default GCP region used by the bootstrap provider."
  default     = "us-central1"
}

variable "bucket_location" {
  type        = string
  description = "Location for the Terraform state bucket."
  default     = "US"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique GCS bucket name for Terraform remote state."
  default     = "terraform-state-streamflix"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "State bucket name must be a valid GCS bucket name."
  }
}

variable "state_version_retention" {
  type        = number
  description = "Number of old state object versions to retain before cleanup."
  default     = 20
  validation {
    condition     = var.state_version_retention >= 5
    error_message = "Keep at least five versions for safe state recovery."
  }
}

variable "owner" {
  type        = string
  description = "Owner label for the bootstrap resources."
  default     = "platform-team"
}

variable "cost_center" {
  type        = string
  description = "Cost center label for the bootstrap resources."
  default     = "streamflix-lab"
}

variable "labels" {
  type        = map(string)
  description = "Additional labels to merge into the state bucket."
  default     = {}
}
