locals {
  required_services = toset([
    "cloudkms.googleapis.com",
    "firestore.googleapis.com",
    "redis.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com"
  ])
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_kms_key_ring" "storage" {
  name     = "${var.environment}-storage-ring"
  location = var.kms_location
  project  = var.project_id

  depends_on = [google_project_service.required]
}

resource "google_kms_crypto_key" "bucket_keys" {
  for_each = var.buckets

  name            = "${each.key}-key"
  key_ring        = google_kms_key_ring.storage.id
  rotation_period = var.kms_rotation_period

  lifecycle {
    prevent_destroy = true
  }
}

data "google_storage_project_service_account" "gcs" {
  project = var.project_id

  depends_on = [google_project_service.required]
}

resource "google_kms_crypto_key_iam_member" "gcs_bucket_access" {
  for_each = var.buckets

  crypto_key_id = google_kms_crypto_key.bucket_keys[each.key].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}

resource "google_storage_bucket" "buckets" {
  for_each = var.buckets

  project                     = var.project_id
  name                        = each.value.name
  location                    = each.value.location
  storage_class               = each.value.storage_class
  force_destroy               = each.value.force_destroy
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true
  labels                      = merge(var.labels, { bucket_role = each.key })

  versioning {
    enabled = each.value.versioning
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_keys[each.key].id
  }

  dynamic "cors" {
    for_each = each.value.cors

    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = cors.value.response_header
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules

    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = try(lifecycle_rule.value.action.storage_class, null)
      }

      condition {
        age                   = try(lifecycle_rule.value.condition.age, null)
        matches_storage_class = try(lifecycle_rule.value.condition.matches_storage_class, null)
        num_newer_versions    = try(lifecycle_rule.value.condition.num_newer_versions, null)
      }
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.gcs_bucket_access]
}

resource "google_sql_database_instance" "primary" {
  project             = var.project_id
  name                = "${var.environment}-postgres"
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  settings {
    tier              = var.instance_tier
    availability_type = var.availability_type
    disk_type         = "PD_SSD"
    disk_size         = var.disk_size_gb
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = var.enable_point_in_time_recovery
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.private_network
    }

    insights_config {
      query_insights_enabled = true
    }

    user_labels = var.labels
  }

  depends_on = [google_project_service.required]
}

resource "google_sql_database" "app" {
  project  = var.project_id
  name     = var.db_name
  instance = google_sql_database_instance.primary.name
}

resource "google_sql_database_instance" "replica" {
  count                = var.read_replica_enabled ? 1 : 0
  project              = var.project_id
  name                 = "${var.environment}-postgres-replica"
  region               = var.region
  database_version     = var.database_version
  master_instance_name = google_sql_database_instance.primary.name
  deletion_protection  = var.deletion_protection

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  settings {
    tier              = var.replica_tier
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = var.disk_size_gb
    disk_autoresize   = true
    user_labels       = var.labels

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.private_network
    }
  }
}

resource "google_firestore_database" "default" {
  project                 = var.project_id
  name                    = var.firestore_database_name
  location_id             = var.firestore_location_id
  type                    = "FIRESTORE_NATIVE"
  delete_protection_state = var.firestore_delete_protection_state
  deletion_policy         = var.firestore_deletion_policy

  depends_on = [google_project_service.required]
}

resource "google_firestore_field" "watch_history_ttl" {
  project    = var.project_id
  database   = google_firestore_database.default.name
  collection = var.firestore_ttl_collection
  field      = var.firestore_ttl_field

  ttl_config {}
}

resource "google_firestore_index" "watch_history" {
  project     = var.project_id
  database    = google_firestore_database.default.name
  collection  = var.firestore_index_collection
  query_scope = "COLLECTION"

  fields {
    field_path = var.firestore_index_first_field
    order      = "ASCENDING"
  }

  fields {
    field_path = var.firestore_index_second_field
    order      = "DESCENDING"
  }
}

resource "google_redis_instance" "cache" {
  project                 = var.project_id
  name                    = "${var.environment}-redis"
  region                  = var.region
  tier                    = var.redis_tier
  memory_size_gb          = var.redis_memory_size_gb
  authorized_network      = var.private_network
  connect_mode            = "PRIVATE_SERVICE_ACCESS"
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  auth_enabled            = true
  redis_version           = "REDIS_7_0"
  display_name            = "${upper(var.environment)} StreamFlix Redis"
  labels                  = var.labels

  depends_on = [google_project_service.required]
}
