output "module_contract" {
  description = "Phase 06 event-driven summary."
  value = {
    topic_names          = { for key, topic in google_pubsub_topic.topics : key => topic.name }
    subscription_names   = { for key, sub in google_pubsub_subscription.subscriptions : key => sub.name }
    function_names       = { for key, fn in google_cloudfunctions2_function.functions : key => fn.name }
    workflow_name        = google_workflows_workflow.media_ingest.name
    eventarc_trigger     = google_eventarc_trigger.media_uploads.name
    storage_notification = google_storage_notification.media_uploads.id
  }
}
