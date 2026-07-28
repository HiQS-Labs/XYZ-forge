#!/usr/bin/env bash
# test/gh289-target-root-build-turn.sh — GH-289: a BUILD turn whose relay thread lives outside
# --target-root cannot append its Log from the target worktree. Refuse before spending a turn.
source "$(dirname "$0")/_setup.sh" gh289-target-root-build-turn

export TICK_BIN="$TICK"
DRIVE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"

# The relay lives in the harness repo ($A), while the foreign target repo is $B. This is the
# cross-repo shape that used to let a BUILD turn run and discard its Log after full cost.
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
git -C "$A" add relay.md >/dev/null 2>&1
git -C "$A" commit -q -m "seed relay in harness" >/dev/null 2>&1

expected_build="relay-drive: --target-root build turn cannot report: relay file '$A/relay.md' resolves outside the target root '$B', so a build turn (ALLOW_PATHS=\"\") has no writable path for its findings and the turn would be discarded after full cost. Vendor the harness into the target repo (relay-automation/xyz-vendor.sh '$B') and drop --target-root, or move the relay thread under the target root."
# This phase modifies relay-drive.sh's inline Bash path; pin it because the shim's default runtime is
# currently Python and its port is deliberately outside this phase's allowlist.
out="$(XYZ_PYTHON=0 bash "$DRIVE" --dry-run --target-root "$B" --relay-file "$A/relay.md" 2>&1)"; rc=$?

[ "$rc" -eq 2 ] && [ "$out" = "$expected_build" ] \
  && pass "GH-289: target-root BUILD turn refuses before it can discard its Log" \
  || fail "GH-289: expected build refusal (rc=2, exact diagnostic); got rc=$rc (out: $out)"

# Existing --review-once behavior is intentionally byte-for-byte unchanged.
expected_review="${expected_build/--target-root build turn/--target-root review turn}"
expected_review="${expected_review/so a build turn/so a review turn}"
out_review="$(XYZ_PYTHON=0 bash "$DRIVE" --dry-run --review-once --target-root "$B" --relay-file "$A/relay.md" 2>&1)"; rc_review=$?
[ "$rc_review" -eq 2 ] && [ "$out_review" = "$expected_review" ] \
  && pass "GH-289: existing review-once refusal remains byte-for-byte unchanged" \
  || fail "GH-289: review-once refusal changed (rc=$rc_review, out: $out_review)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
