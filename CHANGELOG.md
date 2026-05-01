# Changelog

All notable changes to this component will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added enterprise data-egress audit script, dependency deny policy, SAST rules, PR checklist, and rollout review package.
- Added release SBOM, checksum, cosign signing, and GitHub attestation workflow steps.

### Removed

- Removed remote reporting, local command-history reporting, and raw-output persistence from the enterprise build.
- Removed stale release history entries that documented data-collection behavior no longer present in this fork.
- Removed workflow-level external AI review and release-notification egress.

[Unreleased]: https://github.com/bmjcoding/rtk-enterprise/compare/v0.38.0...HEAD
