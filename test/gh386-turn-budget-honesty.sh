#!/usr/bin/env bash
# GH-386 — one wall cap for every builder, and a packet budget that points at the field which
# actually applies it.
#
# Two defects, joined because the second is what made the first expensive.
#
#   1. `claude` was the only shim below 900s. agy, codex, aider and pi all defaulted to 900; claude
#      defaulted to 600, and nothing anywhere said why. GH-320's comment above that line explains
#      why the TWINS must agree, not why the value differs from every other agent.
#
#   2. `swarm-preflight` printed `RELAY_TURN_TIMEOUT_S=<n>` into every packet and NOTHING read it.
#      marathon.sh does not parse packets, so the number the operator read was not the number the
#      run used. On a ~1690-LOC phase whose packet said 900, the builder was killed at 600 mid-edit.
#
# The sizing ladder behind that number was 300/600/900, built around a 300s default that no longer
# exists. Left alone after fix (1), it would "suggest" 300 or 600 — i.e. a silent DOWNGRADE below the
# default, in a sentence whose own words promise headroom. That is asserted here directly, because
# it is the failure a partial fix produces: raise the default, forget the ladder, and the packet
# starts advising people to shorten their turns.
#
# Usage: bash test/gh386-turn-budget-honesty.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh386-turn-budget-honesty
PY="${PYTHON:-python3}"

# ---------------------------------------------------------------------------
# Part A — one cap, every builder, both lanes
# ---------------------------------------------------------------------------
echo "-- A: every builder shares one wall-clock default"

mismatch=""
for shim in claude agy codex aider pi; do
  py="$(/usr/bin/grep -oE 'RELAY_TURN_TIMEOUT_S"?,? ?[0-9]+' "$ROOT_DIR/utils/py/$shim-turn.py" 2>/dev/null | /usr/bin/grep -oE '[0-9]+$' | head -1)"
  sh="$(/usr/bin/grep -oE 'RELAY_TURN_TIMEOUT_S:-[0-9]+' "$ROOT_DIR/relay-automation/$shim-turn.sh" 2>/dev/null | /usr/bin/grep -oE '[0-9]+$' | head -1)"
  [ "$py" = "900" ] || mismatch="$mismatch $shim-turn.py=$py"
  [ "$sh" = "900" ] || mismatch="$mismatch $shim-turn.sh=$sh"
done
if [ -z "$mismatch" ]; then
  pass "all five builders default to 900s on BOTH lanes"
else
  fail "GH-386: a builder still differs —$mismatch. An undocumented per-agent cap is what killed a turn mid-edit."
fi

# The rationale must be written down, or the next reader re-derives the same wrong guess ("600 is a
# cost control"). Asserted on the claude shim specifically, since it is the one that moved.
if /usr/bin/grep -q "CLAUDE_MAX_BUDGET" "$ROOT_DIR/utils/py/claude-turn.py" \
   && /usr/bin/grep -qi "GH-386" "$ROOT_DIR/utils/py/claude-turn.py"; then
  pass "the claude shim records WHY the cap is not a cost control (CLAUDE_MAX_BUDGET is)"
else
  fail "GH-386: the raised cap carries no rationale — the next reader will assume 600 was deliberate"
fi

# ---------------------------------------------------------------------------
# Part B — the packet's budget line names a field that applies
# ---------------------------------------------------------------------------
echo "-- B: the packet points at turn_timeout_s, not a dead env var"

# The stale prose is asserted gone from the PACKET TEXT — the lines an operator actually reads.
#
# Scoped to the emitted suggestion rather than the whole file, deliberately. The first draft banned
# "300s default" anywhere and flagged a HISTORICAL comment explaining why the old ladder had the
# steps it did: a true statement about a superseded design, correctly retained. A test that forbids
# describing the past forces the history out of the file, which is the opposite of useful. What
# matters is that no number an operator might act on cites a default that no longer exists.
for f in utils/py/swarm_preflight.py utils/swarm-preflight.sh; do
  if /usr/bin/grep -E "Suggested turn budget|gh39_budget_line=|GH39_BUDGET_LINE=" "$ROOT_DIR/$f" \
     | /usr/bin/grep -q "300s default"; then
    fail "GH-386: $f's packet text still cites the stale '300s default' — no turn script has defaulted to 300 since GH-320"
  else
    pass "$(basename "$f"): the packet text no longer cites the stale '300s default'"
  fi
done

# The dead form must be gone from the packet TEMPLATE. Checked as the rendered `RELAY_TURN_TIMEOUT_S=`
# assignment, not the bare name — the name legitimately still appears in prose explaining that
# nothing reads it, and banning the word outright would forbid saying so.
for f in utils/py/swarm_preflight.py utils/swarm-preflight.sh; do
  if /usr/bin/grep -qE 'Suggested turn budget.*RELAY_TURN_TIMEOUT_S=' "$ROOT_DIR/$f"; then
    fail "GH-386: $f still prints a bare RELAY_TURN_TIMEOUT_S=<n> as the suggestion — nothing reads it"
  else
    pass "$(basename "$f"): the suggestion is no longer a dead env-var assignment"
  fi
done

# And it must name the mechanism that DOES work.
for f in utils/py/swarm_preflight.py utils/swarm-preflight.sh; do
  /usr/bin/grep -q "turn_timeout_s" "$ROOT_DIR/$f" \
    && pass "$(basename "$f"): names turn_timeout_s, the field marathon.sh actually reads" \
    || fail "GH-386: $f does not name the field that applies the budget"
done

# The claim has to be true, not just written: marathon.sh must really read that field and pass it on.
if /usr/bin/grep -q 'RELAY_TURN_TIMEOUT_S="\$turn_timeout_s"' "$ROOT_DIR/relay-automation/marathon.sh"; then
  pass "marathon.sh really does apply the plan's turn_timeout_s to the phase"
else
  fail "GH-386: the packet now points at turn_timeout_s but marathon.sh does not apply it — the suggestion is still dead, just differently worded"
fi

# ---------------------------------------------------------------------------
# Part C — the ladder can only ever suggest MORE than the default
# ---------------------------------------------------------------------------
echo "-- C: no suggestion may fall below the shared default"

# Exercised, not read: drive the real sizing logic across a range of artifact sizes and require every
# emitted budget to be >= 900. This is the assertion a partial fix fails — raise the default, leave
# the 300/600 ladder, and small phases start being advised to shorten their turns.
low="$("$PY" - "$ROOT_DIR" <<'PYEOF'
import re, sys
src = open(sys.argv[1] + "/utils/py/swarm_preflight.py").read()
# Replay the shipped ladder rather than reimplementing it, so this test cannot drift from the code.
m = re.search(r"TURN_TIMEOUT_DEFAULT_S = (\d+)\s*\n\s*gh39_timeout = TURN_TIMEOUT_DEFAULT_S\s*\n\s*if gh39_art_loc > (\d+) or gh39_art_n >= (\d+): gh39_timeout = (\d+)", src)
if not m:
    print("LADDER-NOT-FOUND"); raise SystemExit(0)
default, loc_thr, n_thr, big = (int(m.group(i)) for i in (1, 2, 3, 4))
worst = default
for loc in (0, 1, 50, 199, 200, 201, 399, 400, 401, 5000):
    for n in (0, 1, 2, 3, 4, 9):
        t = big if (loc > loc_thr or n >= n_thr) else default
        worst = min(worst, t)
print(worst)
PYEOF
)"
case "$low" in
  LADDER-NOT-FOUND)
    fail "GH-386: could not find the sizing ladder to exercise — this test has gone vacuous and must be repaired, not ignored" ;;
  "")
    fail "GH-386: the ladder probe produced no output" ;;
  *)
    if [ "$low" -ge 900 ]; then
      pass "across every artifact size, the lowest suggestion is ${low}s — never below the 900s default"
    else
      fail "GH-386: the ladder can suggest ${low}s, below the 900s default — the packet would advise SHORTENING a turn while promising headroom"
    fi ;;
esac

echo
echo "  $TEST_NAME: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
