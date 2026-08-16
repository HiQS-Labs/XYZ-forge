#!/usr/bin/env bash
# GH-408 (+ GH-409 Phase 1) — a failed `tick claim` must be BOTH detectable and readable.
#
# The 2026-08-07 incident this encodes: an agent sat at its claim cap, `tick claim` printed
# `lost: claim limit reached (holding T-cite, T-offlane)` and exited 0, and every caller sent
# that line to DEVNULL. Three layers each had the answer and each threw it away, so the turn
# died with a message pointing at `tick info <task>` — which shows a perfectly healthy token
# and therefore argues against the real cause.
#
# Two independent belts, and this file asserts both, because either one alone still loses:
#   (1) EXIT STATUS   — `tick claim` fails non-zero when it does not acquire the claim, so a
#                       caller that only checks `$?` is correct.
#   (2) OUTPUT        — the callers stop discarding tick's own message, so a caller that only
#                       reads the output is also correct.
#
# Covered call sites, per the GH-409 capture doc's acceptance item 4 ("both sites, or the fix is
# partial by construction"):
#   • utils/py/rtl.py       :: claim_task_or_exit  — on EVERY turn's path (the expensive one)
#   • utils/py/marathon_drive.py :: run_tick_loud  — the site #408 actually names
#
# The Bash twins under relay-automation/ are FROZEN (GH-308) and are deliberately NOT asserted
# here: Python is authoritative, and changing them is what the twin guard exists to block.
#
# Usage: bash test/gh408-tick-failure-visibility.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh408-tick-failure-visibility

PY="${PYTHON:-python3}"
export PYTHONPATH="$ROOT/utils/py${PYTHONPATH:+:$PYTHONPATH}"

# ---------------------------------------------------------------------------
# Belt 1 — `tick claim` exit status
# ---------------------------------------------------------------------------
echo "-- belt 1: tick claim exit status"

tick_a log task.created T-one --agent seed >/dev/null
tick_a log task.created T-two --agent seed >/dev/null
tick_a log task.created T-three --agent seed >/dev/null

out="$(tick_a claim T-one --agent agy --paths 'a.txt' 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && [[ "$out" == won:* ]]; then
  pass "a won claim exits 0 ($out)"
else
  fail "a won claim must exit 0 and print 'won:' — rc=$rc out=$out"
fi

# Idempotent re-claim by the SAME agent is a win, not a loss. This is the assertion that stops a
# naive "any non-'won' output is an error" fix from breaking every shim: the shims claim
# unconditionally on a token they may already hold, so a non-zero here would fail healthy turns.
out="$(tick_a claim T-one --agent agy --paths 'a.txt' 2>&1)"; rc=$?
if [ "$rc" -eq 0 ]; then
  pass "an idempotent re-claim by the holder still exits 0"
else
  fail "re-claiming a task you already hold must exit 0 — rc=$rc out=$out"
fi

out="$(tick_a claim T-two --agent agy --paths 'b.txt' 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "second claim (still under the cap of 2) must exit 0 — rc=$rc out=$out"
pass "second claim, still under the cap, exits 0"

# The incident itself: at the cap, on the third claim.
out="$(tick_a claim T-three --agent agy --paths 'c.txt' 2>&1)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "a cap-blocked claim exits non-zero (rc=$rc)"
else
  fail "GH-408: a cap-blocked claim exited 0 — no caller can detect it by status. out=$out"
fi
case "$out" in
  *"claim limit reached"*) pass "the cap-hit message says 'claim limit reached'" ;;
  *) fail "cap-hit output must say 'claim limit reached' — got: $out" ;;
esac
if [[ "$out" == *T-one* && "$out" == *T-two* ]]; then
  pass "the cap-hit message names BOTH held tasks (T-one, T-two)"
else
  fail "cap-hit output must name the held tasks so the operator knows what to release — got: $out"
fi

out="$(tick_a claim T-one --agent codex --paths 'a.txt' 2>&1)"; rc=$?
if [ "$rc" -ne 0 ] && [[ "$out" == *"already claimed by agy"* ]]; then
  pass "a claim lost to another owner exits non-zero and names the owner"
else
  fail "losing to another owner must exit non-zero and name it — rc=$rc out=$out"
fi

tick_a release T-one --agent agy >/dev/null
tick_a done T-one --agent agy >/dev/null 2>&1 || tick_a claim T-one --agent agy --paths 'a.txt' >/dev/null 2>&1
tick_a done T-one --agent agy >/dev/null 2>&1
out="$(tick_a claim T-one --agent codex --paths 'a.txt' 2>&1)"; rc=$?
if [ "$rc" -ne 0 ]; then
  pass "a claim on a spent (terminal) task exits non-zero"
else
  fail "a spent task must not be claimable with exit 0 — rc=$rc out=$out"
fi
case "$out" in
  *"fresh per-relay id"*) pass "the spent-task message keeps its GH-18 remedy pointer" ;;
  *) fail "the spent-task remedy hint was lost — got: $out" ;;
esac

# A usage error is a DIFFERENT failure from a lost claim, and stays 2. Without this, "make it
# non-zero" quietly collapses two causes into one status and the next debugger cannot tell a
# missing --paths from a busy agent.
tick_a claim T-two --agent agy >/dev/null 2>&1; rc=$?
if [ "$rc" -eq 2 ]; then
  pass "a usage error still exits 2, distinct from a lost claim"
else
  fail "usage errors must stay exit 2 — got rc=$rc"
fi

# ---------------------------------------------------------------------------
# Belt 2 — rtl.claim_task_or_exit surfaces the cause (utils/py/rtl.py)
# ---------------------------------------------------------------------------
echo "-- belt 2: rtl.claim_task_or_exit (every turn's path)"

# Fresh coordination root so the cap state is exactly what this case builds.
C="$WORK/rtl-case"
git init -q "$C"
git -C "$C" config user.email c@t
git -C "$C" config user.name c
: >"$C/relay.md"
git -C "$C" add relay.md
git -C "$C" commit -q -m init

tick_in "$C" log task.created H-one --agent seed >/dev/null
tick_in "$C" log task.created H-two --agent seed >/dev/null
tick_in "$C" log task.created TURN-3 --agent seed >/dev/null
tick_in "$C" claim H-one --agent agy --paths 'x' >/dev/null 2>&1
tick_in "$C" claim H-two --agent agy --paths 'y' >/dev/null 2>&1

# TURN-3 is handed off to agy and looks perfectly healthy — `tick info TURN-3` reports
# status: open, handoff-to: agy. That is precisely the trap: the old message told the operator to
# inspect a token that is fine, while the real cause is the cap two phases earlier.
tick_in "$C" release TURN-3 --agent seed --to agy >/dev/null 2>&1 || true

set +e
TICK_REPO_ROOT="$C" XYZ_ROOT="$ROOT" "$PY" - "$C" "$ROOT" <<'PYEOF' >"$WORK/rtl.out" 2>"$WORK/rtl.err"
import sys
sys.path.insert(0, sys.argv[2] + "/utils/py")
import rtl
rtl.claim_task_or_exit(sys.argv[1], sys.argv[2], sys.argv[1] + "/relay.md", "", "TURN-3", "agy", "agy-turn")
PYEOF
rtl_rc=$?
set -e
rtl_err="$(cat "$WORK/rtl.err")"

if [ "$rtl_rc" -eq 5 ]; then
  pass "claim_task_or_exit still refuses to run the turn (exit 5)"
else
  fail "claim_task_or_exit must exit 5 when it cannot own the token — got rc=$rtl_rc; stderr: $rtl_err"
fi

case "$rtl_err" in
  *"claim limit reached"*)
    pass "GH-408: tick's own cap message now reaches the operator's stderr" ;;
  *)
    fail "GH-408: the 'claim limit reached' line was discarded — stderr was: $rtl_err" ;;
esac

if [[ "$rtl_err" == *H-one* && "$rtl_err" == *H-two* ]]; then
  pass "the surfaced message names the held tasks (H-one, H-two)"
else
  fail "the surfaced message must name what is held — stderr: $rtl_err"
fi

# Acceptance item 5: do not hand the operator a diagnostic that contradicts the cause. On a cap hit
# `tick info TURN-3` reports a healthy token, so SUGGESTING it sends the investigation the wrong way.
#
# The assertion is "does not suggest it", not "does not mention it", and the difference is the point.
# The first draft of this test banned the substring outright and failed the fix — which had gone
# further than the acceptance item asked, naming `tick info` explicitly as the WRONG instrument.
# Staying silent about it would be weaker: running `tick info` on the named task is exactly what an
# operator does next by reflex, so the healthy-looking output is met either way. Better to inoculate
# against it than to omit it and let it be discovered.
if [[ "$rtl_err" == *"inspect \`tick info"* ]]; then
  fail "a cap hit must not tell the operator to INSPECT 'tick info' — that token is healthy. stderr: $rtl_err"
else
  pass "the cap-hit path does not send the operator to the contradicting 'tick info' diagnostic"
fi
if [[ "$rtl_err" == *"tick info TURN-3"* ]]; then
  case "$rtl_err" in
    *"wrong instrument"*|*"will look healthy"*)
      pass "where it does name 'tick info', it marks it as the wrong instrument" ;;
    *)
      fail "'tick info' is named without warning that it misleads here — stderr: $rtl_err" ;;
  esac
fi
case "$rtl_err" in
  *"tick reap agy"*) pass "the cap-hit path names the remedy that actually applies (tick reap)" ;;
  *) fail "a cap hit must point at the remedy for a cap hit — stderr: $rtl_err" ;;
esac

# The other-owner branch must KEEP the old message: `tick info` is the right instrument there.
tick_in "$C" log task.created OWNED --agent seed >/dev/null
tick_in "$C" claim OWNED --agent codex --paths 'z' >/dev/null 2>&1
set +e
TICK_REPO_ROOT="$C" XYZ_ROOT="$ROOT" "$PY" - "$C" "$ROOT" <<'PYEOF' >/dev/null 2>"$WORK/rtl2.err"
import sys
sys.path.insert(0, sys.argv[2] + "/utils/py")
import rtl
rtl.claim_task_or_exit(sys.argv[1], sys.argv[2], sys.argv[1] + "/relay.md", "", "OWNED", "pi", "pi-turn")
PYEOF
rtl2_rc=$?
set -e
rtl2_err="$(cat "$WORK/rtl2.err")"
if [ "$rtl2_rc" -eq 5 ] && [[ "$rtl2_err" == *"tick info OWNED"* ]]; then
  pass "the other-owner branch still points at 'tick info', which is correct there"
else
  fail "the other-owner branch must keep its 'tick info' hint — rc=$rtl2_rc stderr: $rtl2_err"
fi
if [[ "$rtl2_err" == *"claim limit"* ]]; then
  fail "an other-owner failure must NOT be described as a cap hit — stderr: $rtl2_err"
else
  pass "an other-owner failure is not mislabelled as a cap hit"
fi

# ---------------------------------------------------------------------------
# Belt 3 — marathon_drive.run_tick_loud (the site #408 names)
# ---------------------------------------------------------------------------
echo "-- belt 3: marathon_drive.run_tick_loud"

set +e
"$PY" - "$ROOT" <<'PYEOF' >"$WORK/loud.out" 2>"$WORK/loud.err"
import sys
sys.path.insert(0, sys.argv[1] + "/utils/py")
import marathon_drive
# A command that fails with a message on BOTH streams. run_tick_loud's whole job is to be loud:
# it exits on the failure, so the message it is exiting on has to have been shown first.
marathon_drive.run_tick_loud(
    [sys.executable, "-c",
     "import sys; sys.stdout.write('lost: claim limit reached (holding T-a, T-b)\\n');"
     "sys.stderr.write('tick: boom\\n'); sys.exit(3)"])
PYEOF
loud_rc=$?
set -e
loud_all="$(cat "$WORK/loud.out" "$WORK/loud.err")"

if [ "$loud_rc" -eq 3 ]; then
  pass "run_tick_loud still propagates the tool's own exit code (3)"
else
  fail "run_tick_loud must exit with the failed command's code — got $loud_rc"
fi
case "$loud_all" in
  *"claim limit reached"*) pass "GH-408: run_tick_loud no longer discards stdout" ;;
  *) fail "GH-408: run_tick_loud discarded the failure's stdout — captured: $loud_all" ;;
esac
case "$loud_all" in
  *"tick: boom"*) pass "GH-408: run_tick_loud no longer discards stderr" ;;
  *) fail "GH-408: run_tick_loud discarded the failure's stderr — captured: $loud_all" ;;
esac

# Not just "it prints on failure": a SUCCEEDING tick call must stay quiet, or every marathon
# phase gains four lines of token bookkeeping noise and operators stop reading the log.
set +e
"$PY" - "$ROOT" <<'PYEOF' >"$WORK/quiet.out" 2>"$WORK/quiet.err"
import sys
sys.path.insert(0, sys.argv[1] + "/utils/py")
import marathon_drive
marathon_drive.run_tick_loud(
    [sys.executable, "-c", "import sys; sys.stdout.write('won: T claimed\\n')"])
PYEOF
quiet_rc=$?
set -e
if [ "$quiet_rc" -eq 0 ] && [ ! -s "$WORK/quiet.out" ] && [ ! -s "$WORK/quiet.err" ]; then
  pass "a successful tick call stays silent (no new per-phase log noise)"
else
  fail "run_tick_loud must stay quiet on success — rc=$quiet_rc out=$(cat "$WORK/quiet.out") err=$(cat "$WORK/quiet.err")"
fi

echo
echo "  $TEST_NAME: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
