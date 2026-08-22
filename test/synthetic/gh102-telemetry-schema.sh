#!/usr/bin/env bash
# Synthetic Test: GH-102 Unified Telemetry Schema (1.0) & checkin.py Validation
# Extended by #141 Phase 2: the classification block carries DERIVED signal, not aliases —
#   - nested classification.status is ABSENT (it was a pure alias of top-level status, the
#     third alias GH-141's review counted)
#   - severity grades the documented harness exit classes (2 low · 3/4/5 medium · 6/7 high),
#     so two failing records can carry different severities
#   - likely_cause inspects the captured output (traceback / timeout / invariant)
# Acceptance pinned here: over a MIXED corpus, no analytic field is a pure function of status;
# checkin.py's RENDERED groups and compile_issue's dry-run buckets reflect the derived values.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh102-telemetry-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

# 1. Mixed-outcome fixture dir: pass · assertion-fail · usage-class fail · timeout-class fail ·
#    traceback-output fail — five distinct (exit, output) combinations, only one of which passes.
DUMMY_DIR="$WORK/dummy_tests"
mkdir -p "$DUMMY_DIR"
mk() { printf '#!/usr/bin/env bash\n%s\n' "$2" > "$DUMMY_DIR/$1"; chmod +x "$DUMMY_DIR/$1"; }
mk test-pass.sh        'exit 0'
mk test-assert.sh      'echo "assertion mismatch" >&2; exit 1'
mk test-usage.sh       'echo "unknown flag" >&2; exit 2'
mk test-timeout.sh     'echo "exceeded wall cap" >&2; exit 7'
mk test-traceback.sh   'echo "Traceback (most recent call last):" >&2; echo "  boom" >&2; exit 1'

FUZZ_LOG="$WORK/fuzz_telemetry.jsonl"
ATE_LOG="$WORK/ate_telemetry.jsonl"

# 2. Exercise fuzz-loop.sh with --test-dir and --jsonl output (ad-hoc dir: the registry-derived
#    default selection is pinned separately by test/gh141-synthetic-registry.sh).
bash "$ROOT/utils/fuzzing/fuzz-loop.sh" --test-dir "$DUMMY_DIR" --jsonl "$FUZZ_LOG" >/dev/null 2>&1 || true

[ -f "$FUZZ_LOG" ] || {
  echo "FAIL: fuzz-loop.sh failed to create $FUZZ_LOG"
  exit 1
}

# 3. Generate sample ATE log records conforming to schema 1.0 (run_variations shape — keeps its
#    classifier-authored nested status; the two producer shapes coexist by design).
python3 -c "
import json
records = [
    {
        'schema_version': '1.0',
        'run_id': 'run-test-1',
        'iteration': 0,
        'engine': 'ate_variations',
        'timestamp': '2026-08-20T12:00:00Z',
        'variation': {'model': 'glm-5.2', 'tool_mode': 'programmatic_python'},
        'status': 'pass',
        'exit_code': 0,
        'duration_ms': 1250,
        'turn_count': 1,
        'prompt_tokens': 450,
        'completion_tokens': 120,
        'total_tokens': 570,
        'tokens_source': 'api_usage',
        'classification': {'status': 'pass', 'category': 'tool_call_success', 'likely_cause': None, 'severity': 'none'}
    },
    {
        'schema_version': '1.0',
        'run_id': 'run-test-2',
        'iteration': 1,
        'engine': 'ate_variations',
        'timestamp': '2026-08-20T12:01:00Z',
        'variation': {'model': 'glm-5.2', 'tool_mode': 'json_function_calling'},
        'status': 'fail',
        'exit_code': 1,
        'duration_ms': 2100,
        'turn_count': 2,
        'prompt_tokens': 1200,
        'completion_tokens': 300,
        'total_tokens': 1500,
        'tokens_source': 'api_usage',
        'classification': {'status': 'fail', 'category': 'token_overflow', 'likely_cause': 'schema_bloat', 'severity': 'medium'}
    }
]
with open('$ATE_LOG', 'w') as f:
    for r in records:
        f.write(json.dumps(r) + chr(10))
"

# 4. Schema invariants + the #141 Phase 2 de-aliasing contract over the MIXED fuzz corpus
python3 - "$FUZZ_LOG" <<'PY' || { echo "FAIL: schema/de-alias validation"; exit 1; }
import json, sys
from pathlib import Path

records = [json.loads(l) for l in Path(sys.argv[1]).read_text().splitlines() if l.strip()]
assert len(records) == 5, f"expected 5 records, got {len(records)}"

for rec in records:
    assert rec.get("schema_version") == "1.0"
    assert rec.get("engine") == "fuzz_loop"
    assert rec.get("status") in ("pass", "fail")
    assert isinstance(rec.get("duration_ms"), int)
    cls = rec.get("classification") or {}
    # #141 Phase 2: the alias is GONE
    assert "status" not in cls, f"nested classification.status must be absent: {cls}"
    assert cls.get("category") == "deterministic_synthetic_fuzz"
    assert "severity" in cls and "likely_cause" in cls

by_name = {r["test_name"]: r for r in records}

# derived severity follows the documented exit classes
exp_sev = {"test-pass.sh": "none", "test-assert.sh": "high", "test-usage.sh": "low", "test-timeout.sh": "high", "test-traceback.sh": "high"}
exp_cause = {"test-pass.sh": None, "test-assert.sh": "synthetic_invariant_failure",
             "test-usage.sh": "synthetic_invariant_failure", "test-timeout.sh": "timeout",
             "test-traceback.sh": "unhandled_traceback"}
for name, r in by_name.items():
    got_sev = (r["classification"] or {}).get("severity")
    got_cause = (r["classification"] or {}).get("likely_cause")
    assert got_sev == exp_sev[name], f"{name}: severity {got_sev} != {exp_sev[name]}"
    assert got_cause == exp_cause[name], f"{name}: cause {got_cause} != {exp_cause[name]}"

# the no-pure-alias negative: status alone must NOT determine the analytic fields —
# two FAIL records with different severities, and two with different causes
fails = [r for r in records if r["status"] == "fail"]
assert len({(r["classification"] or {}).get("severity") for r in fails}) >= 2, "severity is a pure alias of status"
assert len({(r["classification"] or {}).get("likely_cause") for r in fails}) >= 3, "likely_cause is a pure alias of status"

print("SCHEMA_AND_DEALIAS_OK")
PY

# 5. checkin.py renders the derived groups (the operator-facing render, not just JSON keys)
CHECKIN_OUT="$(python3 "$ROOT/utils/ate/scripts/checkin.py" --log "$FUZZ_LOG" 2>&1)"
case "$CHECKIN_OUT" in
  *"Categories:"*"deterministic_synthetic_fuzz"*) echo "  PASS: checkin renders the category group" ;;
  *) echo "FAIL: checkin human render lost the category group"; exit 1 ;;
esac
CI_JSON="$(python3 "$ROOT/utils/ate/scripts/checkin.py" --log "$FUZZ_LOG" --json 2>/dev/null)"
case "$CI_JSON" in
  *unhandled_traceback*|*timeout*) echo "  PASS: checkin summary carries the derived causes" ;;
  *) echo "FAIL: derived causes absent from checkin summary"; exit 1 ;;
esac
python3 "$ROOT/utils/ate/scripts/checkin.py" --log "$FUZZ_LOG" --json >/dev/null || { echo "FAIL: checkin.py failed on fuzz log"; exit 1; }
python3 "$ROOT/utils/ate/scripts/checkin.py" --log "$ATE_LOG" --json >/dev/null || { echo "FAIL: checkin.py failed on ATE log"; exit 1; }
python3 "$ROOT/utils/ate/scripts/checkin.py" --compare "$FUZZ_LOG" "$ATE_LOG" --json >/dev/null || { echo "FAIL: checkin.py failed on compare mode"; exit 1; }

# 6. compile_issue consumes BOTH shapes: fuzz corpus (no nested status) buckets by the derived
#    signature; clean passes are skipped via TOP-LEVEL status; severities land in the right sections.
DRY_OUT="$(cd "$WORK" && python3 "$ROOT/utils/ate/scripts/compile_issue.py" --log "$FUZZ_LOG" \
  --repo acme/widgets --test-name gh102 --dry-run 2>&1)"
case "$DRY_OUT" in
  *"## LOW"*) echo "  PASS: exit-class severity reaches the LOW section (usage-class fail)" ;;
  *) echo "FAIL: no LOW section — severity not derived from exit classes"; exit 1 ;;
esac
case "$DRY_OUT" in
  *unhandled_traceback*) echo "  PASS: derived cause reaches the rollup signature" ;;
  *) echo "FAIL: derived cause absent from rollup"; exit 1 ;;
esac
case "$DRY_OUT" in
  *"Total variations logged: 5"*) echo "  PASS: all five records counted" ;;
  *) echo "FAIL: record count wrong in rollup"; exit 1 ;;
esac
if grep -q "test-pass" <<<"$DRY_OUT"; then
  echo "FAIL: clean pass leaked into the findings rollup"; exit 1
else
  echo "  PASS: clean pass skipped via top-level status (no nested status required)"
fi

echo "PASS: gh102-telemetry-schema"
exit 0
