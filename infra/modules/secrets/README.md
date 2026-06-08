## Secrets Module

Phase 03 status: implemented.

Resources created by this module:
- `google_service_account` for per-service GCP identities
- `google_project_iam_member` for least-privilege project role bindings
- `google_service_account_iam_binding` for GKE Workload Identity access
- `google_secret_manager_secret` for secret containers only
- `google_secret_manager_secret_iam_member` for scoped secret access

Important behavior:
- secret values are not created in Terraform, so they do not land in state
- Workload Identity bindings map one Kubernetes service account to one GCP service account per service
- `roles/editor` and `roles/owner` are blocked by module validation
