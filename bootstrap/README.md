## Bootstrap

This root creates the GCS bucket that stores Terraform remote state for every StreamFlix environment.

Why this exists:
- Terraform cannot use a remote backend until that backend already exists.
- `bootstrap/` uses local state one time to create the shared GCS bucket.
- After the bucket exists, each environment root runs `terraform init` against that bucket with its own state prefix.

Run order:
1. Update `terraform.tfvars` with your real `project_id` and a globally unique `state_bucket_name`.
2. From `bootstrap/`, run `terraform init`.
3. Run `terraform apply`.
4. Copy the bucket name into your `terraform init -backend-config="bucket=..."` command for each env root.

Notes:
- Keep `bootstrap/` on local state. Do not point it back to the same bucket it creates.
- The bucket uses versioning and public access prevention so old state versions can be recovered safely.


