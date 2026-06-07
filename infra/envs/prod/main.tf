terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  common_labels = {
    env         = var.environment
    owner       = var.owner
    cost_center = var.cost_center
    managed_by  = "terraform"
    project     = "streamflix"
  }
}

module "network" {
  source      = "../../modules/network"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  vpc_name    = "${var.environment}-streamflix-vpc"
  labels      = local.common_labels
}

module "gke_cluster" {
  source       = "../../modules/gke-cluster"
  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  cluster_name = "${var.environment}-streamflix-gke"
}

module "secrets" {
  source      = "../../modules/secrets"
  project_id  = var.project_id
  environment = var.environment
  secret_ids  = var.secret_ids
}

module "database" {
  source        = "../../modules/database"
  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  db_name       = "${var.environment}_streamflix"
  instance_tier = var.db_instance_tier
}
