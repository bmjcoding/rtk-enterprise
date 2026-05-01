#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-bmjcoding/rtk-enterprise}"
BRANCH="${2:-main}"

failures=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

pass() {
  printf 'PASS: %s\n' "$1"
}

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    fail "missing required tool: gh"
    return 1
  fi
  pass "found gh"
}

expect_value() {
  local label="$1"
  local actual="$2"
  local expected="$3"

  if [ "$actual" = "$expected" ]; then
    pass "$label is $expected"
  else
    fail "$label is $actual, expected $expected"
  fi
}

expect_enabled() {
  local label="$1"
  local endpoint="$2"
  local jq_expr="${3:-.enabled}"
  local value

  if ! value="$(gh api "$endpoint" --jq "$jq_expr" 2>/dev/null)"; then
    fail "$label endpoint unavailable"
    return
  fi
  expect_value "$label" "$value" "true"
}

expect_disabled() {
  local label="$1"
  local endpoint="$2"
  local jq_expr="${3:-.enabled}"
  local value

  if ! value="$(gh api "$endpoint" --jq "$jq_expr" 2>/dev/null)"; then
    fail "$label endpoint unavailable"
    return
  fi
  expect_value "$label" "$value" "false"
}

require_gh

default_branch="$(gh api "repos/$REPO" --jq '.default_branch')"
delete_branch_on_merge="$(gh api "repos/$REPO" --jq '.delete_branch_on_merge')"
web_commit_signoff_required="$(gh api "repos/$REPO" --jq '.web_commit_signoff_required')"
secret_scanning="$(gh api "repos/$REPO" --jq '.security_and_analysis.secret_scanning.status')"
push_protection="$(gh api "repos/$REPO" --jq '.security_and_analysis.secret_scanning_push_protection.status')"
dependabot_updates="$(gh api "repos/$REPO" --jq '.security_and_analysis.dependabot_security_updates.status')"

expect_value "default branch" "$default_branch" "$BRANCH"
expect_value "delete branch on merge" "$delete_branch_on_merge" "true"
expect_value "web commit signoff" "$web_commit_signoff_required" "true"
expect_value "secret scanning" "$secret_scanning" "enabled"
expect_value "secret scanning push protection" "$push_protection" "enabled"
expect_value "Dependabot security updates" "$dependabot_updates" "disabled"

protection="repos/$REPO/branches/$BRANCH/protection"
expect_enabled "admin enforcement" "$protection/enforce_admins"
expect_enabled "required linear history" "$protection/required_linear_history"
expect_enabled "required signed commits" "$protection/required_signatures"
expect_enabled "required conversation resolution" "$protection/required_conversation_resolution"
expect_disabled "force pushes" "$protection/allow_force_pushes"
expect_disabled "branch deletions" "$protection/allow_deletions"

required_reviews="repos/$REPO/branches/$BRANCH/protection/required_pull_request_reviews"
require_code_owner_reviews="$(gh api "$required_reviews" --jq '.require_code_owner_reviews')"
dismiss_stale_reviews="$(gh api "$required_reviews" --jq '.dismiss_stale_reviews')"
required_approvals="$(gh api "$required_reviews" --jq '.required_approving_review_count')"

expect_value "CODEOWNERS review" "$require_code_owner_reviews" "true"
expect_value "stale approval dismissal" "$dismiss_stale_reviews" "true"
if [ "$required_approvals" -ge 1 ]; then
  pass "required approvals is $required_approvals"
else
  fail "required approvals is $required_approvals, expected at least 1"
fi

contexts="$(gh api "$protection/required_status_checks" --jq '.contexts[]')"
for required_context in \
  "test presence" \
  "fmt" \
  "clippy" \
  "test (ubuntu-latest)" \
  "test (windows-latest)" \
  "test (macos-latest)" \
  "Security Scan" \
  "semgrep security scan" \
  "enterprise data-egress audit" \
  "benchmark"
do
  if printf '%s\n' "$contexts" | grep -Fxq "$required_context"; then
    pass "required status check present: $required_context"
  else
    fail "missing required status check: $required_context"
  fi
done

if [ "$failures" -ne 0 ]; then
  printf 'Repository controls failed with %s finding(s).\n' "$failures" >&2
  exit 1
fi

printf 'Repository controls passed.\n'
