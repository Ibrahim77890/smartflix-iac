terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.8"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.8"
    }
  }
}

provider "google" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

provider "google-beta" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

data "google_project" "current" {
  project_id = var.project_id
}

locals {
  common_labels = {
    env         = "global"
    owner       = var.owner
    cost_center = var.cost_center
    managed_by  = "terraform"
    project     = "streamflix"
  }

  effective_org_policy_parent = coalesce(
    var.org_policy_parent,
    "projects/${data.google_project.current.number}"
  )

  org_policies = {
    disable_service_account_key_creation = {
      constraint = "iam.disableServiceAccountKeyCreation"
      enforce    = true
    }
    require_shielded_vm = {
      constraint = "compute.requireShieldedVm"
      enforce    = true
    }
    restrict_cloud_sql_public_ip = {
      constraint = "sql.restrictPublicIp"
      enforce    = true
    }
  }

  deployment_blueprint = {
    repositories = {
      app_images = {
        repository_id  = "streamflix-app-images"
        description    = "Container image repository for StreamFlix workloads."
        immutable_tags = true
      }
      release_bundles = {
        repository_id  = "streamflix-release-bundles"
        description    = "OCI release bundles and Helm charts for StreamFlix promotions."
        immutable_tags = true
      }
    }
    targets = {
      dev = {
        require_approval = false
        gke_cluster      = "projects/${var.project_id}/locations/${var.region}/clusters/dev-streamflix-gke"
        run_location     = "projects/${var.project_id}/locations/${var.region}"
        deploy_parameters = {
          lane = "dev"
        }
      }
      stg = {
        require_approval = false
        gke_cluster      = "projects/${var.project_id}/locations/${var.region}/clusters/stg-streamflix-gke"
        run_location     = "projects/${var.project_id}/locations/${var.region}"
        deploy_parameters = {
          lane = "stg"
        }
      }
      uat = {
        require_approval = true
        gke_cluster      = "projects/${var.project_id}/locations/${var.region}/clusters/uat-streamflix-gke"
        run_location     = "projects/${var.project_id}/locations/${var.region}"
        deploy_parameters = {
          lane = "uat"
        }
      }
      prod = {
        require_approval = true
        gke_cluster      = "projects/${var.project_id}/locations/${var.region}/clusters/prod-streamflix-gke"
        run_location     = "projects/${var.project_id}/locations/${var.region}"
        deploy_parameters = {
          lane = "prod"
        }
      }
    }
    pipelines = {
      gke = {
        pipeline_id = "streamflix-gke"
        description = "Progressive promotion pipeline for StreamFlix GKE workloads."
        target_type = "gke"
      }
      run = {
        pipeline_id = "streamflix-run"
        description = "Progressive promotion pipeline for StreamFlix Cloud Run services."
        target_type = "run"
      }
    }
  }
}

resource "google_org_policy_policy" "guardrails" {
  for_each = local.org_policies

  parent = local.effective_org_policy_parent
  name   = "${local.effective_org_policy_parent}/policies/${each.value.constraint}"

  spec {
    rules {
      enforce = each.value.enforce ? "TRUE" : "FALSE"
    }
  }
}

module "deployment_strategy" {
  source                    = "../modules/deployment-strategy"
  project_id                = var.project_id
  region                    = var.region
  runner_service_account_id = "clouddeploy-runner"
  repositories              = local.deployment_blueprint.repositories
  targets                   = local.deployment_blueprint.targets
  pipelines                 = local.deployment_blueprint.pipelines
  labels                    = local.common_labels
}
