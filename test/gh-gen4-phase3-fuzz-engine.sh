#!/usr/bin/env bash
# GH-299 Gen 4 Phase 3: feedback-guided mutational fuzz engine — seed replay, corpus growth,
# novelty eviction at the cap, collision-keeps-smaller, and the cross-twin parity oracle.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh299-p3-fuzz.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FUZZ="$ROOT/utils/py/fuzz_engine.py"
SCHEMA="$ROOT/utils/py/telemetry_schema.py"
PY="$(command -v python3)"

echo "== test: gh-gen4-phase3-fuzz-engine =="

[ -x "$FUZZ" ] && pass "utils/py/fuzz_engine.py exists and is executable" || fail "fuzz_engine.py missing"
if grep -q 'SUITE_RESULT=PASS' <<<"$(python3 "$FUZZ" --mode suite 2>&1)"; then
  pass "fuzz_engine.py --mode suite passes (17 embedded checks)"
else
  fail "fuzz_engine.py --mode suite failed"
fi
grep -q '^\.fuzz_corpus/$' "$ROOT/.gitignore" && pass ".fuzz_corpus/ is gitignored" || fail ".fuzz_corpus/ not in .gitignore"

# 1. Deterministic seed replay through the CLI: identical plans, byte for byte.
python3 "$FUZZ" --mode plan --target "$PY tool.py {mutant}" --base "--jobs 4 --mode fast" --seed 99 --iterations 40 --json > "$WORK/plan-a.json"
python3 "$FUZZ" --mode plan --target "$PY tool.py {mutant}" --base "--jobs 4 --mode fast" --seed 99 --iterations 40 --json > "$WORK/plan-b.json"
python3 "$FUZZ" --mode plan --target "$PY tool.py {mutant}" --base "--jobs 4 --mode fast" --seed 100 --iterations 40 --json > "$WORK/plan-c.json"
require_fixture_file "$WORK/plan-a.json" "plan a"
cmp -s "$WORK/plan-a.json" "$WORK/plan-b.json" && pass "seed replay: --seed 99 yields a byte-identical plan twice" || fail "seed replay diverged"
! cmp -s "$WORK/plan-a.json" "$WORK/plan-c.json" && pass "seed replay: --seed 100 yields a different plan (control)" || fail "different seeds produced the same plan"

# 2. Fuzz a fixture that crashes on a boundary token; corpus must grow; telemetry must be valid.
cat > "$WORK/tool.py" <<'PY'
import sys
a = sys.argv[1:]
if "-1" in a:
    sys.stderr.write("Traceback (most recent call last):\n  ValueError: negative jobs\n"); sys.exit(1)
if any(t.startswith("--") and t not in ("--jobs", "--mode") for t in a):
    sys.stderr.write("usage: tool.py --jobs N --mode M\n"); sys.exit(2)
sys.exit(0)
PY
rc=0; out="$(python3 "$FUZZ" --mode fuzz --target "$PY $WORK/tool.py {mutant}" --base "--jobs 4 --mode fast" --seed 7 --iterations 150 --cwd "$WORK" --corpus "$WORK/corpus" --telemetry-out "$WORK/fuzz.jsonl" --timeout-budget 10 --json 2>&1)" || rc=$?
require_fixture "$WORK/corpus" "fuzz corpus"
executed="$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['executed'])" "$out")"
cex="$(python3 -c "import json,sys; print(len(json.loads(sys.argv[1])['counterexamples']))" "$out")"
corpus="$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['corpus_size'])" "$out")"
[ "$executed" -eq 150 ] && pass "150 mutants executed" || fail "executed=$executed"
[ "$rc" -eq 1 ] && [ "$cex" -ge 1 ] && pass "planted traceback found: $cex counterexample(s), rc=1" || fail "rc=$rc counterexamples=$cex"
[ "$corpus" -ge 2 ] && pass "corpus grew to $corpus distinct feedback signatures" || fail "corpus_size=$corpus"
n_files="$(ls "$WORK/corpus"/*.json | wc -l | tr -d ' ')"
[ "$n_files" -eq "$corpus" ] && pass "corpus persisted on disk ($n_files entries)" || fail "disk corpus $n_files != $corpus"
python3 "$SCHEMA" --mode validate --path "$WORK/fuzz.jsonl" >/dev/null && pass "fuzz telemetry is line-valid TelemetryEvent JSONL" || fail "fuzz telemetry invalid"
[ "$(grep -c '"phase":"fuzz"' "$WORK/fuzz.jsonl")" -eq 150 ] && pass "one telemetry row per mutant (phase=fuzz)" || fail "telemetry row count"
grep -q '"handled_rejection":true' "$WORK/fuzz.jsonl" && pass "usage errors are recorded as handled rejections, not counterexamples" || fail "no handled_rejection rows"
# every counterexample row names the traceback signature, no clean row does
misclass="$(python3 - "$WORK/fuzz.jsonl" <<'PY'
import json, sys
bad = 0
for line in open(sys.argv[1]):
    d = json.loads(line); s = d["extra"].get("stderr_sample", "")
    if ("Traceback" in s) != (d["tier_1_verdict"] == "fail" and not d["extra"].get("handled_rejection")): bad += 1
print(bad)
PY
)"
[ "$misclass" -eq 0 ] && pass "0 misclassified rows across 150 mutants" || fail "$misclass misclassified rows"

# 3. Replay a corpus entry by id and prove the recorded vector reproduces.
first_id="$(python3 -c "import json,sys; c=json.loads(sys.argv[1])['counterexamples']; print(c[0]['corpus_id'] or '')" "$out")"
if [ -n "$first_id" ]; then
  if python3 "$FUZZ" --mode replay --corpus "$WORK/corpus" --id "$first_id" --target "$PY $WORK/tool.py {mutant}" --cwd "$WORK" >/dev/null; then
    pass "corpus entry $first_id replays to the recorded feedback vector"
  else
    fail "replay of $first_id did not reproduce"
  fi
else
  fail "counterexample had no corpus id"
fi

# 4. Novelty-weighted eviction holds the cap: a 500-cap corpus never exceeds 500 (small cap here).
rm -rf "$WORK/corpus2"
cat > "$WORK/noisy.py" <<'PY'
import sys, hashlib
# many distinct signatures: exit code derived from the argv hash
sys.exit(int(hashlib.sha256(" ".join(sys.argv[1:]).encode("utf-8","replace")).hexdigest(), 16) % 7)
PY
python3 "$FUZZ" --mode fuzz --target "$PY $WORK/noisy.py {mutant}" --base "a b c d" --seed 3 --iterations 120 --cwd "$WORK" --corpus "$WORK/corpus2" --corpus-cap 6 --timeout-budget 10 --json > "$WORK/noisy.json" 2>&1 || true
n2="$(ls "$WORK/corpus2"/*.json | wc -l | tr -d ' ')"
[ "$n2" -le 6 ] && pass "corpus honours --corpus-cap 6 under 120 novel-ish mutants ($n2 on disk)" || fail "corpus exceeded cap: $n2"
grep -q '"evicted+added"' "$WORK/noisy.json" && pass "novelty-weighted eviction fired" || fail "no eviction recorded"

# 5. Cross-twin parity oracle on a fixture twin, then a bounded run against the REAL turn-shim
#    twins (bash vs XYZ_PYTHON=0) in a disposable clone — must complete and stay line-valid.
cat > "$WORK/twin.py" <<'PY'
import os, sys
if os.environ.get("TWIN") == "1" and "0" in sys.argv[1:]:
    sys.stderr.write("twin: zero unsupported\n"); sys.exit(2)
sys.exit(0)
PY
out5="$(python3 "$FUZZ" --mode fuzz --target "$PY $WORK/twin.py {mutant}" --base "x y" --seed 11 --iterations 80 --cwd "$WORK" --corpus "$WORK/corpus3" --parity-env TWIN=1 --timeout-budget 10 --json 2>&1 || true)"
div="$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['parity_divergences'])" "$out5")"
[ "$div" -ge 1 ] && pass "parity oracle flags $div divergence(s) between authoritative and twin env" || fail "parity oracle silent on a diverging twin"
out6="$(python3 "$FUZZ" --mode fuzz --target "$PY $WORK/twin.py {mutant}" --base "x y" --seed 11 --iterations 40 --cwd "$WORK" --corpus "$WORK/corpus4" --parity-env TWIN=0 --timeout-budget 10 --json 2>&1 || true)"
div6="$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['parity_divergences'])" "$out6")"
[ "$div6" -eq 0 ] && pass "parity oracle silent when twins agree (control)" || fail "false parity divergence: $div6"

SANDBOX="$WORK/clone"
git clone -q "$ROOT" "$SANDBOX"
require_fixture "$SANDBOX" "sandbox clone"
rc=0; out7="$(python3 "$FUZZ" --mode fuzz --target "bash relay-automation/codex-turn.sh {mutant}" --base=--help --seed 5 --iterations 12 --cwd "$SANDBOX" --corpus "$WORK/corpus5" --telemetry-out "$WORK/parity.jsonl" --parity-env XYZ_PYTHON=0 --timeout-budget 20 --json 2>&1)" || rc=$?
if python3 "$SCHEMA" --mode validate --path "$WORK/parity.jsonl" >/dev/null && [ "$(grep -c '"phase":"fuzz"' "$WORK/parity.jsonl")" -eq 12 ]; then
  d7="$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['parity_divergences'])" "$out7")"
  pass "real twin run: 12 mutants through codex-turn.sh vs XYZ_PYTHON=0 completed (parity divergences: $d7, informational)"
else
  fail "real twin run did not complete cleanly (rc=$rc)"
fi
# the disposable clone must not have been touched outside .fuzz_corpus/ (containment)
if [ -z "$(git -C "$SANDBOX" status --porcelain | grep -v '^?? .fuzz_corpus/' || true)" ]; then
  pass "sandbox clone tree unchanged after the real twin run"
else
  fail "sandbox clone mutated: $(git -C "$SANDBOX" status --porcelain | head -3)"
fi

echo "== gh-gen4-phase3-fuzz-engine: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
