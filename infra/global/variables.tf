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
