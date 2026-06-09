output "module_contract" {
  description = "Phase 09 policy-as-code summary."
  value = {
    attestor_name         = google_binary_authorization_attestor.release.name
    attestor_note         = google_container_analysis_note.release.name
    binary_authz_policy   = google_binary_authorization_policy.project.id
    policy_library_bucket = google_storage_bucket.policy_library.name
    policy_files          = [for object in google_storage_bucket_object.policy_files : object.name]
  }
}
