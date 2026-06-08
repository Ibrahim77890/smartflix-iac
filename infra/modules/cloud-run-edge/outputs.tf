output "module_contract" {
  description = "Cloud Run and edge summary."
  value = {
    connector_name   = google_vpc_access_connector.connector.name
    service_urls     = { for key, service in google_cloud_run_v2_service.services : key => service.uri }
    service_names    = { for key, service in google_cloud_run_v2_service.services : key => service.name }
    lb_enabled       = length(var.lb_domains) > 0
    lb_ip_address    = try(google_compute_global_address.edge[0].address, null)
    cloud_armor_name = try(google_compute_security_policy.edge[0].name, null)
  }
}
