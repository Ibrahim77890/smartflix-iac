## Database Module

Phase 05 status: implemented.

Resources created by this module:
- `google_project_service` for required data-plane APIs
- `google_sql_database_instance` and `google_sql_database` for Cloud SQL PostgreSQL
- optional Cloud SQL read replica
- `google_firestore_database`, `google_firestore_field`, and `google_firestore_index`
- `google_redis_instance` for Memorystore Redis
- `google_kms_key_ring` and `google_kms_crypto_key` for bucket CMEK
- `google_storage_bucket` for media, logs, and Terraform artifacts

Notes:
- Cloud SQL and Redis are private-only and expect private service access from the network phase
- Firestore is configured in Native mode with TTL for `watch_history`
- bucket CMEK is wired through the Cloud Storage service agent
