---
title: Quick Start
description: Get RTK running in 5 minutes and see your first token savings
sidebar:
  order: 2
---

# Quick Start

This guide walks you through your first RTK commands after installation.

## Prerequisites

RTK is installed and verified:

```bash
rtk --version   # rtk x.y.z
rtk --help      # shows RTK command filters
```

If not, see [Installation](./installation.md).

## Step 1: Initialize for your AI assistant

```bash
# For Claude Code (global — applies to all projects)
rtk init --global

# For a single project only
cd /your/project && rtk init
```

This installs the hook that automatically rewrites commands. Restart your AI assistant after this step.

## Step 2: Use your tools normally

Once the hook is installed, nothing changes in how you work. Your AI assistant runs commands as usual — the hook intercepts them transparently and rewrites them before execution.

For example, when Claude Code runs `cargo test`, the hook rewrites it to `rtk cargo test` before it executes. The LLM receives filtered output with only the failures — not 500 lines of passing tests. You never see or type `rtk`.

RTK covers all major ecosystems — Git, Cargo/Rust, JavaScript, Python, Go, Ruby, .NET, Docker/Kubernetes, and more. See [What RTK Optimizes](../resources/what-rtk-covers.md) for the full list.

## Step 3: Run a direct RTK command

You can call RTK wrappers directly when you want compact output without relying on hooks:

```bash
rtk git status
rtk cargo test
```

## Step 4: Unsupported commands

Commands RTK doesn't recognize run through passthrough — output is unchanged:

```bash
rtk proxy make install
```

## Next steps

- [What RTK Optimizes](../resources/what-rtk-covers.md) — all supported commands and savings by ecosystem
- [Supported agents](./supported-agents.md) — Claude Code, Cursor, Copilot, and more
- [Configuration](./configuration.md) — customize RTK behavior
