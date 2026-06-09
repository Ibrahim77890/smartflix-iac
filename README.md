# StreamFlix IaC

Phase 01 through Phase 09 scaffold for the StreamFlix Terraform portfolio project on GCP.

## Repo Layout

```text
.
├── bootstrap/
├── infra/
│   ├── envs/
│   │   ├── dev/
│   │   ├── stg/
│   │   ├── uat/
│   │   └── prod/
│   ├── global/
│   └── modules/
│       ├── database/
│       ├── gke-cluster/
│       ├── network/
│       └── secrets/
├── .pre-commit-config.yaml
├── .terraform-version
└── .tool-versions
```

## Folder Contract

- `bootstrap/`: one-time local-state root that creates the GCS bucket for remote Terraform state.
- `infra/envs/*`: one root per environment, each with isolated state and its own backend prefix.
- `infra/global/`: shared org-level controls such as org policies, DNS, and guardrails.
- `infra/modules/*`: reusable Terraform modules consumed by environment roots.

## Phase 01 Deliverable

This phase intentionally keeps the infrastructure almost empty while locking in the platform shape:
- reusable module boundaries exist
- each environment has its own Terraform root
- remote state is ready through GCS
- variables are typed and documented
- tooling and pre-commit hooks are declared

## Bootstrap The Remote State Bucket

1. Update [bootstrap/terraform.tfvars](/E:/terraform-practice/bootstrap/terraform.tfvars:1) with your real `project_id` and a globally unique `state_bucket_name`.
2. Run the bootstrap root:

```bash
cd bootstrap
terraform init
terraform apply
```

3. After the bucket is created, initialize each Terraform root with the bucket name:

```bash
cd infra/envs/dev
terraform init -backend-config="bucket=YOUR_STATE_BUCKET"

cd ../stg
terraform init -backend-config="bucket=YOUR_STATE_BUCKET"

cd ../uat
terraform init -backend-config="bucket=YOUR_STATE_BUCKET"

cd ../prod
terraform init -backend-config="bucket=YOUR_STATE_BUCKET"

cd ../../global
terraform init -backend-config="bucket=YOUR_STATE_BUCKET"
```

Each root already defines a unique `prefix` in its own `backend.tf`, so only the bucket name must be injected at init time.

## Terraform Roots

- [infra/envs/dev](/E:/terraform-practice/infra/envs/dev:1)
- [infra/envs/stg](/E:/terraform-practice/infra/envs/stg:1)
- [infra/envs/uat](/E:/terraform-practice/infra/envs/uat:1)
- [infra/envs/prod](/E:/terraform-practice/infra/envs/prod:1)
- [infra/global](/E:/terraform-practice/infra/global:1)

## Tooling

Install these tools locally:
- Terraform `>= 1.7`
- `pre-commit`
- `tflint`
- `tfsec`
- `checkov`
- `asdf` optionally, using [.tool-versions](/E:/terraform-practice/.tool-versions:1)

Run the quality checks:

```bash
pre-commit install
pre-commit run --all-files
```

## Sensitive Data Rule

Do not commit plaintext secrets.

For Phase 01:
- use `terraform.tfvars` only for non-sensitive values
- reserve secret values for Secret Manager in later phases

## Phase 02 Networking

The shared [infra/modules/network](/E:/terraform-practice/infra/modules/network:1) module now creates:
- one custom-mode VPC per environment
- three subnet tiers per environment: `public`, `private`, and `data`
- Private Google Access on `private` and `data`
- GKE secondary ranges on the `private` subnet
- one Cloud Router and one Cloud NAT per environment
- explicit deny-all ingress plus map-driven allow firewall rules
- private service access reservation and peering for future Cloud SQL and Redis

Environment CIDRs:
- `dev`: `10.10.0.0/16`
- `stg`: `10.20.0.0/16`
- `uat`: `10.25.0.0/16`
- `prod`: `10.30.0.0/16`

NAT logging:
- `dev`: enabled with `ALL`
- `stg`: disabled
- `uat`: disabled
- `prod`: disabled

## Phase 03 Identity And Access Management

The shared [infra/modules/secrets](/E:/terraform-practice/infra/modules/secrets:1) module now creates:
- one GCP service account per microservice: `catalog`, `auth`, `stream`, `notification`
- least-privilege project IAM grants with `google_project_iam_member`
- Workload Identity bindings between Kubernetes service accounts and GCP service accounts
- Secret Manager secret containers without secret values in Terraform state
- per-secret `roles/secretmanager.secretAccessor` bindings only for approved services

The [infra/global](/E:/terraform-practice/infra/global:1) root now defines guardrail policies for:
- `iam.disableServiceAccountKeyCreation`
- `compute.requireShieldedVm`
- `compute.restrictCloudSQLPublicIp`

Before applying Phase 03 for real:
- replace the placeholder `user:you@example.com` entries in each env `terraform.tfvars`
- keep `project_id` set correctly and let the global root derive `projects/<project-number>` automatically, or override `org_policy_parent` only if you truly need a different numeric parent
- remember that secret values themselves must be created outside Terraform

## Phase 04 Compute Management

The compute layer now includes:
- a private GKE Autopilot cluster per environment via [infra/modules/gke-cluster](/E:/terraform-practice/infra/modules/gke-cluster:1)
- Kubernetes service stubs via [infra/modules/gke-service-stubs](/E:/terraform-practice/infra/modules/gke-service-stubs:1)
- Cloud Run edge services and optional HTTPS edge entry via [infra/modules/cloud-run-edge](/E:/terraform-practice/infra/modules/cloud-run-edge:1)

Configured compute resources:
- `google_container_cluster` in Autopilot mode with private endpoint and Workload Identity
- Kubernetes namespaces and KSAs for `catalog`, `auth`, `stream`, and `recommendation`
- `catalog` stub on `nginx:alpine`
- `stream` stub on `grafana/grafana`
- `recommendation` stub on `hashicorp/http-echo`
- auth placeholder by default, with the Helm/Keycloak path kept available for later hardening
- `google_vpc_access_connector`
- two `google_cloud_run_v2_service` resources: `thumbnail-generation` and `subtitle-indexing`
- optional Cloud Armor and global HTTPS load balancer resources when real domains are supplied

Environment compute differences:
- `dev`, `stg`, `uat` use GKE release channel `REGULAR`
- `prod` uses GKE release channel `STABLE`
- `prod` runs higher replica counts and stricter cluster deletion protection

Important apply notes for Phase 04:
- the optional HTTPS load balancer stays disabled until you provide real domains in the env roots
- the in-cluster auth service is a safe placeholder by default; enabling Helm Keycloak later will need a proper admin secret strategy
- the Serverless VPC Access connector uses its own dedicated `/28` range per environment
- `deploy_gke_workloads` defaults to `false` because the cluster control plane is private-only; apply Kubernetes and Helm workloads later from inside the VPC or through a bastion/runner
- `enable_workload_identity_bindings` defaults to `false` for the first environment apply; enable it after the cluster exists

## Phase 05 Storage, Databases, And Caching

The shared [infra/modules/database](/E:/terraform-practice/infra/modules/database:1) module now creates:
- Cloud SQL PostgreSQL with private IP only
- an app database inside the Cloud SQL instance
- a prod-only Cloud SQL read replica
- Firestore Native databases with TTL and a sample composite index
- Memorystore Redis with private service access and auth enabled
- KMS key ring and per-bucket crypto keys for CMEK
- GCS buckets for `media_assets`, `raw_logs`, and `tf_artifacts`

Phase 05 storage characteristics:
- all SQL and Redis traffic stays on the private VPC
- Firestore is environment-scoped by database ID
- raw logs transition to Coldline after 30 days and delete after 365 days
- bucket encryption is managed through CMEK in the same module
- prod uses stronger deletion protection and a read replica

Important apply notes for Phase 05:
- this phase assumes private service access from Phase 02 already exists
- Firestore database IDs are environment-specific because all env roots currently target the same GCP project
- KMS keys use `prevent_destroy` to reduce accidental loss of encrypted data

## Phase 06 Event-Driven Architecture

The shared [infra/modules/event-driven](/E:/terraform-practice/infra/modules/event-driven:1) module now creates:
- Pub/Sub topics and subscriptions for:
  - `user-events`
  - `transcode-jobs`
  - `recommendation-refresh`
  - `billing-events`
- Cloud Functions Gen 2 consumers:
  - `transcode-trigger`
  - `notification-dispatcher`
- a media-ingest Cloud Workflow
- GCS upload notifications into Pub/Sub for the media bucket
- an Eventarc trigger that routes media finalize events into the workflow

Phase 06 behavior:
- function source is packaged into the Phase 05 `tf_artifacts` bucket
- media uploads fan into the `transcode-jobs` topic
- the workflow calls the Phase 04 Cloud Run edge services and then publishes a follow-up event

Important apply notes for Phase 06:
- run `terraform init` again in each env root because this phase adds the `archive` provider
- the event-driven module reuses the Phase 05 buckets and Phase 03 service accounts
- Eventarc and Cloud Functions Gen 2 can take a bit longer on first creation because they enable and coordinate multiple services

## Phase 07 Deployment Strategy

The shared [infra/modules/deployment-strategy](/E:/terraform-practice/infra/modules/deployment-strategy:1) module now creates:
- Artifact Registry repositories for application images and release bundles
- a dedicated Cloud Deploy runner service account with execution IAM
- a versioned GCS bucket for Cloud Deploy render and rollout artifacts
- Cloud Deploy targets for GKE and Cloud Run in `dev`, `stg`, `uat`, and `prod`
- two delivery pipelines:
  - `streamflix-gke`
  - `streamflix-run`

Phase 07 promotion strategy:
- `dev` and `stg` promote without manual approval
- `uat` and `prod` require approval on the target before promotion continues
- GKE and Cloud Run use separate release lanes so each compute surface can ship independently

Important apply notes for Phase 07:
- apply this phase from [infra/global](/E:/terraform-practice/infra/global:1)
- the pipeline targets assume the Phase 04 cluster and Cloud Run naming convention already exists
- the GKE targets reference private Autopilot clusters, so later real rollouts may need a private worker pool or another in-VPC execution path for Cloud Deploy jobs to reach the control plane

## Phase 08 Observability

The shared [infra/modules/observability](/E:/terraform-practice/infra/modules/observability:1) module now creates:
- Monitoring email notification channels per environment
- an operations log sink that exports into the Phase 05 `raw_logs` bucket
- a custom logging metric for application errors
- Cloud Run uptime checks
- alert policies for:
  - uptime failures
  - Pub/Sub backlog
  - Cloud SQL CPU utilization
  - aggregate application errors

Important apply notes for Phase 08:
- apply this phase through each environment root, not through `global`
- notification channels are optional; set `alert_notification_emails` in an env if you want real email alerts
- the module reuses the Cloud Run, Pub/Sub, SQL, and logging resources already created in earlier phases

## Phase 09 Policy As Code

The shared [infra/modules/policy-as-code](/E:/terraform-practice/infra/modules/policy-as-code:1) module now creates:
- Binary Authorization API enablement
- a KMS-backed attestation key foundation
- a Container Analysis attestor note
- a Binary Authorization attestor
- a project Binary Authorization policy in `DRYRUN_AUDIT_LOG_ONLY`
- a versioned policy-library bucket containing sample Terraform and Kubernetes Rego policies

Important apply notes for Phase 09:
- apply this phase from [infra/global](/E:/terraform-practice/infra/global:1)
- the Binary Authorization policy is intentionally dry-run so it can be introduced safely on top of existing environments
- the uploaded Rego files act as a starter policy library for later CI or admission-controller enforcement
