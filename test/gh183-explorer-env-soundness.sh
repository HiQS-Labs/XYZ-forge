#!/usr/bin/env bash
# GH-183: explorer env-family soundness. Mutations derive from a declared base env and execute
# over a CLEAN environment — ambient runner vars provably cannot satisfy "missing key" vectors.
# Pre-fix behavior: base_env={} produced exactly one always-deferring vector, and ambient
# RELAY_* leaked through os.environ.copy() (see test/baselines/GH-183-negative-control.md,
# soak evidence #177 §3.4).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh183-env-soundness.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "== test: gh183-explorer-env-soundness =="

# Sentinel: if ambient env could leak into probes, this value would appear everywhere.
export RELAY_AGENT=ambient-sentinel-gh183
export RELAY_FILE=ambient-sentinel-file

# 1. Clean-env unit proof: a fixture echoing RELAY_AGENT sees UNSET despite the ambient sentinel.
ECHOER="$WORK/echo_agent.sh"
printf '#!/usr/bin/env bash\necho "AGENT=${RELAY_AGENT:-UNSET}"\nexit 0\n' > "$ECHOER"
chmod +x "$ECHOER"
require_fixture_file "$ECHOER" "echoer"
rc=0; out="$(python3 "$ROOT/utils/py/active_explorer.py" --mode explore --family env --target-cmd "bash $ECHOER" --rounds 4 --json 2>/dev/null)" || rc=$?
if [ "$rc" -eq 0 ] && grep -q "ambient-sentinel-gh183" <<<"$out"; then
  fail "ambient RELAY_AGENT leaked into explorer probes (clean-env discipline broken)"
elif [ "$rc" -eq 0 ]; then
  pass "explorer probes run without ambient RELAY_AGENT leaking in"
else
  fail "explorer env-family run failed (rc=$rc, out=$out)"
fi

# 2. Real-shim env vectors: with a declared base, the missing/empty families execute and the
#    shim's env validation fires (rc 2) even though the AMBIENT sentinel is set.
rc=0; out="$(python3 "$ROOT/utils/py/active_explorer.py" --mode explore --family env \
  --target-cmd "bash relay-automation/agy-turn.sh" \
  --base-env RELAY_AGENT=tester --base-env RELAY_FILE=RELAY.md \
  --rounds 12 --json 2>/dev/null)" || rc=$?
if [ "$rc" -ne 0 ]; then
  fail "explorer env-family against agy-turn.sh failed (rc=$rc, out=$out)"
else
  rc2=0; out2="$(python3 -c "
import json,subprocess,sys
raw = sys.stdin.read()
start = raw.find('{')
data = json.loads(raw[start:]) if start >= 0 else {}
recs = data.get('records', [])
assert data.get('total_probes', 0) >= 5, f\"expected >=5 probes, got {data.get('total_probes')}\"
for r in recs:
    assert r.get('rc') == 2, f'env probe rc != 2: {r}'
print('VECTORS_OK')
" <<<"$out" 2>&1)" || rc2=$?
  if [ "$rc2" -eq 0 ] && grep -q "VECTORS_OK" <<<"$out2"; then
    pass "declared base env drives >=5 missing/empty vectors; every probe hits env validation (rc 2) despite ambient sentinel"
  else
    fail "env vector verification failed (rc=$rc2, out=$out2)"
  fi
fi

# 3. --base-env validation: malformed KEY (no =) is refused loudly.
rc=0; out="$(python3 "$ROOT/utils/py/active_explorer.py" --mode explore --family env --target-cmd "bash $ECHOER" --base-env NOTAPAIR 2>&1)" || rc=$?
if [ "$rc" -eq 2 ] && grep -q "KEY=VAL" <<<"$out"; then
  pass "malformed --base-env refused with guidance"
else
  fail "malformed --base-env not refused (rc=$rc, out=$out)"
fi

echo "  gh183-explorer-env-soundness: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
