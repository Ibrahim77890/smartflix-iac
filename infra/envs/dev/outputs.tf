output "foundation_contract" {
  description = "Phase 01 proof that the dev root is wired to all reusable modules."
  value = {
    environment = var.environment
    network     = module.network.module_contract
    gke         = module.gke_cluster.module_contract
    secrets     = module.secrets.module_contract
    database    = module.database.module_contract
  }
}
