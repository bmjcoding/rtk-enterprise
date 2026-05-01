# RTK Enterprise Installation

This repository is intended for reviewed-source and internally packaged deployment. For regulated environments, do not install RTK Enterprise by piping a remote script into a shell, and do not rely on public package feeds unless your organization mirrors, reviews, pins, and signs the package internally.

## Recommended Reviewed-Source Install

```bash
git clone https://github.com/bmjcoding/rtk-enterprise.git
cd rtk-enterprise

scripts/enterprise-audit.sh
cargo test --locked --all
cargo build --locked --release

install -m 0755 target/release/rtk "$HOME/.local/bin/rtk"
rtk --version
```

This path is preferred because it uses the reviewed lockfile, runs the enterprise source gate, and gives security teams a deterministic binary to hash before internal distribution.

## Internal Package Rollout

For employee-wide rollout, build once in controlled CI and distribute through an approved internal package channel.

Required release evidence:

- `scripts/enterprise-audit.sh` output
- `cargo test --locked --all` output
- release binary SHA-256
- SPDX SBOM
- cosign signatures and certificates
- build provenance attestations
- `scripts/release-evidence.sh` output bundle

## Developer Evaluation

For short-lived local evaluation only:

```bash
cargo install --git https://github.com/bmjcoding/rtk-enterprise rtk --locked
```

This pulls code at install time. Do not use it as the production rollout path unless your controls explicitly allow it.

## Initialize RTK

```bash
rtk init -g                     # Claude Code / Copilot default
rtk init -g --gemini            # Gemini CLI
rtk init -g --codex             # Codex
rtk init -g --agent cursor      # Cursor
rtk init --agent windsurf       # Windsurf
rtk init --agent cline          # Cline / Roo Code
rtk init --agent kilocode       # Kilo Code
rtk init --agent antigravity    # Google Antigravity
```

Restart the AI coding tool after initialization.

## Verify

```bash
rtk --version
rtk --help
scripts/enterprise-audit.sh
```

## Uninstall

```bash
rtk init -g --uninstall
rm -f "$HOME/.local/bin/rtk"
```

See [README.md](README.md) for usage examples and [docs/enterprise/ROLL_OUT_SECURITY_REVIEW.md](docs/enterprise/ROLL_OUT_SECURITY_REVIEW.md) for the rollout review checklist.
