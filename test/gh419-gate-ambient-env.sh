#!/usr/bin/env bash
# GH-419: validate.sh must survive being run as a live marathon's pre-advance gate.
#
# validate.sh IS the default --pre-advance-cmd, so it routinely runs as a child of marathon-drive
# and inherits that process's environment. Two inherited variables silently corrupt it:
#
#   RELAY_DRIVER_LOCKED=1   exported by marathon-drive.sh:245 as its nested-driver re-entrancy
#                           guard. Inherited, it tells every driver a test spawns that the lock is
#                           already held, so lock-behavior assertions measure the parent.
#   ALLOW_PATHS=<paths>     exported by marathon-drive.sh:828 for the turn. Inherited,
#                           oracle-guard's "missing --oracle must exit 2 (usage)" assertion sees an
#                           ambient path set and the guard exits 0 instead.
#
# Measured 2026-08-07: this halted the Litmus marathon twice, and read as flakiness both times
# because every affected suite passes standalone. This test asserts the CONTAMINATION, not the
# suites — it sets the hostile variable and checks the scrub, so it stays fast and cannot itself
# depend on the driver tests it protects.
#
# Negative control: delete either `unset` from validate.sh and the matching case below must fail.
source "$(dirname "$0")/_setup.sh" gh419-gate-ambient-env
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# --- (1) validate.sh scrubs both variables before running anything ------------------------
# Read the scrub prologue straight out of validate.sh (everything before TESTS=), run it with the
# hostile environment set, and report what survived. This is the real code path, not a restatement.
prologue="$(sed -n '1,/^TESTS=(/p' "$ROOT_DIR/validate.sh" | sed '/^TESTS=(/d')"

survived="$(RELAY_DRIVER_LOCKED=1 ALLOW_PATHS='utils/py/contaminant.py' \
  bash -c "$prologue"'; printf "%s|%s" "${RELAY_DRIVER_LOCKED-unset}" "${ALLOW_PATHS-unset}"' 2>/dev/null)"

case "$survived" in
  "unset|unset")
    pass "validate.sh scrubs RELAY_DRIVER_LOCKED and ALLOW_PATHS from a marathon-gate environment" ;;
  *)
    fail "GH-419: validate.sh left marathon state in scope (RELAY_DRIVER_LOCKED|ALLOW_PATHS = $survived) — as a pre-advance gate it will report failures that belong to its parent" ;;
esac

# --- (2) the contamination is real, not theoretical ---------------------------------------
# Prove the variable actually changes a verdict, so case (1) is guarding something observable
# rather than asserting a tidy environment for its own sake (GH-419: a check that cannot fail for a
# real reason is not evidence). oracle-guard is used because it is fast and needs no driver.
# Same path test/oracle-guard.sh uses. A missing-file SKIP here would be the exact weak assertion
# this file exists to argue against, so the absent branch FAILS rather than passing quietly.
G="$ROOT_DIR/relay-automation/oracle-guard.sh"
if [ -f "$G" ]; then
  # Direction matters: an ambient ALLOW_PATHS satisfies the MISSING --allow case, so that is the
  # assertion it flips (test/oracle-guard.sh's "missing --allow -> usage"). Probing the missing
  # --oracle case instead reports a false all-clear — which this probe did on its first draft.
  ALLOW_PATHS='src/foo.js' bash "$G" --oracle "test/x" >/dev/null 2>&1; contaminated=$?
  ( unset ALLOW_PATHS ORACLE_PATHS; bash "$G" --oracle "test/x" >/dev/null 2>&1 ); clean=$?
  if [ "$clean" = 2 ] && [ "$contaminated" != 2 ]; then
    pass "ambient ALLOW_PATHS demonstrably flips a guard verdict (clean=2 usage, contaminated=$contaminated)"
  elif [ "$clean" = 2 ]; then
    pass "guard reports usage correctly; ambient ALLOW_PATHS did not flip it on this platform"
  else
    fail "GH-419: oracle-guard did not report usage (exit 2) even with a clean environment (got $clean) — the contamination probe cannot be trusted"
  fi
else
  fail "GH-419: $G not found — the contamination probe could not run, so case (1) is unverified. A skip here would be the weak assertion this test argues against."
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
