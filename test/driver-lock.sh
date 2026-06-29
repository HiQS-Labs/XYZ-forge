#!/usr/bin/env bash
# driver-lock.sh — GH-42 self-heal: marathon-drive reclaims a STALE relay-driver.lock (the holder
# process is dead) so a crashed/killed driver never blocks every later run until a manual rmdir — but
# it still REFUSES to start when the lock's holder is alive (the real concurrent-driver hazard).
source "$(dirname "$0")/_setup.sh" driver-lock

# Hermetic: the driver lock block is skipped when RELAY_DRIVER_LOCKED=1 (so a driver delegating to a
# sub-driver doesn't double-lock). If this test runs UNDER a marathon gate, it would inherit that
# export and skip the very logic it's testing (the lock would "leak"). Unset it so we always exercise
# the acquire/reclaim path regardless of how validate.sh was invoked.
unset RELAY_DRIVER_LOCKED

MD="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/marathon-drive.sh"
LOCK="$A/.git/relay-driver.lock"
brief="$WORK/brief.md"; printf '# brief\n' >"$brief"

# --dry-run acquires the lock then renders + exits BEFORE spawning any agent, so it exercises the
# lock cheaply. reviewer=agy (a valid QA lane); builder defaults to claude (≠ reviewer).
run_md(){ MARATHON_ROOT="$A" TICK_BIN="$TICK" bash "$MD" --phase-brief "$brief" --reviewer agy --dry-run >/dev/null 2>&1; }

# (1) STALE lock — holder pid not running → reclaimed → driver proceeds (dry-run exit 0) → lock freed.
mkdir -p "$LOCK"; printf '999999\n' >"$LOCK/pid"     # 999999: not a live pid
run_md; rc=$?
[ "$rc" -eq 0 ] && pass "stale lock (dead holder) reclaimed → driver proceeds (exit 0)" || fail "stale lock not reclaimed (rc=$rc)"
[ ! -e "$LOCK" ] && pass "lock released on clean exit" || { fail "lock leaked after run"; rm -rf "$LOCK"; }

# (2) LIVE lock — holder alive (this shell) → driver refuses (exit 1) and leaves the lock intact.
mkdir -p "$LOCK"; printf '%s\n' "$$" >"$LOCK/pid"
run_md; rc=$?
[ "$rc" -eq 1 ] && pass "live lock (alive holder) → driver refuses (exit 1)" || fail "live lock not honored (rc=$rc)"
[ -e "$LOCK" ] && pass "live lock left intact (not stolen)" || fail "live lock was wrongly removed"
rm -rf "$LOCK"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
