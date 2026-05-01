# Enterprise Rollout Security Review

This document is the handoff package for a regulated enterprise review of the telemetry-free RTK build.

Related audit documents:

- [README.md](README.md) - enterprise audit documentation index
- [AUDIT_SUMMARY.md](AUDIT_SUMMARY.md) - hardening summary, review scope, controls, and residual risk
- [NO_TELEMETRY_POSITION.md](NO_TELEMETRY_POSITION.md) - formal boundary for the no-telemetry claim
- [VERIFICATION_RUNBOOK.md](VERIFICATION_RUNBOOK.md) - reproducible reviewer workflow
- [NETWORK_EGRESS_POLICY.md](NETWORK_EGRESS_POLICY.md) - endpoint egress policy guidance
- [EVIDENCE_HANDLING.md](EVIDENCE_HANDLING.md) - generated evidence handling guidance

## Decision Standard

No competent reviewer should approve this as "no risk." The approvable claim is narrower:

- The current source tree contains no known RTK telemetry, local usage history, analytics/reporting command, raw-output persistence, or workflow exfiltration mechanism.
- Automated gates are present to prevent those mechanisms from being reintroduced.
- Release artifacts can be signed, checksummed, attested, and accompanied by an SBOM.

## Required Independent Review

Before employee-wide rollout, an independent security reviewer must verify:

- `scripts/enterprise-audit.sh` passes from a clean checkout.
- `cargo test --locked` passes.
- `cargo build --locked --release` produces the reviewed binary.
- `cargo audit --deny warnings` passes.
- `cargo deny check advisories bans sources` passes.
- `semgrep scan --config .semgrep.yml --error` reports zero findings.
- `gitleaks dir . --redact --no-banner` reports zero findings.
- The release artifact SHA-256 matches `checksums.txt`.
- Sigstore/cosign signatures and GitHub attestations verify against the expected repository identity.
- Enterprise endpoint/network controls block `rtk` from initiating outbound connections except through explicitly invoked child tools such as `git`, `curl`, `aws`, or package managers.

## Network Egress Control

RTK is a command proxy. It should not open sockets or make HTTP requests itself. Some proxied user commands are intentionally network-capable, for example `rtk curl`, `rtk wget`, `rtk aws`, `rtk gh`, package managers, and language tooling.

Required enterprise controls:

- Apply host firewall/EDR policy to the `rtk` process allowing no direct outbound socket creation.
- Monitor child-process egress separately; child tools should follow the enterprise allowlist for developer tooling.
- Alert if `rtk` loads network/TLS client libraries or opens a socket directly.
- Deploy from signed internal packages only; do not allow employee machines to install RTK directly from public GitHub.

## Source Intake

Do not intake the full upstream Git history into a government or mega-bank source archive. The upstream history contains code that has been removed from this enterprise tree. Use one of:

- A signed release source archive generated from this sanitized tree.
- A fresh internal repository initialized from this tree without upstream history.
- A squash import with review evidence attached.

## Evidence Bundle

Generate review evidence with:

```bash
scripts/enterprise-audit.sh
cargo build --locked --release
scripts/release-evidence.sh
```

Expected outputs include:

- Locked dependency metadata
- Locked dependency tree
- SPDX SBOM when `syft` is installed
- Source-control input hashes
- Release binary hash when `target/release/rtk` exists

## Residual Risk

Residual risk remains in:

- Child commands that intentionally access networks or files.
- Hook installation modifying local agent configuration.
- User/project TOML filters, mitigated by trust gating and content hashing.
- Supply-chain risk in build tooling and GitHub Actions.
- Historical upstream repository contents if `.git` history is distributed.

These risks require enterprise policy controls, not only code changes.
