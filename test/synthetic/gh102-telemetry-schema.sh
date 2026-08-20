#!/usr/bin/env bash
# Synthetic Test: GH-102 Unified Telemetry Schema (1.0) & checkin.py Validation
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh102-telemetry-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

DUMMY_DIR="$WORK/dummy_tests"
mkdir -p "$DUMMY_DIR"
cat << 'TEST_EOF' > "$DUMMY_DIR/test-pass.sh"
#!/usr/bin/env bash
exit 0
TEST_EOF
chmod +x "$DUMMY_DIR/test-pass.sh"

cat << 'TEST_EOF' > "$DUMMY_DIR/test-fail.sh"
#!/usr/bin/env bash
exit 1
TEST_EOF
chmod +x "$DUMMY_DIR/test-fail.sh"

FUZZ_LOG="$WORK/fuzz_telemetry.jsonl"
ATE_LOG="$WORK/ate_telemetry.jsonl"

# 1. Exercise fuzz-loop.sh with --test-dir and --jsonl output
bash "$ROOT/utils/fuzzing/fuzz-loop.sh" --test-dir "$DUMMY_DIR" --jsonl "$FUZZ_LOG" >/dev/null 2>&1 || true

[ -f "$FUZZ_LOG" ] || {
  echo "FAIL: fuzz-loop.sh failed to create $FUZZ_LOG"
  exit 1
}

# 2. Generate sample ATE log records conforming to schema 1.0
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
        f.write(json.dumps(r) + '\n')
"

# 3. Validate schema invariants via Python
python3 -c "
import json
from pathlib import Path

# Verify fuzz log schema
fuzz_lines = Path('$FUZZ_LOG').read_text().splitlines()
assert len(fuzz_lines) == 2, f'Expected 2 fuzz records, got {len(fuzz_lines)}'
for line in fuzz_lines:
    rec = json.loads(line)
    assert rec.get('schema_version') == '1.0'
    assert rec.get('engine') == 'fuzz_loop'
    assert rec.get('status') in ('pass', 'fail')
    assert isinstance(rec.get('duration_ms'), int)

# Verify ATE log schema
ate_lines = Path('$ATE_LOG').read_text().splitlines()
assert len(ate_lines) == 2
for line in ate_lines:
    rec = json.loads(line)
    assert rec.get('schema_version') == '1.0'
    assert rec.get('engine') == 'ate_variations'
    assert rec.get('tokens_source') == 'api_usage'
    assert rec.get('total_tokens') == rec.get('prompt_tokens') + rec.get('completion_tokens')

print('SCHEMA_INVARIANTS_OK')
" || {
  echo "FAIL: Schema invariant validation failed"
  exit 1
}

# 4. Verify checkin.py CLI inspection and comparison
python3 "$ROOT/utils/ate/scripts/checkin.py" --log "$FUZZ_LOG" --json >/dev/null || {
  echo "FAIL: checkin.py failed on fuzz log"
  exit 1
}

python3 "$ROOT/utils/ate/scripts/checkin.py" --log "$ATE_LOG" --json >/dev/null || {
  echo "FAIL: checkin.py failed on ATE log"
  exit 1
}

python3 "$ROOT/utils/ate/scripts/checkin.py" --compare "$FUZZ_LOG" "$ATE_LOG" --json >/dev/null || {
  echo "FAIL: checkin.py failed on compare mode"
  exit 1
}

echo "PASS: gh102-telemetry-schema"
exit 0
