## GKE Cluster Module

Phase 04 status: implemented.

Resources created by this module:
- `google_container_cluster` in Autopilot mode

Key characteristics:
- private cluster with private endpoint only
- Workload Identity enabled
- VPC-native IP allocation using the network module's secondary ranges
- release channel controlled per environment
