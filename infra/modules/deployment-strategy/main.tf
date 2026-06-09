data "google_project" "current" {
  project_id = var.project_id
}

locals {
  required_services = toset([
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "clouddeploy.googleapis.com",
    "containeranalysis.googleapis.com"
  ])

  runner_roles = toset([
    "roles/artifactregistry.reader",
    "roles/cloudbuild.builds.editor",
    "roles/clouddeploy.jobRunner",
    "roles/container.developer",
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
    "roles/run.admin",
    "roles/storage.objectAdmin"
  ])
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_project_service_identity" "clouddeploy" {
  provider = google-beta
  project  = var.project_id
  service  = "clouddeploy.googleapis.com"

  depends_on = [google_project_service.required]
}

resource "google_service_account" "runner" {
  project      = var.project_id
  account_id   = var.runner_service_account_id
  display_name = "StreamFlix Cloud Deploy Runner"
  description  = "Execution identity for StreamFlix Cloud Deploy render and deploy jobs."
}

resource "google_project_iam_member" "runner_roles" {
  for_each = local.runner_roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_service_account_iam_member" "clouddeploy_act_as" {
  service_account_id = google_service_account.runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_project_service_identity.clouddeploy.email}"
}

resource "google_storage_bucket" "deploy_artifacts" {
  project                     = var.project_id
  name                        = "${var.project_id}-clouddeploy-artifacts"
  location                    = var.artifact_bucket_location
  storage_class               = "STANDARD"
  force_destroy               = var.artifact_bucket_force_destroy
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = merge(var.labels, { platform = "clouddeploy" })

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.required]
}

resource "google_storage_bucket_iam_member" "runner_bucket_access" {
  bucket = google_storage_bucket.deploy_artifacts.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.runner.email}"
}

resource "google_artifact_registry_repository" "repositories" {
  for_each = var.repositories

  project       = var.project_id
  location      = var.region
  repository_id = each.value.repository_id
  description   = each.value.description
  format        = "DOCKER"
  labels        = merge(var.labels, { repository = each.key })

  docker_config {
    immutable_tags = each.value.immutable_tags
  }

  depends_on = [google_project_service.required]
}

resource "google_clouddeploy_target" "gke" {
  for_each = var.targets

  project          = var.project_id
  location         = var.region
  name             = "${each.key}-gke"
  description      = "GKE deployment target for the ${each.key} environment."
  require_approval = each.value.require_approval
  labels           = merge(var.labels, { environment = each.key, runtime = "gke" })

  gke {
    cluster = each.value.gke_cluster
  }

  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    service_account   = google_service_account.runner.email
    artifact_storage  = "gs://${google_storage_bucket.deploy_artifacts.name}"
    execution_timeout = "3600s"
  }

  deploy_parameters = merge(each.value.deploy_parameters, {
    environment = each.key
    runtime     = "gke"
  })

  depends_on = [
    google_project_service.required,
    google_project_iam_member.runner_roles,
    google_project_service_identity.clouddeploy,
    google_service_account_iam_member.clouddeploy_act_as,
    google_storage_bucket_iam_member.runner_bucket_access
  ]
}

resource "google_clouddeploy_target" "run" {
  for_each = var.targets

  project          = var.project_id
  location         = var.region
  name             = "${each.key}-run"
  description      = "Cloud Run deployment target for the ${each.key} environment."
  require_approval = each.value.require_approval
  labels           = merge(var.labels, { environment = each.key, runtime = "run" })

  run {
    location = each.value.run_location
  }

  execution_configs {
    usages            = ["RENDER", "DEPLOY"]
    service_account   = google_service_account.runner.email
    artifact_storage  = "gs://${google_storage_bucket.deploy_artifacts.name}"
    execution_timeout = "3600s"
  }

  deploy_parameters = merge(each.value.deploy_parameters, {
    environment = each.key
    runtime     = "run"
  })

  depends_on = [
    google_project_service.required,
    google_project_iam_member.runner_roles,
    google_project_service_identity.clouddeploy,
    google_service_account_iam_member.clouddeploy_act_as,
    google_storage_bucket_iam_member.runner_bucket_access
  ]
}

resource "google_clouddeploy_delivery_pipeline" "pipelines" {
  for_each = var.pipelines

  project     = var.project_id
  location    = var.region
  name        = each.value.pipeline_id
  description = each.value.description
  labels      = merge(var.labels, { release_track = each.key })

  serial_pipeline {
    dynamic "stages" {
      for_each = var.targets

      content {
        target_id = each.value.target_type == "gke" ? google_clouddeploy_target.gke[stages.key].name : google_clouddeploy_target.run[stages.key].name
        profiles  = [stages.key]

        strategy {
          standard {
            verify = false
          }
        }

        deploy_parameters {
          values = merge(stages.value.deploy_parameters, {
            environment = stages.key
            runtime     = each.value.target_type
          })

          match_target_labels = {
            environment = stages.key
            runtime     = each.value.target_type
          }
        }
      }
    }
  }

  depends_on = [
    google_clouddeploy_target.gke,
    google_clouddeploy_target.run
  ]
}
