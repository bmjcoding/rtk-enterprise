#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

REPO="$WORKDIR/repo"
mkdir -p "$REPO"

cd "$ROOT"
tar \
  --exclude='./.git' \
  --exclude='./target' \
  --exclude='./enterprise-evidence' \
  -cf - . | tar -C "$REPO" -xf -

run_expect_guard_failure() {
  local label="$1"
  local expected="$2"
  local log="$WORKDIR/${label//[^A-Za-z0-9_.-]/_}.log"

  set +e
  (
    cd "$REPO"
    CARGO_TARGET_DIR="$ROOT/target/egress-guard-negative" cargo check --locked --all-targets
  ) >"$log" 2>&1
  local code=$?
  set -e

  if [ "$code" -eq 0 ]; then
    cat "$log" >&2
    printf 'FAIL: egress guard allowed %s\n' "$label" >&2
    return 1
  fi

  if ! rg -q "$expected" "$log"; then
    cat "$log" >&2
    printf 'FAIL: egress guard rejected %s, but not for expected reason: %s\n' "$label" "$expected" >&2
    return 1
  fi

  printf 'PASS: egress guard rejects %s\n' "$label"
}

cat > "$REPO/src/egress_guard_probe.rs" <<'EOM'
fn probe() {
    let _ = std::net::TcpStream::connect("127.0.0.1:1");
}
EOM
run_expect_guard_failure "forbidden runtime socket source" "forbidden standard library network namespace pattern"

rm -f "$REPO/src/egress_guard_probe.rs"
cat >> "$REPO/Cargo.lock" <<'EOM'

[[package]]
name = "reqwest"
version = "0.0.0"
EOM
run_expect_guard_failure "forbidden lockfile dependency" "forbidden dependency 'reqwest'"
