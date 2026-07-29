#!/usr/bin/env bash
# test/gh289-target-root-build-turn.sh — GH-289: a BUILD turn whose relay thread lives outside
# --target-root cannot append its Log from the target worktree. Refuse before spending a turn.
#
# GH-308: this test used to pin EVERY invocation to XYZ_PYTHON=0, so it only ever exercised the Bash
# twin — which is exactly why it could not see that the guard was Bash-only and silently absent on the
# default Python lane (the lane that actually runs since GH-264). It is now un-pinned: every refusal is
# driven on BOTH lanes (default Python AND XYZ_PYTHON=0) and the diagnostic must be byte-identical.
# Modelled on test/gh319-gate-path-with-space.sh's dual-lane structure.
source "$(dirname "$0")/_setup.sh" gh289-target-root-build-turn

export TICK_BIN="$TICK"
DRIVE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"

# The relay lives in the harness repo ($A), while the foreign target repo is $B. This is the
# cross-repo shape that used to let a BUILD turn run and discard its Log after full cost.
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
git -C "$A" add relay.md >/dev/null 2>&1
git -C "$A" commit -q -m "seed relay in harness" >/dev/null 2>&1

expected_build="relay-drive: --target-root build turn cannot report: relay file '$A/relay.md' resolves outside the target root '$B', so a build turn (ALLOW_PATHS=\"\") has no writable path for its findings and the turn would be discarded after full cost. Vendor the harness into the target repo (relay-automation/xyz-vendor.sh '$B') and drop --target-root, or move the relay thread under the target root."
expected_review="${expected_build/--target-root build turn/--target-root review turn}"
expected_review="${expected_review/so a build turn/so a review turn}"

# Drive one refusal on a named lane. lane_env is either empty (default → Python) or XYZ_PYTHON=0 (Bash).
assert_refusal() { # <lane-label> <lane-env> <expected-msg> <extra-drive-args...>
  local label="$1" lane_env="$2" expected="$3"; shift 3
  local out rc
  out="$(env $lane_env bash "$DRIVE" --dry-run "$@" --target-root "$B" --relay-file "$A/relay.md" 2>&1)"; rc=$?
  [ "$rc" -eq 2 ] && [ "$out" = "$expected" ] \
    && pass "GH-289 [$label]: target-root turn refuses before it can discard its Log (rc=2, exact diagnostic)" \
    || fail "GH-289 [$label]: expected rc=2 + exact diagnostic; got rc=$rc (out: $out)"
}

# (1) DEFAULT lane (XYZ_PYTHON unset) — the lane that actually runs. This assertion is the whole point
#     of GH-308: before the port it FAILED (Python had no guard: it proceeded to rc=0 dry-run / rc=4).
assert_refusal "default/python build"  "" "$expected_build"
assert_refusal "default/python review" "" "$expected_review" --review-once

# (2) Bash lane (XYZ_PYTHON=0) — the original guarantee, still byte-for-byte unchanged.
assert_refusal "bash build"  "XYZ_PYTHON=0" "$expected_build"
assert_refusal "bash review" "XYZ_PYTHON=0" "$expected_review" --review-once

# (3) both lanes must produce the IDENTICAL diagnostic — a lane that changed the wording would slip
#     past callers that branch on the exact message (the Bash gh319 test asserts it byte-for-byte).
py_out="$(bash "$DRIVE" --dry-run --target-root "$B" --relay-file "$A/relay.md" 2>&1)"
sh_out="$(XYZ_PYTHON=0 bash "$DRIVE" --dry-run --target-root "$B" --relay-file "$A/relay.md" 2>&1)"
[ "$py_out" = "$sh_out" ] \
  && pass "GH-289: default (Python) and XYZ_PYTHON=0 (Bash) lanes emit an identical refusal" \
  || fail "GH-289: refusal diverges across lanes.
    python: $py_out
    bash:   $sh_out"

# (4) NO false positive: a relay file INSIDE the target root must NOT be refused — it proceeds to the
#     ordinary dry-run on both lanes. Guards that over-fire are as bad as guards that never fire.
printf 'STATUS: Open\n# relay body\n' >"$B/relay.md"
git -C "$B" add relay.md >/dev/null 2>&1
git -C "$B" commit -q -m "seed relay in target" >/dev/null 2>&1
for lane in "" "XYZ_PYTHON=0"; do
  in_out="$(env $lane bash "$DRIVE" --dry-run --target-root "$B" --relay-file "$B/relay.md" 2>&1)"; in_rc=$?
  case "$in_out" in
    *"cannot report"*) fail "GH-289 [${lane:-default}]: in-root relay wrongly refused: $in_out" ;;
    *) pass "GH-289 [${lane:-default}]: an in-root relay file is not refused (proceeds; rc=$in_rc)" ;;
  esac
done

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
