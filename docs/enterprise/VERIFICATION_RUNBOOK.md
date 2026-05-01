# Enterprise Verification Runbook

This runbook gives reviewers a reproducible process for validating an RTK Enterprise source revision before internal packaging or broad deployment.

## Prerequisites

Install the following tools in the review environment:

- Rust toolchain with `cargo` and `rustc`
- `rg`
- `cargo-audit`
- `cargo-deny`
- `gitleaks`
- `semgrep`
- `syft` for SBOM generation
- `cosign` for signature and attestation verification when release artifacts are used

Use a clean checkout and avoid reusing a workspace that contains build artifacts from another review.

## 1. Pin The Reviewed Source

```bash
git status --short
git rev-parse HEAD
git log --show-signature --max-count=5
```

Record the exact commit SHA. If the source was imported into an internal mirror, record both the public source commit and the internal mirror commit.

The review should fail if the working tree is dirty unless the reviewer explicitly records and approves the local diff.

## 2. Run The Enterprise Gate

```bash
scripts/enterprise-audit.sh
```

This gate checks:

- Rust formatting
- Locked buildability
- Build-time direct-egress guard enforcement
- Removed telemetry, tracking, analytics, and usage-history command surfaces
- Absence of direct network, HTTP client, and SQLite usage-database dependencies
- Remote documentation beacon removal
- External AI, webhook, and reporting workflow removal
- Dependency policy
- RustSec advisory status
- Current-tree secret scan
- SAST rules
- Runtime command-surface rejection
- No first-run persistence for read-only config

Any failure requires remediation or a formally documented exception.

## 3. Run Tests

```bash
cargo test --locked --all
```

Record the result in the evidence package. A release should not be accepted when tests fail unless the exception is explicitly approved by the responsible security and engineering owners.

## 4. Build The Reviewed Binary

```bash
cargo build --locked --release
sha256sum target/release/rtk
```

Record the binary hash. The packaged artifact must match this reviewed hash or the package must be rebuilt and re-reviewed.

## 5. Generate Evidence

```bash
scripts/release-evidence.sh
```

The generated `enterprise-evidence/` directory should be archived internally. Do not commit that directory to the public repository.

Expected evidence includes:

- Build metadata and tool versions
- Locked Cargo metadata
- Locked Cargo dependency tree
- RustSec advisory output
- Cargo deny policy output
- Gitleaks current-tree secret scan output
- Semgrep SAST output
- Source-control input hashes
- Release binary hash when available
- SPDX SBOM when `syft` is installed

## 6. Verify Release Artifacts

For internally built packages, verify:

- Package hash matches the reviewed binary or package manifest.
- SBOM identifies the same dependency graph as `cargo metadata --locked`.
- Signature identity matches the approved internal signing identity.
- Provenance identifies the approved repository, commit, workflow, and builder.

For GitHub release artifacts, verify signatures and attestations with the repository identity expected by the enterprise.

## 7. Validate Endpoint Controls

Before broad deployment, validate on a managed endpoint:

- Direct outbound network connections by the `rtk` process are blocked.
- Child-process egress is visible and governed independently.
- EDR alerts if `rtk` opens sockets or loads unexpected network/TLS client libraries.
- The installed binary hash matches the approved package.
- Hook installation modifies only approved agent configuration paths.

## 8. Approval Record

The approval record should include:

- Reviewed source commit
- Reviewer names and approval date
- Tool versions
- Audit outputs
- Test result
- Binary or package hash
- SBOM
- Signature and attestation verification
- Endpoint policy validation result
- Any exceptions and compensating controls

Retain this record in the enterprise GRC or artifact system.
