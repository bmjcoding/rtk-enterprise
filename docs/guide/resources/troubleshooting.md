---
title: Troubleshooting
description: Common RTK Enterprise issues and how to fix them
sidebar:
  order: 2
---

# Troubleshooting

## Wrong `rtk` Package Installed

**Symptom:**

```bash
rtk --help
# output does not list RTK command filters such as git, cargo, pytest
```

**Cause:** another package can share the `rtk` binary name.

**Fix:**

```bash
cargo uninstall rtk
git clone https://github.com/bmjcoding/rtk-enterprise.git
cd rtk-enterprise
scripts/enterprise-audit.sh
cargo build --locked --release
install -m 0755 target/release/rtk "$HOME/.local/bin/rtk"
rtk --help
```

## AI Assistant Not Using RTK

1. Verify RTK is installed:

   ```bash
   rtk --version
   rtk --help
   ```

2. Initialize the hook:

   ```bash
   rtk init --global
   rtk init --global --cursor
   rtk init --global --opencode
   ```

3. Restart your AI assistant.

4. Verify hook status:

   ```bash
   rtk init --show
   ```

## RTK Not Found After Build

Make sure the install directory is on `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
rtk --version
```

For Cargo-based evaluation installs, make sure `~/.cargo/bin` is on `PATH`:

```bash
export PATH="$HOME/.cargo/bin:$PATH"
```

## Windows

Native Windows supports explicit RTK commands, but the auto-rewrite shell hook requires a Unix shell. Use WSL for full hook support.

Inside WSL:

```bash
git clone https://github.com/bmjcoding/rtk-enterprise.git
cd rtk-enterprise
scripts/enterprise-audit.sh
cargo build --locked --release
install -m 0755 target/release/rtk "$HOME/.local/bin/rtk"
rtk init -g
```

## Build Issues

Use the pinned lockfile and current stable Rust:

```bash
rustup update stable
rustup default stable
cargo build --locked --release
```

## Diagnostic Script

From the repository root:

```bash
bash scripts/check-installation.sh
```

The script checks binary presence, command surface, version output, and hook initialization.
