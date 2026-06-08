locals {
  service_accounts = {
    for service_name, config in var.service_accounts :
    service_name => merge(
      config,
      {
        account_id = coalesce(try(config.account_id, null), substr(replace("${var.environment}-${service_name}", "_", "-"), 0, 30))
      }
    )
  }

  project_role_bindings = flatten([
    for service_name, config in local.service_accounts : [
      for role in config.project_roles : {
        key          = "${service_name}:${role}"
        service_name = service_name
        role         = role
      }
    ]
  ])

  secret_accessor_bindings = flatten([
    for secret_id, config in var.secrets : [
      for accessor in config.accessors : {
        key          = "${secret_id}:${accessor}"
        secret_id    = secret_id
        service_name = accessor
      }
    ]
  ])

  workload_identity_members = {
    for service_name, config in local.service_accounts :
    service_name => [
      "serviceAccount:${var.project_id}.svc.id.goog[${config.kubernetes_namespace}/${config.kubernetes_service_account}]"
    ]
    if var.enable_workload_identity
  }
}

resource "google_service_account" "service_accounts" {
  for_each = local.service_accounts

  project      = var.project_id
  account_id   = each.value.account_id
  display_name = each.value.display_name
  description  = each.value.description
}

resource "google_project_iam_member" "service_roles" {
  for_each = {
    for binding in local.project_role_bindings :
    binding.key => binding
  }

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.service_name].email}"
}

resource "google_service_account_iam_binding" "workload_identity" {
  for_each = var.enable_workload_identity ? local.service_accounts : {}

  service_account_id = google_service_account.service_accounts[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  members            = local.workload_identity_members[each.key]
}

resource "google_secret_manager_secret" "secrets" {
  for_each = var.secrets

  project   = var.project_id
  secret_id = each.key
  labels = merge(
    var.labels,
    {
      env     = var.environment
      service = each.value.owner_service
    }
  )

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "accessors" {
  for_each = {
    for binding in local.secret_accessor_bindings :
    binding.key => binding
  }

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.value.secret_id].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.service_accounts[each.value.service_name].email}"
}

resource "google_secret_manager_secret_iam_member" "admins" {
  for_each = var.secret_admin_members

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.key].secret_id
  role      = "roles/secretmanager.admin"
  member    = each.value
}
