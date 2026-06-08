variable "environment" {
  type        = string
  description = "Environment name."
}

variable "gcp_service_account_emails" {
  type        = map(string)
  description = "Map of GCP service account emails keyed by logical service name."
}

variable "services" {
  type = map(object({
    kubernetes_service_account = string
    gcp_service_account_key    = string
    image                      = string
    replicas                   = number
    limits                     = map(string)
    response_text              = optional(string)
  }))
  description = "GKE service stub definitions."
}

variable "deploy_keycloak" {
  type        = bool
  description = "Deploy Keycloak through Helm instead of the default auth placeholder."
  default     = false
}

variable "keycloak_chart_version" {
  type        = string
  description = "Bitnami Keycloak chart version."
  default     = "24.4.11"
}

variable "keycloak_admin_user" {
  type        = string
  description = "Keycloak admin user when Helm deployment is enabled."
  default     = "streamflix-admin"
}

variable "keycloak_admin_password" {
  type        = string
  description = "Keycloak admin password when Helm deployment is enabled."
  default     = "ChangeMe123!"
  sensitive   = true
}
