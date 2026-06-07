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
  foundation_note = "Phase 01 scaffold only. Global org policies and shared controls land here in later phases."
}
