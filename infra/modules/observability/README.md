# Observability Module

Phase 08 monitoring layer for StreamFlix.

This module creates:
- Monitoring email notification channels
- a project log sink that exports operational logs to the Phase 05 logs bucket
- a custom logging metric for application errors
- uptime checks for Cloud Run services
- alert policies for:
  - Cloud Run uptime failures
  - Pub/Sub backlog
  - Cloud SQL CPU utilization
  - aggregate application errors

The module is environment-scoped and is intended to run inside each `infra/envs/*` root.
