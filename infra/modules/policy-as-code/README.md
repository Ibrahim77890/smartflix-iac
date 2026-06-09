# Policy As Code Module

Phase 09 policy layer for StreamFlix.

This module creates:
- Binary Authorization API enablement
- an attestation KMS key
- a Container Analysis note
- a Binary Authorization attestor
- a project Binary Authorization policy in `DRYRUN_AUDIT_LOG_ONLY`
- a versioned policy-library bucket with sample policy bundles

The dry-run posture is intentional so the policy can be applied safely to an already-running platform before you tighten enforcement in a later pass.
