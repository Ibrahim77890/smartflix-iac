output "foundation_contract" {
  description = "Phase 01 proof that the global root is intentionally reserved for shared controls."
  value = {
    scope = "global"
    note  = local.foundation_note
  }
}
