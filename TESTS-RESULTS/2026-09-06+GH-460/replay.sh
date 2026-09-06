#!/usr/bin/env bash
# GH-460 campaign replay — run from the repo root of the branch/clone under test.
set -euo pipefail
export LC_ALL=C
unset MODEL_ALIASES_FILE
OUT="${1:-/tmp/gh460-replay}"
mkdir -p "$OUT"
for S in 7 8 9; do
  mkdir -p "$OUT/seed$S"
  python3 utils/py/fuzz_engine.py --mode fuzz \
    --target 'bash test/gh460-oracle.sh {mutant}' \
    --base "glm-5.2" --seed "$S" --iterations 500 --timeout-budget 30 \
    --cwd "$(pwd)" --corpus "$OUT/seed$S/.fuzz_corpus" \
    --telemetry-out "$OUT/seed$S/telemetry.jsonl" --json > "$OUT/seed$S/summary.json"
done
mkdir -p "$OUT/wrapper-seed11"
python3 utils/py/fuzz_engine.py --mode fuzz \
  --target 'python3 -c "import sys,subprocess; sys.path.insert(0,\"utils/py\"); from model_alias import resolve_model_slug as r; a=sys.argv[1:]; v=a[0] if a else \"\"; out=r(v,\".\"); ref=subprocess.run([\"bash\",\"relay-automation/resolve-model-alias.sh\",v],capture_output=True); exp=(ref.stdout.decode().strip() or v) if ref.returncode==0 else v; sys.exit(0) if out==exp else sys.exit(9)" {mutant}' \
  --base "glm-5.2" --seed 11 --iterations 300 --timeout-budget 30 \
  --cwd "$(pwd)" --corpus "$OUT/wrapper-seed11/.fuzz_corpus" \
  --telemetry-out "$OUT/wrapper-seed11/telemetry.jsonl" --json > "$OUT/wrapper-seed11/summary.json"
echo "replay complete — summaries under $OUT"
