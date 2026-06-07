variable "project_id" {
  type        = string
  description = "GCP project ID for the environment network."
}

variable "environment" {
  type        = string
  description = "Environment name for the network module."
  validation {
    condition     = contains(["dev", "stg", "uat", "prod"], var.environment)
    error_message = "Environment must be one of dev, stg, uat, or prod."
  }
}

variable "region" {
  type        = string
  description = "Primary GCP region for the environment."
}

variable "vpc_name" {
  type        = string
  description = "Future VPC name for the environment."
}

variable "labels" {
  type        = map(string)
  description = "Labels that later network resources must inherit."
  default     = {}
}
