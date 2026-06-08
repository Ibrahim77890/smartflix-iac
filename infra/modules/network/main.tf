locals {
  subnet_names = {
    for subnet_key, subnet in var.subnets :
    subnet_key => coalesce(try(subnet.name, null), "${var.environment}-${subnet_key}-subnet")
  }

  nat_subnets = {
    for subnet_key, subnet in var.subnets :
    subnet_key => subnet if try(subnet.nat_enabled, false)
  }

  firewall_rule_names = {
    for rule_key, rule in var.firewall_rules :
    rule_key => coalesce(try(rule.name, null), "${var.environment}-${rule_key}")
  }
}

resource "google_compute_network" "vpc" {
  name                            = var.vpc_name
  project                         = var.project_id
  auto_create_subnetworks         = false
  routing_mode                    = "GLOBAL"
  mtu                             = 1460
  delete_default_routes_on_create = false
}

resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name                     = local.subnet_names[each.key]
  project                  = var.project_id
  region                   = each.value.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = each.value.ip_cidr_range
  private_ip_google_access = each.value.private_google_access
  description              = each.value.description

  dynamic "secondary_ip_range" {
    for_each = try(each.value.secondary_ip_ranges, {})

    content {
      range_name    = secondary_ip_range.key
      ip_cidr_range = secondary_ip_range.value
    }
  }
}

resource "google_compute_router" "nat" {
  name    = "${var.environment}-nat-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "private_egress" {
  name                               = "${var.environment}-cloud-nat"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.nat.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = local.nat_subnets

    content {
      name                    = google_compute_subnetwork.subnets[subnetwork.key].id
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }

  dynamic "log_config" {
    for_each = var.nat_log_enabled ? [1] : []

    content {
      enable = true
      filter = var.nat_log_filter
    }
  }
}

resource "google_compute_firewall" "default_deny_ingress" {
  name        = "${var.environment}-deny-all-ingress"
  project     = var.project_id
  network     = google_compute_network.vpc.name
  description = "Explicit deny-all ingress baseline for ${var.environment}."
  direction   = "INGRESS"
  priority    = 65534

  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "rules" {
  for_each = var.firewall_rules

  name        = local.firewall_rule_names[each.key]
  project     = var.project_id
  network     = google_compute_network.vpc.name
  description = each.value.description
  direction   = each.value.direction
  priority    = try(each.value.priority, 1000)

  source_ranges      = length(try(each.value.source_ranges, [])) > 0 ? each.value.source_ranges : null
  destination_ranges = length(try(each.value.destination_ranges, [])) > 0 ? each.value.destination_ranges : null
  source_tags        = length(try(each.value.source_tags, [])) > 0 ? each.value.source_tags : null
  target_tags        = length(try(each.value.target_tags, [])) > 0 ? each.value.target_tags : null

  dynamic "allow" {
    for_each = try(each.value.allow, [])

    content {
      protocol = allow.value.protocol
      ports    = length(try(allow.value.ports, [])) > 0 ? allow.value.ports : null
    }
  }

  dynamic "deny" {
    for_each = try(each.value.deny, [])

    content {
      protocol = deny.value.protocol
      ports    = length(try(deny.value.ports, [])) > 0 ? deny.value.ports : null
    }
  }

  dynamic "log_config" {
    for_each = try(each.value.log_metadata, null) == null ? [] : [each.value.log_metadata]

    content {
      metadata = log_config.value
    }
  }
}

resource "google_compute_global_address" "private_service_access" {
  name          = "${var.environment}-private-service-range"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_access_prefix_length
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_service_access" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access.name]
}
