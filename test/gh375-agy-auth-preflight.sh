#!/usr/bin/env bash
# test/gh375-agy-auth-preflight.sh — GH-375 regression.
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh375-agy-auth-preflight.sh; pre-fix revisions: (a) agy-turn.py/consult.py before acf2d3e, deciding on exit status alone with the captured output deleted — the reported TTY output read as successful auth; (b) the first fix, which made that TTY output FATAL — test/relay-self-sufficiency.sh went 4/0 to 0/4 with 'agy shim exited 5' on a machine where agy was signed in and working. Post-fix result: 17/0 with the TTY shape classified unverifiable rather than failed"}
#
# The agy auth pre-flight decided pass/fail on EXIT STATUS alone and deleted the captured output on
# the success branch. `agy whoami` exits 0 while failing to run at all when there is no TTY:
#
#   $ agy whoami </dev/null; echo "exit=$?"
#   CLI error: bubbletea: error opening TTY: ... open /dev/tty: device not configured
#   exit=0
#
# and the probe passes stdin=DEVNULL, so that is the NORMAL path under automation — every marathon
# and every driven relay turn. The guard that exists to stop a lane before it burns a turn on
# expired credentials could not fail in the one context it exists for. The protection depended on a
# hang that only happens when a TTY is present, so attended runs were protected and unattended ones
# were not: exactly inverted from the intent.
#
# Both directions are asserted here. A probe that only ever says "fail" would satisfy the bug report
# and break every real run, and that failure mode is live: the first fix for this matched a bare
# "error" substring anywhere in the output, which fails any account whose handle, org, or banner
# contains the word. A false failure stops the run outright — worse than the bug being fixed.
source "$(dirname "$0")/_setup.sh" gh375-agy-auth-preflight
PY="$(cd "$(dirname "$0")/.." && pwd)/utils/py"

probe() {  # <fixture-text> → prints "<severity>|<message>"; severity is ""/unverifiable/failed
  printf '%s' "$1" > "$WORK/agy-out.txt"
  python3 -c "
import sys
sys.path.insert(0, '$PY')
from rtl import agy_auth_output_verdict
sev, msg = agy_auth_output_verdict('$WORK/agy-out.txt')
print(f'{sev}|{msg}')
"
}
sev() { printf '%s' "${1%%|*}"; }

# --- the reported failure, verbatim from the issue ------------------------------------------------
# It must be NOTICED (the original bug was that it read as success) but classified `unverifiable`,
# NOT `failed`. See the block below for what the difference cost.
r="$(probe 'CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured')"
[ -n "$(sev "$r")" ] && pass "the headless TTY output is no longer read as successful auth" \
  || fail "GH-375 is back: the exact reported output reads as successful auth"
[ "$(sev "$r")" = "unverifiable" ] \
  && pass "the TTY output is classified unverifiable, not failed" \
  || fail "the TTY output is classified '$(sev "$r")' — a fatal verdict here blocks a WORKING agy lane"

# --- WHY unverifiable AND NOT failed --------------------------------------------------------------
# GH-375's suggested fix said to treat the TTY error as a failed probe and stop the turn. That was
# implemented literally, and it broke the agy lane outright: test/relay-self-sufficiency.sh, which
# drives a LIVE agy turn, went 4/0 to 0/4 with `agy shim exited 5` — on a machine where agy was
# signed in and working. Two measurements settle it:
#
#   * `agy whoami` cannot run headless at all. Exit 0, `CLI error: ... could not open TTY`.
#   * `agy -p` — the print mode the ACTUAL turn uses — runs headless perfectly well.
#
# So the TTY banner says nothing about auth; it says this probe is the wrong instrument here.
# Treating it as failure converts an unmeasurable check into a hard block on a lane that
# demonstrably works, which is strictly worse than the bug GH-375 reported: that one merely let a
# possibly-unauthed lane proceed, this one stopped one of two working builders dead.
#
# What GH-375 established stands and is asserted above: exit status alone cannot decide this, and
# the captured output must survive to be printed. The inference "the probe could not run, therefore
# auth is bad" is the part that does not follow.
r="$(probe 'CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured')"
printf '%s' "$r" | grep -Fq "not verified" \
  && pass "the unverifiable message says auth was not verified, rather than asserting it failed" \
  || fail "the message overstates what the probe established: $r"

# --- silence is deliberately NOT failure ----------------------------------------------------------
# This pins a decision that was made the other way first and reverted on evidence. "A probe that
# establishes nothing must not report success" reads well, but test/gh410-containment-advisory.sh's
# agy stub prints nothing for `whoami`: under that rule the pre-flight rejected it, the turn exited 5
# before running, and a containment assertion unrelated to auth went red. One rule, one real turn
# killed, on first contact.
#
# The asymmetry is the whole argument. agy exiting 0 with a VISIBLE error is observed and documented
# (GH-375). agy exiting 0 SILENTLY on success is not something this repo can rule out — and guessing
# wrong there breaks every turn in the fleet rather than one. These two assertions exist so nobody
# re-adds the stricter rule without first re-reading why it was removed.
r="$(probe '')"
[ -z "$(sev "$r")" ] && pass "empty output is NOT treated as failure (see the incident note in rtl.py)" \
  || fail "empty output rejected — this kills any turn whose agy prints nothing: $r"

r="$(probe '
')"
[ -z "$(sev "$r")" ] && pass "whitespace-only output is NOT treated as failure" \
  || fail "whitespace-only output rejected ($r)"

# --- other genuine error shapes ------------------------------------------------------------------
# These are the shape the pre-flight EXISTS for, and they must stay `failed` — the fix above widened
# one branch, it must not have softened this one into a warning that lets a dead lane run anyway.
for bad in "Error: not logged in" "panic: runtime error: invalid memory address" "fatal: credentials expired"; do
  r="$(probe "$bad")"
  [ "$(sev "$r")" = "failed" ] && pass "rejected as failed: ${bad:0:32}" \
    || fail "a genuine error line is classified '$(sev "$r")', not failed: $bad"
done

# --- THE OTHER DIRECTION: real auth output must NOT be rejected ----------------------------------
# Each of these contains the letters "error" somewhere a naive substring test would trip on. They are
# what a working `agy whoami` can legitimately print. Failing these is not a safe default — it makes
# the pre-flight refuse every turn.
while IFS= read -r good; do
  [ -z "$good" ] && continue
  r="$(probe "$good")"
  [ -z "$(sev "$r")" ] && pass "accepted real auth output: ${good:0:44}" \
    || fail "FALSE FAILURE — legitimate auth output rejected ($r): $good"
done <<'GOOD'
noel@neochro.me
Logged in as: terror-form-labs
account: acme-corp  org: error-budget-team
user: mirror-ops
plan: pro   errors_last_24h: 0
GOOD

# --- the shim wires it in ------------------------------------------------------------------------
# The verdict living in rtl.py is only worth anything if the callers use it. Both had the same hole.
grep -q 'agy_auth_output_verdict' "$PY/agy-turn.py" \
  && pass "agy-turn.py consults the output verdict, not just the exit status" \
  || fail "agy-turn.py still decides on exit status alone"
grep -q 'agy_auth_output_verdict' "$PY/consult.py" \
  && pass "consult.py consults the output verdict too (same hole, same fix)" \
  || fail "consult.py still decides on exit status alone"

# The captured output is the diagnosis; deleting it on the success branch is what hid this for so
# long. Assert the failure path keeps it long enough to print.
grep -q 'Run `agy login` in a normal terminal' "$PY/agy-turn.py" \
  && pass "the remedy an operator needs is still printed" \
  || fail "the 'agy login' remedy is missing from the failure path"

# --- the callers must ACT on the three states, not just import the function -----------------------
# The verdict is only worth anything if `unverifiable` actually lets the turn proceed. A caller that
# imports the new function and then treats any non-empty severity as fatal reproduces the exact
# regression this rework undoes, while passing every assertion above.
grep -q 'unverifiable' "$PY/agy-turn.py" \
  && pass "agy-turn.py branches on the unverifiable state (a working lane is not blocked)" \
  || fail "agy-turn.py ignores the unverifiable state — any non-empty verdict still kills the turn"
grep -q 'unverifiable' "$PY/consult.py" \
  && pass "consult.py branches on it too (headless is the normal path there as well)" \
  || fail "consult.py ignores the unverifiable state — the agy seat is disabled on every consult"

exit 0
