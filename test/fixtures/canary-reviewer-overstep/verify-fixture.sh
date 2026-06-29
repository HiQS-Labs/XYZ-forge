#!/usr/bin/env bash
# verify-fixture.sh — prove the reviewer-overstep canary is grounded in the REAL containment kernel.
#
# The fault: a REVIEWER turn edits a source/artifact file (validate.sh) instead of only appending
# findings to the relay file. The real 2026-06-20 incident — an over-eager agy reviewer edited
# validate.sh because the artifact sat on ALLOW_PATHS. The guard: rtl_init detects a reviewer turn
# (NEXT names the Reviewer) and SCOPES the allowlist to the relay file ONLY, so any artifact edit is
# reverted + exit 6 by rtl_enforce.
#
# This script asserts that scoping behavior directly against the real lib (rtl_init / rtl_in_allow):
#   - reviewer turn  + ALLOW_PATHS=validate.sh  -> validate.sh is OFF the allowlist (would be reverted)
#   - producer turn  + ALLOW_PATHS=validate.sh  -> validate.sh is ON the allowlist (legit build)
# The contrast IS the systemic lesson: scoping is the only thing standing between a reviewer and a
# silent source edit.
#
#   bash test/fixtures/canary-reviewer-overstep/verify-fixture.sh
#
# rtl_init only READS git config (no mutation), but we still apply the GH-44 guard (GIT_CEILING +
# .git assertion) so this can never act on the parent repo.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
LIB="$ROOT/relay-automation/relay-turn-lib.sh"
SC="$HERE/.scenario"

cleanup() { rm -rf "$SC"; }
trap cleanup EXIT
fail() { echo "FIXTURE FAIL: $*"; exit 1; }

export GIT_CEILING_DIRECTORIES="$HERE"
# shellcheck source=/dev/null
source "$LIB"

rm -rf "$SC"; mkdir -p "$SC"
git init -q "$SC" 2>/dev/null
[ -d "$SC/.git" ] || fail "could not create scratch git repo at $SC/.git — aborting (won't touch the parent repo)"

echo "[1/3] reviewer turn (NEXT: Reviewer) + ALLOW_PATHS=validate.sh …"
printf 'NEXT: Reviewer\nSTATUS: Open\n# relay body\n' >"$SC/relay.md"
rtl_init "$SC" "$SC/relay.md" "validate.sh" 2>/dev/null
rtl_in_allow "relay.md"   || fail "reviewer's own relay file should be on the allowlist"
if rtl_in_allow "validate.sh"; then
  fail "validate.sh is on the allowlist for a REVIEWER turn — scoping failed (the 2026-06-20 hole)"
fi
echo "  -> validate.sh OFF the allowlist for a reviewer (an edit would be reverted + exit 6) ✓"

echo "[2/3] producer turn (NEXT: Producer) + ALLOW_PATHS=validate.sh …"
printf 'NEXT: Producer\nSTATUS: Open\n# relay body\n' >"$SC/relay.md"
rtl_init "$SC" "$SC/relay.md" "validate.sh" 2>/dev/null
rtl_in_allow "validate.sh" || fail "validate.sh should be ON the allowlist for a PRODUCER turn (legit build)"
echo "  -> validate.sh ON the allowlist for a producer ✓ (contrast: scoping is reviewer-only)"

echo "[3/3] scoping is what protects the reviewer case…"
echo
echo "FIXTURE OK: a reviewer turn is scoped to the relay file only — an edit to validate.sh is"
echo "off-allowlist (reverted + exit 6). Remove that scoping (or treat the turn as a producer) and the"
echo "same edit slips through. Expected Reviewer verdict: see EXPECTED.md."
