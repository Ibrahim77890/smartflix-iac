resource "google_container_cluster" "autopilot" {
  name                = var.cluster_name
  project             = var.project_id
  location            = var.region
  network             = var.network
  subnetwork          = var.subnetwork
  enable_autopilot    = true
  deletion_protection = var.deletion_protection
  networking_mode     = "VPC_NATIVE"

  release_channel {
    channel = var.release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.bastion_cidr
      display_name = "bastion-cidr"
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  dns_config {
    cluster_dns       = "CLOUD_DNS"
    cluster_dns_scope = "CLUSTER_SCOPE"
  }
}
