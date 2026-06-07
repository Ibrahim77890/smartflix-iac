output "state_bucket_name" {
  description = "GCS bucket name to pass into terraform init for each environment root."
  value       = google_storage_bucket.tf_state.name
}

output "backend_init_examples" {
  description = "Ready-to-run terraform init examples for each root."
  value = {
    dev    = "terraform init -backend-config=\"bucket=${google_storage_bucket.tf_state.name}\""
    stg    = "terraform init -backend-config=\"bucket=${google_storage_bucket.tf_state.name}\""
    uat    = "terraform init -backend-config=\"bucket=${google_storage_bucket.tf_state.name}\""
    prod   = "terraform init -backend-config=\"bucket=${google_storage_bucket.tf_state.name}\""
    global = "terraform init -backend-config=\"bucket=${google_storage_bucket.tf_state.name}\""
  }
}
