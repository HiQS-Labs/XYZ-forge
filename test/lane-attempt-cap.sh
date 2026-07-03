#!/usr/bin/env bash
# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
# Proves the cap logic in relay-drive.sh + marathon-drive.sh: a lane is REFUSED (exit 8, no token)
# once it hits LANE_MAX_ATTEMPTS; --force overrides; a nested (LANE_ATTEMPT_COUNTED) call is a no-op;
# and both drivers carry a byte-consistent mirror + wire the gate at the right seam.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
WORK="$(mktemp -d -t "lane-attempt-cap.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
echo "== test: lane-attempt-cap =="

RELAY_DRIVE="$ROOT/relay-automation/relay-drive.sh"
MARATHON_DRIVE="$ROOT/relay-automation/marathon-drive.sh"

# ── 1. Both drivers parse + are wired ──────────────────────────────────────
bash -n "$RELAY_DRIVE"     && pass "relay-drive.sh parses"     || fail "relay-drive.sh syntax"
bash -n "$MARATHON_DRIVE"  && pass "marathon-drive.sh parses"  || fail "marathon-drive.sh syntax"

grep -qE 'lane_attempt_gate .*"\$RELAY_TASK" "\$FORCE"' "$RELAY_DRIVE" \
  && pass "relay-drive.sh calls lane_attempt_gate (keyed on RELAY_TASK)" || fail "relay-drive gate call missing"
grep -qE 'lane_attempt_gate .*"\$PHASE_ID" "\$FORCE"' "$MARATHON_DRIVE" \
  && pass "marathon-drive.sh calls lane_attempt_gate (keyed on PHASE_ID)" || fail "marathon-drive gate call missing"
grep -q 'TICK_REPO_ROOT:-' "$RELAY_DRIVE" \
  && pass "relay-drive.sh keys attempts off TICK_REPO_ROOT (hermetic in tests)" || fail "relay-drive not TICK_REPO_ROOT-anchored"
grep -q 'LANE_ATTEMPT_COUNTED=1' "$MARATHON_DRIVE" \
  && pass "marathon-drive.sh guards the nested relay-drive against double-count" || fail "LANE_ATTEMPT_COUNTED guard missing"
grep -qE 'REVIEW_ONCE == 0' "$RELAY_DRIVE" \
  && pass "relay-drive.sh skips the cap for a single --review-once turn" || fail "review-once cap-skip missing"

# ── 2. Byte-consistent mirror (the contract requires it) ───────────────────
extract() { sed -n '/^lane_attempt_gate() {/,/^}/p' "$1"; }
extract "$RELAY_DRIVE" > "$WORK/fn-relay.sh"
extract "$MARATHON_DRIVE" > "$WORK/fn-marathon.sh"
[ -s "$WORK/fn-relay.sh" ] && pass "lane_attempt_gate present in relay-drive.sh" || fail "function missing in relay-drive"
if diff -q "$WORK/fn-relay.sh" "$WORK/fn-marathon.sh" >/dev/null; then
  pass "lane_attempt_gate is byte-identical in both drivers"
else
  fail "lane_attempt_gate diverges between the two drivers"
fi

# ── 3. Behavior — source the real function and exercise it ─────────────────
. "$WORK/fn-relay.sh"
R="$WORK/repo"; mkdir -p "$R/.tick"

# default cap = 2: two fires pass, the third parks (exit 8)
( LANE_MAX_ATTEMPTS=2; lane_attempt_gate "$R" "LANE-A" 0 ); r1=$?
( LANE_MAX_ATTEMPTS=2; lane_attempt_gate "$R" "LANE-A" 0 ); r2=$?
out="$(LANE_MAX_ATTEMPTS=2 lane_attempt_gate "$R" "LANE-A" 0 2>&1)"; r3=$?
[ "$r1" = 0 ] && [ "$r2" = 0 ] && pass "first two fires proceed (exit 0)" || fail "early fires blocked (r1=$r1 r2=$r2)"
[ "$r3" = 8 ] && pass "third fire PARKED with exit 8 (cap reached)" || fail "cap did not fire (r3=$r3)"
printf '%s' "$out" | grep -q 'PARKED' && pass "park message printed" || fail "no park message: $out"
[ "$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')" = 2 ] \
  && pass "parked fire seeded NO extra attempt (still 2 recorded)" || fail "parked fire wrongly appended"

# --force bypasses the cap and logs the override, and DOES count
out="$(LANE_MAX_ATTEMPTS=2 lane_attempt_gate "$R" "LANE-A" 1 2>&1)"; rf=$?
[ "$rf" = 0 ] && pass "--force proceeds past the cap (exit 0)" || fail "--force blocked (rf=$rf)"
printf '%s' "$out" | grep -q 'force override' && pass "--force logs the override" || fail "no override log: $out"
[ "$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')" = 3 ] \
  && pass "--force fire is recorded (now 3 attempts)" || fail "--force fire not recorded"

# nested guard: LANE_ATTEMPT_COUNTED makes it a no-op (no refuse, no append)
before=$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')
( LANE_MAX_ATTEMPTS=2; LANE_ATTEMPT_COUNTED=1; lane_attempt_gate "$R" "LANE-A" 0 ); rn=$?
after=$(wc -l < "$R/.tick/attempts/LANE-A" | tr -d ' ')
[ "$rn" = 0 ] && [ "$before" = "$after" ] \
  && pass "LANE_ATTEMPT_COUNTED short-circuits (no refuse, no double-count)" || fail "nested guard failed (rn=$rn $before->$after)"

# env-overridable cap + key sanitization (a path-like lane id is flattened)
( LANE_MAX_ATTEMPTS=1; lane_attempt_gate "$R" "PROJECT/1-INBOX/GH-45.md" 0 ); k1=$?
o2="$(LANE_MAX_ATTEMPTS=1 lane_attempt_gate "$R" "PROJECT/1-INBOX/GH-45.md" 0 2>&1)"; k2=$?
[ "$k1" = 0 ] && [ "$k2" = 8 ] && pass "LANE_MAX_ATTEMPTS=1 caps after one fire" || fail "custom cap wrong (k1=$k1 k2=$k2)"
[ -f "$R/.tick/attempts/PROJECT_1-INBOX_GH-45.md" ] \
  && pass "path-like lane id sanitized to a single flat key" || fail "key not sanitized"

echo "  lane-attempt-cap: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
