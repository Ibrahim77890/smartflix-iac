data "google_project" "current" {
  project_id = var.project_id
}

locals {
  required_services = toset([
    "binaryauthorization.googleapis.com",
    "cloudkms.googleapis.com",
    "containeranalysis.googleapis.com"
  ])

  policy_files = fileset("${path.module}/assets", "**")

  default_whitelist_patterns = [
    "gcr.io/google-containers/*",
    "gcr.io/gke-release/*",
    "k8s.gcr.io/*",
    "registry.k8s.io/*",
    "us-docker.pkg.dev/cloudrun/container/*"
  ]
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_project_service_identity" "binaryauthorization" {
  provider = google-beta
  project  = var.project_id
  service  = "binaryauthorization.googleapis.com"

  depends_on = [google_project_service.required]
}

resource "google_kms_key_ring" "attestor" {
  project  = var.project_id
  name     = "${var.project_prefix}-binauthz"
  location = var.kms_location

  depends_on = [google_project_service.required]
}

resource "google_kms_crypto_key" "attestor" {
  name            = "release-attestor"
  key_ring        = google_kms_key_ring.attestor.id
  purpose         = "ASYMMETRIC_SIGN"

  version_template {
    algorithm        = "RSA_SIGN_PKCS1_4096_SHA512"
    protection_level = "SOFTWARE"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_container_analysis_note" "release" {
  project           = var.project_id
  name              = "${var.project_prefix}-release-attestor"
  short_description = "StreamFlix release attestor"
  long_description  = "Attestation note used by the StreamFlix Binary Authorization policy."

  attestation_authority {
    hint {
      human_readable_name = "StreamFlix Release Attestor"
    }
  }

  depends_on = [google_project_service.required]
}

resource "google_binary_authorization_attestor" "release" {
  project     = var.project_id
  name        = "${var.project_prefix}-release-attestor"
  description = "Attestor used for StreamFlix release verification."

  attestation_authority_note {
    note_reference = google_container_analysis_note.release.name
  }
}

resource "google_storage_bucket" "policy_library" {
  project                     = var.project_id
  name                        = "${var.project_id}-policy-library"
  location                    = var.policy_bucket_location
  storage_class               = "STANDARD"
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = merge(var.labels, { platform = "policy-library" })

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_object" "policy_files" {
  for_each = { for file in local.policy_files : file => file }

  name   = each.value
  bucket = google_storage_bucket.policy_library.name
  source = "${path.module}/assets/${each.value}"
}

resource "google_binary_authorization_policy" "project" {
  project                       = var.project_id
  description                   = "StreamFlix Binary Authorization policy managed as code."
  global_policy_evaluation_mode = "ENABLE"

  default_admission_rule {
    evaluation_mode         = "REQUIRE_ATTESTATION"
    enforcement_mode        = "DRYRUN_AUDIT_LOG_ONLY"
    require_attestations_by = [google_binary_authorization_attestor.release.name]
  }

  dynamic "admission_whitelist_patterns" {
    for_each = concat(local.default_whitelist_patterns, var.additional_whitelist_patterns)

    content {
      name_pattern = admission_whitelist_patterns.value
    }
  }

  depends_on = [
    google_project_service.required,
    google_project_service_identity.binaryauthorization,
    google_binary_authorization_attestor.release
  ]
}
