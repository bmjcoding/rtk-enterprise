# Enterprise Audit Summary

This document summarizes the enterprise hardening work performed on RTK Enterprise. It is intended to help reviewers orient themselves before running the verification steps in [VERIFICATION_RUNBOOK.md](VERIFICATION_RUNBOOK.md).

This is not a compliance certification, legal opinion, or "zero risk" approval. The defensible claim is narrower: the current source tree is designed to contain no known RTK-owned telemetry, usage reporting, analytics, local usage-history database, crash reporting, update-ping, or workflow exfiltration mechanisms when the enterprise gate passes.

## Source Scope

RTK Enterprise is a fresh-history source tree derived from RTK and hardened for regulated enterprise review.

The review scope is the source tree at the exact commit selected by the enterprise reviewer. For every release or internal package, record:

- Git commit SHA: `git rev-parse HEAD`
- Repository URL or internal mirror path
- Build date and build environment
- Rust toolchain version
- Output of `scripts/enterprise-audit.sh`
- Output bundle from `scripts/release-evidence.sh`

Do not treat this document as approval for future commits unless those commits are reviewed and the verification runbook passes again.

## Removed Or Disabled Surfaces

The enterprise fork removes or disables source surfaces that would be inappropriate for a broad regulated rollout:

- RTK-owned telemetry and analytics modules
- Local usage-history database behavior
- Usage-learning, discovery, economics, session, telemetry, and hook-audit command surfaces
- Raw command-output tee persistence by default
- Release notification or external update-ping behavior
- External AI, webhook, or reporting calls in CI/CD workflows
- Public installer script and public Homebrew formula distribution path
- Dependency paths that introduced HTTP clients, socket clients, TLS client stacks, reporting vendors, or SQLite usage-database crates

RTK remains a command proxy. User-invoked child tools such as `git`, `gh`, `curl`, `aws`, package managers, and language toolchains may access the network because the user explicitly ran those tools through RTK.

## Enterprise Controls Added

The source tree includes controls intended to keep the enterprise posture reviewable:

- [scripts/enterprise-audit.sh](../../scripts/enterprise-audit.sh): local audit gate for formatting, buildability, dependency policy, SAST, current-tree secret scanning, removed command surfaces, and first-run persistence checks
- [scripts/verify-egress-guard.sh](../../scripts/verify-egress-guard.sh): negative self-test proving the direct-egress build guard rejects injected socket source and forbidden lockfile dependencies
- [build.rs](../../build.rs): build-time direct-egress guard that fails compilation if RTK-owned runtime source adds direct socket, HTTP client, or local database APIs, or if banned network/database crates enter the lockfile
- [scripts/release-evidence.sh](../../scripts/release-evidence.sh): evidence bundle generator for metadata, dependency tree, dependency audit output, SAST output, current-tree secret scan output, hashes, and SBOM generation when available
- [deny.toml](../../deny.toml): dependency policy banning network, telemetry, reporting, database, and unknown-source dependency classes
- [.semgrep.yml](../../.semgrep.yml): SAST rules for direct network egress, HTTP client use, local usage databases, removed command surfaces, and workflow exfiltration paths
- [.github/workflows/ci.yml](../../.github/workflows/ci.yml): CI enforcement for build, tests, dependency policy, SAST, current-tree secret scanning, and enterprise audit
- [.github/workflows/release.yml](../../.github/workflows/release.yml): explicit release packaging gated by the enterprise audit and full test suite, with checksums, SBOM support, cosign signing, and provenance attestation support

Write-capable branch-push CD and `pull_request_target` automation are intentionally absent from the enterprise fork. Releases should be explicit, reviewed, and tied to a recorded commit and evidence package.

## Verification Status

An enterprise reviewer should verify the following before approving an internal rollout:

- The selected commit is the intended fresh-history source tree.
- `scripts/enterprise-audit.sh` passes from a clean checkout.
- `cargo test --locked --all` passes.
- `cargo build --locked --release` produces the reviewed binary.
- The release evidence bundle is generated and archived internally.
- Network egress controls deny direct outbound connections by the `rtk` process.
- Child process egress is governed by existing enterprise policy.
- Build provenance, signatures, checksums, and SBOM are stored in the enterprise artifact system.

## Residual Risk

The hardening work does not eliminate every deployment risk. Residual risk remains in:

- User-invoked child tools that intentionally access networks or files
- Hook installation that modifies local agent/tool configuration
- Project-level configuration supplied by users or repositories
- Supply-chain compromise in build tools, dependencies, GitHub Actions, or internal package systems
- Operational misconfiguration of endpoint, firewall, proxy, or EDR policy
- Human approval processes that do not pin evidence to the exact shipped commit

These risks require enterprise controls in addition to source-level review.
