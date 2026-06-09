variable "project_id" {
  type        = string
  description = "GCP project ID for observability resources."
}

variable "environment" {
  type        = string
  description = "Environment name."
}

variable "logs_bucket_name" {
  type        = string
  description = "Bucket that receives exported operational logs."
}

variable "cloud_run_service_urls" {
  type        = map(string)
  description = "Cloud Run service URLs keyed by logical service name."
}

variable "pubsub_subscription_names" {
  type        = map(string)
  description = "Pub/Sub subscription names keyed by logical subscription key."
}

variable "sql_instance_name" {
  type        = string
  description = "Cloud SQL instance name for database alerting."
}

variable "notification_emails" {
  type        = set(string)
  description = "Email addresses used for Monitoring notification channels."
  default     = []
}

variable "pubsub_backlog_threshold" {
  type        = number
  description = "Backlog threshold for Pub/Sub undelivered message alerts."
  default     = 100
}

variable "sql_cpu_threshold" {
  type        = number
  description = "CPU threshold for Cloud SQL alerts, expressed as a ratio from 0 to 1."
  default     = 0.8
}

variable "error_count_threshold" {
  type        = number
  description = "Threshold for the custom application error metric."
  default     = 0.02
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to supported observability resources."
  default     = {}
}
