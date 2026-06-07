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
  default_labels = merge(
    {
      project     = "streamflix"
      managed_by  = "terraform"
      phase       = "foundation"
      owner       = var.owner
      cost_center = var.cost_center
    },
    var.labels
  )
}

resource "google_storage_bucket" "tf_state" {
  name                        = var.state_bucket_name
  location                    = var.bucket_location
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  storage_class               = "STANDARD"
  labels                      = local.default_labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = var.state_version_retention
    }

    action {
      type = "Delete"
    }
  }
}
