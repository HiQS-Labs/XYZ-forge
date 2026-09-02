#!/usr/bin/env bash
set -euo pipefail

# GH-368 — one AGY lane may host both the builder and reviewer.  This uses copied dispatcher
# stubs, then imports the authoritative Python shim with its auth probe replaced, so no model,
# tick, or repository mutation is needed to prove either side of the routing contract.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh368-routing.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL + 1)); }

echo "== test: gh368-same-lane-routing =="

DISPATCH="$WORK/dispatch"
mkdir -p "$DISPATCH"
cp "$ROOT/relay-automation/marathon-agent.sh" "$DISPATCH/marathon-agent.sh"
cat > "$DISPATCH/agy-turn.sh" <<'EOF'
#!/usr/bin/env bash
printf 'DISPATCHED:%s\n' "$RELAY_AGENT"
EOF
chmod +x "$DISPATCH/agy-turn.sh"

for actor in agy agy-qa; do
  out="$(env -i PATH="$PATH" RELAY_AGENT="$actor" RELAY_FILE="$WORK/relay.md" \
      AGY_AGENT='agy,agy-qa' bash "$DISPATCH/marathon-agent.sh" 2>&1)"; rc=$?
  if [[ "$rc" -eq 0 && "$out" == "DISPATCHED:$actor" ]]; then
    pass "dispatcher routes same-lane actor $actor"
  else
    fail "dispatcher did not route $actor (rc=$rc out=$out)"
  fi
done

out="$(ROOT_UNDER_TEST="$ROOT" python3 - <<'PY'
import importlib.util
import os
import sys

root = os.environ["ROOT_UNDER_TEST"]
spec = importlib.util.spec_from_file_location("agy_turn_gh368", root + "/utils/py/agy-turn.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class ReachedAuth(Exception):
    pass

def reached_auth(_):
    raise ReachedAuth

module.agy_auth_preflight = reached_auth
os.environ.update({
    "RELAY_AGENT": "agy-qa",
    "RELAY_FILE": "/tmp/gh368-relay.md",
    "RELAY_TASK": "GH368-TURN",
    "AGY_AGENT": "agy,agy-qa",
})
try:
    module.main()
except ReachedAuth:
    print("AUTH_REACHED")
except SystemExit as exc:
    print(f"EXITED:{exc.code}")
PY
)"
if [[ "$out" == *AUTH_REACHED* ]]; then
  pass "agy-qa reaches the shim instead of deferring on AGY_AGENT equality"
else
  fail "agy-qa deferred before the shim's auth/ownership path (out=$out)"
fi

if grep -F -q 'claim_task_or_exit(' "$ROOT/utils/py/agy-turn.py"; then
  pass "agy shim retains the tick ownership guard"
else
  fail "agy shim lost claim_task_or_exit ownership enforcement"
fi

echo "  gh368-same-lane-routing: $PASS pass, $FAIL fail"
[[ "$FAIL" -eq 0 ]]
