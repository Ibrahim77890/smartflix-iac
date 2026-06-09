locals {
  required_services = toset([
    "clouderrorreporting.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com"
  ])

  cloud_run_hosts = {
    for key, url in var.cloud_run_service_urls :
    key => split("/", trimprefix(url, "https://"))[0]
  }

  notification_channels = values(google_monitoring_notification_channel.email)
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_monitoring_notification_channel" "email" {
  for_each = var.notification_emails

  project      = var.project_id
  display_name = "${upper(var.environment)} ${replace(each.value, "@", " at ")}"
  type         = "email"
  labels = {
    email_address = each.value
  }

  user_labels = merge(var.labels, {
    environment = var.environment
  })

  depends_on = [google_project_service.required]
}

resource "google_logging_project_sink" "operations" {
  project                = var.project_id
  name                   = "${var.environment}-ops-sink"
  destination            = "storage.googleapis.com/${var.logs_bucket_name}"
  unique_writer_identity = true
  filter                 = <<-EOT
    severity>=ERROR OR
    resource.type="cloud_run_revision" OR
    resource.type="cloud_function" OR
    resource.type="k8s_container" OR
    resource.type="cloudsql_database"
  EOT
}

resource "google_storage_bucket_iam_member" "sink_writer" {
  bucket = var.logs_bucket_name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.operations.writer_identity
}

resource "google_logging_metric" "application_errors" {
  project = var.project_id
  name    = "${var.environment}_application_errors"
  filter  = "severity>=ERROR AND (resource.type=\"cloud_run_revision\" OR resource.type=\"cloud_function\" OR resource.type=\"k8s_container\" OR resource.type=\"cloudsql_database\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_uptime_check_config" "cloud_run" {
  for_each = var.cloud_run_service_urls

  project      = var.project_id
  display_name = "${upper(var.environment)} ${each.key} uptime"
  timeout      = "10s"
  period       = "300s"

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = local.cloud_run_hosts[each.key]
    }
  }

  http_check {
    path         = "/"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  selected_regions = ["USA"]

  depends_on = [google_project_service.required]
}

resource "google_monitoring_alert_policy" "uptime_failure" {
  for_each = google_monitoring_uptime_check_config.cloud_run

  project      = var.project_id
  display_name = "${upper(var.environment)} ${each.key} uptime failure"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "${each.key} uptime check is failing"

    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\" AND metric.label.check_id=\"${each.value.uptime_check_id}\""
      duration        = "300s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_NEXT_OLDER"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [for channel in local.notification_channels : channel.name]

  documentation {
    mime_type = "text/markdown"
    content   = "Cloud Run uptime checks are failing for `${each.key}` in `${var.environment}`."
  }
}

resource "google_monitoring_alert_policy" "pubsub_backlog" {
  for_each = var.pubsub_subscription_names

  project      = var.project_id
  display_name = "${upper(var.environment)} ${each.value} backlog"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "${each.value} undelivered backlog"

    condition_threshold {
      filter          = "metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.type=\"pubsub_subscription\" AND resource.label.subscription_id=\"${each.value}\""
      duration        = "600s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.pubsub_backlog_threshold

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [for channel in local.notification_channels : channel.name]

  documentation {
    mime_type = "text/markdown"
    content   = "Pub/Sub subscription `${each.value}` has exceeded the allowed undelivered backlog in `${var.environment}`."
  }
}

resource "google_monitoring_alert_policy" "sql_cpu" {
  project      = var.project_id
  display_name = "${upper(var.environment)} Cloud SQL CPU high"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "${var.sql_instance_name} CPU utilization"

    condition_threshold {
      filter          = "metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\" AND resource.type=\"cloudsql_database\" AND resource.label.database_id=\"${var.project_id}:${var.sql_instance_name}\""
      duration        = "600s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.sql_cpu_threshold

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [for channel in local.notification_channels : channel.name]

  documentation {
    mime_type = "text/markdown"
    content   = "Cloud SQL instance `${var.sql_instance_name}` is running above the configured CPU threshold in `${var.environment}`."
  }
}

resource "google_monitoring_alert_policy" "application_errors" {
  project      = var.project_id
  display_name = "${upper(var.environment)} application errors"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Application error burst"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.application_errors.name}\" AND resource.type=\"global\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.error_count_threshold

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [for channel in local.notification_channels : channel.name]

  documentation {
    mime_type = "text/markdown"
    content   = "The environment is producing elevated application errors across Cloud Run, Functions, GKE, or Cloud SQL."
  }
}
