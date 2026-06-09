# Deployment Strategy Module

Phase 07 release-management layer for StreamFlix on GCP.

This module creates:
- Artifact Registry repositories for release artifacts
- a Cloud Deploy runner service account with execution IAM
- a Cloud Deploy artifact bucket
- Cloud Deploy targets for GKE and Cloud Run across `dev`, `stg`, `uat`, and `prod`
- delivery pipelines that promote releases through those targets in order

The intended rollout model is:
- `dev` and `stg` promote automatically
- `uat` and `prod` require approval at the target level
- GKE and Cloud Run use separate pipelines so they can evolve independently

Important note:
- the GKE targets point at the private Autopilot clusters created in Phase 04
- actual rollout execution to those private clusters may require a private worker pool or another in-VPC execution path later, depending on how you choose to run Cloud Deploy
