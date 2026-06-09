## Event-Driven Module

Phase 06 status: implemented.

Resources created by this module:
- `google_pubsub_topic` and `google_pubsub_subscription`
- `google_storage_bucket_object` for packaged Cloud Functions source
- `google_cloudfunctions2_function` for Pub/Sub-driven consumers
- `google_workflows_workflow` for saga-style orchestration
- `google_storage_notification` for GCS-to-Pub/Sub wiring
- `google_eventarc_trigger` for storage finalize events into the workflow

Notes:
- function source code is kept in this module under `assets/functions`
- the media upload path publishes through Pub/Sub and also emits an Eventarc trigger for workflow orchestration
