## Cloud Run Edge Module

Phase 04 status: implemented.

Resources created by this module:
- `google_vpc_access_connector` for private egress from Cloud Run
- `google_cloud_run_v2_service` for lightweight edge services
- `google_cloud_run_v2_service_iam_member` for public invocation
- optional global HTTPS load balancer resources backed by Cloud Run serverless NEGs
- `google_compute_security_policy` for rate limiting and geo restriction

Notes:
- the HTTPS load balancer is only created when `lb_domains` is non-empty
- managed SSL certificates require real domains that point at the load balancer IP
