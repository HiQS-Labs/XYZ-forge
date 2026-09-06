#!/usr/bin/env bash
# GH-460: standing fuzz smoke — the model-alias resolver's structural contract, enforced
# through the Gen4 fuzz engine (utils/py/fuzz_engine.py) driving test/gh460-oracle.sh.
#
# Green = engine exit 0 AND nonempty valid JSON summary AND executed >= 20 AND
# counts.fail == 0 AND counts.anomaly == 0, with the pre-fuzz environment pins passing
# at their EXACT observed values. Any missing/malformed summary fails closed.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
ORACLE="$HERE/gh460-oracle.sh"
ENGINE="$ROOT/utils/py/fuzz_engine.py"
SEED=7
ITERS=20
FLOOR=20
RESOLVER="$ROOT/relay-automation/resolve-model-alias.sh"

fail(){ echo "gh460-smoke: FAIL: $*" >&2; exit 1; }

[ -x "$ORACLE" ] || fail "oracle missing: $ORACLE"
[ -f "$ENGINE" ] || fail "engine missing: $ENGINE"
[ -f "$RESOLVER" ] || fail "resolver missing: $RESOLVER"

export LC_ALL=C
unset MODEL_ALIASES_FILE

# --- R1-pre: environment pins at EXACT observed values (resolver, direct) ---
out=$(bash "$RESOLVER" "glm-5.2" 2>/dev/null); rc=$?
if [ $rc -ne 0 ] || [ -z "$out" ]; then fail "known hit glm-5.2 observed rc=$rc out='${out:-}' (want rc 0, nonempty)"; fi
out=$(bash "$RESOLVER" "totally-unknown-model-xyz" 2>/dev/null); rc=$?
if [ $rc -ne 1 ] || [ -n "$out" ]; then fail "observed miss rc=$rc out='${out:-}' (want rc 1, empty)"; fi

# --- R1-pre: the oracle must pass both pins ---
bash "$ORACLE" "glm-5.2" >/dev/null 2>&1 || fail "oracle rejected the known hit (glm-5.2)"
bash "$ORACLE" "totally-unknown-model-xyz" >/dev/null 2>&1 || fail "oracle rejected the observed miss (totally-unknown-model-xyz)"

# --- R1-pre: wrapper mapping checks through model_alias.resolve_model_slug ---
PYTHONPATH="$ROOT/utils/py" python3 - "$ROOT" <<'PY' || fail "wrapper mapping checks failed"
import sys
root = sys.argv[1]
from model_alias import resolve_model_slug as r
assert r("glm-5.2", root) == "z-ai/glm-5.2", "glm-5.2 mapping changed"
assert r("deepseek v4 pro", root) == "deepseek/deepseek-v4-pro", "deepseek v4 pro mapping changed"
assert r("totally-unknown-model-xyz", root) == "totally-unknown-model-xyz", "miss passthrough broken"
assert r("", root) == "", "empty input identity broken"
PY

# --- R1: the fuzz run under the shared run contract ---
RUNDIR=$(mktemp -d "${TMPDIR:-/tmp}/gh460-smoke.XXXXXX")
TARGET="bash \"$ORACLE\" {mutant}"
python3 "$ENGINE" --mode fuzz \
  --target "$TARGET" \
  --base "glm-5.2" \
  --seed "$SEED" \
  --iterations "$ITERS" \
  --timeout-budget 30 \
  --cwd "$ROOT" \
  --corpus "$RUNDIR/.fuzz_corpus" \
  --telemetry-out "$RUNDIR/telemetry.jsonl" \
  --json > "$RUNDIR/summary.json" || fail "engine exited nonzero (see $RUNDIR)"

# --- fail-closed JSON summary assertions ---
PYTHONPATH="$ROOT/utils/py" python3 - "$RUNDIR/summary.json" "$FLOOR" <<'PY' || fail "summary assertions failed"
import json, sys
path, floor = sys.argv[1], int(sys.argv[2])
try:
    rep = json.load(open(path))
except Exception as exc:
    print(f"summary unreadable/malformed: {exc}"); raise SystemExit(1)
if not isinstance(rep, dict) or "executed" not in rep or "counts" not in rep:
    print(f"summary missing required keys: keys={sorted(rep)}"); raise SystemExit(1)
executed = rep["executed"]
counts = rep["counts"]
cf, ca = counts.get("fail"), counts.get("anomaly")
if not isinstance(executed, int) or executed < floor:
    print(f"executed={executed!r} < floor {floor}"); raise SystemExit(1)
if cf != 0 or ca != 0:
    print(f"counts.fail={cf!r} counts.anomaly={ca!r} (want 0/0)"); raise SystemExit(1)
if rep.get("counterexamples"):
    print(f"counterexamples present: {rep['counterexamples']!r}"); raise SystemExit(1)
print(f"gh460-smoke: green — executed={executed} fail=0 anomaly=0 counterexamples=0")
PY
echo "gh460-smoke: PASS"
