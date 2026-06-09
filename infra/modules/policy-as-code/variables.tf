variable "project_id" {
  type        = string
  description = "GCP project ID for policy-as-code resources."
}

variable "project_prefix" {
  type        = string
  description = "Short prefix used for policy resource naming."
  default     = "streamflix"
}

variable "kms_location" {
  type        = string
  description = "KMS location used for attestation keys."
  default     = "us"
}

variable "policy_bucket_location" {
  type        = string
  description = "Location used for the policy library bucket."
  default     = "US"
}

variable "additional_whitelist_patterns" {
  type        = list(string)
  description = "Additional Binary Authorization whitelist patterns."
  default     = []
}

variable "labels" {
  type        = map(string)
  description = "Labels applied to supported policy resources."
  default     = {}
}
