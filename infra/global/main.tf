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
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

data "google_project" "current" {
  project_id = var.project_id
}

locals {
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
