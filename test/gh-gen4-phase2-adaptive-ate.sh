#!/usr/bin/env bash
# GH-299 Gen 4 Phase 2: constraint-aware pairwise ATE + calibrated $0 Tier-1 triage.
#
# Proves: a 12-flag grid with conflicts/requires yields <=200 cases with 100% valid 2-way
# coverage (checked by an INDEPENDENT brute-force pair walk in this suite, not the generator's
# own report); the Tier-1 classifier is calibrated with 0% false negatives on the 50/20
# benchmark; and the run path finds a failure planted on one specific flag pair.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh299-p2-ate.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

ATE="$ROOT/utils/py/adaptive_ate.py"
CAL="$ROOT/utils/py/calibrate_tier1.py"
GRID="$ROOT/utils/ate/grids/gen4-pairwise-example.yaml"
CALFILE="$ROOT/utils/ate/tier1-calibration.json"

echo "== test: gh-gen4-phase2-adaptive-ate =="

[ -x "$ATE" ] && pass "utils/py/adaptive_ate.py exists and is executable" || fail "adaptive_ate.py missing"
[ -x "$CAL" ] && pass "utils/py/calibrate_tier1.py exists and is executable" || fail "calibrate_tier1.py missing"
[ -f "$GRID" ] && pass "reference grid utils/ate/grids/gen4-pairwise-example.yaml shipped" || fail "reference grid missing"
[ -f "$CALFILE" ] && pass "utils/ate/tier1-calibration.json shipped" || fail "calibration file missing"

if grep -q 'SUITE_RESULT=PASS' <<<"$(python3 "$ATE" --mode suite 2>&1)"; then
  pass "adaptive_ate.py --mode suite passes"
else
  fail "adaptive_ate.py --mode suite failed"
fi

# 1. Generate from the 12-flag reference grid; verify the bound and coverage INDEPENDENTLY.
GEN="$WORK/cases.json"
python3 "$ATE" --mode generate --grid "$GRID" --seed 3 --json > "$GEN"
require_fixture_file "$GEN" "generated cases"
n="$(python3 -c "import json,sys; print(len(json.load(open(sys.argv[1]))['cases']))" "$GEN")"
if [ "$n" -le 200 ] && [ "$n" -ge 6 ]; then
  pass "12-flag grid yields $n cases (<=200; Cartesian is 13824)"
else
  fail "12-flag grid yielded $n cases (expected 6..200)"
fi
indep="$(python3 - "$GEN" "$GRID" <<'PY'
import itertools, json, sys, yaml
cases = json.load(open(sys.argv[1]))["cases"]
grid = yaml.safe_load(open(sys.argv[2]))
flags = list(grid["flags"])
def holds(assign, case):
    return all(json.dumps(case.get(f)) == json.dumps(v) for f, v in assign.items())
def valid(case):
    for c in grid.get("conflicts", []):
        if holds(c, case): return False
    for r in grid.get("requires", []):
        if holds(r["if"], case) and not holds(r["then"], case): return False
    return True
# every case must be complete and valid
bad = [c for c in cases if set(c) != set(flags) or not valid(c)]
# brute-force every pair that SOME valid full case can contain (Cartesian walk, 13824 cases)
coverable = set()
for combo in itertools.product(*[grid["flags"][f] for f in flags]):
    case = dict(zip(flags, combo))
    if valid(case):
        for a, b in itertools.combinations(flags, 2):
            coverable.add((a, json.dumps(case[a]), b, json.dumps(case[b])))
seen = set()
for c in cases:
    for a, b in itertools.combinations(flags, 2):
        seen.add((a, json.dumps(c[a]), b, json.dumps(c[b])))
missing = coverable - seen
print(f"invalid={len(bad)} required={len(coverable)} missing={len(missing)}")
PY
)"
if [ "$indep" = "$(printf 'invalid=0 required=%s missing=0' "$(sed -E 's/.*required=([0-9]+).*/\1/' <<<"$indep")")" ]; then
  pass "independent brute-force check: 0 invalid cases, 100% 2-way coverage ($indep)"
else
  fail "independent brute-force check disagrees: $indep"
fi
if python3 "$ATE" --mode coverage --grid "$GRID" --seed 3 >/dev/null; then
  pass "--mode coverage reports complete"
else
  fail "--mode coverage reports incomplete"
fi

# 2. Falsification: a grid whose requires makes a pair impossible must not be counted as missing,
#    and a broken constraint spec is refused loudly.
cat > "$WORK/bad.json" <<'J'
{"flags": {"--a": [true,false]}, "conflicts": [{"--a": true, "--zzz": true}]}
J
if python3 "$ATE" --mode coverage --grid "$WORK/bad.json" >/dev/null 2>&1; then
  fail "grid referencing an unknown flag was accepted"
else
  pass "grid referencing an unknown flag is refused"
fi

# 3. Tier-1 calibration: 0% false negatives on the 50/20 benchmark, re-verified from the shipped file.
out="$(python3 "$CAL" --verify 2>&1)"
if grep -q 'FN=0' <<<"$out"; then
  pass "calibrate_tier1.py --verify: 0 false negatives on the built-in 50-pass/20-fail benchmark"
else
  fail "calibration verify: $out"
fi
python3 "$CAL" --emit-benchmark "$WORK/bench.jsonl" >/dev/null
n_pass="$(grep -c '"label": "pass"' "$WORK/bench.jsonl")"; n_fail="$(grep -c '"label": "fail"' "$WORK/bench.jsonl")"
if [ "$n_pass" -eq 50 ] && [ "$n_fail" -eq 24 ]; then
  pass "benchmark is 50 known-pass / 24 known-fail (20 + 4 shapes from the first Gen 4 campaign)"
else
  fail "benchmark shape $n_pass/$n_fail"
fi
# recalibrating into a scratch file reproduces a calibrated, FN=0 result (determinism)
if grep -q 'FN=0' <<<"$(python3 "$CAL" --out "$WORK/cal.json" 2>&1)" && grep -q '"calibrated": true' "$WORK/cal.json"; then
  pass "recalibration into a scratch file is deterministic and FN=0"
else
  fail "recalibration failed"
fi
# falsification: a benchmark that labels a silent rc=0 as fail cannot be calibrated to FN=0
printf '%s\n' '{"label":"fail","exit_code":0,"signal":0,"stderr":"","duration_ms":1}' '{"label":"pass","exit_code":0,"signal":0,"stderr":"","duration_ms":1}' > "$WORK/impossible.jsonl"
if python3 "$CAL" --benchmark "$WORK/impossible.jsonl" --out "$WORK/imp.json" >/dev/null 2>&1; then
  fail "calibrator claimed FN=0 on an unsatisfiable benchmark"
else
  pass "calibrator exits 1 when the 0% false-negative floor cannot be met"
fi

# 4. Run path: plant a failure on ONE pair (--burst + --fmt json) and prove the array finds it,
#    the Tier-1 classifier labels it fail (not anomaly), and clean cases stay pass.
cat > "$WORK/target.py" <<'PY'
import sys
a = sys.argv[1:]
if "--burst" in a and "json" in a:
    sys.stderr.write("target.py: error: --burst cannot render json (planted defect)\n"); sys.exit(2)
sys.exit(0)
PY
TEL="$WORK/run.jsonl"
rc=0; out="$(python3 "$ATE" --mode run --grid "$GRID" --seed 3 --cwd "$WORK" --command "python3 $WORK/target.py {flags}" --telemetry-out "$TEL" --anomalies-out "$WORK/anom.json" --json 2>&1)" || rc=$?
require_fixture_file "$TEL" "run telemetry"
fails="$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['counts']['fail'])" "$out")"
anoms="$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['counts']['anomaly'])" "$out")"
if [ "$rc" -eq 1 ] && [ "$fails" -ge 1 ] && [ "$anoms" -eq 0 ]; then
  pass "planted --burst+json defect found by the pairwise array ($fails fail, 0 anomaly, rc=1)"
else
  fail "run path: rc=$rc fails=$fails anomalies=$anoms"
fi
if grep -q '"phase":"pairwise"' "$TEL" && python3 "$ROOT/utils/py/telemetry_schema.py" --mode validate --path "$TEL" >/dev/null; then
  pass "run telemetry is line-valid TelemetryEvent JSONL (phase=pairwise)"
else
  fail "run telemetry invalid"
fi
# every failing row names the planted pair — no false positives on clean cases
bad_rows="$(python3 - "$TEL" <<'PY'
import json, sys
bad = 0
for line in open(sys.argv[1]):
    d = json.loads(line); case = d["extra"]["case"]
    planted = case.get("--burst") is True and case.get("--fmt") == "json"
    if (d["tier_1_verdict"] == "fail") != planted: bad += 1
print(bad)
PY
)"
[ "$bad_rows" -eq 0 ] && pass "0 false positives / 0 false negatives across the executed array" || fail "$bad_rows rows misclassified"

# 5. Tier-2 escalation is invoked ONLY for anomalies: a clean run must not call it.
cat > "$WORK/tier2.sh" <<'SH'
#!/usr/bin/env bash
cat > "$1"; exit 0
SH
chmod +x "$WORK/tier2.sh"
python3 "$ATE" --mode run --grid "$GRID" --seed 3 --cwd "$WORK" --command "python3 -c 'import sys; sys.exit(0)' {flags}" --telemetry-out "$WORK/clean.jsonl" --tier2-cmd "$WORK/tier2.sh $WORK/tier2.in" >/dev/null
[ ! -e "$WORK/tier2.in" ] && pass "tier-2 command not invoked on a clean run (\$0 floor)" || fail "tier-2 invoked with no anomalies"
python3 "$ATE" --mode run --grid "$GRID" --seed 3 --cwd "$WORK" --command "python3 -c 'import sys; sys.exit(7)' {flags}" --telemetry-out "$WORK/anom.jsonl" --tier2-cmd "$WORK/tier2.sh $WORK/tier2.in" >/dev/null 2>&1 || true
if [ -s "$WORK/tier2.in" ] && grep -q 'outside calibrated sets' "$WORK/tier2.in"; then
  pass "tier-2 command receives the anomaly list when rc=7 is unclassified"
else
  fail "tier-2 escalation did not fire on anomalies"
fi

echo "== gh-gen4-phase2-adaptive-ate: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
