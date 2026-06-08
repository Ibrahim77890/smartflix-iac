variable "project_id" {
  type        = string
  description = "GCP project ID used by the global root."
}

variable "region" {
  type        = string
  description = "Default GCP region for globally scoped resources that still need one."
  default     = "us-central1"
}

variable "owner" {
  type        = string
  description = "Owner label applied to global resources."
}

variable "cost_center" {
  type        = string
  description = "Cost center label applied to global resources."
}

variable "org_policy_parent" {
  type        = string
  description = "Optional override for org policy parent, for example organizations/1234567890 or projects/1234567890. Leave null to derive the current project's numeric parent automatically."
  default     = null
  validation {
    condition     = var.org_policy_parent == null || can(regex("^(organizations|projects)/[0-9]+$", var.org_policy_parent))
    error_message = "org_policy_parent must look like organizations/1234567890 or projects/1234567890."
  }
}
