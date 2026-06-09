variable "project_id" {
  type        = string
  description = "GCP project ID used for the deployment platform."
}

variable "region" {
  type        = string
  description = "Primary region for Artifact Registry and Cloud Deploy resources."
}

variable "artifact_bucket_location" {
  type        = string
  description = "Location for the Cloud Deploy artifact bucket."
  default     = "US"
}

variable "artifact_bucket_force_destroy" {
  type        = bool
  description = "Whether the Cloud Deploy artifact bucket can be force-destroyed."
  default     = false
}

variable "runner_service_account_id" {
  type        = string
  description = "Account ID for the Cloud Deploy execution service account."
  default     = "clouddeploy-runner"
}

variable "repositories" {
  type = map(object({
    repository_id  = string
    description    = string
    immutable_tags = bool
  }))
  description = "Artifact Registry repositories used by the deployment platform."
}

variable "targets" {
  type = map(object({
    require_approval  = bool
    gke_cluster       = string
    run_location      = string
    deploy_parameters = optional(map(string), {})
  }))
  description = "Environment deployment targets for GKE and Cloud Run."
}

variable "pipelines" {
  type = map(object({
    pipeline_id = string
    description = string
    target_type = string
  }))
  description = "Cloud Deploy delivery pipelines keyed by release lane."

  validation {
    condition = alltrue([
      for pipeline in values(var.pipelines) : contains(["gke", "run"], pipeline.target_type)
    ])
    error_message = "Each pipeline target_type must be either gke or run."
  }
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to supported deployment resources."
  default     = {}
}
