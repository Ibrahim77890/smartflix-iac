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
    prod = {
      subnets = {
        public = {
          description           = "Public subnet for load balancers and future edge entry points."
          region                = var.region
          ip_cidr_range         = "10.30.0.0/24"
          private_google_access = false
          nat_enabled           = false
        }
        private = {
          description           = "Private subnet for GKE nodes and serverless VPC connector workloads."
          region                = var.region
          ip_cidr_range         = "10.30.16.0/20"
          private_google_access = true
          nat_enabled           = true
          secondary_ip_ranges = {
            "prod-gke-pods"     = "10.30.64.0/18"
            "prod-gke-services" = "10.30.128.0/20"
          }
        }
        data = {
          description           = "Private data subnet for Cloud SQL, Redis, and managed data-plane services."
          region                = var.region
          ip_cidr_range         = "10.30.32.0/24"
          private_google_access = true
          nat_enabled           = true
        }
      }
      firewall_rules = {
        allow-internal = {
          description   = "Allow internal east-west traffic inside the prod VPC."
          direction     = "INGRESS"
          priority      = 1000
          source_ranges = ["10.30.0.0/16"]
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

  identity_blueprint = {
    service_accounts = {
      catalog = {
        display_name               = "StreamFlix Catalog Service"
        description                = "Runtime identity for the catalog microservice."
        kubernetes_namespace       = "catalog"
        kubernetes_service_account = "catalog-ksa"
        project_roles = [
          "roles/logging.logWriter",
          "roles/monitoring.metricWriter",
          "roles/storage.objectViewer"
        ]
      }
      auth = {
        display_name               = "StreamFlix Auth Service"
        description                = "Runtime identity for the auth microservice."
        kubernetes_namespace       = "auth"
        kubernetes_service_account = "auth-ksa"
        project_roles = [
          "roles/logging.logWriter",
          "roles/monitoring.metricWriter"
        ]
      }
      stream = {
        display_name               = "StreamFlix Stream Service"
        description                = "Runtime identity for the stream microservice."
        kubernetes_namespace       = "stream"
        kubernetes_service_account = "stream-ksa"
        project_roles = [
          "roles/logging.logWriter",
          "roles/monitoring.metricWriter",
          "roles/storage.objectViewer"
        ]
      }
      notification = {
        display_name               = "StreamFlix Notification Service"
        description                = "Runtime identity for the notification microservice."
        kubernetes_namespace       = "notification"
        kubernetes_service_account = "notification-ksa"
        project_roles = [
          "roles/logging.logWriter",
          "roles/monitoring.metricWriter",
          "roles/pubsub.publisher"
        ]
      }
    }

    secrets = {
      "catalog-api-key" = {
        owner_service = "catalog"
        accessors     = ["catalog"]
      }
      "jwt-signing-key" = {
        owner_service = "auth"
        accessors     = ["auth"]
      }
      "notification-webhook-url" = {
        owner_service = "notification"
        accessors     = ["notification"]
      }
    }
  }
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
  source                   = "../../modules/secrets"
  project_id               = var.project_id
  environment              = var.environment
  secret_ids               = var.secret_ids
  labels                   = local.common_labels
  enable_workload_identity = true
  service_accounts         = local.identity_blueprint.service_accounts
  secrets                  = local.identity_blueprint.secrets
  secret_admin_members     = var.secret_admin_members
}

module "database" {
  source        = "../../modules/database"
  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  db_name       = "${var.environment}_streamflix"
  instance_tier = var.db_instance_tier
}
