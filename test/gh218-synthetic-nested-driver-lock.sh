#!/usr/bin/env bash
# test/gh218-synthetic-nested-driver-lock.sh — GH-218: a synthetic suite driving relay_drive.py must
# not try to acquire the HARNESS clone's driver lock.
#
# The live incident: test/synthetic/gh101-relay-programmatic-stress.sh drove relay_drive.py with
# RELAY_DRIVER_LOCKED=0. relay_drive.py resolves its lock from the SCRIPT's location
# (utils/py/../.. = the harness clone), NOT the CWD — so standalone the suite quietly acquired the
# real clone's .git/relay-driver.lock, and when validate.sh ran as a marathon-drive pre-advance gate
# that same lock was HELD by the parent driver: the programmatic turn failed and escalated a live
# phase. The issue's fix sketch (cd into the fixture) does NOT fix this — that was measured by
# holding the lock and running the cd-only variant; only RELAY_DRIVER_LOCKED=1 (the GH-441 Phase 1
# nested-driver idiom) does.
#
# Two guards:
#   S  static — no test/synthetic suite may invoke relay_drive.py/marathon_drive.py with
#      RELAY_DRIVER_LOCKED=0 on or around the invocation line (a suite driving its own throwaway
#      fixture has no business contending for the harness lock)
#   D  dynamic — the issue's reproduction: hold the harness clone's lock, run gh101, expect green
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$HERE"

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*"; FAIL=$((FAIL+1)); }

# ── (S) static sweep: no LOCKED=0 driver invocations in synthetic suites ────────────────────────
violations=""
while IFS= read -r -d '' f; do
  # Flag any line that sets RELAY_DRIVER_LOCKED=0 on a driver-invocation line itself (the env-prefix
  # idiom) or within 3 lines above one (prefix lines / subshell openers).
  hit="$(awk '
    /relay_drive\.py|marathon_drive\.py/ {
      if ($0 ~ /RELAY_DRIVER_LOCKED=0/) { print "hit"; exit }
      for (i = NR - 3; i < NR; i++) if (locked[i]) { print "hit"; exit }
    }
    /RELAY_DRIVER_LOCKED=0/ { locked[NR] = 1 }
  ' "$f")"
  [ -n "$hit" ] && violations="$violations $(basename "$f")"
done < <(find "$ROOT/test/synthetic" -name '*.sh' -print0 2>/dev/null)
[ -z "$violations" ] && pass "static: no synthetic suite drives a driver with RELAY_DRIVER_LOCKED=0" \
  || fail "static: RELAY_DRIVER_LOCKED=0 driver invocation(s) in:$violations"

# ── (D) dynamic: the issue's reproduction, held parent lock ──────────────────────────────────────
# Hold the harness clone's lock exactly the way a live marathon-drive does (dir + live pid), run
# gh101, release. The window is the suite's own runtime (~seconds); no validate sibling acquires
# this lock (fixtures + LOCKED=1 are the norm — that is what this test enforces).
LOCK="$ROOT/.git/relay-driver.lock"
if [ -e "$LOCK" ]; then
  pass "dynamic: SKIPPED — a real driver lock already exists (a live driver owns this clone); not touching it"
else
  mkdir -p "$LOCK" && echo $$ >"$LOCK/pid"
  if bash "$ROOT/test/synthetic/gh101-relay-programmatic-stress.sh" >/tmp/gh218-dyn.$$ 2>&1; then
    pass "dynamic: gh101 green under a held parent driver lock (the live incident shape)"
  else
    fail "dynamic: gh101 failed under a held parent lock — the collision is back:"
    tail -5 /tmp/gh218-dyn.$$ >&2
  fi
  rm -f /tmp/gh218-dyn.$$ 2>/dev/null
  rm -rf "$LOCK"
fi

echo
echo "gh218-synthetic-nested-driver-lock: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
