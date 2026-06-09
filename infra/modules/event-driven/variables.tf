variable "project_id" {
  type        = string
  description = "GCP project ID for event-driven resources."
}

variable "environment" {
  type        = string
  description = "Environment name."
}

variable "region" {
  type        = string
  description = "Primary region for event-driven services."
}

variable "artifact_bucket_name" {
  type        = string
  description = "Bucket used to store Cloud Functions source archives."
}

variable "media_bucket_name" {
  type        = string
  description = "Media bucket used to generate upload events."
}

variable "media_bucket_location" {
  type        = string
  description = "Location of the media bucket, used for the Eventarc trigger region."
}

variable "storage_service_account_email" {
  type        = string
  description = "Cloud Storage service account email for Pub/Sub notifications."
}

variable "topics" {
  type = map(object({
    message_retention_duration = string
    subscriptions = map(object({
      name                       = string
      ack_deadline_seconds       = number
      message_retention_duration = string
      dead_letter_topic_key      = optional(string)
    }))
  }))
  description = "Pub/Sub topics and subscriptions."
}

variable "functions" {
  type = map(object({
    source_dir            = string
    entry_point           = string
    topic_key             = string
    service_account_email = string
    available_memory      = string
    timeout_seconds       = number
  }))
  description = "Cloud Functions Gen 2 definitions."
}

variable "workflow_service_account_email" {
  type        = string
  description = "Service account used by Cloud Workflows."
}

variable "eventarc_service_account_email" {
  type        = string
  description = "Service account used by Eventarc."
}

variable "workflow_thumbnail_url" {
  type        = string
  description = "URL called by the workflow for thumbnail generation."
}

variable "workflow_subtitle_url" {
  type        = string
  description = "URL called by the workflow for subtitle indexing."
}

variable "workflow_publish_topic_key" {
  type        = string
  description = "Topic key the workflow publishes to after orchestration."
}

variable "media_upload_topic_key" {
  type        = string
  description = "Topic key that receives media bucket upload notifications."
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to supported resources."
  default     = {}
}
