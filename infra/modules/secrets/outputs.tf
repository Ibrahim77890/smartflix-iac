output "module_contract" {
  description = "Identity and secret-management summary returned to the environment roots."
  value = {
    environment                  = var.environment
    service_account_emails       = { for name, sa in google_service_account.service_accounts : name => sa.email }
    service_account_names        = { for name, sa in google_service_account.service_accounts : name => sa.name }
    service_account_roles        = { for name, config in local.service_accounts : name => sort(tolist(config.project_roles)) }
    workload_identity_enabled    = var.enable_workload_identity
    workload_identity_principals = local.workload_identity_members
    secret_ids                   = keys(google_secret_manager_secret.secrets)
    secret_accessor_map          = { for secret_id, config in var.secrets : secret_id => sort(tolist(config.accessors)) }
  }
}
