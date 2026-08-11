#!/usr/bin/env bash
# test/gh492-idle-kill.sh — GH-492.
#
# A turn that is idle by the EXISTING criteria (no CPU growth, no worktree progress) must be killed
# on a short idle threshold rather than only at the full wall cap. The incident this pins burned a
# 900s wall budget at cpu=0.02s/s with worktree-progress=no across 90 samples that were unanimous
# from the start.
#
# The negative control is the load-bearing half and criterion 5 names it explicitly: a turn that is
# SLOW BUT GENUINELY PROGRESSING must NOT be killed. Without it this suite cannot distinguish "the
# idle bound works" from "the harness became trigger-happy", and a trigger-happy bound is strictly
# worse than the hang — it kills good reviews.
#
# Hermetic: drives utils/py/turn_diagnostics.py directly against synthetic processes. No agy, no
# network, no paid turn.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PY_DIR="$ROOT/utils/py"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh492-idle.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: gh492-idle-kill =="
echo "  workdir: $WORK"

[ -f "$PY_DIR/turn_diagnostics.py" ] || { fail "missing turn_diagnostics.py"; echo "  gh492-idle-kill: $PASS pass, $FAIL fail"; exit 1; }

# ── (1) an idle tree accumulates idle_seconds; (2) CONTROL: a progressing tree does not ──────────
#
# Both scenarios run in ONE python process so they share a machine, a clock and a sampler
# implementation. Running them separately would let an unrelated load spike explain a difference
# between them.
IDLE_OUT="$WORK/idle.txt"
PYTHONPATH="$PY_DIR" python3 - "$WORK" > "$IDLE_OUT" 2>&1 <<'PYEOF'
import os, sys, time, subprocess
from turn_diagnostics import TurnDiagnostics, IDLE_MIN_SAMPLES, REASON_IDLE, REASON_SLOW_PROGRESS

work = sys.argv[1]
INTERVAL = 0.2

# ── scenario A: BLOCKED. `sleep` burns no CPU and writes nothing. This is the shape of the
# observed hang: alive, responsive to signals, doing nothing.
wt_a = os.path.join(work, "wt-a"); os.makedirs(wt_a, exist_ok=True)
open(os.path.join(wt_a, "seed.txt"), "w").write("seed\n")
proc_a = subprocess.Popen(["sleep", "30"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
diag_a = TurnDiagnostics(worktree=wt_a, interval=INTERVAL)
diag_a.start()

# ── scenario B: SLOW BUT PROGRESSING. Writes a file every interval and burns no meaningful CPU
# otherwise — deliberately the HARDEST negative control, because it is idle on the CPU axis and
# only the worktree axis distinguishes it. A bound that watched CPU alone would kill this.
wt_b = os.path.join(work, "wt-b"); os.makedirs(wt_b, exist_ok=True)
open(os.path.join(wt_b, "seed.txt"), "w").write("seed\n")
diag_b = TurnDiagnostics(worktree=wt_b, interval=INTERVAL)
diag_b.start()

deadline = time.monotonic() + 4.0
n = 0
while time.monotonic() < deadline:
    n += 1
    # touch a NEW file so _newest_mtime advances
    with open(os.path.join(wt_b, f"progress-{n}.txt"), "w") as f:
        f.write(str(n))
    time.sleep(INTERVAL)

diag_a.stop(); diag_b.stop()
try:
    proc_a.kill(); proc_a.wait(timeout=5)
except Exception:
    pass

idle_a = diag_a.idle_seconds()
idle_b = diag_b.idle_seconds()
reason_a, _ = diag_a.classify()
reason_b, _ = diag_b.classify()
print(f"SAMPLES_A={len(diag_a.samples)}")
print(f"SAMPLES_B={len(diag_b.samples)}")
print(f"IDLE_A={idle_a}")
print(f"IDLE_B={idle_b}")
print(f"REASON_A={reason_a}")
print(f"REASON_B={reason_b}")
print(f"MIN_SAMPLES={IDLE_MIN_SAMPLES}")
print(f"EXPECT_IDLE={REASON_IDLE}")
print(f"EXPECT_SLOW={REASON_SLOW_PROGRESS}")
PYEOF

if ! grep -q "^IDLE_A=" "$IDLE_OUT"; then
  fail "the diagnostics harness did not run: $(cat "$IDLE_OUT")"
  echo "  gh492-idle-kill: $PASS pass, $FAIL fail"; exit 1
fi

get() { grep "^$1=" "$IDLE_OUT" | head -1 | cut -d= -f2-; }
IDLE_A="$(get IDLE_A)"; IDLE_B="$(get IDLE_B)"
REASON_A="$(get REASON_A)"; REASON_B="$(get REASON_B)"
SAMPLES_A="$(get SAMPLES_A)"

# (1) enough samples were taken for idle_seconds() to answer at all
[ "${SAMPLES_A:-0}" -ge "$(get MIN_SAMPLES)" ] \
  && pass "the sampler collected enough readings for a verdict (samples=$SAMPLES_A)" \
  || fail "too few samples to test the idle bound (samples=$SAMPLES_A)"

# (2) THE PIN — a blocked tree reports real accumulated idle time
awk -v v="$IDLE_A" 'BEGIN{exit !(v+0 >= 1.0)}' 2>/dev/null \
  && pass "a blocked turn accumulates idle time (idle=${IDLE_A}s) — killable before the wall cap" \
  || fail "a blocked turn reported idle=${IDLE_A} — the idle bound would never fire"

# (3) THE CONTROL — a slow-but-progressing tree must stay near zero idle, so it is NOT killed
awk -v v="$IDLE_B" 'BEGIN{exit !(v+0 <= 1.0)}' 2>/dev/null \
  && pass "CONTROL: a slow-but-progressing turn stays un-idle (idle=${IDLE_B}s) — not killed" \
  || fail "CONTROL FAILED: a progressing turn reported idle=${IDLE_B}s — this bound is trigger-happy and would kill good reviews"

# (4) the two must be SEPARATED, not merely both present. A bound cannot act on a difference it
# cannot see, and equal values would mean the signal carries no information.
awk -v a="$IDLE_A" -v b="$IDLE_B" 'BEGIN{exit !(a+0 > b+0 + 0.5)}' 2>/dev/null \
  && pass "blocked and progressing are separated by the signal the bound acts on (${IDLE_A}s vs ${IDLE_B}s)" \
  || fail "blocked (${IDLE_A}s) and progressing (${IDLE_B}s) are not separated — the bound has nothing to act on"

# (5) GH-390's attribution must be UNCHANGED by the early kill: three causes, three verdicts.
[ "$REASON_A" = "$(get EXPECT_IDLE)" ] \
  && pass "the blocked turn still classifies as $REASON_A — GH-390 attribution preserved" \
  || fail "expected $(get EXPECT_IDLE) for the blocked turn, got $REASON_A"
[ "$REASON_B" = "$(get EXPECT_SLOW)" ] \
  && pass "the progressing turn still classifies as $REASON_B — not conflated with idle" \
  || fail "expected $(get EXPECT_SLOW) for the progressing turn, got $REASON_B"

# ── (6) idle_seconds() returns None before it has evidence, and None must never mean "kill" ──────
NONE_OUT="$WORK/none.txt"
PYTHONPATH="$PY_DIR" python3 - > "$NONE_OUT" 2>&1 <<'PYEOF'
from turn_diagnostics import TurnDiagnostics
d = TurnDiagnostics(worktree=None, interval=99)
print("FRESH=", d.idle_seconds())
PYEOF
grep -q "FRESH= None" "$NONE_OUT" \
  && pass "idle_seconds() is None before any sample — callers must read that as 'do not kill'" \
  || fail "expected None from a fresh sampler, got: $(cat "$NONE_OUT")"

# ── (7) the shim honours RELAY_TURN_IDLE_S=0 as 'disable', not as 'kill immediately' ─────────────
# An off-by-one here would kill every turn the instant sampling began, so it is asserted against
# the source rather than assumed from the default.
grep -q "if idle_cap > 0:" "$PY_DIR/agy-turn.py" \
  && pass "agy-turn guards the idle bound behind idle_cap > 0 (RELAY_TURN_IDLE_S=0 disables it)" \
  || fail "agy-turn does not guard the idle bound — RELAY_TURN_IDLE_S=0 would not disable it"
grep -q "_idle is not None and _idle >= idle_cap" "$PY_DIR/agy-turn.py" \
  && pass "agy-turn treats an unmeasured idle reading as not-killable" \
  || fail "agy-turn does not null-check the idle reading — an unmeasured turn could be killed"

# ── (8) CONSULT SCOPING — a busy advisor must not mask an idle one ──────────────────────────────
#
# This is the failure a consult would hit that a turn shim never does. A turn shim IS its process
# tree, so os.getpid() is the right CPU root. A consult launches every advisor as a SIBLING under one
# parent and runs them all in ONE shared worktree — so measuring the parent sums all advisors, and a
# fast codex answer would hold the whole tree's CPU above idle while agy hangs. That is exactly the
# 2026-08-10 shape: one advisor died, the other worked.
#
# Asserted both ways: correctly scoped (the advisor's own pid) sees the hang; unscoped (the shared
# parent) does NOT. Without the second half this case could pass on a build where scoping does
# nothing at all.
SCOPE_OUT="$WORK/scope.txt"
PYTHONPATH="$PY_DIR" python3 - "$WORK" > "$SCOPE_OUT" 2>&1 <<'PYEOF'
import os, sys, time, subprocess
from turn_diagnostics import TurnDiagnostics

work = sys.argv[1]
INTERVAL = 0.2

# advisor A: HUNG — alive, zero CPU, writes nothing (the agy failure shape)
out_a = os.path.join(work, "advisor-a.md"); open(out_a, "w").write("")
proc_a = subprocess.Popen(["sleep", "30"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# advisor B: BUSY — burns real CPU continuously (the codex-still-working shape)
busy = "x=0\nwhile True:\n    x+=1\n"
proc_b = subprocess.Popen([sys.executable, "-c", busy], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# correctly scoped: watch ONLY advisor A's subtree and ONLY A's transcript
scoped = TurnDiagnostics(worktree=out_a, root_pid=proc_a.pid, interval=INTERVAL)
# deliberately WRONG scoping: the shared parent, which is what the pre-GH-492 class could only do
unscoped = TurnDiagnostics(worktree=out_a, interval=INTERVAL)
scoped.start(); unscoped.start()
time.sleep(3.0)
scoped.stop(); unscoped.stop()

for p in (proc_a, proc_b):
    try:
        p.kill(); p.wait(timeout=5)
    except Exception:
        pass

print(f"SCOPED_IDLE={scoped.idle_seconds()}")
print(f"UNSCOPED_IDLE={unscoped.idle_seconds()}")
PYEOF

if grep -q "^SCOPED_IDLE=" "$SCOPE_OUT"; then
  S_IDLE="$(grep '^SCOPED_IDLE=' "$SCOPE_OUT" | cut -d= -f2)"
  U_IDLE="$(grep '^UNSCOPED_IDLE=' "$SCOPE_OUT" | cut -d= -f2)"
  awk -v v="$S_IDLE" 'BEGIN{exit !(v+0 >= 1.0)}' 2>/dev/null \
    && pass "CONSULT: a hung advisor is seen as idle when scoped to its own pid (idle=${S_IDLE}s)" \
    || fail "CONSULT: a hung advisor reported idle=${S_IDLE}s even when correctly scoped"
  awk -v v="$U_IDLE" 'BEGIN{exit !(v+0 < 1.0)}' 2>/dev/null \
    && pass "CONSULT: the SHARED-parent scope masks that same hang (idle=${U_IDLE}s) — which is why root_pid exists" \
    || fail "CONSULT: the shared-parent scope reported idle=${U_IDLE}s, so this case proves nothing about scoping"
else
  fail "consult scoping harness did not run: $(cat "$SCOPE_OUT")"
fi

# ── (9) a FILE is a usable progress signal, since advisors share one worktree ────────────────────
FILE_OUT="$WORK/filesig.txt"
PYTHONPATH="$PY_DIR" python3 - "$WORK" > "$FILE_OUT" 2>&1 <<'PYEOF'
import os, sys, time
sys.path.insert(0, os.environ.get("PY_DIR", ""))
from turn_diagnostics import _newest_mtime

work = sys.argv[1]
f = os.path.join(work, "transcript.md")
open(f, "w").write("a")
first = _newest_mtime(f)
time.sleep(0.05)
with open(f, "a") as fh:
    fh.write("bbbbbbbbbb")
second = _newest_mtime(f)
print(f"FIRST={first}")
print(f"SECOND={second}")
print(f"GREW={second > first}")
print(f"MISSING={_newest_mtime(os.path.join(work, 'nope.md'))}")
PYEOF
grep -q "^GREW=True" "$FILE_OUT" \
  && pass "a growing transcript FILE registers as progress (advisors share a worktree; a file is per-advisor)" \
  || fail "a growing transcript file did not register as progress: $(cat "$FILE_OUT")"
grep -q "^MISSING=0.0" "$FILE_OUT" \
  && pass "a missing transcript reads 0.0 rather than raising — an advisor that never writes is still measurable" \
  || fail "a missing transcript did not read 0.0: $(cat "$FILE_OUT")"

# ── (10) consult honours CONSULT_IDLE_S=0 as 'disable', and null-checks the reading ──────────────
grep -q "if idle_cap <= 0:" "$PY_DIR/consult.py" \
  && pass "consult guards the idle bound (CONSULT_IDLE_S=0 restores pure wall-cap behaviour)" \
  || fail "consult does not guard the idle bound — CONSULT_IDLE_S=0 would not disable it"
grep -q "idle is not None and idle >= idle_cap" "$PY_DIR/consult.py" \
  && pass "consult treats an unmeasured idle reading as not-killable" \
  || fail "consult does not null-check the idle reading — an unmeasured advisor could be killed"
grep -q "root_pid=proc.pid" "$PY_DIR/consult.py" \
  && pass "consult scopes each advisor's diagnostics to that advisor's own pid" \
  || fail "consult does not pass root_pid — one busy advisor would mask another's hang"

echo "  gh492-idle-kill: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
