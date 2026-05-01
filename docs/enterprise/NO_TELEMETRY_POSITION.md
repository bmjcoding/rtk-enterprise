# No Telemetry Position

This document states the RTK Enterprise telemetry position for security, privacy, and compliance review. It should be read with [VERIFICATION_RUNBOOK.md](VERIFICATION_RUNBOOK.md) and [NETWORK_EGRESS_POLICY.md](NETWORK_EGRESS_POLICY.md).

## Position Statement

RTK Enterprise is intended to run without RTK-owned telemetry, product analytics, usage reporting, crash reporting, local usage-history databases, release notification pings, or update checks.

The source tree must not contain:

- HTTP client or raw socket code used by RTK itself
- Tracking, analytics, telemetry, or reporting vendor integrations
- Local usage-history databases such as `tracking.db`, `history.db`, `usage.db`, or `analytics.db`
- Removed command surfaces such as `rtk telemetry`, `rtk gain`, `rtk discover`, `rtk learn`, `rtk session`, `rtk hook-audit`, or `rtk cc-economics`
- Public GitHub Actions workflow calls to external AI, webhook, reporting, or telemetry endpoints
- Remote badge, image, or documentation beacons in user-facing docs
- First-run persistence from read-only commands such as `rtk config`

This position is only valid for source revisions that pass the enterprise verification gate.

## Boundary Of The Claim

The no-telemetry claim applies to RTK-owned code paths and repository-controlled automation. This public source tree intentionally has no `.github/` workflow tree.

It does not claim that all child commands are offline. RTK executes commands requested by the user. The following examples may legitimately access the network because the user invoked those tools:

- `rtk git fetch`
- `rtk gh pr view`
- `rtk curl`
- `rtk aws`
- `rtk npm install`
- `rtk cargo build` when dependencies are not already cached

Enterprise policy should evaluate direct RTK egress separately from child-process egress.

## Required Evidence

For every reviewed release, retain:

- Clean `scripts/enterprise-audit.sh` output
- Clean `cargo audit --deny warnings` output
- Clean `cargo deny check advisories bans sources` output
- Clean `semgrep scan --config .semgrep.yml --error` output
- Clean `gitleaks dir . --redact --no-banner` output
- Dependency tree from `cargo tree --locked`
- Build metadata from `scripts/release-evidence.sh`
- Release binary SHA-256 hash
- SBOM and signature or attestation material where available

Evidence should be stored in the enterprise evidence system, not committed to the public repository.

## Reviewer Acceptance Criteria

A reviewer can accept the no-telemetry position for a specific release only when:

- The commit under review is pinned and recorded.
- The source tree is fresh-history or imported without upstream history that contains removed code.
- All enterprise audit gates pass from a clean checkout.
- The release artifact hash matches the reviewed build output.
- Endpoint controls prevent direct RTK process network egress.
- Child process egress is governed by existing enterprise allowlists.

## Non-Acceptable Claims

Do not describe this software as:

- Zero risk
- Government approved
- Certified compliant without an actual certification
- Guaranteed to prevent all data loss
- A replacement for endpoint, proxy, DLP, SCA, SAST, or independent security review

The accurate claim is: no known RTK-owned telemetry or usage-tracking mechanism remains in the reviewed source tree when the documented audit gates pass.
