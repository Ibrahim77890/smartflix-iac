terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "current" {}

locals {
  common_labels = {
    env         = var.environment
    owner       = var.owner
    cost_center = var.cost_center
    managed_by  = "terraform"
    project     = "streamflix"
  }

  network_blueprint = {
    subnets = {
      public = {
        description           = "Public subnet for load balancers and future edge entry points."
        region                = var.region
        ip_cidr_range         = "10.20.0.0/24"
        private_google_access = false
        nat_enabled           = false
      }
      private = {
        description           = "Private subnet for GKE nodes and serverless VPC connector workloads."
        region                = var.region
        ip_cidr_range         = "10.20.16.0/20"
        private_google_access = true
        nat_enabled           = true
        secondary_ip_ranges = {
          "stg-gke-pods"     = "10.20.64.0/18"
          "stg-gke-services" = "10.20.128.0/20"
        }
      }
      data = {
        description           = "Private data subnet for Cloud SQL, Redis, and managed data-plane services."
        region                = var.region
        ip_cidr_range         = "10.20.32.0/24"
        private_google_access = true
        nat_enabled           = true
      }
    }
    firewall_rules = {
      allow-internal = {
        description   = "Allow internal east-west traffic inside the stg VPC."
        direction     = "INGRESS"
        priority      = 1000
        source_ranges = ["10.20.0.0/16"]
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
      recommendation = {
        display_name               = "StreamFlix Recommendation Service"
        description                = "Runtime identity for the recommendation microservice."
        kubernetes_namespace       = "recommendation"
        kubernetes_service_account = "recommendation-ksa"
        project_roles = [
          "roles/logging.logWriter",
          "roles/monitoring.metricWriter"
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

  compute_blueprint = {
    release_channel         = "REGULAR"
    master_ipv4_cidr_block  = "172.16.1.0/28"
    bastion_cidr            = local.network_blueprint.subnets.public.ip_cidr_range
    deploy_keycloak         = false
    connector_ip_cidr_range = "10.20.48.0/28"
    gke_services = {
      catalog = {
        kubernetes_service_account = "catalog-ksa"
        gcp_service_account_key    = "catalog"
        image                      = "nginx:alpine"
        replicas                   = 1
        limits = {
          cpu    = "250m"
          memory = "256Mi"
        }
      }
      auth = {
        kubernetes_service_account = "auth-ksa"
        gcp_service_account_key    = "auth"
        image                      = "nginx:alpine"
        replicas                   = 1
        limits = {
          cpu    = "250m"
          memory = "256Mi"
        }
      }
      stream = {
        kubernetes_service_account = "stream-ksa"
        gcp_service_account_key    = "stream"
        image                      = "grafana/grafana:11.1.0"
        replicas                   = 1
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
      recommendation = {
        kubernetes_service_account = "recommendation-ksa"
        gcp_service_account_key    = "recommendation"
        image                      = "hashicorp/http-echo:1.0"
        replicas                   = 1
        response_text              = "streamflix-recommendations-stg"
        limits = {
          cpu    = "250m"
          memory = "256Mi"
        }
      }
    }
    cloud_run_services = {
      "thumbnail-generation" = {
        image                 = "us-docker.pkg.dev/cloudrun/container/hello"
        container_port        = 8080
        service_account_email = "stream"
        ingress               = "INGRESS_TRAFFIC_ALL"
        min_instances         = 0
        max_instances         = 2
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        env = {
          SERVICE_NAME = "thumbnail-generation"
          ENVIRONMENT  = var.environment
        }
      }
      "subtitle-indexing" = {
        image                 = "us-docker.pkg.dev/cloudrun/container/hello"
        container_port        = 8080
        service_account_email = "notification"
        ingress               = "INGRESS_TRAFFIC_ALL"
        min_instances         = 0
        max_instances         = 2
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        env = {
          SERVICE_NAME = "subtitle-indexing"
          ENVIRONMENT  = var.environment
        }
      }
    }
    lb_domains  = []
    lb_backends = ["thumbnail-generation", "subtitle-indexing"]
    lb_path_rules = [
      {
        paths       = ["/subtitles/*"]
        backend_key = "subtitle-indexing"
      }
    ]
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
  source                        = "../../modules/gke-cluster"
  project_id                    = var.project_id
  region                        = var.region
  environment                   = var.environment
  cluster_name                  = "${var.environment}-streamflix-gke"
  network                       = module.network.module_contract.vpc_self_link
  subnetwork                    = module.network.module_contract.subnet_self_links.private
  cluster_secondary_range_name  = "stg-gke-pods"
  services_secondary_range_name = "stg-gke-services"
  master_ipv4_cidr_block        = local.compute_blueprint.master_ipv4_cidr_block
  bastion_cidr                  = local.compute_blueprint.bastion_cidr
  release_channel               = local.compute_blueprint.release_channel
  deletion_protection           = false
}

provider "kubernetes" {
  host                   = "https://${module.gke_cluster.module_contract.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(module.gke_cluster.module_contract.ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke_cluster.module_contract.endpoint}"
    token                  = data.google_client_config.current.access_token
    cluster_ca_certificate = base64decode(module.gke_cluster.module_contract.ca_certificate)
  }
}

module "secrets" {
  source                   = "../../modules/secrets"
  project_id               = var.project_id
  environment              = var.environment
  secret_ids               = var.secret_ids
  labels                   = local.common_labels
  enable_workload_identity = var.enable_workload_identity_bindings
  service_accounts         = local.identity_blueprint.service_accounts
  secrets                  = local.identity_blueprint.secrets
  secret_admin_members     = var.secret_admin_members

  depends_on = [module.gke_cluster]
}

module "database" {
  source        = "../../modules/database"
  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  db_name       = "${var.environment}_streamflix"
  instance_tier = var.db_instance_tier
}

module "cloud_run_edge" {
  source                  = "../../modules/cloud-run-edge"
  project_id              = var.project_id
  region                  = var.region
  environment             = var.environment
  connector_network       = module.network.module_contract.vpc_name
  connector_ip_cidr_range = local.compute_blueprint.connector_ip_cidr_range
  services = {
    for key, service in local.compute_blueprint.cloud_run_services :
    key => merge(service, {
      service_account_email = module.secrets.module_contract.service_account_emails[service.service_account_email]
    })
  }
  lb_domains         = local.compute_blueprint.lb_domains
  lb_backends        = local.compute_blueprint.lb_backends
  default_lb_backend = "thumbnail-generation"
  lb_path_rules      = local.compute_blueprint.lb_path_rules
}

module "gke_service_stubs" {
  count                      = var.deploy_gke_workloads ? 1 : 0
  source                     = "../../modules/gke-service-stubs"
  environment                = var.environment
  services                   = local.compute_blueprint.gke_services
  gcp_service_account_emails = module.secrets.module_contract.service_account_emails
  deploy_keycloak            = local.compute_blueprint.deploy_keycloak

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  depends_on = [module.gke_cluster]
}
