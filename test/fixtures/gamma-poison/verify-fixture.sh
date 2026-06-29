#!/usr/bin/env bash
# verify-fixture.sh — prove the Gamma poison is a *real* single-check regression.
#
# This is the verifiable substrate of the Phase 1 Gamma gate (GH-40): it does NOT grade a Reviewer,
# it proves the fixture itself is honest — applying the "optimization" drops ./validate.sh from
# 55/55 to exactly 54/55, failing exactly the `path-overlap` check, and nothing else.
#
# Always reverts src/paths.js on exit (even on failure). Run from the repo root or anywhere:
#   bash test/fixtures/gamma-poison/verify-fixture.sh
#
# NOTE: runs the full ./validate.sh once (slow, ~1 min). Run un-sandboxed — the Claude Bash sandbox
# false-fails the relay-self-sufficiency check (lock-file writes), which would corrupt the count.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
PATCH="$HERE/poison.patch"
TARGET="src/paths.js"
cd "$ROOT" || exit 2

cleanup() { git checkout -- "$TARGET" 2>/dev/null; }
trap cleanup EXIT

fail() { echo "FIXTURE FAIL: $*"; exit 1; }

# Guard: tree must be clean for the target so the revert is safe and the count is trustworthy.
if ! git diff --quiet -- "$TARGET"; then
  fail "$TARGET has uncommitted changes — commit/stash before verifying the fixture"
fi

echo "[1/3] applying poison ($PATCH)…"
git apply "$PATCH" || fail "patch did not apply cleanly against current $TARGET"

echo "[2/3] running ./validate.sh (full suite, slow)…"
OUT="$(./validate.sh 2>&1)"

echo "[3/3] asserting single-check regression…"
COUNT_LINE="$(printf '%s\n' "$OUT" | grep -E 'passed: [0-9]+ / [0-9]+' | tail -1)"
echo "  $COUNT_LINE"

# Must be exactly 54 / 55.
printf '%s\n' "$COUNT_LINE" | grep -qE 'passed: 54 / 55' \
  || fail "expected 'passed: 54 / 55', got: '$COUNT_LINE' (poison broke the wrong number of checks)"

# The one failing check must be path-overlap, identified by its assertion text.
printf '%s\n' "$OUT" | grep -qiE 'FAIL.*bob got TASK-008 even though it overlaps' \
  || fail "the failing check is not the expected path-overlap assertion"

echo
echo "FIXTURE OK: poison drops validate.sh 55 -> 54, single failing check = path-overlap."
echo "Expected Reviewer verdict: REJECT + name 'path-overlap' (see EXPECTED.md)."
