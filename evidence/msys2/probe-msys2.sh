#!/usr/bin/env bash
# probe-msys2.sh — re-run PR #29's Windows/MSYS2 findings against a current checkout.
#
# PR #29 audited 911878c and was closed without its evidence half landing. This script
# answers the only question a follow-up needs to answer: do those findings still
# reproduce today, and which ones were fixed in the meantime?
#
# Non-destructive: writes nothing outside its own $OUT dir, needs no credentials, no
# network, and spends nothing. Run it from inside a checkout, under MSYS2/Git-Bash.
#
#   bash evidence/msys2/probe-msys2.sh [--out DIR]
#
# Exit 0 always — this is a reporter, not a gate. Read the VERDICT lines.

set -u

OUT="${TMPDIR:-/tmp}/msys2-probe-$$"
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT="$2"; shift 2 ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
mkdir -p "$OUT" || { echo "cannot create $OUT" >&2; exit 2; }

REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO" || exit 2

PY="${PROBE_PYTHON:-python}"
command -v "$PY" >/dev/null 2>&1 || PY=python3

say()    { printf '%s\n' "$*"; }
verdict(){ printf 'VERDICT %-6s %-4s %s\n' "$1" "$2" "$3"; }

say "== probe-msys2 =="
say "repo      : $REPO"
say "head      : $(git rev-parse HEAD 2>/dev/null || echo unknown)"
say "uname     : $(uname -a)"
say "bash      : $BASH_VERSION"
say "python    : $("$PY" --version 2>&1)"
say "node      : $(node --version 2>&1)"
say "git       : $(git --version 2>&1)"
say "out       : $OUT"
say ""

# ---------------------------------------------------------------- F10
# Unconditional signal.SIGHUP. A try/except AttributeError now wraps signal.signal(),
# but SIGHUP is dereferenced building the loop's TUPLE, which is outside that try —
# so on Windows the guard cannot fire. Reproduce the exact source shape.
say "-- F10: signal.SIGHUP on a platform that has none --"
SITE="$(grep -n 'signal.SIGTERM, signal.SIGINT, signal.SIGHUP' utils/py/marathon_drive.py 2>/dev/null | head -1)"
say "site: utils/py/marathon_drive.py:${SITE%%:*}"
"$PY" - >"$OUT/f10.log" 2>&1 <<'PY'
import signal
print("has SIGHUP:", hasattr(signal, "SIGHUP"))
def _terminate(signum, _frame):
    raise SystemExit(128 + signum)
try:
    # verbatim shape from marathon_drive.py
    for _sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        try:
            signal.signal(_sig, _terminate)
        except (ValueError, OSError, AttributeError):
            pass
    print("RESULT: loop completed — guard effective")
except AttributeError as e:
    print("RESULT: AttributeError escaped the guard ->", e)
PY
sed 's/^/  /' "$OUT/f10.log"
if grep -q "escaped the guard" "$OUT/f10.log"; then
  verdict F10 OPEN "guard is inside the loop; SIGHUP is dereferenced building the tuple"
elif grep -q "has SIGHUP: True" "$OUT/f10.log"; then
  verdict F10 N/A  "this platform has SIGHUP — run under Windows Python to test"
else
  verdict F10 FIXED "guard absorbed the missing signal"
fi
say ""

# ---------------------------------------------------------------- F7
# rtl.py execs bin/tick via subprocess.run([tick_bin, ...]). bin/tick is a
# `#!/usr/bin/env node` script; CreateProcess does not honour shebangs.
say "-- F7: exec a shebang script through subprocess (no shell) --"
say "site: utils/py/rtl.py:$(grep -n 'subprocess.run(\[tick_bin, "info"' utils/py/rtl.py | head -1 | cut -d: -f1)"
say "tick shebang: $(head -1 bin/tick)"
PROBE_TICK="$REPO/bin/tick" "$PY" - >"$OUT/f7.log" 2>&1 <<'PY'
import os, subprocess
tick = os.environ["PROBE_TICK"]
print("tick path:", tick)
print("isfile:", os.path.isfile(tick), "X_OK:", os.access(tick, os.X_OK))
try:
    r = subprocess.run([tick, "--help"], capture_output=True, text=True, timeout=30)
    print("RESULT: exec ok, rc=", r.returncode)
except OSError as e:
    print("RESULT: OSError ->", type(e).__name__, getattr(e, "winerror", ""), e)
except Exception as e:
    print("RESULT:", type(e).__name__, e)
PY
sed 's/^/  /' "$OUT/f7.log"
if grep -q "OSError" "$OUT/f7.log"; then
  verdict F7 OPEN "subprocess cannot exec the shebang script; no node fallback"
elif grep -q "exec ok" "$OUT/f7.log"; then
  verdict F7 FIXED "the tick exec path resolves an interpreter"
else
  verdict F7 UNCLEAR "see $OUT/f7.log"
fi
say ""

# ---------------------------------------------------------------- F8
# `case "$x" in /*)` classifies a path as absolute. A Windows absolute path
# (C:/...) does not start with /, so it is treated as relative and concatenated.
say "-- F8: 'case \$x in /*)' vs a Windows absolute path --"
say "call sites: $(grep -rn 'case "\$[A-Za-z_]*" in /\*)' --include=*.sh . 2>/dev/null | grep -v '/\.git/' | wc -l | tr -d ' ')"
{
  REPO_T="C:/tmp/repo"
  for CAND in "C:/Users/example/hooks" "/c/Users/example/hooks" "relative/hooks"; do
    OUTP="$CAND"
    case "$OUTP" in /*) ;; *) OUTP="$REPO_T/$OUTP" ;; esac
    printf 'input=%-26s -> %s\n' "$CAND" "$OUTP"
  done
} >"$OUT/f8.log" 2>&1
sed 's/^/  /' "$OUT/f8.log"
if grep -q 'C:/tmp/repo/C:/' "$OUT/f8.log"; then
  verdict F8 OPEN "a C:/ path is concatenated onto the repo root"
else
  verdict F8 FIXED "the construct recognises a drive-letter path"
fi
say ""

# ---------------------------------------------------------------- F11
# validate.sh recursed into itself via githooks/pre-push and never terminated.
# The cheap fix PR #29 proposed was an explicit re-entrancy guard. Check for one
# statically — deliberately NOT by running the gate, which is the 47-minute hang.
say "-- F11: re-entrancy guard in validate.sh (static check only) --"
if grep -qE 'XYZ_VALIDATE_ACTIVE|VALIDATE_(RE)?ENTRAN|already (running|active)' validate.sh 2>/dev/null; then
  grep -nE 'XYZ_VALIDATE_ACTIVE|VALIDATE_(RE)?ENTRAN|already (running|active)' validate.sh | sed 's/^/  /'
  verdict F11 FIXED "validate.sh refuses a nested invocation"
else
  say "  no re-entrancy guard found in validate.sh"
  verdict F11 OPEN "no guard; the recursion class is still reachable"
fi
say ""

say "logs in $OUT"
exit 0
