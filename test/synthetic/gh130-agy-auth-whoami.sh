#!/usr/bin/env bash
# #130 — agy auth pre-flight killed the lane when the installed agy has no `whoami` subcommand.
# agy 1.1.18 exits 2 with `Error: unexpected argument "whoami".` — an `error:`-prefixed line that
# the verdict function classified as a credentials FAILURE, so `agy_auth_preflight` returned False,
# the shim exited 5 before the turn ran, and the remedy ("run `agy login`") was wrong because auth
# was never the question: the probe itself was incompatible with that CLI.
#
# Contract pinned here (the GH-375/GH-492 three-state verdict, extended):
#   usage / CLI-syntax errors .... unverifiable -> preflight returns True, lane proceeds
#   TTY errors (exit 0 or not) ... unverifiable -> preflight returns True, lane proceeds
#   error-prefixed credentials ... failed       -> preflight returns False, shim exits 5
#   non-zero with NO diagnostic .. failed       -> preflight returns False (conservative, pre-#130)
#
# Usage: bash test/synthetic/gh130-agy-auth-whoami.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/../.." && pwd)"
PY="${PYTHON:-python3}"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh130-agy-whoami.XXXXXX")"
trap '[ -n "$WORK" ] && [ -d "$WORK" ] && rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); [ "${TEST_SOFT_FAIL:-0}" = "1" ] || { echo "gh130: $PASS passed, $FAIL failed"; exit 1; }; }

case "$WORK" in ""|*..*) echo "FAIL: invalid sandbox root"; exit 1 ;; esac

# --- agy stubs ---------------------------------------------------------------------------------------------
# agy 1.1.18 shape, measured in the issue: non-zero exit, clap usage error on stderr.
STUB_USAGE="$WORK/agy-usage"
cat >"$STUB_USAGE" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = whoami ]; then
  printf 'Error: unexpected argument "whoami".\n'
  printf 'Prompts are read only from -p/--print, -i/--prompt-interactive, or stdin, so this argument would have been ignored.\n'
  exit 2
fi
exit 0
EOF
chmod +x "$STUB_USAGE"

# A genuine credentials rejection: error-prefixed, no usage/TTY shape.
STUB_CREDS="$WORK/agy-creds"
cat >"$STUB_CREDS" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = whoami ]; then
  printf 'Error: not logged in — credentials rejected by the auth server\n'
  exit 1
fi
exit 0
EOF
chmod +x "$STUB_CREDS"

# A usage error spelled WITHOUT an Error: prefix (clap prints this shape for some commands).
STUB_UNKNOWN_CMD="$WORK/agy-unknown-cmd"
cat >"$STUB_UNKNOWN_CMD" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = whoami ]; then
  printf 'unknown command "whoami" for "agy"\n'
  exit 2
fi
exit 0
EOF
chmod +x "$STUB_UNKNOWN_CMD"

# Non-zero exit saying nothing at all — must stay fatal (the conservative pre-#130 branch).
STUB_SILENT="$WORK/agy-silent"
cat >"$STUB_SILENT" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = whoami ]; then
  exit 3
fi
exit 0
EOF
chmod +x "$STUB_SILENT"

# --- direct preflight driver: exit 0 = True (proceed), exit 5 = False (block) ------------------------------
DRIVER="$WORK/preflight_driver.py"
cat >"$DRIVER" <<EOF
import importlib.util, os, sys

harness = sys.argv[1]
stub = sys.argv[2]
sys.path.insert(0, os.path.join(harness, "utils", "py"))
spec = importlib.util.spec_from_file_location(
    "agy_turn_mod", os.path.join(harness, "utils", "py", "agy-turn.py"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
sys.exit(0 if mod.agy_auth_preflight(stub) else 5)
EOF

run_preflight() { # <stub>
  AGY_AUTH_TIMEOUT_S=10 "$PY" "$DRIVER" "$ROOT_DIR" "$1" >"$WORK/last.out" 2>"$WORK/last.err"
  RC=$?
}

echo "=== 1. verdict classification (rtl.agy_auth_output_verdict) ==="
VERDICT="$WORK/verdict.py"
cat >"$VERDICT" <<EOF
import os, sys
sys.path.insert(0, os.path.join(sys.argv[1], "utils", "py"))
import rtl

def verdict_for(text):
    p = os.path.join(sys.argv[2], "probe.out")
    with open(p, "w") as f:
        f.write(text)
    return rtl.agy_auth_output_verdict(p)[0]

checks = [
    ('Error: unexpected argument "whoami".\n', "unverifiable"),
    ('unknown command "whoami" for "agy"\n', "unverifiable"),
    ("CLI error: bubbletea: error opening TTY: open /dev/tty: device not configured\n", "unverifiable"),
    ("Error: not logged in\n", "failed"),
    ("agy@example.test\n", ""),
]
bad = 0
for text, want in checks:
    got = verdict_for(text)
    if got != want:
        print("MISMATCH: want %r got %r for %r" % (want, got, text))
        bad += 1
sys.exit(1 if bad else 0)
EOF
if "$PY" "$VERDICT" "$ROOT_DIR" "$WORK" >"$WORK/verdict.out" 2>&1; then
  pass "verdict: usage errors -> unverifiable, TTY -> unverifiable, credentials -> failed, identity -> pass"
else
  fail "verdict classification regressed: $(cat "$WORK/verdict.out")"
fi

echo "=== 2. preflight: usage-error probe (exit 2) is non-blocking ==="
run_preflight "$STUB_USAGE"
[ "$RC" -eq 0 ] \
  && pass "agy_auth_preflight(us, exit 2) returns True (unverifiable, lane proceeds)" \
  || fail "usage-error probe blocked the lane (rc=$RC) — the exact #130 defect"
grep -q "unverifiable" "$WORK/last.err" \
  && pass "single NOTE names the probe unverifiable" \
  || fail "expected an unverifiable NOTE on stderr, got: $(cat "$WORK/last.err")"

echo "=== 3. preflight: usage error without an Error: prefix is also non-blocking ==="
run_preflight "$STUB_UNKNOWN_CMD"
[ "$RC" -eq 0 ] \
  && pass "agy_auth_preflight(unknown command, exit 2) returns True" \
  || fail "unprefixed usage-error probe blocked the lane (rc=$RC)"

echo "=== 4. preflight: genuine credentials failure still blocks (exit 5) ==="
run_preflight "$STUB_CREDS"
[ "$RC" -eq 5 ] \
  && pass "agy_auth_preflight(credentials error) returns False (shim exits 5)" \
  || fail "credentials failure stopped blocking (rc=$RC) — over-broad unverifiable"
grep -q "agy login" "$WORK/last.err" \
  && pass "credentials failure keeps the \`agy login\` remedy" \
  || fail "credentials failure lost its remedy text: $(cat "$WORK/last.err")"

echo "=== 5. preflight: silent non-zero exit stays fatal (conservative branch) ==="
run_preflight "$STUB_SILENT"
[ "$RC" -eq 5 ] \
  && pass "agy_auth_preflight(silent exit 3) returns False — unrecognized failures still block" \
  || fail "silent non-zero probe stopped blocking (rc=$RC)"

echo "=== 6. #135: consult.py's preflight routes non-zero exits through the verdict too ==="
# consult.py had the same fatal CalledProcessError branch #130 fixed in agy-turn.py; its exit-0
# path already used the shared verdict, so only the non-zero branch is exercised here.
CONSULT_DRIVER="$WORK/consult_driver.py"
cat >"$CONSULT_DRIVER" <<EOF
import importlib.util, os, sys

harness, stub, log = sys.argv[1], sys.argv[2], sys.argv[3]
sys.path.insert(0, os.path.join(harness, "utils", "py"))
spec = importlib.util.spec_from_file_location(
    "consult_mod", os.path.join(harness, "utils", "py", "consult.py"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
sys.exit(0 if mod.agy_auth_preflight(stub, log) else 5)
EOF
CLOG="$WORK/consult-preflight.log"
: >"$CLOG"
AGY_AUTH_TIMEOUT_S=10 "$PY" "$CONSULT_DRIVER" "$ROOT_DIR" "$STUB_USAGE" "$CLOG" >/dev/null 2>&1
rcu=$?
[ "$rcu" -eq 0 ] \
  && pass "consult agy_auth_preflight(usage stub, exit 2) returns True (#135)" \
  || fail "consult still blocks the lane on a usage-error probe (rc=$rcu) — the #135 defect"
grep -q "unverifiable headless (expected, probe exited 2" "$CLOG" \
  && pass "consult records the unverifiable NOTE in its log" \
  || fail "consult NOTE missing from log: $(cat "$CLOG")"
AGY_AUTH_TIMEOUT_S=10 "$PY" "$CONSULT_DRIVER" "$ROOT_DIR" "$STUB_CREDS" "$CLOG" >/dev/null 2>&1
rcc=$?
[ "$rcc" -eq 5 ] \
  && pass "consult agy_auth_preflight(credentials error) still returns False" \
  || fail "consult stopped blocking credentials failures (rc=$rcc) — over-broad unverifiable"
grep -q "agy login" "$CLOG" \
  && pass "consult keeps the \`agy login\` remedy on real errors" \
  || fail "consult lost its remedy text: $(cat "$CLOG")"

echo "gh130: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
