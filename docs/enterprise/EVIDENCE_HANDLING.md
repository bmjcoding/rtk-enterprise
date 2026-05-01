# Evidence Handling

This document describes how to generate, store, and review RTK Enterprise audit evidence without exposing unnecessary operational detail in the public repository.

## Public Repository Contents

The public repository should contain:

- Source code
- Review process documentation
- Audit scripts
- Dependency policy
- SAST rules
- Documentation that public GitHub Actions and repository-local build/release automation are intentionally absent

The public repository should not contain generated enterprise evidence bundles.

## Why Evidence Is Not Committed Publicly

Generated evidence can include:

- Local usernames and paths
- Tool versions and operating system details
- Build timestamps
- Internal branch names
- Dependency inventory at a specific point in time
- Scanner output that may include environment details
- Package or binary hashes tied to internal distribution systems

These records are valuable for auditability but should usually live in an internal artifact repository, GRC system, or release record.

## Generate Evidence

From a clean reviewed checkout:

```bash
scripts/enterprise-audit.sh
cargo test --locked --all
cargo build --locked --release
scripts/release-evidence.sh
scripts/verify-repo-controls.sh bmjcoding/rtk-enterprise main | tee enterprise-evidence/repository-controls.txt
```

The default output directory is:

```text
enterprise-evidence/
```

Use a release-specific directory when generating multiple packages:

```bash
scripts/release-evidence.sh enterprise-evidence/rtk-enterprise-$(git rev-parse --short HEAD)
```

## Archive Evidence Internally

Store the generated bundle with:

- Source commit SHA
- Internal mirror commit SHA if different
- Source-control hashes for audit and release-control inputs
- Release package name and version
- Binary or package hash
- SBOM
- Signature and attestation verification output
- Hosted repository control verification output, or equivalent internal mirror control evidence
- Reviewer approvals
- Any exceptions and compensating controls

Evidence should be immutable after approval. If evidence must be regenerated, record why and link it to the same source commit or to the new commit under review.

## Redaction Guidance

Before sharing evidence outside the review group:

- Remove local home directory paths when unnecessary.
- Remove internal hostnames when unnecessary.
- Remove internal package repository URLs when unnecessary.
- Preserve hashes, commit SHAs, tool versions, and pass/fail status.
- Preserve enough detail for an independent reviewer to reproduce the conclusion.

Do not redact findings that affect the security decision.

## Retention Guidance

Retain evidence for at least the longer of:

- The enterprise software retention requirement
- The regulatory retention requirement
- The support lifetime of the deployed RTK package

Evidence for emergency fixes should be retained with the same rigor as standard releases.
