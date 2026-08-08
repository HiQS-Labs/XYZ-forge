#!/usr/bin/env bash
# test/gh375-agy-auth-preflight.sh — GH-375 regression.
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

probe() {  # <fixture-text> → prints the verdict reason, empty when the output reads as real auth
  printf '%s' "$1" > "$WORK/agy-out.txt"
  python3 -c "
import sys
sys.path.insert(0, '$PY')
from rtl import agy_auth_output_failure
print(agy_auth_output_failure('$WORK/agy-out.txt'))
"
}

# --- the reported failure, verbatim from the issue ------------------------------------------------
r="$(probe 'CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured')"
[ -n "$r" ] && pass "the headless TTY failure is caught despite exit 0 ($r)" \
  || fail "GH-375 is back: the exact reported output reads as successful auth"

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
[ -z "$r" ] && pass "empty output is NOT treated as failure (see the incident note in rtl.py)" \
  || fail "empty output rejected — this kills any turn whose agy prints nothing: $r"

r="$(probe '
')"
[ -z "$r" ] && pass "whitespace-only output is NOT treated as failure" \
  || fail "whitespace-only output rejected ($r)"

# --- other genuine error shapes ------------------------------------------------------------------
for bad in "Error: not logged in" "panic: runtime error: invalid memory address" "fatal: credentials expired"; do
  r="$(probe "$bad")"
  [ -n "$r" ] && pass "rejected: ${bad:0:32}" || fail "accepted a genuine error line: $bad"
done

# --- THE OTHER DIRECTION: real auth output must NOT be rejected ----------------------------------
# Each of these contains the letters "error" somewhere a naive substring test would trip on. They are
# what a working `agy whoami` can legitimately print. Failing these is not a safe default — it makes
# the pre-flight refuse every turn.
while IFS= read -r good; do
  [ -z "$good" ] && continue
  r="$(probe "$good")"
  [ -z "$r" ] && pass "accepted real auth output: ${good:0:44}" \
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
grep -q 'agy_auth_output_failure' "$PY/agy-turn.py" \
  && pass "agy-turn.py consults the output verdict, not just the exit status" \
  || fail "agy-turn.py still decides on exit status alone"
grep -q 'agy_auth_output_failure' "$PY/consult.py" \
  && pass "consult.py consults the output verdict too (same hole, same fix)" \
  || fail "consult.py still decides on exit status alone"

# The captured output is the diagnosis; deleting it on the success branch is what hid this for so
# long. Assert the failure path keeps it long enough to print.
grep -q 'Run `agy login` in a normal terminal' "$PY/agy-turn.py" \
  && pass "the remedy an operator needs is still printed" \
  || fail "the 'agy login' remedy is missing from the failure path"

exit 0
