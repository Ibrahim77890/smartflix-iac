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
  description = "Primary application database name."
}

variable "instance_tier" {
  type        = string
  description = "Cloud SQL primary instance tier."
}

variable "private_network" {
  type        = string
  description = "Private VPC self link used by Cloud SQL and Redis."
}

variable "availability_type" {
  type        = string
  description = "Cloud SQL availability type."
  default     = "ZONAL"
  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "availability_type must be ZONAL or REGIONAL."
  }
}

variable "disk_size_gb" {
  type        = number
  description = "Cloud SQL disk size in GB."
  default     = 10
}

variable "enable_point_in_time_recovery" {
  type        = bool
  description = "Enable point-in-time recovery for Cloud SQL."
  default     = true
}

variable "backup_start_time" {
  type        = string
  description = "Cloud SQL backup start time in UTC."
  default     = "03:00"
}

variable "database_version" {
  type        = string
  description = "Cloud SQL database version."
  default     = "POSTGRES_15"
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection for stateful resources."
  default     = false
}

variable "read_replica_enabled" {
  type        = bool
  description = "Create a read replica for the Cloud SQL instance."
  default     = false
}

variable "replica_tier" {
  type        = string
  description = "Tier for the Cloud SQL read replica."
  default     = "db-custom-1-3840"
}

variable "firestore_database_name" {
  type        = string
  description = "Firestore database ID."
}

variable "firestore_location_id" {
  type        = string
  description = "Firestore location ID."
}

variable "firestore_delete_protection_state" {
  type        = string
  description = "Firestore delete protection state."
  default     = "DELETE_PROTECTION_DISABLED"
}

variable "firestore_deletion_policy" {
  type        = string
  description = "Firestore deletion policy."
  default     = "DELETE"
}

variable "firestore_ttl_collection" {
  type        = string
  description = "Collection group that gets TTL configured."
  default     = "watch_history"
}

variable "firestore_ttl_field" {
  type        = string
  description = "Field used as the Firestore TTL marker."
  default     = "expires_at"
}

variable "firestore_index_collection" {
  type        = string
  description = "Collection group that gets the sample composite index."
  default     = "watch_history"
}

variable "firestore_index_first_field" {
  type        = string
  description = "First field in the sample Firestore composite index."
  default     = "profile_id"
}

variable "firestore_index_second_field" {
  type        = string
  description = "Second field in the sample Firestore composite index."
  default     = "watched_at"
}

variable "redis_tier" {
  type        = string
  description = "Memorystore service tier."
  default     = "BASIC"
}

variable "redis_memory_size_gb" {
  type        = number
  description = "Redis memory size in GB."
  default     = 1
}

variable "kms_location" {
  type        = string
  description = "Location for the KMS key ring used by storage buckets."
  default     = "us-central1"
}

variable "kms_rotation_period" {
  type        = string
  description = "Rotation period for bucket crypto keys."
  default     = "7776000s"
}

variable "buckets" {
  type = map(object({
    name          = string
    location      = string
    storage_class = string
    versioning    = bool
    force_destroy = bool
    cors = list(object({
      origin          = list(string)
      method          = list(string)
      response_header = list(string)
      max_age_seconds = number
    }))
    lifecycle_rules = list(object({
      action = object({
        type          = string
        storage_class = optional(string)
      })
      condition = object({
        age                   = optional(number)
        matches_storage_class = optional(list(string))
        num_newer_versions    = optional(number)
      })
    }))
  }))
  description = "Bucket definitions for media, logs, and artifacts."
}

variable "labels" {
  type        = map(string)
  description = "Common labels for data resources."
  default     = {}
}
