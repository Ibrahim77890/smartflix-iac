locals {
  required_services = toset([
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "eventarc.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "workflows.googleapis.com"
  ])

  topic_subscription_pairs = flatten([
    for topic_key, topic in var.topics : [
      for sub_key, sub in topic.subscriptions : {
        key                        = "${topic_key}:${sub_key}"
        topic_key                  = topic_key
        subscription_name          = sub.name
        ack_deadline_seconds       = sub.ack_deadline_seconds
        message_retention_duration = sub.message_retention_duration
        dead_letter_topic_key      = try(sub.dead_letter_topic_key, null)
      }
    ]
  ])
}

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_project_iam_member" "cloud_build_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_pubsub_topic" "topics" {
  for_each = var.topics

  project                    = var.project_id
  name                       = each.key
  message_retention_duration = each.value.message_retention_duration

  depends_on = [google_project_service.required]
}

resource "google_pubsub_subscription" "subscriptions" {
  for_each = {
    for pair in local.topic_subscription_pairs :
    pair.key => pair
  }

  project                    = var.project_id
  name                       = each.value.subscription_name
  topic                      = google_pubsub_topic.topics[each.value.topic_key].name
  ack_deadline_seconds       = each.value.ack_deadline_seconds
  message_retention_duration = each.value.message_retention_duration

  dynamic "dead_letter_policy" {
    for_each = each.value.dead_letter_topic_key == null ? [] : [each.value.dead_letter_topic_key]

    content {
      dead_letter_topic     = google_pubsub_topic.topics[dead_letter_policy.value].id
      max_delivery_attempts = 5
    }
  }
}

resource "google_pubsub_topic_iam_member" "storage_publish" {
  project = var.project_id
  topic   = google_pubsub_topic.topics[var.media_upload_topic_key].name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.storage_service_account_email}"
}

resource "google_project_iam_member" "storage_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.storage_service_account_email}"
}

data "archive_file" "functions" {
  for_each    = var.functions
  type        = "zip"
  source_dir  = "${path.module}/assets/functions/${each.value.source_dir}"
  output_path = "${path.module}/.generated/${var.environment}-${each.key}.zip"
}

resource "google_storage_bucket_object" "function_archives" {
  for_each = var.functions

  name   = "${var.environment}/functions/${each.key}.zip"
  bucket = var.artifact_bucket_name
  source = data.archive_file.functions[each.key].output_path
}

resource "google_storage_bucket_iam_member" "gcf_source_reader" {
  bucket = var.artifact_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:service-${data.google_project.current.number}@gcf-admin-robot.iam.gserviceaccount.com"
}

resource "google_cloudfunctions2_function" "functions" {
  for_each = var.functions

  project  = var.project_id
  location = var.region
  name     = "${var.environment}-${each.key}"

  build_config {
    runtime     = "python312"
    entry_point = each.value.entry_point

    source {
      storage_source {
        bucket = var.artifact_bucket_name
        object = google_storage_bucket_object.function_archives[each.key].name
      }
    }
  }

  service_config {
    available_memory      = each.value.available_memory
    timeout_seconds       = each.value.timeout_seconds
    ingress_settings      = "ALLOW_ALL"
    service_account_email = each.value.service_account_email
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.topics[each.value.topic_key].id
    retry_policy   = "RETRY_POLICY_RETRY"
  }

  depends_on = [
    google_project_service.required,
    google_storage_bucket_iam_member.gcf_source_reader,
    google_project_iam_member.cloud_build_builder
  ]
}

resource "google_project_iam_member" "workflow_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${var.eventarc_service_account_email}"
}

resource "google_project_iam_member" "eventarc_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${var.eventarc_service_account_email}"
}

resource "google_workflows_workflow" "media_ingest" {
  name            = "${var.environment}-media-ingest"
  project         = var.project_id
  region          = var.region
  service_account = var.workflow_service_account_email
  description     = "Saga-style media ingest workflow for StreamFlix ${var.environment}."
  labels          = var.labels

  source_contents = templatefile("${path.module}/assets/workflows/media-ingest.yaml.tftpl", {
    environment   = var.environment
    project_id    = var.project_id
    thumbnail_url = var.workflow_thumbnail_url
    subtitle_url  = var.workflow_subtitle_url
    catalog_topic = "projects/${var.project_id}/topics/${google_pubsub_topic.topics[var.workflow_publish_topic_key].name}"
  })

  depends_on = [google_project_service.required]
}

resource "google_storage_notification" "media_uploads" {
  bucket         = var.media_bucket_name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.topics[var.media_upload_topic_key].id
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [
    google_pubsub_topic_iam_member.storage_publish,
    google_project_iam_member.storage_pubsub_publisher
  ]
}

resource "google_eventarc_trigger" "media_uploads" {
  name     = "${var.environment}-media-upload-trigger"
  project  = var.project_id
  location = lower(var.media_bucket_location)

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  matching_criteria {
    attribute = "bucket"
    value     = var.media_bucket_name
  }

  destination {
    workflow = google_workflows_workflow.media_ingest.id
  }

  service_account = var.eventarc_service_account_email

  depends_on = [
    google_project_service.required,
    google_project_iam_member.workflow_invoker,
    google_project_iam_member.eventarc_receiver,
    google_project_iam_member.storage_pubsub_publisher
  ]
}
