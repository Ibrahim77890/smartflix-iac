variable "project_id" {
  type        = string
  description = "GCP project ID for Cloud Run edge services."
}

variable "environment" {
  type        = string
  description = "Environment name."
}

variable "region" {
  type        = string
  description = "Primary GCP region."
}

variable "connector_network" {
  type        = string
  description = "VPC name used by the Serverless VPC Access connector."
}

variable "connector_ip_cidr_range" {
  type        = string
  description = "Dedicated /28 range for the Serverless VPC Access connector."
}

variable "connector_machine_type" {
  type        = string
  description = "Machine type for the VPC access connector."
  default     = "e2-micro"
}

variable "connector_min_instances" {
  type        = number
  description = "Minimum connector instances."
  default     = 2
}

variable "connector_max_instances" {
  type        = number
  description = "Maximum connector instances."
  default     = 3
}

variable "services" {
  type = map(object({
    image                 = string
    container_port        = number
    service_account_email = string
    ingress               = string
    min_instances         = number
    max_instances         = number
    limits                = map(string)
    env                   = map(string)
  }))
  description = "Cloud Run services to deploy."
}

variable "lb_domains" {
  type        = list(string)
  description = "Domains for the optional HTTPS load balancer. Leave empty to skip LB creation."
  default     = []
}

variable "lb_backends" {
  type        = set(string)
  description = "Cloud Run service keys to expose through the external HTTPS load balancer."
  default     = []
}

variable "default_lb_backend" {
  type        = string
  description = "Default backend key for the HTTPS load balancer."
  default     = "thumbnail-generation"
}

variable "lb_path_rules" {
  type = list(object({
    paths       = list(string)
    backend_key = string
  }))
  description = "Path routing rules for the optional HTTPS load balancer."
  default     = []
}

variable "geo_deny_expression" {
  type        = string
  description = "Cloud Armor CEL expression for geo restriction."
  default     = "origin.region_code != 'US' && origin.region_code != 'CA'"
}
