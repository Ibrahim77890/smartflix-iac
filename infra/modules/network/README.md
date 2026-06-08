## Network Module

Phase 02 status: implemented.

Resources created by this module:
- `google_compute_network` for a custom-mode VPC per environment
- `google_compute_subnetwork` for public, private, and data subnet tiers
- `google_compute_router` and `google_compute_router_nat` for private egress
- `google_compute_firewall` for an explicit deny-all ingress baseline plus map-driven allow rules
- `google_compute_global_address` and `google_service_networking_connection` for private service access

Patterns implemented:
- firewall rules are a `map(object(...))` and materialized with `for_each`
- GKE secondary ranges are attached only where provided
- Cloud NAT logging is configurable per environment
- Private Google Access is configured at the subnet level
