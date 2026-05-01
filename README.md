# RTK Enterprise

<p align="center">
  <strong>Enterprise-sanitized CLI proxy that reduces LLM token consumption by 60-90%</strong>
</p>

<p align="center">
  <a href="#installation">Install</a> &bull;
  <a href="#enterprise-security-posture">Enterprise Security</a> &bull;
  <a href="docs/enterprise/README.md">Audit Docs</a> &bull;
  <a href="#commands">Commands</a> &bull;
  <a href="docs/enterprise/ROLL_OUT_SECURITY_REVIEW.md">Rollout Review</a> &bull;
  <a href="SECURITY.md">Security</a>
</p>

---

RTK filters and compresses command outputs before they reach your LLM context. It is a single Rust binary with 100+ supported command filters and normally adds less than 10ms of overhead.

This enterprise fork keeps the useful command-filtering behavior while removing the data-collection and reporting surfaces that are inappropriate for regulated deployment:

- No outbound product reporting from RTK itself
- No local usage-history database
- No raw-output persistence by default
- No external AI or release-notification calls in CI/CD
- No HTTP client, socket, reporting vendor, or SQLite usage-database crates
- Release support for SBOMs, checksums, cosign signatures, and GitHub build attestations
- Local audit gates for SCA, SAST, current-tree secret scanning, removed command surfaces, and first-run persistence

RTK is still a command proxy. Commands you explicitly run through it, such as `rtk curl`, `rtk aws`, `rtk gh`, or package managers, can access the network because those child tools are user-invoked. Enterprise endpoint policy should block RTK itself from initiating direct outbound connections and govern child tools separately.

## Token Savings (30-min Claude Code Session)

| Operation | Frequency | Standard | rtk | Savings |
|-----------|-----------|----------|-----|---------|
| `ls` / `tree` | 10x | 2,000 | 400 | -80% |
| `cat` / `read` | 20x | 40,000 | 12,000 | -70% |
| `grep` / `rg` | 8x | 16,000 | 3,200 | -80% |
| `git status` | 10x | 3,000 | 600 | -80% |
| `git diff` | 5x | 10,000 | 2,500 | -75% |
| `git log` | 5x | 2,500 | 500 | -80% |
| `git add/commit/push` | 8x | 1,600 | 120 | -92% |
| `cargo test` / `npm test` | 5x | 25,000 | 2,500 | -90% |
| `ruff check` | 3x | 3,000 | 600 | -80% |
| `pytest` | 4x | 8,000 | 800 | -90% |
| `go test` | 3x | 6,000 | 600 | -90% |
| `docker ps` | 3x | 900 | 180 | -80% |
| **Total** | | **~118,000** | **~23,900** | **-80%** |

> Estimates based on medium-sized TypeScript/Rust projects. Actual savings vary by project size.

## Installation

For regulated environments, prefer a reviewed-source build or a signed internal package. Avoid `curl | sh` installers and unaudited public package feeds because they bypass normal source review, binary provenance checks, and endpoint allowlisting.

### Reviewed Source Build (Recommended)

```bash
git clone https://github.com/bmjcoding/rtk-enterprise.git
cd rtk-enterprise

# Run the local enterprise gate before accepting the source tree.
scripts/enterprise-audit.sh

# Build exactly from the reviewed lockfile.
cargo build --locked --release

# Install to a controlled location on your PATH.
install -m 0755 target/release/rtk "$HOME/.local/bin/rtk"
```

Why this path is preferred:

- The lockfile fixes the Rust dependency graph reviewed by security.
- The audit script checks formatting, buildability, dependency policy, SAST, current-tree secrets, removed command surfaces, and first-run persistence.
- The binary hash can be recorded before internal distribution.
- The source tree can be imported into an internal mirror without upstream Git history.

### Internal Package Distribution

For broad employee rollout, build once in your controlled CI environment and distribute through an internal package channel:

```bash
scripts/enterprise-audit.sh
cargo test --locked --all
cargo build --locked --release
scripts/release-evidence.sh
```

Require the package owner to publish:

- SHA-256 checksums
- SPDX SBOM
- cosign signatures and certificates
- build provenance attestations
- the `enterprise-evidence/` bundle generated for that release

### Cargo From This Repository

For developer evaluation only:

```bash
cargo install --git https://github.com/bmjcoding/rtk-enterprise rtk --locked
```

This is convenient, but it still pulls from the network at install time. For production rollout, use the reviewed-source or internal-package path above.

### Homebrew and Public Feeds

Do not use public Homebrew taps, crates.io packages, or installer scripts for regulated deployment unless your organization has mirrored, reviewed, pinned, and signed the package internally.

### Verify Installation

```bash
rtk --version   # Should show "rtk 0.38.0"
rtk --help      # Should show available commands
```

> **Name collision warning**: Another project named `rtk` exists on crates.io. Use this repository or an internal mirror of it when installing RTK Enterprise.

## Enterprise Security Posture

This fork is designed to be reviewable by enterprise security teams rather than trusted by assertion. The primary controls are:

- `scripts/enterprise-audit.sh` - local gate for source, dependency, SAST, secret-scan, runtime command-surface, and persistence checks
- `scripts/verify-egress-guard.sh` - negative self-test proving the build guard fails closed for direct socket source and forbidden lockfile dependencies
- `build.rs` - build-time direct-egress guard that fails compilation if RTK-owned runtime source adds socket/HTTP/database APIs or banned network/database crates
- `deny.toml` - dependency policy blocking network/client/database/reporting crates and unknown sources
- `.semgrep.yml` - custom SAST rules for direct network egress, local usage databases, removed commands, and CI/CD exfiltration paths
- `.github/workflows/ci.yml` - CI enforcement for tests, SCA, dependency policy, SAST, and enterprise audit
- `.github/workflows/release.yml` - explicit/manual release flow with enterprise gate, SBOM, checksums, cosign signatures, and GitHub attestations for release assets
- `docs/enterprise/README.md` - index of public enterprise audit documentation
- `docs/enterprise/AUDIT_SUMMARY.md` - hardening summary, review scope, added controls, and residual risk
- `docs/enterprise/NO_TELEMETRY_POSITION.md` - formal boundary for the no data-collection claim
- `docs/enterprise/VERIFICATION_RUNBOOK.md` - reproducible source, test, build, evidence, and endpoint validation workflow
- `docs/enterprise/NETWORK_EGRESS_POLICY.md` - recommended deny-by-default RTK process egress policy
- `docs/enterprise/EVIDENCE_HANDLING.md` - guidance for retaining generated evidence internally without publishing sensitive operational details
- `docs/enterprise/ROLL_OUT_SECURITY_REVIEW.md` - handoff checklist for independent review and endpoint policy

Fresh-history source intake matters. Do not distribute a clone that includes the original upstream `.git` graph, because historical commits contain code that this fork intentionally removed. Import this sanitized tree into a fresh internal repository or distribute signed release/source archives.

## Quick Start

```bash
# 1. Install for your AI tool
rtk init -g                     # Claude Code / Copilot (default)
rtk init -g --gemini            # Gemini CLI
rtk init -g --codex             # Codex (OpenAI)
rtk init -g --agent cursor      # Cursor
rtk init --agent windsurf       # Windsurf
rtk init --agent cline          # Cline / Roo Code
rtk init --agent kilocode       # Kilo Code
rtk init --agent antigravity    # Google Antigravity

# 2. Restart your AI tool, then test
git status  # Automatically rewritten to rtk git status
```

The hook transparently rewrites Bash commands (e.g., `git status` -> `rtk git status`) before execution. Claude never sees the rewrite, it just gets compressed output.

**Important:** the hook only runs on Bash tool calls. Claude Code built-in tools like `Read`, `Grep`, and `Glob` do not pass through the Bash hook, so they are not auto-rewritten. To get RTK's compact output for those workflows, use shell commands (`cat`/`head`/`tail`, `rg`/`grep`, `find`) or call `rtk read`, `rtk grep`, or `rtk find` directly.

## How It Works

```
  Without rtk:                                    With rtk:

  Claude  --git status-->  shell  -->  git         Claude  --git status-->  RTK  -->  git
    ^                                   |            ^                      |          |
    |        ~2,000 tokens (raw)        |            |   ~200 tokens        | filter   |
    +-----------------------------------+            +------- (filtered) ---+----------+
```

Four strategies applied per command type:

1. **Smart Filtering** - Removes noise (comments, whitespace, boilerplate)
2. **Grouping** - Aggregates similar items (files by directory, errors by type)
3. **Truncation** - Keeps relevant context, cuts redundancy
4. **Deduplication** - Collapses repeated log lines with counts

## Commands

### Files
```bash
rtk ls .                        # Token-optimized directory tree
rtk read file.rs                # Smart file reading
rtk read file.rs -l aggressive  # Signatures only (strips bodies)
rtk smart file.rs               # 2-line heuristic code summary
rtk find "*.rs" .               # Compact find results
rtk grep "pattern" .            # Grouped search results
rtk diff file1 file2            # Condensed diff
```

### Git
```bash
rtk git status                  # Compact status
rtk git log -n 10               # One-line commits
rtk git diff                    # Condensed diff
rtk git add                     # -> "ok"
rtk git commit -m "msg"         # -> "ok abc1234"
rtk git push                    # -> "ok main"
rtk git pull                    # -> "ok 3 files +10 -2"
```

### GitHub CLI
```bash
rtk gh pr list                  # Compact PR listing
rtk gh pr view 42               # PR details + checks
rtk gh issue list               # Compact issue listing
rtk gh run list                 # Workflow run status
```

### Test Runners
```bash
rtk jest                        # Jest compact (failures only)
rtk vitest                      # Vitest compact (failures only)
rtk playwright test             # E2E results (failures only)
rtk pytest                      # Python tests (-90%)
rtk go test                     # Go tests (NDJSON, -90%)
rtk cargo test                  # Cargo tests (-90%)
rtk rake test                   # Ruby minitest (-90%)
rtk rspec                       # RSpec tests (JSON, -60%+)
rtk err <cmd>                   # Filter errors only from any command
rtk test <cmd>                  # Generic test wrapper - failures only (-90%)
```

### Build & Lint
```bash
rtk lint                        # ESLint grouped by rule/file
rtk lint biome                  # Supports other linters
rtk tsc                         # TypeScript errors grouped by file
rtk next build                  # Next.js build compact
rtk prettier --check .          # Files needing formatting
rtk cargo build                 # Cargo build (-80%)
rtk cargo clippy                # Cargo clippy (-80%)
rtk ruff check                  # Python linting (JSON, -80%)
rtk golangci-lint run           # Go linting (JSON, -85%)
rtk rubocop                     # Ruby linting (JSON, -60%+)
```

### Package Managers
```bash
rtk pnpm list                   # Compact dependency tree
rtk pip list                    # Python packages (auto-detect uv)
rtk pip outdated                # Outdated packages
rtk bundle install              # Ruby gems (strip Using lines)
rtk prisma generate             # Schema generation (no ASCII art)
```

### AWS
```bash
rtk aws sts get-caller-identity # One-line identity
rtk aws ec2 describe-instances  # Compact instance list
rtk aws lambda list-functions   # Name/runtime/memory (strips secrets)
rtk aws logs get-log-events     # Timestamped messages only
rtk aws cloudformation describe-stack-events  # Failures first
rtk aws dynamodb scan           # Unwraps type annotations
rtk aws iam list-roles          # Strips policy documents
rtk aws s3 ls                   # Truncated compact listing
```

### Containers
```bash
rtk docker ps                   # Compact container list
rtk docker images               # Compact image list
rtk docker logs <container>     # Deduplicated logs
rtk docker compose ps           # Compose services
rtk kubectl pods                # Compact pod list
rtk kubectl logs <pod>          # Deduplicated logs
rtk kubectl services            # Compact service list
```

### Data Tools
```bash
rtk json config.json            # Structure without values
rtk deps                        # Dependencies summary
rtk env -f AWS                  # Filtered env vars
rtk log app.log                 # Deduplicated logs
rtk curl <url>                  # Compact HTTP responses
rtk wget <url>                  # Download, strip progress bars
rtk summary <long command>      # Heuristic summary
rtk proxy <command>             # Raw passthrough
```

## Global Flags

```bash
-u, --ultra-compact    # ASCII icons, inline format (extra token savings)
-v, --verbose          # Increase verbosity (-v, -vv, -vvv)
```

## Examples

**Directory listing:**
```
# ls -la (45 lines, ~800 tokens)        # rtk ls (12 lines, ~150 tokens)
drwxr-xr-x  15 user staff 480 ...       my-project/
-rw-r--r--   1 user staff 1234 ...       +-- src/ (8 files)
...                                      |   +-- main.rs
                                         +-- Cargo.toml
```

**Git operations:**
```
# git push (15 lines, ~200 tokens)       # rtk git push (1 line, ~10 tokens)
Enumerating objects: 5, done.             ok main
Counting objects: 100% (5/5), done.
Delta compression using up to 8 threads
...
```

**Test output:**
```
# cargo test (200+ lines on failure)     # rtk test cargo test (~20 lines)
running 15 tests                          FAILED: 2/15 tests
test utils::test_parse ... ok               test_edge_case: assertion failed
test utils::test_format ... ok              test_overflow: panic at utils.rs:18
...
```

## Auto-Rewrite Hook

The most effective way to use rtk. The hook transparently intercepts Bash commands and rewrites them to rtk equivalents before execution.

**Result**: 100% rtk adoption across all conversations and subagents, zero token overhead.

**Scope note:** this only applies to Bash tool calls. Claude Code built-in tools such as `Read`, `Grep`, and `Glob` bypass the hook, so use shell commands or explicit `rtk` commands when you want RTK filtering there.

### Setup

```bash
rtk init -g                 # Install hook + RTK.md (recommended)
rtk init -g --opencode      # OpenCode plugin (instead of Claude Code)
rtk init -g --auto-patch    # Non-interactive (CI/CD)
rtk init -g --hook-only     # Hook only, no RTK.md
rtk init --show             # Verify installation
```

After install, **restart Claude Code**.

## Windows

RTK works on Windows with some limitations. The auto-rewrite hook (`rtk-rewrite.sh`) requires a Unix shell, so on native Windows RTK falls back to **CLAUDE.md injection mode** — your AI assistant receives RTK instructions but commands are not rewritten automatically.

### Recommended: WSL (full support)

For the best experience, use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) (Windows Subsystem for Linux). Inside WSL, RTK works exactly like Linux — full hook support, auto-rewrite, everything:

```bash
# Inside WSL
git clone https://github.com/bmjcoding/rtk-enterprise.git
cd rtk-enterprise
scripts/enterprise-audit.sh
cargo build --locked --release
install -m 0755 target/release/rtk "$HOME/.local/bin/rtk"
rtk init -g
```

### Native Windows (limited support)

On native Windows (cmd.exe / PowerShell), RTK filters work but the hook does not auto-rewrite commands:

```powershell
# 1. Download a signed Windows release from your approved internal package channel
# 2. Add rtk.exe to your PATH
# 3. Initialize (falls back to CLAUDE.md injection)
rtk init -g
# 4. Use rtk explicitly
rtk cargo test
rtk git status
```

**Important**: Do not double-click `rtk.exe` — it is a CLI tool that prints usage and exits immediately. Always run it from a terminal (Command Prompt, PowerShell, or Windows Terminal).

| Feature | WSL | Native Windows |
|---------|-----|----------------|
| Filters (cargo, git, etc.) | Full | Full |
| Auto-rewrite hook | Yes | No (CLAUDE.md fallback) |
| `rtk init -g` | Hook mode | CLAUDE.md mode |

## Supported AI Tools

RTK supports 12 AI coding tools. Each integration transparently rewrites shell commands to `rtk` equivalents for 60-90% token savings.

| Tool | Install | Method |
|------|---------|--------|
| **Claude Code** | `rtk init -g` | PreToolUse hook (bash) |
| **GitHub Copilot (VS Code)** | `rtk init -g --copilot` | PreToolUse hook — transparent rewrite |
| **GitHub Copilot CLI** | `rtk init -g --copilot` | PreToolUse deny-with-suggestion (CLI limitation) |
| **Cursor** | `rtk init -g --agent cursor` | preToolUse hook (hooks.json) |
| **Gemini CLI** | `rtk init -g --gemini` | BeforeTool hook |
| **Codex** | `rtk init -g --codex` | AGENTS.md + RTK.md instructions |
| **Windsurf** | `rtk init --agent windsurf` | .windsurfrules (project-scoped) |
| **Cline / Roo Code** | `rtk init --agent cline` | .clinerules (project-scoped) |
| **OpenCode** | `rtk init -g --opencode` | Plugin TS (tool.execute.before) |
| **OpenClaw** | `openclaw plugins install ./openclaw` | Plugin TS (before_tool_call) |
| **Kilo Code** | `rtk init --agent kilocode` | .kilocode/rules/rtk-rules.md (project-scoped) |
| **Google Antigravity** | `rtk init --agent antigravity` | .agents/rules/antigravity-rtk-rules.md (project-scoped) |

For per-agent setup details, override controls, and graceful degradation, see the [Supported Agents guide](docs/guide/getting-started/supported-agents.md).

## Configuration

`~/.config/rtk/config.toml` (macOS: `~/Library/Application Support/rtk/config.toml`):

```toml
[hooks]
exclude_commands = ["curl", "playwright"]  # skip rewrite for these

[tee]
enabled = false         # raw output persistence is disabled in this build
mode = "never"
```

For the full config reference (all sections, env vars, per-project filters), see the [Configuration guide](docs/guide/getting-started/configuration.md).

### Uninstall

```bash
rtk init -g --uninstall     # Remove hook, RTK.md, settings.json entry
cargo uninstall rtk          # Remove binary
```

## Documentation

- **[docs/enterprise/ROLL_OUT_SECURITY_REVIEW.md](docs/enterprise/ROLL_OUT_SECURITY_REVIEW.md)** - enterprise rollout review checklist
- **[INSTALL.md](INSTALL.md)** - security-conscious installation reference
- **[docs/contributing/ARCHITECTURE.md](docs/contributing/ARCHITECTURE.md)** - system design and technical decisions
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - contribution guide
- **[SECURITY.md](SECURITY.md)** - security policy

## Privacy

This enterprise build does not collect or report data.

## Core team

- **Patrick Szymkowiak** — Founder
  [GitHub](https://github.com/pszymkowiak) · [LinkedIn](https://www.linkedin.com/in/patrick-szymkowiak/)
- **Florian Bruniaux** — Core contributor
  [GitHub](https://github.com/FlorianBruniaux) · [LinkedIn](https://www.linkedin.com/in/florian-bruniaux-43408b83/)
- **Adrien Eppling** — Core contributor
  [GitHub](https://github.com/aeppling) · [LinkedIn](https://www.linkedin.com/in/adrien-eppling/)

## Contributing

Contributions should preserve the enterprise security posture. Run `scripts/enterprise-audit.sh` before opening a PR.


## License

MIT License - see [LICENSE](LICENSE) for details.

## Disclaimer

See [DISCLAIMER.md](DISCLAIMER.md).
