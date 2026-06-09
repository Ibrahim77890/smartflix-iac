output "module_contract" {
  description = "Phase 05 data platform summary."
  value = {
    environment           = var.environment
    sql_instance_name     = google_sql_database_instance.primary.name
    sql_private_ip        = google_sql_database_instance.primary.private_ip_address
    sql_database_name     = google_sql_database.app.name
    sql_read_replica_name = try(google_sql_database_instance.replica[0].name, null)
    firestore_database    = google_firestore_database.default.name
    firestore_location    = google_firestore_database.default.location_id
    redis_name            = google_redis_instance.cache.name
    redis_host            = google_redis_instance.cache.host
    redis_port            = google_redis_instance.cache.port
    bucket_names          = { for key, bucket in google_storage_bucket.buckets : key => bucket.name }
    bucket_locations      = { for key, bucket in google_storage_bucket.buckets : key => bucket.location }
    bucket_kms_keys       = { for key, key_resource in google_kms_crypto_key.bucket_keys : key => key_resource.id }
  }
}
