#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

failures=0

section() {
  printf '\n==> %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

pass() {
  printf 'PASS: %s\n' "$1"
}

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "missing required tool: $1"
    return 1
  fi
  pass "found $1"
}

run_no_match() {
  local label="$1"
  shift
  local output
  set +e
  output="$("$@" 2>&1)"
  local code=$?
  set -e
  if [ "$code" -eq 0 ] && [ -n "$output" ]; then
    printf '%s\n' "$output" >&2
    fail "$label"
  elif [ "$code" -eq 1 ]; then
    pass "$label"
  elif [ "$code" -eq 0 ]; then
    pass "$label"
  else
    printf '%s\n' "$output" >&2
    fail "$label scan command failed"
  fi
}

section "Tooling"
require_tool rg
require_tool cargo
require_tool git
require_tool tar

section "Formatting and build"
cargo fmt --check || fail "cargo fmt --check"
cargo check --locked --all-targets || fail "cargo check --locked --all-targets"

section "Preventative guard self-test"
scripts/verify-egress-guard.sh || fail "direct egress build guard self-test"

section "Enterprise telemetry and tracking denylist"
run_no_match "no telemetry/tracking/vendor analytics references outside license text" \
  bash -c 'rg -n --hidden --glob "!target/**" --glob "!enterprise-evidence/**" --glob "!.git/**" --glob "!deny.toml" --glob "!.semgrep.yml" --glob "!scripts/enterprise-audit.sh" --glob "!docs/enterprise/**" --glob "!SECURITY.md" --glob "!CHANGELOG.md" -i "\b(telemetry|tracking|analytics|posthog|sentry|amplitude|mixpanel|segment\.io|datadog|honeycomb|opentelemetry|newrelic|statsd|prometheus|logrocket|fullstory|hotjar|plausible|matomo|rudderstack|snowplow)\b" | grep -v "^LICENSE:"'

run_no_match "removed command surfaces remain absent" \
  rg -n --hidden --glob '!target/**' --glob '!enterprise-evidence/**' --glob '!.git/**' --glob '!deny.toml' --glob '!.semgrep.yml' --glob '!scripts/enterprise-audit.sh' --glob '!docs/enterprise/**' --glob '!SECURITY.md' --glob '!CHANGELOG.md' 'rtk (gain|discover|learn|session|telemetry|hook-audit|cc-economics)\b|src/(analytics|learn)/|core/(tracking|telemetry)\.rs|tracking\.db|history\.db|usage\.db|analytics\.db|RTK_TELEMETRY|TELEMETRY_URL|RTK_TEE|maybe_ping|Telemetry|tracking::|telemetry::|record_hook_event'

run_no_match "no direct HTTP/network/database crates or APIs in runtime sources" \
  rg -n --hidden --glob '!target/**' --glob '!enterprise-evidence/**' --glob '!.git/**' --glob '!deny.toml' --glob '!.semgrep.yml' --glob '!scripts/enterprise-audit.sh' -i '\b(ureq|reqwest|hyper|isahc|surf|TcpStream|UdpSocket|TcpListener|ToSocketAddrs|webhook|send_string|send_json|client\.get|client\.post|Connection::open|rusqlite|libsqlite3|sqlite)\b' src Cargo.toml Cargo.lock

run_no_match "no remote badge/image beacons in docs" \
  rg -n '<img src="https://|img\.shields\.io|discord\.gg|avatars\.githubusercontent\.com|workflows/.*/badge|badge\.svg' README* docs hooks --hidden --glob '!target/**' --glob '!enterprise-evidence/**'

run_no_match "no external AI/webhook/reporting automation hooks" \
  rg -n --hidden --glob '!target/**' --glob '!enterprise-evidence/**' --glob '!.git/**' --glob '!scripts/enterprise-audit.sh' --glob '!docs/enterprise/**' -i 'ANTHROPIC|DISCORD|WEBHOOK|RTK_TELEMETRY|TELEMETRY_URL|api\.anthropic\.com' scripts docs src hooks

section "Public GitHub automation"
if [ -d .github ]; then
  fail ".github directory is present"
else
  pass ".github directory is absent"
fi

run_no_match "no public GitHub workflow references" \
  rg -n --hidden --glob '!target/**' --glob '!enterprise-evidence/**' --glob '!.git/**' --glob '!scripts/enterprise-audit.sh' '\.github/workflows|pull_request_target|create-github-app-token|APP_CLIENT_ID|APP_PRIVATE_KEY' README* docs scripts

section "Dependency denylist"
if cargo tree --locked | rg -i '\b(ureq|reqwest|hyper|h2|http-body|socket|tls|openssl|native-tls|rustls|webpki|sentry|opentelemetry|posthog|amplitude|mixpanel|rusqlite|sqlite|libsqlite3)\b'; then
  fail "forbidden dependency present in cargo tree"
else
  pass "cargo tree has no forbidden egress/database dependencies"
fi

if command -v cargo-deny >/dev/null 2>&1; then
  cargo deny check advisories bans sources || fail "cargo deny advisories/bans/sources"
else
  fail "cargo-deny not installed"
fi

if command -v cargo-audit >/dev/null 2>&1; then
  cargo audit --deny warnings || fail "cargo audit --deny warnings"
else
  fail "cargo-audit not installed"
fi

section "Secret scan"
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks dir . --redact --no-banner || fail "gitleaks dir"
else
  fail "gitleaks not installed"
fi

section "SAST"
if command -v semgrep >/dev/null 2>&1; then
  semgrep scan --config .semgrep.yml --error || fail "semgrep scan"
else
  fail "semgrep not installed"
fi

section "Runtime command surface"
if [ ! -x target/debug/rtk ]; then
  cargo build --locked || fail "cargo build --locked"
fi

if target/debug/rtk --help | rg -n 'telemetry|gain|cc-economics|session|discover|learn|hook-audit|tracking|analytics'; then
  fail "removed commands appear in help"
else
  pass "removed commands absent from help"
fi

for cmd in telemetry gain cc-economics session discover learn hook-audit; do
  set +e
  output="$(target/debug/rtk "$cmd" 2>&1 >/dev/null)"
  code=$?
  set -e
  if [ "$code" -eq 2 ] && printf '%s' "$output" | rg -q 'unrecognized subcommand'; then
    pass "removed command rejected: $cmd"
  else
    printf '%s\n' "$output" >&2
    fail "removed command was not rejected: $cmd"
  fi
done

section "No first-run persistence for read-only config"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" XDG_DATA_HOME="$tmp/data" target/debug/rtk config >/tmp/rtk-config-audit.out 2>&1 || fail "rtk config fresh-home smoke"
if find "$tmp" -type f | rg .; then
  fail "rtk config created files in fresh HOME"
else
  pass "rtk config created no files in fresh HOME"
fi

section "Final verdict"
if [ "$failures" -ne 0 ]; then
  printf 'Enterprise audit failed with %s finding(s).\n' "$failures" >&2
  exit 1
fi

printf 'Enterprise audit passed.\n'
