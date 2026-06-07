locals {
  module_contract = {
    environment = var.environment
    project_id  = var.project_id
    region      = var.region
    vpc_name    = var.vpc_name
  }
}
