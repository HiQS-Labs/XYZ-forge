#!/usr/bin/env bash
# verify-fixture.sh — prove the Gamma poison is a *real* single-check regression.
#
# This is the verifiable substrate of the Phase 1 Gamma gate (GH-40): it does NOT grade a Reviewer,
# it proves the fixture itself is honest — applying the "optimization" drops ./validate.sh from
# the suite by exactly one check — failing exactly `path-overlap` and nothing else (count-independent,
# so growing the suite doesn't break it).
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

# Restore from HEAD (not the index): undoes BOTH unstaged and staged changes the run made to $TARGET.
cleanup() { git checkout HEAD -- "$TARGET" 2>/dev/null; }
trap cleanup EXIT

fail() { echo "FIXTURE FAIL: $*"; exit 1; }

# Guard: $TARGET must be clean in BOTH the worktree AND the index, so the revert is a true restore to
# HEAD and the count is trustworthy. (A staged-but-uncommitted change would otherwise slip past a
# worktree-only check, and a checkout-from-index would "restore" the staged change, not the pre-run state.)
if ! git diff --quiet -- "$TARGET" || ! git diff --cached --quiet -- "$TARGET"; then
  fail "$TARGET has uncommitted (worktree or staged) changes — commit/stash before verifying the fixture"
fi

echo "[1/3] applying poison ($PATCH)…"
git apply "$PATCH" || fail "patch did not apply cleanly against current $TARGET"

echo "[2/3] running ./validate.sh (full suite, slow)…"
OUT="$(./validate.sh 2>&1)"

echo "[3/3] asserting single-check regression…"
COUNT_LINE="$(printf '%s\n' "$OUT" | grep -E 'passed: [0-9]+ / [0-9]+' | tail -1)"
echo "  $COUNT_LINE"

# Suite-size-independent: assert EXACTLY ONE check failed, and it is path-overlap. (Hardcoding the
# count, e.g. 54/55, breaks whenever the suite grows — it did when the GH-40 canaries were wired in.)
FAILED="$(printf '%s\n' "$OUT" | sed -n '/^failed:/,$p' | grep -E '^[[:space:]]*-[[:space:]]' || true)"
NFAIL="$(printf '%s\n' "$FAILED" | grep -c . )"
[ "$NFAIL" = "1" ] \
  || fail "expected exactly ONE failing check, got $NFAIL: $(printf '%s' "$FAILED" | tr '\n' ' ')"
grep -q 'path-overlap' <<<"$(printf '%s\n' "$FAILED")" \
  || fail "the single failing check is not path-overlap: $FAILED"

# Belt-and-suspenders: confirm it failed on the expected assertion, not some unrelated path-overlap break.
grep -qiE 'FAIL.*bob got TASK-008 even though it overlaps' <<<"$(printf '%s\n' "$OUT")" \
  || fail "path-overlap failed, but not on the expected claim-routing assertion"

echo
echo "FIXTURE OK: poison drops the suite by exactly one check ($COUNT_LINE), failing only path-overlap."
echo "Expected Reviewer verdict: REJECT + name 'path-overlap' (see EXPECTED.md)."
