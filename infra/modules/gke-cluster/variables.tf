variable "project_id" {
  type        = string
  description = "GCP project ID for the future GKE cluster."
}

variable "environment" {
  type        = string
  description = "Environment name for the GKE module."
  validation {
    condition     = contains(["dev", "stg", "uat", "prod"], var.environment)
    error_message = "Environment must be one of dev, stg, uat, or prod."
  }
}

variable "region" {
  type        = string
  description = "Primary GCP region for the future cluster."
}

variable "cluster_name" {
  type        = string
  description = "GKE cluster name."
}

variable "network" {
  type        = string
  description = "VPC self link or name for the GKE cluster."
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork self link or name for the GKE cluster nodes."
}

variable "cluster_secondary_range_name" {
  type        = string
  description = "Secondary subnet range name used for pod IPs."
}

variable "services_secondary_range_name" {
  type        = string
  description = "Secondary subnet range name used for service IPs."
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "Private control-plane CIDR block for the cluster."
}

variable "bastion_cidr" {
  type        = string
  description = "CIDR allowed to reach the GKE control plane."
}

variable "release_channel" {
  type        = string
  description = "GKE release channel."
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be RAPID, REGULAR, or STABLE."
  }
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection on the GKE cluster."
  default     = false
}
