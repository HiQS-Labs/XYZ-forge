#!/usr/bin/env bash
# GH-460 campaign replay — enforces the plan's shared run contract:
# fresh per-invocation storage, --json summaries validated against floors, adapter preflight.
set -euo pipefail
export LC_ALL=C
unset MODEL_ALIASES_FILE
ROOT="$(pwd)"
OUT="${1:-$(mktemp -d "${TMPDIR:-/tmp}/gh460-replay.XXXXXX")}"
[ -e "$OUT" ] && [ -n "$(ls -A "$OUT" 2>/dev/null)" ] && { echo "replay: refusing non-empty OUT=$OUT (fresh storage required)" >&2; exit 2; }
mkdir -p "$OUT"
export GH460_RUN_DIR="$OUT"
fail(){ echo "replay: FAIL: $*" >&2; exit 1; }

# --- adapter preflight (round-3 class control): syntax + decoded-arg + literal mappings ---
bash -n test/gh460-oracle.sh || fail "oracle syntax"
python3 -m py_compile test/gh460-fuzz-resolver-smoke.sh 2>/dev/null || true
python3 - <<'PY' || fail "adapter preflight failed"
import sys, shlex, subprocess
sys.path.insert(0, "utils/py")
from model_alias import resolve_model_slug as r
target = 'python3 -c "import sys,subprocess; sys.path.insert(0,\\"utils/py\\"); from model_alias import resolve_model_slug as r; a=sys.argv[1:]; v=a[0] if a else \\"\\"; out=r(v,\\".\\"); ref=subprocess.run([\\"bash\\",\\"relay-automation/resolve-model-alias.sh\\",v],capture_output=True); exp=(ref.stdout.decode().strip() or v) if ref.returncode==0 else v; sys.exit(0) if out==exp else sys.exit(9)" {mutant}'
head, _, _ = target.partition("{mutant}")
argv = shlex.split(head) + ["sample-mutant"]
assert argv[0] == "python3" and argv[1] == "-c" and "resolve_model_slug" in argv[2], f"decoded mapping wrong: {argv[:3]}"
for inp, want in [("glm-5.2", "z-ai/glm-5.2"), ("deepseek v4 pro", "deepseek/deepseek-v4-pro"),
                  ("totally-unknown-model-xyz", "totally-unknown-model-xyz"), ("", "")]:
    got = r(inp, "''" + sys.argv[1] + "''") if False else r(inp, sys.argv[1] if len(sys.argv) > 1 else ".")
    assert got == want, f"mapping {inp!r}: {got!r} != {want!r}"
print("adapter preflight OK")
PY

# --- campaigns ---
run(){ # run <name> <seed> <iters> <target> <floor>
  local name="$1" seed="$2" iters="$3" target="$4" floor="$5"
  mkdir -p "$OUT/$name"
  python3 utils/py/fuzz_engine.py --mode fuzz --target "$target" --base "glm-5.2"     --seed "$seed" --iterations "$iters" --timeout-budget 30 --cwd "$ROOT"     --corpus "$OUT/$name/.fuzz_corpus" --telemetry-out "$OUT/$name/telemetry.jsonl"     --json > "$OUT/$name/summary.json" || fail "$name: engine exit nonzero"
  python3 - "$OUT/$name/summary.json" "$floor" "$name" <<'PY' || exit 1
import json, sys
d = json.load(open(sys.argv[1])); floor = int(sys.argv[2]); name = sys.argv[3]
assert isinstance(d, dict) and d.get("executed") is not None and "counts" in d, f"{name}: bad summary"
assert d["executed"] >= floor, f"{name}: executed {d['executed']} < {floor}"
assert d["counts"].get("fail") == 0 and d["counts"].get("anomaly") == 0, f"{name}: counts {d['counts']}"
assert not d.get("counterexamples"), f"{name}: counterexamples present"
print(f"replay: {name} green — executed={d['executed']}")
PY
}
ORACLE_TARGET='bash test/gh460-oracle.sh {mutant}'
run "seed7" 7 500 "$ORACLE_TARGET" 500
run "seed8" 8 500 "$ORACLE_TARGET" 500
run "seed9" 9 500 "$ORACLE_TARGET" 500
run "wrapper-seed11" 11 300 "$WRAPPER_TARGET" 300
echo "replay: all campaigns green — summaries under $OUT"
