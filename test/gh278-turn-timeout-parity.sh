#!/usr/bin/env bash
# GH-278: the Python runtime is the default path, but the Bash compatibility shim and relay-xyz
# guidance must name the same Aider turn timeout. A static parity guard catches a future unilateral
# default change before a thinking-heavy builder is unexpectedly killed.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
PY="$ROOT/utils/py/aider-turn.py"
SH="$ROOT/relay-automation/aider-turn.sh"
SKILL="$ROOT/skills/relay-xyz/SKILL.md"
EXPECTED=900
pass=0; fail=0

ok()  { echo "  PASS: $1"; pass=$((pass + 1)); }
bad() { echo "  FAIL: $1"; fail=$((fail + 1)); }

echo "== test: gh278-turn-timeout-parity =="

# Parse the Python source so comments and unrelated numeric literals cannot satisfy the check.
py_default="$(python3 - "$PY" <<'PYEOF'
import ast
import sys

tree = ast.parse(open(sys.argv[1]).read(), filename=sys.argv[1])
for node in ast.walk(tree):
    if not isinstance(node, ast.Assign):
        continue
    if not any(isinstance(target, ast.Name) and target.id == "turn_timeout" for target in node.targets):
        continue
    call = node.value
    if (isinstance(call, ast.Call) and isinstance(call.func, ast.Name) and call.func.id == "int"
            and len(call.args) == 1 and isinstance(call.args[0], ast.Call)):
        env = call.args[0]
        if (isinstance(env.func, ast.Attribute) and isinstance(env.func.value, ast.Attribute)
                and isinstance(env.func.value.value, ast.Name) and env.func.value.value.id == "os"
                and env.func.value.attr == "environ" and env.func.attr == "get"
                and len(env.args) == 2 and isinstance(env.args[0], ast.Constant)
                and env.args[0].value == "RELAY_TURN_TIMEOUT_S"
                and isinstance(env.args[1], ast.Constant)):
            print(env.args[1].value)
            break
PYEOF
)"
[[ "$py_default" == "$EXPECTED" ]] \
  && ok "Python default is ${EXPECTED}s" \
  || bad "Python default must be ${EXPECTED}s, got [${py_default:-missing}]"

# The Bash assignment is intentionally exact: it is the compatibility runtime's actual cap.
if grep -Fxq 'turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"' "$SH"; then
  sh_default="$EXPECTED"
else
  sh_default="missing"
fi
[[ "$sh_default" == "$EXPECTED" ]] \
  && ok "Bash default is ${EXPECTED}s" \
  || bad "Bash default must be ${EXPECTED}s, got [${sh_default:-missing}]"

# The operator-facing skill must describe that same Aider default, rather than merely mention a cap.
if grep -Fq 'Aider default: 900s in both runtime shims' "$SKILL"; then
  ok "relay-xyz documents the shared ${EXPECTED}s Aider default"
else
  bad "relay-xyz must document the shared ${EXPECTED}s Aider default"
fi

echo "  gh278-turn-timeout-parity: $pass pass, $fail fail"
[[ "$fail" -eq 0 ]]
