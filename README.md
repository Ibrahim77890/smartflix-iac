# StreamFlix IaC

Phase 01 foundation scaffold for the StreamFlix Terraform portfolio project on GCP.

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

## Next Phase

Phase 02 will implement the actual `network` module resources: VPC, subnets, Cloud NAT, firewall rules, and private service access.
