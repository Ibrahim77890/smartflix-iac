output "module_contract" {
  description = "Phase 07 deployment platform summary."
  value = {
    artifact_bucket_name   = google_storage_bucket.deploy_artifacts.name
    runner_service_account = google_service_account.runner.email
    repositories           = { for key, repo in google_artifact_registry_repository.repositories : key => repo.id }
    gke_targets            = { for key, target in google_clouddeploy_target.gke : key => target.name }
    run_targets            = { for key, target in google_clouddeploy_target.run : key => target.name }
    pipelines              = { for key, pipeline in google_clouddeploy_delivery_pipeline.pipelines : key => pipeline.name }
  }
}
