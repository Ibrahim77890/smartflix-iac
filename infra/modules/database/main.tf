locals {
  module_contract = {
    environment = var.environment
    db_name     = var.db_name
    tier        = var.instance_tier
  }
}
