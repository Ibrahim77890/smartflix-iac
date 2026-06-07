variable "project_id" {
  type        = string
  description = "GCP project ID for the future GKE cluster."
}

variable "environment" {
  type        = string
  description = "Environment name for the GKE module."
  validation {
    condition     = contains(["dev", "stg", "uat", "prod"], var.environment)
    error_message = "Environment must be one of dev, stg, uat, or prod."
  }
}

variable "region" {
  type        = string
  description = "Primary GCP region for the future cluster."
}

variable "cluster_name" {
  type        = string
  description = "Future GKE cluster name."
}
