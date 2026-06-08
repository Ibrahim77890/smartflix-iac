output "module_contract" {
  description = "Compute summary for the GKE Autopilot cluster."
  value = {
    environment      = var.environment
    cluster_name     = google_container_cluster.autopilot.name
    endpoint         = google_container_cluster.autopilot.endpoint
    ca_certificate   = google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate
    location         = google_container_cluster.autopilot.location
    workload_pool    = google_container_cluster.autopilot.workload_identity_config[0].workload_pool
    release_channel  = google_container_cluster.autopilot.release_channel[0].channel
    private_endpoint = google_container_cluster.autopilot.private_cluster_config[0].private_endpoint
  }
}
