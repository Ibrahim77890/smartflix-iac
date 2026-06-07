variable "project_id" {
  type        = string
  description = "GCP project ID for the database module."
}

variable "environment" {
  type        = string
  description = "Environment name for the database module."
  validation {
    condition     = contains(["dev", "stg", "uat", "prod"], var.environment)
    error_message = "Environment must be one of dev, stg, uat, or prod."
  }
}

variable "region" {
  type        = string
  description = "Primary GCP region for data services."
}

variable "db_name" {
  type        = string
  description = "Future primary database name."
}

variable "instance_tier" {
  type        = string
  description = "Future Cloud SQL instance tier."
}
