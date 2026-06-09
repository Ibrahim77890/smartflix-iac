variable "project_id" {
  type        = string
  description = "GCP project ID for the prod environment."
}

variable "environment" {
  type        = string
  description = "Environment name for this root."
  default     = "prod"
  validation {
    condition     = var.environment == "prod"
    error_message = "The prod root must use environment = prod."
  }
}

variable "region" {
  type        = string
  description = "Primary GCP region for the prod environment."
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
  default     = "db-g1-small"
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

variable "enable_workload_identity_bindings" {
  type        = bool
  description = "Create GCP Workload Identity bindings for Kubernetes service accounts."
  default     = false
}

variable "deploy_gke_workloads" {
  type        = bool
  description = "Deploy Kubernetes and Helm workloads into the GKE cluster. Keep false when applying from outside the VPC to a private-only control plane."
  default     = false
}

variable "alert_notification_emails" {
  type        = set(string)
  description = "Optional email addresses used for Monitoring alert notifications in this environment."
  default     = []
}
