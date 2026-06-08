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

  network_blueprint = {
    uat = {
      subnets = {
        public = {
          description           = "Public subnet for load balancers and future edge entry points."
          region                = var.region
          ip_cidr_range         = "10.25.0.0/24"
          private_google_access = false
          nat_enabled           = false
        }
        private = {
          description           = "Private subnet for GKE nodes and serverless VPC connector workloads."
          region                = var.region
          ip_cidr_range         = "10.25.16.0/20"
          private_google_access = true
          nat_enabled           = true
          secondary_ip_ranges = {
            "uat-gke-pods"     = "10.25.64.0/18"
            "uat-gke-services" = "10.25.128.0/20"
          }
        }
        data = {
          description           = "Private data subnet for Cloud SQL, Redis, and managed data-plane services."
          region                = var.region
          ip_cidr_range         = "10.25.32.0/24"
          private_google_access = true
          nat_enabled           = true
        }
      }
      firewall_rules = {
        allow-internal = {
          description   = "Allow internal east-west traffic inside the uat VPC."
          direction     = "INGRESS"
          priority      = 1000
          source_ranges = ["10.25.0.0/16"]
          target_tags   = ["gke-node", "internal-service", "bastion"]
          allow = [
            {
              protocol = "tcp"
              ports    = ["0-65535"]
            },
            {
              protocol = "udp"
              ports    = ["0-65535"]
            },
            {
              protocol = "icmp"
            }
          ]
        }
        allow-iap-ssh-bastion = {
          description   = "Allow IAP-managed SSH access to the bastion tag only."
          direction     = "INGRESS"
          priority      = 1100
          source_ranges = ["35.235.240.0/20"]
          target_tags   = ["bastion"]
          allow = [
            {
              protocol = "tcp"
              ports    = ["22"]
            }
          ]
        }
        allow-lb-health-checks = {
          description   = "Allow Google load balancer health checks to service nodes."
          direction     = "INGRESS"
          priority      = 1200
          source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
          target_tags   = ["gke-node", "internal-service"]
          allow = [
            {
              protocol = "tcp"
              ports    = ["80", "443", "8080"]
            }
          ]
        }
      }
      nat_log_enabled                      = false
      nat_log_filter                       = "ERRORS_ONLY"
      private_service_access_prefix_length = 16
    }
  }[var.environment]
}

module "network" {
  source                               = "../../modules/network"
  project_id                           = var.project_id
  region                               = var.region
  environment                          = var.environment
  vpc_name                             = "${var.environment}-streamflix-vpc"
  labels                               = local.common_labels
  subnets                              = local.network_blueprint.subnets
  firewall_rules                       = local.network_blueprint.firewall_rules
  nat_log_enabled                      = local.network_blueprint.nat_log_enabled
  nat_log_filter                       = local.network_blueprint.nat_log_filter
  private_service_access_prefix_length = local.network_blueprint.private_service_access_prefix_length
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
