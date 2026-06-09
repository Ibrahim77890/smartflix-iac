output "module_contract" {
  description = "Phase 08 observability summary."
  value = {
    notification_channels = { for key, channel in google_monitoring_notification_channel.email : key => channel.name }
    log_sink_name         = google_logging_project_sink.operations.name
    log_metric_name       = google_logging_metric.application_errors.name
    uptime_checks         = { for key, check in google_monitoring_uptime_check_config.cloud_run : key => check.name }
    alert_policies = merge(
      { for key, policy in google_monitoring_alert_policy.uptime_failure : "uptime_${key}" => policy.name },
      { for key, policy in google_monitoring_alert_policy.pubsub_backlog : "pubsub_${key}" => policy.name },
      {
        sql_cpu            = google_monitoring_alert_policy.sql_cpu.name
        application_errors = google_monitoring_alert_policy.application_errors.name
      }
    )
  }
}
