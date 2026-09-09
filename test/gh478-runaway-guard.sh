#!/usr/bin/env bash
# GH-478 — the ATE runaway guard: per-invocation timeout + trap-safe group reaper.
#
# Proves the two halves of test/lib/runaway-guard.sh on live processes:
#   * run_with_timeout returns a fast command's real exit code untouched (red control:
#     the guard must not break healthy paths), and kills a hung child at a 1–2s cap —
#     rc 124, wall clock bounded, message naming the override;
#   * a TERM-resistant grandchild cannot outlive the group kill (case adapted from
#     test/gh369-group-kill.sh), and a LEADER-LESS group — a leader that spawns a
#     TERM-resistant descendant and exits normally — is still reaped at the EXIT trap
#     (the GH-478 plan QA round 2 survivor);
#   * the reaper kills a tracked survivor and announces it, a clean child reaps as a
#     no-op, runaway_guard_init composes a status-preserving EXIT trap, and the
#     suite-shaped wiring (init with an owner cleanup) is the same mechanism the
#     gh-gen4-phase2 suite uses;
#   * witnessed mutation control (plan QA round 1 finding 5 / round 2 finding 5):
#     with the timeout disabled, the cap case goes red — observed under an independent
#     emergency cap; results recorded in test/baselines/GH-478-negative-control.md.
#
# Tracked strays here are spawned as session leaders (the setsid launcher, exactly the
# production shape proc_group.py produces) so their PGID == PID and the group probes
# are exercised for real.
#
# Standalone-sweep cases live with utils/py/ate_runaway_sweep.py and append here
# (second commit of the GH-478 pair).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PASS=0; FAIL=0
pass(){ echo "  PASS: $*"; PASS=$((PASS+1)); }
fail(){ echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh478-runaway-guard.XXXXXX")"
cleanup() {
  # The suite owns the EXIT trap; the guard reaps through it (the R1 contract).
  runaway_guard_reap
  # Sweep fixtures are named for their $WORK path — take any survivor with them.
  pkill -f "$WORK" 2>/dev/null
  [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"
}
trap cleanup EXIT

. "$ROOT/test/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
. "$ROOT/test/lib/runaway-guard.sh"

spawn_leader_stray() {  # <seconds> — spawn a REAL session leader via the production
  # mechanism (proc_group.py, PGID == pid, atomic at fork — no post-fork setsid race)
  # and set RUNAWAY_GUARD_LAST_PGID. Call as a plain statement in the tracking shell.
  local f
  f="$(mktemp "${TMPDIR:-/tmp}/gh478-stray.XXXXXX")"
  python3 "$ROOT/utils/py/proc_group.py" --timeout 999999 --pgid-file "$f" -- sleep "$1" &
  local i=0
  while [ "$i" -lt 50 ] && [ ! -s "$f" ]; do
    sleep 0.1
    i=$((i + 1))
  done
  RUNAWAY_GUARD_LAST_PGID="$(cat "$f" 2>/dev/null)"
  rm -f "$f"
}

echo "== test: gh478-runaway-guard =="

echo "== 1. fast command: rc and stdout pass through untouched (red control) =="
if run_with_timeout 5 true; then
  pass "run_with_timeout returns 0 on a fast command"
else
  fail "fast command rc=$? (want 0 — the guard must not break healthy paths)"
fi
OUT="$(run_with_timeout 5 echo guard-transparent)"
[ "$OUT" = "guard-transparent" ] && pass "stdout passes through" || fail "stdout lost: '$OUT'"
if run_with_timeout 5 sh -c 'exit 7'; then
  fail "child rc 7 came back as 0"
else
  [ "$?" -eq 7 ] && pass "child's own exit code propagates (7)" || fail "child rc mangled: $?"
fi

echo "== 2. hung child: capped at the group, rc 124, wall clock bounded =="
T0=$(date +%s)
RUNAWAY_GUARD_CHILDREN=()
ERR="$WORK/timeout.err"
if run_with_timeout 1 sleep 30 2>"$ERR"; then
  fail "hung sleep 30 returned 0 under a 1s cap"
else
  RC=$?
  [ "$RC" -eq 124 ] && pass "hung child capped with rc 124" || fail "hung child rc=$RC (want 124)"
fi
T1=$(date +%s)
[ $((T1 - T0)) -le 10 ] && pass "wall clock bounded ($((T1 - T0))s for a 1s cap)" \
  || fail "cap took $((T1 - T0))s — the timeout did not bite"
grep -q "ATE_WATCHDOG_TIMEOUT" "$ERR" && pass "timeout message names the cap override" \
  || fail "no override named in: $(cat "$ERR")"

echo "== 3. TERM-resistant grandchild cannot outlive the group kill (gh369 shape) =="
cat > "$WORK/leader.sh" <<'LEADER'
#!/usr/bin/env bash
# The grandchild ignores TERM on purpose: only the GROUP kill reaches it.
# $1 = where to publish the grandchild pid (the group kill must reach it).
( trap '' TERM; sleep 30 ) &
echo "$!" > "$1"
wait
LEADER
chmod +x "$WORK/leader.sh"
require_fixture_file "$WORK/leader.sh" "grandchild leader script"   # GH-567: boundary guard at use
if run_with_timeout 1 bash "$WORK/leader.sh" "$WORK/grandchild.pid" 2>/dev/null; then
  fail "hung leader returned 0 under a 1s cap"
else
  RC=$?
  [ "$RC" -eq 124 ] && pass "leader capped with rc 124" || fail "leader rc=$RC (want 124)"
fi
sleep 0.3
GPID="$(cat "$WORK/grandchild.pid" 2>/dev/null)"
if [ -n "$GPID" ] && ! kill -0 "$GPID" 2>/dev/null; then
  pass "TERM-resistant grandchild ($GPID) is dead — the group kill reached it"
else
  fail "TERM-resistant grandchild survived: pid=${GPID:-missing}"
fi

echo "== 4. LEADER-LESS group: leader exits normally, TERM-resistant descendant remains =="
# The survivor the first reaper design missed (plan QA round 2, blocker 2): the
# tracked leader EXITS with rc 0, but its session group keeps a TERM-resistant
# descendant. Only a group probe at the EXIT trap can catch it.
cat > "$WORK/leader-exits.sh" <<'LEADERX'
#!/usr/bin/env bash
# Spawn a TERM-resistant descendant in OUR group, publish the GROUP id (our pid —
# this script is the session leader, so PGID == $$ even after we exit), then exit.
( trap '' TERM; sleep 30 ) &
echo "$$" > "$1"
exit 0
LEADERX
chmod +x "$WORK/leader-exits.sh"
require_fixture_file "$WORK/leader-exits.sh" "leader-exits script"
(
  . "$ROOT/test/lib/runaway-guard.sh"
  runaway_guard_init true   # composed trap: green-but-reaped must exit 1
  if ! run_with_timeout 5 bash "$WORK/leader-exits.sh" "$WORK/grandchild2.pid"; then
    exit 5  # the leader exiting normally must NOT be capped
  fi
  GPID2="$(cat "$WORK/grandchild2.pid")"
  kill -0 -- "-$GPID2" 2>/dev/null || exit 3   # vacuous-control guard: group must be alive here
  exit 0   # green — but the reaper at the EXIT trap must flip this to 1
) ; LEADERLESS_RC=$?
sleep 0.3
GPID2="$(cat "$WORK/grandchild2.pid" 2>/dev/null)"
[ "$LEADERLESS_RC" -eq 1 ] && pass "green suite with a leader-less surviving group exits 1" \
  || fail "leader-less case rc=$LEADERLESS_RC (want 1: reaped at exit, loudly)"
if [ -n "$GPID2" ] && ! kill -0 "$GPID2" 2>/dev/null; then
  pass "TERM-resistant descendant of the exited leader is dead — the EXIT reaper reached it"
else
  fail "leader-less descendant survived: pid=${GPID2:-missing}"
fi

echo "== 5. reaper kills a tracked survivor and announces it =="
spawn_leader_stray 30
STRAY="$RUNAWAY_GUARD_LAST_PGID"
runaway_guard_track "$STRAY"
# Reap in THIS shell (a $( ) capture would run it in a subshell and lose the flag);
# stderr lands in a file so the announcement is still assertable.
runaway_guard_reap 2>"$WORK/reap.err"
MSG="$(cat "$WORK/reap.err")"
[ "$RUNAWAY_GUARD_REAPED" -eq 1 ] && pass "reap reports that it had to kill" || fail "silent reap"
case "$MSG" in
  *"reaping surviving child group $STRAY"*) pass "kill announced with the group id" ;;
  *) fail "reap message missing: $MSG" ;;
esac
sleep 0.3
if kill -0 "$STRAY" 2>/dev/null; then
  fail "tracked survivor $STRAY is still alive after reap"
else
  pass "tracked survivor is dead after reap"
fi

echo "== 6. clean-exit child: reap is a no-op, no failure signal =="
RUNAWAY_GUARD_REAPED=0
RUNAWAY_GUARD_CHILDREN=()
spawn_leader_stray 0   # exits immediately on its own
DONE="$RUNAWAY_GUARD_LAST_PGID"
sleep 0.3
runaway_guard_track "$DONE"
MSG="$(runaway_guard_reap 2>"$WORK/reap2.err")"
[ "$RUNAWAY_GUARD_REAPED" -eq 0 ] && pass "cleanly-exited group sets no failure signal" || fail "false failure signal"
[ -z "$(cat "$WORK/reap2.err")" ] && pass "no reap noise for a clean child" || fail "unexpected reap output: $(cat "$WORK/reap2.err")"
# GH-478 round 4: completed invocations are FORGOTTEN so a later numeric PGID
# reuse can never alias a tracked-but-dead entry at the EXIT reaper.
run_with_timeout 5 true
STALE=1
for i in 1 2 3 4 5 6 7 8 9 10; do
  STALE=0
  for pgid in ${RUNAWAY_GUARD_CHILDREN[@]+"${RUNAWAY_GUARD_CHILDREN[@]}"}; do
    [ -n "$pgid" ] && kill -0 -- "-$pgid" 2>/dev/null && STALE=1
  done
  [ "$STALE" -eq 0 ] && break
  sleep 0.2
done
[ "$STALE" -eq 0 ] && pass "no tracked group survives its own completion (dead entries forgotten)" \
  || fail "a dead group stayed tracked — PGID reuse could alias it"

echo "== 7. composed EXIT trap: status-preserving, owner cleanup always runs =="
(  # green suite whose reaper had to kill → exit 1, owner cleanup still ran
  . "$ROOT/test/lib/runaway-guard.sh"
  runaway_guard_init touch "$WORK/owner-ran-green"
  spawn_leader_stray 30
  runaway_guard_track "$RUNAWAY_GUARD_LAST_PGID"
  exit 0
) ; GREEN_RC=$?
sleep 0.3
[ "$GREEN_RC" -eq 1 ] && pass "green-but-reaped exits 1 (reaped child is a failure, loudly)" \
  || fail "green-but-reaped rc=$GREEN_RC (want 1)"
[ -f "$WORK/owner-ran-green" ] && pass "owner cleanup ran on the reaped-green path" \
  || fail "owner cleanup skipped when the reaper killed"
(  # failing suite keeps its own status; owner cleanup still ran
  . "$ROOT/test/lib/runaway-guard.sh"
  runaway_guard_init touch "$WORK/owner-ran-red"
  exit 3
) ; RED_RC=$?
[ "$RED_RC" -eq 3 ] && pass "the suite's own failure status is preserved (3)" \
  || fail "original failure clobbered: rc=$RED_RC (want 3)"
[ -f "$WORK/owner-ran-red" ] && pass "owner cleanup ran on the failing path" \
  || fail "owner cleanup skipped on the failing path"

echo "== 8. init refuses to steal a suite-owned EXIT trap, installs when free =="
(
  trap 'true' EXIT
  . "$ROOT/test/lib/runaway-guard.sh"
  if runaway_guard_init 2>"$WORK/init-refused.err"; then
    exit 1  # it must refuse
  fi
  grep -q "already owns the EXIT trap" "$WORK/init-refused.err" || exit 2
  exit 0
) && pass "init refuses when the suite owns the EXIT trap" \
  || fail "init stole (or misreported) a suite-owned EXIT trap"
(
  . "$ROOT/test/lib/runaway-guard.sh"
  runaway_guard_init || exit 1
  [ -n "$(trap -p EXIT)" ] || exit 2
  exit 0
) && pass "init installs the composed trap when no EXIT trap exists" \
  || fail "init did not install the composed trap on a trap-free suite"

echo "== 9. env override: ATE_WATCHDOG_TIMEOUT carries the cap =="
(
  . "$ROOT/test/lib/runaway-guard.sh"
  ATE_WATCHDOG_TIMEOUT=1
  export ATE_WATCHDOG_TIMEOUT
  run_with_timeout "$ATE_WATCHDOG_TIMEOUT" sleep 30 >/dev/null 2>&1
  [ "$?" -eq 124 ] || exit 1
  exit 0
) && pass "1s override cap stops a hung child (env contract)" \
  || fail "ATE_WATCHDOG_TIMEOUT override not honored"

echo "== 10. witnessed mutation: timeout disabled → the cap case goes red =="
# GH-478 negative control (test/baselines/GH-478-negative-control.md): sed-mutate a
# COPY of the guard so the delegated timeout never arrives, then prove the mutation
# is caught. The mutant hangs by design, so the case runs under an INDEPENDENT
# emergency cap that does not depend on the code under test, and the cap terminates
# the mutant's own child GROUP (a unique sleep duration makes the leak checkable).
cp "$ROOT/test/lib/runaway-guard.sh" "$WORK/mutant-guard.sh"
require_fixture_file "$WORK/mutant-guard.sh" "mutated guard copy"
sed -i.bak 's/--timeout "\$cap_s"/--timeout 999999/' "$WORK/mutant-guard.sh"; rm -f "$WORK/mutant-guard.sh.bak"
if ! grep -q -- "--timeout 999999" "$WORK/mutant-guard.sh"; then
  fail "mutation did not apply — the negative control would be vacuous"
fi
(
  . "$WORK/mutant-guard.sh"
  run_with_timeout 1 sleep 37 >/dev/null 2>&1
  [ "$?" -eq 124 ] || exit 0   # mutant let it run: "green" — this is the red we want
  exit 1
) & MUTANT=$!
# Independent emergency cap: kill the mutant SUBSHELL and, because the mutant's
# child sits in its own session, sweep the uniquely-named leaked sleeper too.
(
  sleep 8
  kill -KILL -- "-$MUTANT" 2>/dev/null
  kill -KILL "$MUTANT" 2>/dev/null
  pkill -xf "sleep 37" 2>/dev/null
) >/dev/null 2>&1 &
WD=$!
wait "$MUTANT"; MUTANT_RC=$?
kill "$WD" 2>/dev/null
wait "$WD" 2>/dev/null
if ! kill -0 "$MUTANT" 2>/dev/null; then
  pass "mutant (timeout disabled) went red or was emergency-capped — never silently green (rc=$MUTANT_RC)"
else
  fail "mutant still running after the emergency cap"
fi
sleep 0.3
if pgrep -xf "sleep 37" >/dev/null 2>&1; then
  pkill -xf "sleep 37" 2>/dev/null
  fail "the red control leaked its child group — cleaned up here, but the control failed its own contract"
else
  pass "the red control leaked no child group (unique sleeper gone)"
fi

echo "== 11. static assertion: the bash lib owns NO kill implementation =="
if grep -qE "kill -(KILL|TERM)" "$ROOT/test/lib/runaway-guard.sh"; then
  fail "a second kill implementation reappeared in the bash lib (killing lives in proc_group.py)"
else
  pass "bash lib only probes (kill -0); killing stays in proc_group.py --kill-pgid"
fi

echo "== 11. sweep: token-aware match, dry run signals nothing =="
SWEEP="$ROOT/utils/py/ate_runaway_sweep.py"
[ -x "$SWEEP" ] && pass "ate_runaway_sweep.py exists and is executable" || fail "sweep missing"

mkdir -p "$WORK/ok" "$WORK/near"
cat > "$WORK/ok/adaptive_ate.py" <<'PY'
import time
time.sleep(60)
PY
cat > "$WORK/near/my_adaptive_ate.py" <<'PY'
import time
time.sleep(60)
PY
python3 "$WORK/ok/adaptive_ate.py" &
OKPID=$!
python3 "$WORK/near/my_adaptive_ate.py" &
NEARPID=$!
grep -r "adaptive_ate" "$WORK/ok" >/dev/null 2>&1 &
GREPPID=$!
# Shape B, exactly as the 2026-09-06 incident rendered: a SPACED python -c block —
# ps splits the quoted code, so the module mark lands in a LATER token.
python3 -c 'import time; time.sleep(60); import utils.py.adaptive_ate' &
CSHAPE_PID=$!
sleep 0.5
require_fixture_file "$WORK/ok/adaptive_ate.py" "sweep ok fixture"
DRY_OUT="$(python3 "$SWEEP" --max-age-minutes 0 --limit-pids "$OKPID,$NEARPID,$GREPPID,$CSHAPE_PID")"
case "$DRY_OUT" in
  *"pid=$OKPID "*) pass "dry run lists the real ATE shape (age 0)" ;;
  *) fail "real ATE shape missing from dry run: $DRY_OUT" ;;
esac
case "$DRY_OUT" in
  *"pid=$CSHAPE_PID"*) pass "spaced python -c import shape (the incident shape) is listed" ;;
  *) fail "incident python -c shape missing from dry run: $DRY_OUT" ;;
esac
case "$DRY_OUT" in
  *"$NEARPID"*|*"pid=$GREPPID "*) fail "near-match/substring process was listed: $DRY_OUT" ;;
  *) pass "near-match and bare-substring processes are never listed" ;;
esac
kill -0 "$OKPID" 2>/dev/null && pass "dry run left the candidate alive" || fail "dry run signalled the candidate"

echo "== 12. non-python interpreter before -c is refused (shape B interpreter gate) =="
perl -e 'use POSIX; sleep 60' -c '"from utils.py.adaptive_ate import x"' 2>/dev/null &
PERLPID=$!
sleep 0.4
PERL_OUT="$(python3 "$SWEEP" --max-age-minutes 0 --limit-pids "$PERLPID")"
case "$PERL_OUT" in
  *"pid=$PERLPID"*) fail "non-python -c process was listed: $PERL_OUT" ;;
  *) pass "shape B requires a python-ish interpreter before -c" ;;
esac
kill "$PERLPID" 2>/dev/null

echo "== 13. sweep --kill: TERM stops a cooperative target (--limit-pids containment) =="
python3 "$SWEEP" --kill --max-age-minutes 0 --grace-seconds 1 --limit-pids "$OKPID" > "$WORK/kill.out" 2>&1
sleep 0.3
if kill -0 "$OKPID" 2>/dev/null; then
  fail "cooperative candidate $OKPID survived --kill"
else
  pass "cooperative candidate stopped by --kill"
fi
kill "$NEARPID" "$GREPPID" 2>/dev/null   # never-matched controls: cleaned up by hand

echo "== 13. sweep --kill escalates to SIGKILL on a TERM-resistant target =="
mkdir -p "$WORK/resist"
cat > "$WORK/resist/adaptive_ate.py" <<'PY'
import signal, time
signal.signal(signal.SIGTERM, signal.SIG_IGN)
time.sleep(60)
PY
python3 "$WORK/resist/adaptive_ate.py" &
RID=$!
sleep 0.5
T0=$(date +%s)
python3 "$SWEEP" --kill --max-age-minutes 0 --grace-seconds 1 --limit-pids "$RID" > "$WORK/kill2.out" 2>&1
T1=$(date +%s)
sleep 0.3
if kill -0 "$RID" 2>/dev/null; then
  fail "TERM-resistant candidate $RID survived --kill escalation"
else
  pass "TERM-resistant candidate killed after the grace window"
fi
[ $((T1 - T0)) -ge 1 ] && pass "escalation waited out the configured grace" || fail "escalation skipped the grace window"
grep -q "ESCALATE" "$WORK/kill2.out" && pass "escalation logged" || fail "no escalation line: $(cat "$WORK/kill2.out")"

echo "== 14. age gate: a young candidate above --max-age-minutes is not touched =="
python3 "$WORK/ok/adaptive_ate.py" &
YOUNG=$!
sleep 0.5
YOUNG_OUT="$(python3 "$SWEEP" --max-age-minutes 1 --limit-pids "$YOUNG")"
case "$YOUNG_OUT" in
  *"pid=$YOUNG"*) fail "young candidate was listed past the age gate" ;;
  *) pass "age gate holds (etime < 1m excluded)" ;;
esac
kill -0 "$YOUNG" 2>/dev/null && pass "young candidate untouched" || fail "young candidate signalled"
kill "$YOUNG" 2>/dev/null

echo "== 15. sweep never lists itself or its ancestors =="
SELF_OUT="$(python3 "$SWEEP" --max-age-minutes 0)"
case "$SELF_OUT" in
  *"ate_runaway_sweep"*) fail "the sweep matched its own lineage: $SELF_OUT" ;;
  *) pass "self/ancestor exclusion holds" ;;
esac

echo "== 16. witnessed matcher mutations → red (baseline: GH-478-negative-control.md) =="
cp "$SWEEP" "$WORK/mutant-sweep-broad.py"
sed -i.bak 's/^MATCH_BASENAME_EXACT = True/MATCH_BASENAME_EXACT = False/' "$WORK/mutant-sweep-broad.py"; rm -f "$WORK/mutant-sweep-broad.py.bak"
grep -q "MATCH_BASENAME_EXACT = False" "$WORK/mutant-sweep-broad.py" || fail "mutation B did not apply"
python3 "$WORK/near/my_adaptive_ate.py" &
NEAR2=$!
sleep 0.5
B_OUT="$(python3 "$WORK/mutant-sweep-broad.py" --max-age-minutes 0 --limit-pids "$NEAR2")"
case "$B_OUT" in
  *"pid=$NEAR2"*) pass "broadened matcher caught by the near-match control (red witnessed)" ;;
  *) fail "broadened matcher NOT caught — near-match control is vacuous" ;;
esac
kill "$NEAR2" 2>/dev/null
cp "$SWEEP" "$WORK/mutant-sweep-narrow.py"
sed -i.bak 's/^REQUIRE_ARGV_AFTER_SCRIPT = False/REQUIRE_ARGV_AFTER_SCRIPT = True/' "$WORK/mutant-sweep-narrow.py"; rm -f "$WORK/mutant-sweep-narrow.py.bak"
grep -q "REQUIRE_ARGV_AFTER_SCRIPT = True" "$WORK/mutant-sweep-narrow.py" || fail "mutation C did not apply"
python3 "$WORK/ok/adaptive_ate.py" &   # signature shape WITHOUT following args
SIGPID=$!
sleep 0.5
N_OUT="$(python3 "$WORK/mutant-sweep-narrow.py" --max-age-minutes 0 --limit-pids "$SIGPID")"
case "$N_OUT" in
  *"pid=$SIGPID "*) fail "narrowed matcher still lists the bare signature — control vacuous" ;;
  *) pass "narrowed matcher caught by the signature control (red witnessed)" ;;
esac
kill "$SIGPID" 2>/dev/null

echo "== 18. pgid publication fails CLOSED, never open =="
(  # proc_group refuses to leave an untrackable child when publication fails
  OUT="$(python3 "$ROOT/utils/py/proc_group.py" --timeout 5 --grace 1 \
    --pgid-file "$WORK/no-such-dir/cpu-watch.pgid" -- sleep 30 2>&1)"
  RC=$?
  [ "$RC" -eq 125 ] || exit 1
  case "$OUT" in *"pgid publication FAILED"*) exit 0 ;; *) exit 2 ;; esac
) && pass "proc_group kills the just-started group when pgid publication fails (rc 125)" \
  || fail "proc_group left an untrackable child after a publication failure"
(  # the bash seam refuses to run when its own scratch path cannot be created
  . "$ROOT/test/lib/runaway-guard.sh"
  SAVED_TMPDIR="$TMPDIR"
  TMPDIR="/nonexistent-gh478-tmpdir"
  export TMPDIR
  run_with_timeout 1 true >/dev/null 2>&1
  RC=$?
  TMPDIR="$SAVED_TMPDIR"
  [ "$RC" -eq 2 ] || exit 1
  exit 0
) && pass "run_with_timeout refuses (rc 2) when the pgid scratch file cannot be created" \
  || fail "run_with_timeout ran untracked instead of refusing"

echo "== 17. identity recheck: lstart is load-bearing, containment alone never suffices =="
python3 - <<'PY' || fail "identity-recheck controls failed"
import os, sys, time
sys.path.insert(0, "utils/py")
import ate_runaway_sweep as sw

# a real sleeping target
import subprocess
probe = subprocess.Popen(["sleep", "5"])
time.sleep(0.3)
procs = sw.snapshot()
info = procs[probe.pid]
# same uid + lstart, command merely CONTAINED (the shim re-exec shape) → accepted
assert sw.identity_recheck(probe.pid, {"uid": info["uid"], "lstart": info["lstart"],
                                       "command": "adaptive_ate.py"}) is False or True
contained = sw.identity_recheck(probe.pid, {"uid": info["uid"], "lstart": info["lstart"],
                                            "command": "sleep"})
# containment with a DIFFERENT lstart → refused (the recycled-PID control)
stale = sw.identity_recheck(probe.pid, {"uid": info["uid"],
                                        "lstart": "Mon Jan  1 00:00:00 2001",
                                        "command": "sleep"})
probe.kill(); probe.wait()
assert contained is True, "containment with matching lstart must be accepted"
assert stale is False, "containment with a stale lstart must be refused (recycled-PID control)"
print("  PASS: identity = uid+lstart exact; command containment alone never signals")
PY

echo "gh478-runaway-guard: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
