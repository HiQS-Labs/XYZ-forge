#!/usr/bin/env bash
# test/gh114-headless-tty.sh — GH-114: headless `agy -p` gets a TTY, and an idle kill names its blocker.
#
# The observed stall (marathon/daybreak-wave-2, 2026-08-20): `agy -p` wedged at ~0 CPU under the
# 300s idle watchdog while its transcript said `bubbletea: could not open TTY` — the CLI's TUI needs
# a TTY even in -p mode, and the watchdog's attribution only offered the generic "a lock, a prompt,
# or a hung network call". The fix has two halves, both pinned here:
#   1. agy-turn.py provisions a pty for the turn by default (AGY_PTY=0 restores the pipe path).
#   2. On an idle/wall kill it runs _probe_idle_blocker BEFORE signalling and emits an
#      "idle-blocker attribution: blocker=<tty|lock|network|unknown>" block to stderr + transcript.
#
# Drives the real shim with a stub `agy` (same shape as test/agy-turn.sh) for the e2e cases, and
# imports the module directly for the lsof-based blocker branches (a live network hang is not
# reproducible deterministically, so the open-file table is faked on PATH instead).
set -uo pipefail

source "$(dirname "$0")/_setup.sh" agy-turn
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/agy-turn.sh"
PY_SHIM="$(cd "$(dirname "$0")/.." && pwd)/utils/py/agy-turn.py"
tick_a init >/dev/null

printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

# Stub `agy`: passes the whoami/models pre-flights, then for the real turn checks whether stdin is a
# TTY. STUB_MODE: ttycheck (default) — fail loudly with the exact observed bubbletea error if not a
# TTY, else perform the good-turn contract and print a TTY-OK marker; idle — print the bubbletea
# error and stall (no CPU, no file progress) until killed, reproducing the watchdog shape.
STUB="$WORK/agy"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
if [ "${1:-}" = whoami ]; then printf 'agy@example.test\n'; exit 0; fi
if [ "${1:-}" = models ]; then printf 'Gemini 3.5 Flash\n'; exit 0; fi
TTY_ERR='CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured'
if [ "${STUB_MODE:-ttycheck}" = idle ]; then
  printf '%s\n' "$TTY_ERR"
  sleep 120
  exit 0
fi
if ! [ -t 0 ]; then
  printf '%s\n' "$TTY_ERR"
  exit 1
fi
printf 'agy-stub: TTY-OK stdin is a tty; model response for %s\n' "$RELAY_AGENT"
export TICK_REPO_ROOT="$A"
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
printf '\n### Round 1 · Reviewer · %s (agy-stub)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to agy >/dev/null; }

# --- (1) pty default: a headless turn with no controlling TTY never logs the TTY error ---------
seed_token RELAY-TURN-gh114-pty
log="$WORK/gh114-pty.log"; : >"$log"
err="$WORK/gh114-pty.err"; : >"$err"
RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-gh114-pty AGY_AGENT=agy \
AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$log" STUB_MODE=ttycheck \
bash "$SHIM" >/dev/null 2>"$err"; rc=$?
[ "$rc" -eq 0 ] && pass "pty default: turn exits 0 with a stub that REQUIRES a TTY on stdin" \
  || fail "pty default: expected exit 0, got $rc"
grep -q "TTY-OK" "$log" && pass "pty default: the child saw a real tty on stdin (isatty true)" \
  || fail "pty default: child did not see a tty — pty not provisioned"
if grep -qi "could not open TTY" "$log" || grep -qi "could not open TTY" "$err"; then
  fail "pty default: the bubbletea TTY error was logged on a headless turn"
else
  pass "pty default: no 'could not open TTY' error anywhere in the turn's output"
fi

# --- (2) idle kill attribution: AGY_PTY=0 + stalled child -> blocker=tty, exit 7 ---------------
seed_token RELAY-TURN-gh114-idle
log2="$WORK/gh114-idle.log"; : >"$log2"
err2="$WORK/gh114-idle.err"; : >"$err2"
RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-gh114-idle AGY_AGENT=agy \
AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$log2" STUB_MODE=idle \
AGY_PTY=0 RELAY_TURN_IDLE_S=4 RELAY_DIAG_INTERVAL_S=1 RELAY_TURN_TIMEOUT_S=40 \
bash "$SHIM" >/dev/null 2>"$err2"; rc=$?
[ "$rc" -eq 7 ] && pass "idle stall (pipe mode): watchdog kills at exit 7" \
  || fail "idle stall: expected exit 7, got $rc"
grep -q "idle-blocker attribution: blocker=tty" "$err2" \
  && pass "idle stall: stderr attribution block names blocker=tty" \
  || fail "idle stall: no blocker=tty attribution block on stderr"
grep -q "\[GH-114 idle-blocker\] blocker=tty" "$log2" \
  && pass "idle stall: the transcript carries the same attribution block" \
  || fail "idle stall: transcript missing the attribution block"

# --- (3) blocker branches: lock / network / unknown via a faked open-file table ----------------
FAKEBIN="$WORK/fakebin"; mkdir -p "$FAKEBIN"
mk_fake_lsof(){ printf '#!/usr/bin/env bash\ncat <<EOF\n%s\nEOF\n' "$1" >"$FAKEBIN/lsof"; chmod +x "$FAKEBIN/lsof"; }
probe(){ # <log-content> -> prints blocker name from the module's own probe
  PATH="$FAKEBIN:/usr/bin:/bin" \
  python3 - "$PY_SHIM" <<'PYEOF'
import importlib.util, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(sys.argv[1])))  # rtl/turn_diagnostics live beside the shim
spec = importlib.util.spec_from_file_location("agy_turn_mod", sys.argv[1])  # dashed filename: importlib, not `import`
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
log = os.environ["GH114_PROBE_LOG"]
proc = subprocess.Popen(["/bin/sleep", "5"])
try:
    print(m._probe_idle_blocker(proc, log)[0])
finally:
    proc.kill(); proc.wait()
PYEOF
}
PROBE_LOG="$WORK/gh114-probe.log"
GH114_PROBE_LOG="$PROBE_LOG" ; export GH114_PROBE_LOG

printf 'ordinary transcript, no tty complaint\n' >"$PROBE_LOG"
mk_fake_lsof 'agy 1234 u 5u REG 1,2 0 123 /repo/.git/index.lock'
[ "$(probe x)" = "lock" ] && pass "blocker probe: an open .lock file attributes blocker=lock" \
  || fail "blocker probe: expected lock, got '$(probe x)'"

mk_fake_lsof 'agy 1234 u 6u IPv6 0x0 TCP 10.0.0.2:51734->140.82.121.6:443 (ESTABLISHED)'
[ "$(probe x)" = "network" ] && pass "blocker probe: an open TCP socket attributes blocker=network" \
  || fail "blocker probe: expected network, got '$(probe x)'"

mk_fake_lsof ''
[ "$(probe x)" = "unknown" ] && pass "blocker probe: no tty error + empty table attributes blocker=unknown" \
  || fail "blocker probe: expected unknown, got '$(probe x)'"

printf 'CLI error: bubbletea: error opening TTY: bubbletea: could not open TTY: open /dev/tty: device not configured\n' >"$PROBE_LOG"
mk_fake_lsof 'agy 1234 u 6u IPv6 0x0 TCP 10.0.0.2:51734->140.82.121.6:443 (ESTABLISHED)'
[ "$(probe x)" = "tty" ] && pass "blocker probe: the transcript's own TTY error outranks open sockets (tty first)" \
  || fail "blocker probe: expected tty, got '$(probe x)'"

echo
echo "gh114-headless-tty: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
