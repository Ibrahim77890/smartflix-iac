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
  description = "Custom VPC name for the environment."
}

variable "labels" {
  type        = map(string)
  description = "Labels that later network resources must inherit."
  default     = {}
}

variable "subnets" {
  type = map(object({
    name                  = optional(string)
    description           = string
    region                = string
    ip_cidr_range         = string
    private_google_access = bool
    nat_enabled           = optional(bool, false)
    secondary_ip_ranges   = optional(map(string), {})
  }))
  description = "Subnet definitions keyed by tier name."
}

variable "firewall_rules" {
  type = map(object({
    name               = optional(string)
    description        = string
    direction          = string
    priority           = optional(number, 1000)
    source_ranges      = optional(list(string), [])
    destination_ranges = optional(list(string), [])
    source_tags        = optional(list(string), [])
    target_tags        = optional(list(string), [])
    log_metadata       = optional(string)
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string), [])
    })), [])
  }))
  description = "Firewall rules defined as a map so rules can be added without adding new resource blocks."
  validation {
    condition = alltrue([
      for rule in values(var.firewall_rules) :
      contains(["INGRESS", "EGRESS"], rule.direction)
    ])
    error_message = "Firewall rule direction must be either INGRESS or EGRESS."
  }
}

variable "nat_log_enabled" {
  type        = bool
  description = "Enable Cloud NAT logging for troubleshooting."
  default     = false
}

variable "nat_log_filter" {
  type        = string
  description = "Cloud NAT logging filter when logging is enabled."
  default     = "ERRORS_ONLY"
  validation {
    condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.nat_log_filter)
    error_message = "nat_log_filter must be ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL."
  }
}

variable "private_service_access_prefix_length" {
  type        = number
  description = "Prefix length reserved for service networking private IP allocation."
  default     = 16
  validation {
    condition     = var.private_service_access_prefix_length >= 16 && var.private_service_access_prefix_length <= 24
    error_message = "private_service_access_prefix_length should stay between /16 and /24."
  }
}
