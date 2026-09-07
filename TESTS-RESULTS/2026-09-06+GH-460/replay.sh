#!/usr/bin/env bash
# GH-460 campaign replay — enforces the plan's shared run contract:
#   - adapter preflight exercises the DECODED adapter (preflight.py) before any campaign
#   - fresh per-invocation owned storage (refuses non-empty OUT)
#   - --json summaries validated against floors; cleanup is guarded (failures are retained)
# Run from the repo root:  bash TESTS-RESULTS/2026-09-06+GH-460/replay.sh [OUT]
set -euo pipefail
export LC_ALL=C
unset MODEL_ALIASES_FILE
ROOT="$(pwd)"
OUT="${1:-$(mktemp -d "${TMPDIR:-/tmp}/gh460-replay.XXXXXX")}"
if [ -e "$OUT" ] && [ -n "$(ls -A "$OUT" 2>/dev/null)" ]; then
  echo "replay: refusing non-empty OUT=$OUT (fresh storage required)" >&2; exit 2
fi
mkdir -p "$OUT/run" "$OUT/artifacts"
export GH460_RUN_DIR="$OUT/run"
RETAIN=0
cleanup() {
  if [ "${RETAIN:-0}" = "1" ]; then
    echo "replay: FAILURE — artifacts retained under $OUT (summaries/telemetry/oracle captures)" >&2
  else
    rm -rf "$OUT/run"
  fi
}
trap cleanup EXIT
fail(){ RETAIN=1; echo "replay: FAIL: $*" >&2; exit 1; }

# --- adapter preflight (exercises the DECODED adapter; see preflight.py) ---
python3 TESTS-RESULTS/2026-09-06+GH-460/preflight.py "$ROOT" || fail "adapter preflight"

# --- campaigns (floors enforced; engine exit alone is not trusted) ---
run(){ # run <name> <seed> <iters> <target> <floor>
  local name="$1" seed="$2" iters="$3" target="$4" floor="$5"
  mkdir -p "$OUT/artifacts/$name"
  python3 utils/py/fuzz_engine.py --mode fuzz --target "$target" --base "glm-5.2" \
    --seed "$seed" --iterations "$iters" --timeout-budget 30 --cwd "$ROOT" \
    --corpus "$OUT/artifacts/$name/.fuzz_corpus" --telemetry-out "$OUT/artifacts/$name/telemetry.jsonl" \
    --json > "$OUT/artifacts/$name/summary.json" || fail "$name: engine exit nonzero"
  python3 - "$OUT/artifacts/$name/summary.json" "$floor" "$name" <<'PY' || { RETAIN=1; exit 1; }
import json, sys
d = json.load(open(sys.argv[1])); floor = int(sys.argv[2]); name = sys.argv[3]
assert isinstance(d, dict) and d.get("executed") is not None and "counts" in d, f"{name}: bad summary"
assert d["executed"] >= floor, f"{name}: executed {d['executed']} < {floor}"
assert d["counts"].get("fail") == 0 and d["counts"].get("anomaly") == 0, f"{name}: counts {d['counts']}"
assert not d.get("counterexamples"), f"{name}: counterexamples present"
print(f"replay: {name} green - executed={d['executed']}")
PY
}
ORACLE_TARGET='bash test/gh460-oracle.sh {mutant}'
WRAPPER_TARGET="$(cat TESTS-RESULTS/2026-09-06+GH-460/wrapper-target.txt)"
run "seed7" 7 500 "$ORACLE_TARGET" 500
run "seed8" 8 500 "$ORACLE_TARGET" 500
run "seed9" 9 500 "$ORACLE_TARGET" 500
run "wrapper-seed11" 11 300 "$WRAPPER_TARGET" 300
echo "replay: all campaigns green — artifacts under $OUT/artifacts"
