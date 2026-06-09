output "foundation_contract" {
  description = "Phase 03 proof that global org-policy guardrails are configured."
  value = {
    scope             = "global"
    org_policy_parent = local.effective_org_policy_parent
    policies          = { for key, policy in google_org_policy_policy.guardrails : key => policy.name }
  }
}

output "deployment_contract" {
  description = "Phase 07 release-management summary."
  value       = module.deployment_strategy.module_contract
}
