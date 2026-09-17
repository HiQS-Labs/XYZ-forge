#!/usr/bin/env bash
# Test: pdda.sh changelog accepts both bare-date and semver-prefixed headings, and always uses the
# topmost matching heading as the newest entry.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
PDDA="$REPO_ROOT/utils/pdda/pdda.sh"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'ok   - %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL - %s\n' "$1"; }

assert_contains() { case "$1" in *"$2"*) pass "$3" ;; *) fail "$3 (missing: $2)"; printf -- '----\n%s\n----\n' "$1" ;; esac; }
assert_absent()   { case "$1" in *"$2"*) fail "$3 (unexpected: $2)"; printf -- '----\n%s\n----\n' "$1" ;; *) pass "$3" ;; esac; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/pdda-changelog.XXXXXX")"
[ -n "$WORK" ] && [ -d "$WORK" ] || exit 1
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
SBOX=""
cleanup() { if [ -n "$SBOX" ] && [ -d "$SBOX" ]; then require_fixture "$SBOX"; rm -rf "$SBOX"; fi; }
trap 'cleanup; rm -rf "$WORK"' EXIT

new_sandbox() {
  cleanup
  SBOX="$(mktemp -d "$WORK/case.XXXXXX")"
  [ -n "$SBOX" ] && [ -d "$SBOX" ] || exit 1
  require_fixture "$SBOX" "changelog sandbox"
  (
    cd "$SBOX" || exit 1
    git init -q
    git config user.name "PDDA Test"
    git config user.email "pdda@example.com"
    printf 'seed\n' > README.md
    git add README.md
    GIT_AUTHOR_DATE="2026-06-30T12:00:00Z" \
    GIT_COMMITTER_DATE="2026-06-30T12:00:00Z" \
      git commit -q -m "seed"
  ) || exit 1
}

run_check() {
  PDDA_REPO_ROOT="$SBOX" \
  PDDA_CHANGELOG="$SBOX/CHANGELOG.md" \
  PDDA_MODE=observe \
  PDDA_FORMAT=text \
  bash "$PDDA" changelog 2>&1
}

new_sandbox
cat > "$SBOX/CHANGELOG.md" <<'EOF'
# Changelog

## [1.2.3] - 2026-06-30

- semver heading only
EOF
out="$(run_check)"
assert_contains "$out" "errors=0 warns=0 info=0" "semver-only heading is accepted"
assert_absent "$out" "predates the latest commit" "semver-only heading stays fresh"

new_sandbox
cat > "$SBOX/CHANGELOG.md" <<'EOF'
# Changelog

## 2026-06-30

- bare-date heading only
EOF
out="$(run_check)"
assert_contains "$out" "errors=0 warns=0 info=0" "bare-date heading remains accepted"
assert_absent "$out" "predates the latest commit" "bare-date heading stays fresh"

new_sandbox
cat > "$SBOX/CHANGELOG.md" <<'EOF'
# Changelog

## [0.49.1] - 2026-06-30

- newest semver entry

## 2026-03-28

- legacy bare-date entry below
EOF
out="$(run_check)"
assert_contains "$out" "errors=0 warns=0 info=0" "mixed headings use the top semver entry"
assert_absent "$out" "2026-03-28" "mixed headings do not fall through to a lower legacy date"
assert_absent "$out" "predates the latest commit" "mixed headings do not false-flag stale freshness"

new_sandbox
cat > "$SBOX/CHANGELOG.md" <<'EOF'
# Changelog

## 1.4.211 - 2026-06-30

- bracketless semver heading (GH-13)
EOF
out="$(run_check)"
assert_contains "$out" "errors=0 warns=0 info=0" "bracketless semver heading is accepted"
assert_absent "$out" "predates the latest commit" "bracketless semver heading stays fresh"
assert_absent "$out" "no dated" "bracketless semver does not trigger missing dated entry warning"

new_sandbox
cat > "$SBOX/CHANGELOG.md" <<'EOF'
# Changelog

## 1.3.5.58 - 2026-06-30

- bracketless quad-version heading

## 2026-03-28

- older bare-date entry
EOF
out="$(run_check)"
assert_contains "$out" "errors=0 warns=0 info=0" "bracketless quad-version heading is accepted"
assert_absent "$out" "2026-03-28" "bracketless quad-version does not fall through to legacy date"
assert_absent "$out" "predates the latest commit" "bracketless quad-version stays fresh"

new_sandbox
cat > "$SBOX/CHANGELOG.md" <<'EOF'
# Changelog

## [1.2.3 - 2026-06-30

- unbalanced opening bracket
EOF
out="$(run_check)"
assert_contains "$out" "no dated" "unbalanced opening bracket is rejected"

new_sandbox
cat > "$SBOX/CHANGELOG.md" <<'EOF'
# Changelog

## 1.2.3] - 2026-06-30

- unbalanced closing bracket
EOF
out="$(run_check)"
assert_contains "$out" "no dated" "unbalanced closing bracket is rejected"

new_sandbox
cat > "$SBOX/CHANGELOG.md" <<'EOF'
# Changelog

## 2025-01-01 - 2026-06-30

- date-like prefix before terminal date
EOF
out="$(run_check)"
assert_contains "$out" "errors=0 warns=0 info=0" "date prefix extracts terminal date"
assert_absent "$out" "2025-01-01" "terminal date used, not prefix date"
assert_absent "$out" "predates the latest commit" "date prefix heading stays fresh"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
