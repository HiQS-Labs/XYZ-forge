#!/usr/bin/env bash
# GH-369: a turn timeout must reap a child which outlives its command leader.
source "$(dirname "$0")/_setup.sh" gh369-group-kill

ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$ROOT_REPO/relay-automation/relay-turn-lib.sh"
PIDFILE="$WORK/grandchild.pid"

source "$LIB"

assert_dead() {  # <pid> <label>
  local pid="$1" label="$2" state
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    state="$(ps -o stat= -p "$pid" 2>/dev/null | tr -d '[:space:]')"
    [ -z "$state" ] && { pass "$label is gone after the timeout"; return; }
    case "$state" in Z*) pass "$label was reaped (zombie awaiting init)"; return ;; esac
    sleep 0.1
  done
  fail "$label survived the bounded timeout (pid $pid, state ${state:-unknown})"
}

run_bash_shape() {
  local rc=0
  rtl_run_bounded 1 bash -c 'sleep 30 & child=$!; printf "%s\n" "$child" > "$1"; wait "$child"' _ "$PIDFILE" || rc=$?
  [ "$rc" -eq 7 ] \
    && pass "Bash bounded runner returns timeout exit 7" \
    || fail "Bash bounded runner returned $rc, expected 7"
}

run_bash_shape
[ -s "$PIDFILE" ] || fail "Bash fixture did not publish its grandchild PID"
assert_dead "$(cat "$PIDFILE")" "Bash grandchild"

PY_PIDFILE="$WORK/python-grandchild.pid"
PY_RC="$(ROOT_REPO="$ROOT_REPO" PY_PIDFILE="$PY_PIDFILE" python3 - <<'PYEOF'
import os
import sys
sys.path.insert(0, os.path.join(os.environ["ROOT_REPO"], "utils", "py"))
import rtl
rc = rtl.rtl_run_bounded(1, [
    "bash", "-c",
    'sleep 30 & child=$!; printf "%s\\n" "$child" > "$1"; wait "$child"',
    "_", os.environ["PY_PIDFILE"],
])
print(rc)
PYEOF
)"
[ "$PY_RC" -eq 7 ] \
  && pass "Python bounded runner returns the same timeout exit 7" \
  || fail "Python bounded runner returned $PY_RC, expected 7"
[ -s "$PY_PIDFILE" ] || fail "Python fixture did not publish its grandchild PID"
assert_dead "$(cat "$PY_PIDFILE")" "Python grandchild"

grep -q 'GH-369' "$LIB" \
  && pass "Bash change site retains the GH-369 preflight marker" \
  || fail "Bash change site lost its GH-369 marker"
grep -q 'GH-369' "$ROOT_REPO/utils/py/rtl.py" \
  && pass "Python twin retains the GH-369 marker" \
  || fail "Python twin lost its GH-369 marker"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
