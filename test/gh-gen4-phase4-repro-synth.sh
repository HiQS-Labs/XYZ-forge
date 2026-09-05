#!/usr/bin/env bash
# GH-299 Gen 4 Phase 4: clustered hermetic reproducer synthesis — a counterexample cluster
# automatically becomes ONE runnable, minimized test/ghXXX-*.sh suite; 50 mutations of the same
# root cause emit exactly one suite; the emitted suite goes red once the defect is fixed.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh299-p4-synth.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"

PASS=0; FAIL=0
pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SYNTH="$ROOT/utils/py/repro_synth.py"
BUILDER="$ROOT/utils/py/repro_builder.py"
FUZZ="$ROOT/utils/py/fuzz_engine.py"
PY="$(command -v python3)"

echo "== test: gh-gen4-phase4-repro-synth =="

[ -x "$SYNTH" ] && pass "utils/py/repro_synth.py exists and is executable" || fail "repro_synth.py missing"
if grep -q 'SUITE_RESULT=PASS' <<<"$(python3 "$SYNTH" --mode suite 2>&1)"; then
  pass "repro_synth.py --mode suite passes (15 embedded checks incl. falsification)"
else
  fail "repro_synth.py --mode suite failed"
fi
if grep -q 'SUITE_RESULT=PASS' <<<"$(python3 "$BUILDER" --mode suite 2>&1)"; then
  pass "repro_builder.py --mode suite still passes (Gen 3 minimizers untouched)"
else
  fail "repro_builder.py --mode suite regressed"
fi

# Fixture "repo": the real fixture-guard, a tool with two root causes, and a usage path.
FIX="$WORK/repo"; mkdir -p "$FIX/test/lib"
cp "$ROOT/test/lib/fixture-guard.sh" "$FIX/test/lib/fixture-guard.sh"
cat > "$FIX/tool.py" <<'PY'
import sys
a = sys.argv[1:]
if "-1" in a:
    sys.stderr.write("Traceback (most recent call last):\n  File \"tool.py\", line 9\nValueError: negative jobs\n"); sys.exit(1)
if any("‮" in x for x in a):
    sys.stderr.write("UnicodeError: rtl override in argv\n"); sys.exit(1)
if any(x.startswith("--") and x not in ("--jobs", "--mode") for x in a):
    sys.stderr.write("usage: tool.py --jobs N --mode M\n"); sys.exit(2)
sys.exit(0)
PY
require_fixture "$FIX" "fixture repo"

# 1. Fuzz -> telemetry (300 mutants), then cluster.
TEL="$WORK/fuzz.jsonl"
python3 "$FUZZ" --mode fuzz --target "$PY tool.py {mutant}" --base "--jobs 4 --mode fast" --seed 7 --iterations 300 --cwd "$FIX" --corpus "$WORK/corpus" --telemetry-out "$TEL" --timeout-budget 10 --json > "$WORK/fuzz.json" 2>&1 || true
require_fixture_file "$TEL" "fuzz telemetry"
cex="$(python3 -c "import json; print(len(json.load(open('$WORK/fuzz.json'))['counterexamples']))")"
[ "$cex" -ge 4 ] && pass "fuzz produced $cex counterexamples across 300 mutants" || fail "only $cex counterexamples"
python3 "$SYNTH" --mode cluster --telemetry "$TEL" --json > "$WORK/clusters.json"
nclu="$(python3 -c "import json; print(len(json.load(open('$WORK/clusters.json'))))")"
[ "$nclu" -ge 1 ] && [ "$nclu" -le 3 ] && pass "$cex counterexamples collapse to $nclu root-cause cluster(s)" || fail "cluster count $nclu"
if ! grep -q 'usage: tool.py' "$WORK/clusters.json"; then
  pass "handled usage rejections are excluded from clusters"
else
  fail "usage rejections leaked into clusters"
fi

# 2. Synthesize: one minimized, executable, hermetic suite per cluster; each PASSES (defect reproduces).
python3 "$SYNTH" --mode synth --telemetry "$TEL" --out-dir "$FIX/test" --issue 299 --repo-root "$FIX" --json > "$WORK/synth.json"
nemit="$(python3 -c "import json; print(len(json.load(open('$WORK/synth.json'))['emitted']))")"
nskip="$(python3 -c "import json; print(len(json.load(open('$WORK/synth.json'))['skipped']))")"
[ "$nemit" -eq "$nclu" ] && [ "$nskip" -eq 0 ] && pass "one suite emitted per cluster ($nemit), 0 skipped" || fail "emitted=$nemit skipped=$nskip clusters=$nclu"
for f in "$FIX"/test/gh299-gen4-*.sh; do
  require_fixture_file "$f" "emitted suite"
  base="$(basename "$f")"
  [ -x "$f" ] && grep -q 'fixture-guard.sh' "$f" && grep -q 'Synthesized by utils/py/repro_synth.py' "$f" \
    && pass "$base is executable, sources fixture-guard, carries provenance" || fail "$base malformed"
  if XYZ_ROOT="$FIX" bash "$f" >/dev/null 2>&1; then
    pass "$base PASSES while the defect reproduces"
  else
    fail "$base did not reproduce the defect"
  fi
done
# ddmin actually shrank the argv
python3 - "$WORK/synth.json" <<'PY' && pass "every emitted suite carries a ddmin-minimized argv (<= original)" || fail "minimization did not shrink"
import json, sys
e = json.load(open(sys.argv[1]))["emitted"]
sys.exit(0 if e and all(x["minimized_to"] <= x["minimized_from"] for x in e) and any(x["minimized_to"] < x["minimized_from"] for x in e) else 1)
PY
# signature assertion names the error class, not a volatile path/line number
if grep -q 'ValueError: negative jobs' "$FIX"/test/gh299-gen4-*valueerror*.sh 2>/dev/null; then
  pass "emitted assertion targets the stable error line (ValueError: negative jobs)"
else
  fail "emitted assertion did not pick the stable error line"
fi

# 3. Falsification: fix the tool -> every emitted suite must go RED.
printf 'import sys\nsys.exit(0)\n' > "$FIX/tool.py"
red=0; total=0
for f in "$FIX"/test/gh299-gen4-*.sh; do
  total=$((total + 1))
  XYZ_ROOT="$FIX" bash "$f" >/dev/null 2>&1 || red=$((red + 1))
done
[ "$red" -eq "$total" ] && [ "$total" -ge 1 ] && pass "all $total emitted suites fail once the defect is fixed" || fail "$red/$total suites went red after the fix"

# 4. Cluster-before-minimization: 50 mutations of ONE root cause -> exactly ONE suite.
SAME="$WORK/same.jsonl"; : > "$SAME"
for i in $(seq 1 50); do
  python3 - "$SAME" "$i" <<'PY'
import json, sys
sys.path.insert(0, "utils/py")
from telemetry_schema import event_from_completed, append_jsonl
i = sys.argv[2]
argv = ["sh", "-c", 'echo "RuntimeError: same root cause" >&2; exit 1', "x", f"tok{i}", "--n", i]
ev = event_from_completed("fuzz", argv, 1, "RuntimeError: same root cause\n", 3.0, stderr_sample="RuntimeError: same root cause\n", mutant=argv[3:])
ev.tier_1_verdict = "fail"
append_jsonl(sys.argv[1], ev)
PY
done
mkdir -p "$WORK/out50"
python3 "$SYNTH" --mode synth --telemetry "$SAME" --out-dir "$WORK/out50" --issue 299 --repo-root "$FIX" --json > "$WORK/synth50.json"
n50="$(ls "$WORK/out50"/*.sh 2>/dev/null | wc -l | tr -d ' ')"
members="$(python3 -c "import json; print(json.load(open('$WORK/synth50.json'))['emitted'][0]['members'])")"
[ "$n50" -eq 1 ] && [ "$members" -eq 50 ] && pass "50 same-root-cause mutations emit exactly 1 suite (members=50)" || fail "50-mutation cluster emitted $n50 suites (members=$members)"

# 5. Unified entry point: repro_builder.py --mode synth delegates here.
mkdir -p "$WORK/via-builder"
if python3 "$BUILDER" --mode synth --telemetry "$SAME" --out-dir "$WORK/via-builder" --issue 299 --repo-root "$FIX" >/dev/null 2>&1 && [ "$(ls "$WORK/via-builder"/*.sh | wc -l | tr -d ' ')" -eq 1 ]; then
  pass "repro_builder.py --mode synth delegates to the Gen 4 synthesizer"
else
  fail "repro_builder.py --mode synth did not emit"
fi

# 6. Telemetry that has no counterexamples emits nothing and exits 0 (no vacuous suites).
CLEAN="$WORK/clean.jsonl"
python3 "$FUZZ" --mode fuzz --target "$PY -c 'import sys; sys.exit(0)' {mutant}" --base "a" --seed 1 --iterations 20 --cwd "$FIX" --corpus "$WORK/corpus-clean" --telemetry-out "$CLEAN" --timeout-budget 10 >/dev/null 2>&1 || true
mkdir -p "$WORK/out-clean"
if python3 "$SYNTH" --mode synth --telemetry "$CLEAN" --out-dir "$WORK/out-clean" --issue 299 --repo-root "$FIX" >/dev/null && [ -z "$(ls "$WORK/out-clean" 2>/dev/null)" ]; then
  pass "clean telemetry emits no suites and exits 0"
else
  fail "clean telemetry produced suites or a non-zero exit"
fi

echo "== gh-gen4-phase4-repro-synth: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
