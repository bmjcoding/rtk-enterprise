# Enterprise Audit Documentation

This directory contains the public review documentation for RTK Enterprise. These files describe the security posture, verification process, and evidence handling model. They are not a substitute for independent security review or internal approval.

- [AUDIT_SUMMARY.md](AUDIT_SUMMARY.md): hardening summary, source scope, controls, and residual risk
- [NO_TELEMETRY_POSITION.md](NO_TELEMETRY_POSITION.md): formal boundary for the no-telemetry claim
- [VERIFICATION_RUNBOOK.md](VERIFICATION_RUNBOOK.md): reproducible reviewer workflow for source, tests, build, evidence, and endpoint policy
- [NETWORK_EGRESS_POLICY.md](NETWORK_EGRESS_POLICY.md): recommended deny-by-default RTK process egress model
- [EVIDENCE_HANDLING.md](EVIDENCE_HANDLING.md): how to generate, store, redact, and retain audit evidence
- [ROLL_OUT_SECURITY_REVIEW.md](ROLL_OUT_SECURITY_REVIEW.md): rollout decision standard and review checklist

The accurate approval scope is a specific commit, build, and evidence package. Do not use these documents to claim blanket approval for future commits.
