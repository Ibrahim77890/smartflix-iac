# infrastructure-as-Code

SmartFlix is a cloud-based streaming platform concept built to show how a real digital product can be designed and managed with modern infrastructure practices. Instead of creating resources manually, this project models the full backend platform in code so the same setup can be repeated, improved, and scaled safely. It includes networking, identity, compute, storage, event-driven services, deployment pipelines, observability, and governance controls. The overall idea is to represent how a real company could grow from a small development setup into a more production-ready cloud platform.

<img width="5448" height="3262" alt="smartflix-archi" src="https://github.com/user-attachments/assets/0136b4b9-e0e0-40ad-9064-7a1633a3485c" />

## Why Terraform

Terraform is an Infrastructure as Code tool that helps us define cloud resources in simple configuration files instead of creating everything manually from the console. It solves problems like inconsistent environments, manual mistakes, poor repeatability, and difficulty tracking changes over time. Terraform works by reading the desired infrastructure written in `.tf` files, comparing that desired state with the real cloud environment, and then creating, updating, or deleting resources to make both match. Its own architecture is based on providers, state, modules, and execution plans. Providers let Terraform talk to platforms like Google Cloud, state remembers what Terraform manages, modules help organize reusable blocks, and plans show what will happen before actual changes are applied.

## Repo Layout

```text
.
|-- bootstrap/
|-- infra/
|   |-- envs/
|   |   |-- dev/
|   |   |-- stg/
|   |   |-- uat/
|   |   `-- prod/
|   |-- global/
|   `-- modules/
|       |-- cloud-run-edge/
|       |-- database/
|       |-- deployment-strategy/
|       |-- event-driven/
|       |-- gke-cluster/
|       |-- gke-service-stubs/
|       |-- network/
|       |-- observability/
|       |-- policy-as-code/
|       `-- secrets/
|-- ARCHITECTURE_DIAGRAM_GUIDE.md
|-- VIDEO_DEMO_CAPTURE_GUIDE.md
`-- README.md
```

## Folder Contract

- `bootstrap/` is used to create the remote Terraform state bucket.
- `infra/envs/` contains one Terraform root for each environment such as `dev`, `stg`, `uat`, and `prod`.
- `infra/global/` contains shared controls that apply across the whole project, such as governance and deployment strategy.
- `infra/modules/` contains reusable Terraform modules for networking, compute, storage, events, observability, and policy.
- root-level markdown files are used for documentation, architecture explanation, and demo preparation.

## GCP Demo Video

https://github.com/user-attachments/assets/e6df00ca-9645-43ff-9b1c-f9ff65441c7d

## Project Implementation Flow

In order to simulate a real-world scenario and progressive infrastructure acquisition, this project is divided into phases of implementation.

## Phase 01: Foundation

This phase creates the base structure of the project so all future infrastructure can be managed in a clean and scalable way. It prepares the repository layout, environment separation, remote state usage, validation flow, and Terraform module boundaries. The goal here is not heavy cloud creation, but a strong starting platform.

Resources created or prepared:
- **GCS bucket for Terraform remote state**
- **environment roots for dev, stg, uat, and prod**
- **shared Terraform modules structure**
- **tooling files such as pre-commit and version control helpers**

Environment limitations:
- `dev`, `stg`, `uat`, and `prod` exist only as isolated Terraform roots at this stage
- no full application infrastructure runs yet
- this phase is mostly about structure and future readiness

## Phase 02: Networking

This phase builds the private network foundation for SmartFlix. It separates public, private, and data traffic areas so later compute and databases can run in a safer layout. It also prepares private access for managed services.

Resources created or updated:
- **custom VPC per environment**
- **public subnet**
- **private subnet**
- **data subnet**
- **Cloud Router**
- **Cloud NAT**
- **firewall rules**
- **private service access connection**

Environment limitations:
- `dev` is more debugging-friendly and keeps NAT logging enabled
- `stg` and `uat` follow the same structure but with fewer operational extras
- `prod` uses the same segmented pattern but is intended for stricter and safer use

## Phase 03: Identity And Access Management

This phase introduces controlled access for services and secret ownership. Instead of letting workloads share broad permissions, each logical service gets its own identity and only the permissions it needs. This makes the system more secure and more realistic.

Resources created or updated:
- **GCP service accounts for catalog, auth, stream, notification, and recommendation**
- **IAM role bindings**
- **Secret Manager secret containers**
- **Workload Identity mappings**
- **global guardrail policies**

Environment limitations:
- `dev` is easier for testing identities and secret flow
- `stg` and `uat` help validate least-privilege behavior before production
- `prod` is the most sensitive environment and should avoid loose permission experiments

## Phase 04: Compute Management

This phase adds the application runtime layer. SmartFlix now gets its private Kubernetes platform and supporting serverless HTTP services. This is where the system starts to look like a real streaming backend platform.

Resources created or updated:
- **private GKE Autopilot cluster**
- **Kubernetes namespaces and service accounts**
- **Cloud Run services for thumbnail-generation and subtitle-indexing**
- **Serverless VPC Access connector**
- **optional edge and load balancer path**

Environment limitations:
- `dev`, `stg`, and `uat` use the `REGULAR` GKE release channel
- `prod` uses the `STABLE` GKE release channel
- `prod` has higher replicas and stronger protection settings
- GKE workloads may require in-VPC access because the cluster is private

## Phase 05: Storage, Database, And Caching

This phase adds the persistent data layer. SmartFlix now stores relational data, document-style application data, cache data, logs, media files, and artifacts. This is the point where the platform becomes stateful and more realistic.

Resources created or updated:
- **Cloud SQL PostgreSQL**
- **application database**
- **Firestore Native database**
- **Memorystore Redis**
- **KMS key ring and crypto keys**
- **GCS media bucket**
- **GCS logs bucket**
- **GCS artifacts bucket**

Environment limitations:
- `dev`, `stg`, and `uat` are simpler and lower-cost
- `prod` uses stronger deletion protection and more resilient database settings
- `prod` also enables a Cloud SQL read replica

## Phase 06: Event-Driven Architecture

This phase gives SmartFlix an asynchronous workflow. Instead of making every process run in a direct request path, uploads and application events can now trigger background processing. This is important for things like media handling, notifications, and recommendation refreshes.

Resources created or updated:
- **Pub/Sub topics**
- **Pub/Sub subscriptions**
- **Cloud Functions Gen 2**
- **Cloud Workflow**
- **Eventarc trigger**
- **Cloud Storage notifications**

Environment limitations:
- `dev` is best for safely testing event flow and function behavior
- `stg` and `uat` help verify that workflows behave correctly before release
- `prod` carries the real background orchestration pattern and should be treated more carefully during updates

## Phase 07: Deployment Strategy

This phase introduces controlled software delivery. Instead of manually pushing everything, the project now has a deployment path that can promote application changes across environments in a more organized way.

Resources created or updated:
- **Artifact Registry repositories**
- **Cloud Deploy runner service account**
- **Cloud Deploy artifact bucket**
- **Cloud Deploy targets**
- **Cloud Deploy pipelines**

Environment limitations:
- `dev` and `stg` move faster and do not require manual approval
- `uat` and `prod` are more controlled and require approval
- `prod` is meant for carefully promoted releases, not direct experimentation

## Phase 08: Observability

This phase makes the platform easier to monitor and troubleshoot. A real project is not complete if it only creates resources but cannot explain what is happening when performance drops or failures occur.

Resources created or updated:
- **Monitoring notification channels**
- **log sink**
- **custom logging metric**
- **uptime checks**
- **alert policies for Cloud Run, Pub/Sub, SQL, and application errors**

Environment limitations:
- `dev` is useful for testing alerts and visibility setup
- `stg` and `uat` help verify alert quality before production use
- `prod` should carry the final operational signals and meaningful alert thresholds

## Phase 09: Policy As Code

This phase adds governance and security controls as code. It shows that SmartFlix is not only deployable, but also manageable under rules, compliance thinking, and controlled release trust.

Resources created or updated:
- **Binary Authorization attestor**
- **Container Analysis note**
- **KMS-backed attestation key**
- **Binary Authorization policy**
- **policy library bucket with Rego policy files**

Environment limitations:
- `dev` is still a learning and validation space
- `stg` and `uat` help test security policy effects before strict rollout
- `prod` is where policy matters most, so this environment should eventually move from dry-run checks to stronger enforcement

## Closing Note

This project is designed to represent how I would build and grow a cloud platform in a structured way using Terraform on Google Cloud. Each phase adds one important layer of maturity, starting from the foundation and ending with observability and governance. The result is a full SmartFlix Infrastructure as Code project that is easier to understand, easier to repeat, and closer to how real enterprise systems are managed.
