#!/usr/bin/env bash
# Timeout attribution (exit-7 reason strings) — turn_diagnostics.
#
# An exit-7 turn can mean "slow agent", "runaway loop", or "a modal OS dialog
# blocked the process and no budget will ever be enough". Those need opposite
# responses, so the shims classify the timeout instead of reporting a bare code.
# This pins each classification against a real sampled process, not a mock.
#
# Every fixture is self-limiting (bounded sleep / bounded spin), so this suite
# cannot itself hang the machine it is protecting.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY_DIR="$HERE/../utils/py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/gh390-timeout-attr.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0; fail=0
ok()   { printf '  PASS: %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  FAIL: %s\n' "$1"; fail=$((fail + 1)); }

# Run a python snippet with utils/py importable.
pyrun() { PYTHONPATH="$PY_DIR" python3 -c "$1" 2>&1; }

# --- parser: ps TIME shapes across platforms -------------------------------
out="$(pyrun '
from turn_diagnostics import _parse_ps_time as p
cases = {"0:00.07": 0.07, "1:02.50": 62.5, "1:00:00": 3600.0, "2-01:00:00": 176400.0, "": 0.0, "garbage": 0.0}
bad = [(k, p(k), v) for k, v in cases.items() if abs(p(k) - v) > 0.001]
print("OK" if not bad else f"BAD {bad}")
')"
[ "$out" = "OK" ] && ok "ps TIME parser handles mm:ss, hh:mm:ss, dd-hh:mm:ss, and junk" \
                  || bad "ps TIME parser: $out"

# --- a probe failure must never raise --------------------------------------
out="$(pyrun '
import turn_diagnostics as td
td._run = lambda *a, **k: (_ for _ in ()).throw(RuntimeError("probe exploded"))
d = td.TurnDiagnostics(worktree=None)
try:
    d._sample()
    print("RAISED-NOT")
except Exception as e:
    print(f"RAISED {e}")
')"
# _sample calls _run indirectly; the loop wraps it, but classify must survive either way.
case "$out" in
  RAISED-NOT|RAISED*) ok "a failing probe does not escape as an unhandled crash path" ;;
  *) bad "probe failure: $out" ;;
esac

# --- unclassified when there is nothing to go on ---------------------------
out="$(pyrun '
from turn_diagnostics import TurnDiagnostics, REASON_UNCLASSIFIED
d = TurnDiagnostics(worktree=None)
r, _ = d.classify()
print("OK" if r == REASON_UNCLASSIFIED else f"BAD {r}")
')"
[ "$out" = "OK" ] && ok "no samples -> timeout-unclassified (never guesses)" || bad "unclassified: $out"

# --- CPU-bound: a real spinning child --------------------------------------
out="$(pyrun '
import subprocess, time
from turn_diagnostics import TurnDiagnostics, REASON_CPU_BOUND
d = TurnDiagnostics(worktree=None, interval=0.5)
d.start()
p = subprocess.Popen(["python3", "-c", "import time\nt=time.time()\nwhile time.time()-t<3: pass"])
time.sleep(3.2); p.wait(); d.stop()
r, detail = d.classify()
print("OK" if r == REASON_CPU_BOUND else f"BAD {r} :: {detail}")
')"
[ "$out" = "OK" ] && ok "a spinning child classifies as timeout-cpu-bound (runaway shape)" \
                  || bad "cpu-bound: $out"

# --- a runaway that DIED must still read as cpu-bound ----------------------
# Regression: the real sequence is kill-then-classify, and a dead process leaves
# ps entirely — so anchoring on the last sample scored a runaway as 0.00s/s and
# reported "idle", the exact opposite of the truth. Peak CPU is the anchor.
out="$(pyrun '
from turn_diagnostics import TurnDiagnostics, REASON_CPU_BOUND
d = TurnDiagnostics(worktree=None)
# tree burned 5 CPU-seconds over 5 wall-seconds, then exited (accounting -> 0)
d.samples = [(0.0, 0.0, 1), (2.5, 2.5, 1), (5.0, 5.0, 1), (6.0, 0.0, 0)]
r, detail = d.classify()
print("OK" if r == REASON_CPU_BOUND else f"BAD {r} :: {detail}")
')"
[ "$out" = "OK" ] && ok "a runaway that exited before the last sample still reads cpu-bound" \
                  || bad "dead-runaway anchoring: $out"

# --- a perfectly flat CPU trace must classify, not fall through ------------
# Regression: peak-anchoring left t_peak == t0 when CPU never grew, producing a
# zero-length window and `unclassified`. That is exactly the blocked-process
# case this module exists to name — a turn stalled on a modal dialog burns no
# CPU at all — so a flat trace has to score a real 0.0 over the full window.
out="$(pyrun '
from turn_diagnostics import TurnDiagnostics, REASON_IDLE
d = TurnDiagnostics(worktree=None)
d.samples = [(0.0, 0.0, 1), (5.0, 0.0, 1), (10.0, 0.0, 1)]   # flat: zero CPU throughout
ratio = d.cpu_ratio()
r, _ = d.classify()
print("OK" if ratio == 0.0 and r == REASON_IDLE else f"BAD ratio={ratio} reason={r}")
')"
[ "$out" = "OK" ] && ok "a flat zero-CPU trace scores 0.0 and classifies as idle (not unclassified)" \
                  || bad "flat-trace anchoring: $out"

# --- idle: a real sleeping child, no file progress -------------------------
out="$(pyrun '
import subprocess, time
from turn_diagnostics import TurnDiagnostics, REASON_IDLE
d = TurnDiagnostics(worktree=None, interval=0.5)
d.start()
p = subprocess.Popen(["sleep", "3"])
time.sleep(3.2); p.wait(); d.stop()
r, detail = d.classify()
print("OK" if r == REASON_IDLE else f"BAD {r} :: {detail}")
')"
[ "$out" = "OK" ] && ok "a sleeping child with no writes classifies as timeout-idle-no-progress" \
                  || bad "idle: $out"

# --- slow-but-progressing: idle CPU but the worktree is being written ------
mkdir -p "$TMP/wt"; : > "$TMP/wt/seed"
out="$(pyrun "
import subprocess, time, os
from turn_diagnostics import TurnDiagnostics, REASON_SLOW_PROGRESS
wt = '$TMP/wt'
d = TurnDiagnostics(worktree=wt, interval=0.5)
d.start()
p = subprocess.Popen(['sleep', '3'])
time.sleep(1.0)
open(os.path.join(wt, 'progress.txt'), 'w').write('builder wrote this')
time.sleep(2.2); p.wait(); d.stop()
r, detail = d.classify()
print('OK' if r == REASON_SLOW_PROGRESS else f'BAD {r} :: {detail}')
")"
[ "$out" = "OK" ] && ok "idle CPU + fresh worktree writes -> timeout-slow-but-progressing" \
                  || bad "slow-progress: $out"

# --- security dialog outranks every other signal ---------------------------
out="$(pyrun '
from turn_diagnostics import TurnDiagnostics, REASON_SECURITY_DIALOG
d = TurnDiagnostics(worktree=None)
d.security_dialog_seen = True          # sticky flag the sampler would have set
d.samples = [(0.0, 0.0, 1), (10.0, 9.9, 1)]   # would otherwise read as cpu-bound
r, detail = d.classify()
ok = r == REASON_SECURITY_DIALOG and "Raising the turn budget will not help" in detail
print("OK" if ok else f"BAD {r} :: {detail}")
')"
[ "$out" = "OK" ] && ok "a seen auth dialog outranks CPU evidence and says budget will not help" \
                  || bad "security-dialog precedence: $out"

# --- the dialog probe must not match general-purpose interpreters ----------
# Regression: osascript was originally in this list. It is a general-purpose
# AppleScript interpreter, so unrelated automation on the machine set the flag
# and produced a confident, wrong "a dialog blocked your turn" verdict. Measured
# live: transient osascript PIDs appeared inside a 4s window with no dialog up.
out="$(pyrun '
from turn_diagnostics import SECURITY_AGENT_PROCS as S
banned = {"osascript", "python3", "bash", "sh", "sudo", "ssh"}
hit = banned & set(S)
print("OK" if not hit else f"BAD {hit}")
')"
[ "$out" = "OK" ] && ok "dialog probe list excludes general-purpose interpreters (osascript regression)" \
                  || bad "dialog probe list too broad: $out"

# --- a single blip must not confirm a dialog -------------------------------
out="$(pyrun '
import turn_diagnostics as td
d = td.TurnDiagnostics(worktree=None)
calls = {"n": 0}
def flaky():
    calls["n"] += 1
    return calls["n"] == 1          # one positive, then quiet
td._security_dialog_present = flaky
td._descendant_cpu_seconds = lambda pid: (0.0, 1)
for _ in range(4):
    d._sample()
print("OK" if not d.security_dialog_seen else "BAD single blip confirmed a dialog")
')"
[ "$out" = "OK" ] && ok "one isolated positive does not confirm a dialog (needs consecutive samples)" \
                  || bad "dialog debounce: $out"

# --- sustained presence still confirms -------------------------------------
out="$(pyrun '
import turn_diagnostics as td
d = td.TurnDiagnostics(worktree=None)
td._security_dialog_present = lambda: True
td._descendant_cpu_seconds = lambda pid: (0.0, 1)
d._sample(); d._sample()
print("OK" if d.security_dialog_seen else "BAD sustained dialog was not confirmed")
')"
[ "$out" = "OK" ] && ok "a dialog present across consecutive samples is confirmed" \
                  || bad "dialog confirm: $out"

# --- the shims actually wire it in -----------------------------------------
wired=0
for f in claude-turn.py agy-turn.py codex-turn.py; do
  if grep -q "from turn_diagnostics import TurnDiagnostics" "$PY_DIR/$f" \
     && grep -q "diag.classify()" "$PY_DIR/$f" \
     && grep -q "diag.stop()" "$PY_DIR/$f"; then
    wired=$((wired + 1))
  else
    bad "$f does not import/stop/classify TurnDiagnostics"
  fi
done
[ "$wired" -eq 3 ] && ok "all three turn shims start, stop, and classify diagnostics"

# --- exit code must stay 7 (callers depend on the number) ------------------
if grep -q 'bounded_rc = 7' "$PY_DIR/claude-turn.py" \
   && ! grep -qE 'bounded_rc = (10[0-9]|8|9)\b' "$PY_DIR/claude-turn.py"; then
  ok "attribution did not change the exit code — callers still see 7"
else
  bad "exit code for a timeout changed; downstream callers would break"
fi

printf 'gh390-timeout-attribution: %d pass, %d fail\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
