output "foundation_contract" {
  description = "Phase 04 proof that the dev root is wired to the foundational, network, identity, and compute modules."
  value = {
    environment   = var.environment
    network       = module.network.module_contract
    gke           = module.gke_cluster.module_contract
    gke_workloads = var.deploy_gke_workloads ? module.gke_service_stubs[0].module_contract : null
    cloud_run     = module.cloud_run_edge.module_contract
    secrets       = module.secrets.module_contract
    database      = module.database.module_contract
  }
}
