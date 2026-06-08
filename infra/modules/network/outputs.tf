output "module_contract" {
  description = "Network summary returned to the environment roots."
  value = {
    environment                   = var.environment
    vpc_name                      = google_compute_network.vpc.name
    vpc_self_link                 = google_compute_network.vpc.self_link
    subnet_names                  = { for key, subnet in google_compute_subnetwork.subnets : key => subnet.name }
    subnet_cidrs                  = { for key, subnet in google_compute_subnetwork.subnets : key => subnet.ip_cidr_range }
    private_google_access_subnets = [for key, subnet in var.subnets : key if subnet.private_google_access]
    nat_router_name               = google_compute_router.nat.name
    nat_name                      = google_compute_router_nat.private_egress.name
    nat_logging_enabled           = var.nat_log_enabled
    private_service_range_name    = google_compute_global_address.private_service_access.name
    private_service_connection    = google_service_networking_connection.private_service_access.peering
    firewall_rule_names           = values(local.firewall_rule_names)
    gke_secondary_ranges_by_subnet = {
      for key, subnet in var.subnets :
      key => try(subnet.secondary_ip_ranges, {})
      if length(try(subnet.secondary_ip_ranges, {})) > 0
    }
  }
}
