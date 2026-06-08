output "module_contract" {
  description = "Kubernetes workload summary."
  value = {
    namespaces       = keys(kubernetes_namespace_v1.namespaces)
    keycloak_mode    = var.deploy_keycloak ? "helm" : "placeholder"
    service_accounts = { for key, sa in kubernetes_service_account_v1.service_accounts : key => sa.metadata[0].name }
  }
}
