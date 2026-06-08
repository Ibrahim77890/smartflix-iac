# StreamFlix IaC

Phase 01 through Phase 03 scaffold for the StreamFlix Terraform portfolio project on GCP.

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
