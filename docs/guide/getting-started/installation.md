# Installation

RTK Enterprise should be installed from reviewed source or an approved internal package. Avoid remote shell installers and unaudited public package feeds for regulated deployment.

## Reviewed Source Build

```bash
git clone https://github.com/bmjcoding/rtk-enterprise.git
cd rtk-enterprise
scripts/enterprise-audit.sh
cargo build --locked --release
install -m 0755 target/release/rtk "$HOME/.local/bin/rtk"
```

## Internal Distribution

Build once in a controlled internal build system, then publish through your organization's package channel with:

- SHA-256 checksums
- SPDX SBOM
- cosign signatures and certificates
- build provenance attestations
- `scripts/release-evidence.sh` output

## Verify

```bash
rtk --version
rtk --help
scripts/enterprise-audit.sh
```

Continue with [Supported Agents](supported-agents.md) after installation.
