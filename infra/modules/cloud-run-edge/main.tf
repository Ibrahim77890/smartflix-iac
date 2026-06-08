locals {
  lb_enabled = length(var.lb_domains) > 0
}

resource "google_vpc_access_connector" "connector" {
  name          = "${var.environment}-run-connector"
  project       = var.project_id
  region        = var.region
  machine_type  = var.connector_machine_type
  min_instances = var.connector_min_instances
  max_instances = var.connector_max_instances
  network       = var.connector_network
  ip_cidr_range = var.connector_ip_cidr_range
}

resource "google_cloud_run_v2_service" "services" {
  for_each = var.services

  name     = "${var.environment}-${each.key}"
  project  = var.project_id
  location = var.region
  ingress  = each.value.ingress

  template {
    service_account = each.value.service_account_email

    scaling {
      min_instance_count = each.value.min_instances
      max_instance_count = each.value.max_instances
    }

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = each.value.image

      ports {
        container_port = each.value.container_port
      }

      resources {
        limits = each.value.limits
      }

      dynamic "env" {
        for_each = each.value.env

        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  for_each = var.services

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.services[each.key].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_compute_security_policy" "edge" {
  count   = local.lb_enabled ? 1 : 0
  name    = "${var.environment}-edge-armor"
  project = var.project_id

  rule {
    priority = 1000
    action   = "rate_based_ban"

    match {
      versioned_expr = "SRC_IPS_V1"

      config {
        src_ip_ranges = ["*"]
      }
    }

    rate_limit_options {
      conform_action   = "allow"
      exceed_action    = "deny(429)"
      enforce_on_key   = "IP"
      ban_duration_sec = 300

      rate_limit_threshold {
        count        = 200
        interval_sec = 60
      }

      ban_threshold {
        count        = 400
        interval_sec = 60
      }
    }
  }

  rule {
    priority = 1100
    action   = "deny(403)"

    match {
      expr {
        expression = var.geo_deny_expression
      }
    }
  }

  rule {
    priority = 2147483647
    action   = "allow"

    match {
      versioned_expr = "SRC_IPS_V1"

      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}

resource "google_compute_region_network_endpoint_group" "serverless_negs" {
  for_each = local.lb_enabled ? var.lb_backends : toset([])

  name                  = "${var.environment}-${each.key}-neg"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.services[each.key].name
  }
}

resource "google_compute_backend_service" "serverless" {
  for_each              = local.lb_enabled ? var.lb_backends : toset([])
  name                  = "${var.environment}-${each.key}-backend"
  project               = var.project_id
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  security_policy       = google_compute_security_policy.edge[0].id

  backend {
    group = google_compute_region_network_endpoint_group.serverless_negs[each.key].id
  }
}

resource "google_compute_managed_ssl_certificate" "edge" {
  count   = local.lb_enabled ? 1 : 0
  name    = "${var.environment}-edge-cert"
  project = var.project_id

  managed {
    domains = var.lb_domains
  }
}

resource "google_compute_url_map" "edge" {
  count           = local.lb_enabled ? 1 : 0
  name            = "${var.environment}-edge-url-map"
  project         = var.project_id
  default_service = google_compute_backend_service.serverless[var.default_lb_backend].id

  host_rule {
    hosts        = var.lb_domains
    path_matcher = "streamflix-edge"
  }

  path_matcher {
    name            = "streamflix-edge"
    default_service = google_compute_backend_service.serverless[var.default_lb_backend].id

    dynamic "path_rule" {
      for_each = var.lb_path_rules

      content {
        paths   = path_rule.value.paths
        service = google_compute_backend_service.serverless[path_rule.value.backend_key].id
      }
    }
  }
}

resource "google_compute_target_https_proxy" "edge" {
  count            = local.lb_enabled ? 1 : 0
  name             = "${var.environment}-edge-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.edge[0].id
  ssl_certificates = [google_compute_managed_ssl_certificate.edge[0].id]
}

resource "google_compute_global_address" "edge" {
  count   = local.lb_enabled ? 1 : 0
  name    = "${var.environment}-edge-ip"
  project = var.project_id
}

resource "google_compute_global_forwarding_rule" "edge" {
  count                 = local.lb_enabled ? 1 : 0
  name                  = "${var.environment}-edge-https"
  project               = var.project_id
  ip_address            = google_compute_global_address.edge[0].id
  port_range            = "443"
  target                = google_compute_target_https_proxy.edge[0].id
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
