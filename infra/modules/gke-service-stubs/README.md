## GKE Service Stubs Module

Phase 04 status: implemented.

Resources created by this module:
- Kubernetes namespaces and Kubernetes service accounts for app stubs
- NGINX catalog stub
- Grafana stream stub
- HTTP echo recommendation stub
- Auth placeholder by default, with optional Keycloak Helm release

Notes:
- `deploy_keycloak` defaults to `false` so Phase 04 can be applied without committing a real admin secret
- enabling Helm Keycloak will store its admin password in state unless you switch to an external secret pattern later
