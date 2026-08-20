# Autonomous Fuzzing Loop — execute every synthetic shell test and leave a concise, parseable log.
# Supports --jsonl <path> to emit structured telemetry conforming to schema_version: "1.0".
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
TEST_DIR="${FUZZ_TEST_DIR:-$ROOT/test/synthetic}"
JSONL_OUT="${FUZZ_JSONL_PATH:-}"

# Parse optional arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --jsonl)
      JSONL_OUT="$2"
      shift 2
      ;;
    --test-dir)
      TEST_DIR="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

[ -d "$TEST_DIR" ] || {
  printf 'FUZZ_SUMMARY|status=ERROR|reason=missing-test-dir|test_dir=%s\n' "$TEST_DIR" >&2
  exit 2
}

if [ -n "$JSONL_OUT" ]; then
  mkdir -p "$(dirname "$JSONL_OUT")"
fi

total=0
passed=0
failed=0
session_id="$(date -u +"%Y%m%d%H%M%S")"

printf 'FUZZ_START|test_dir=%s\n' "$TEST_DIR"

# find + sort catches nested synthetic suites too; process substitution keeps the counters in this
# shell (a pipeline would put the loop in a subshell and lose the totals).
while IFS= read -r test_script; do
  [ -n "$test_script" ] || continue
  total=$((total + 1))
  started_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
  output="$(bash "$test_script" 2>&1)"
  status=$?
  finished_ms="$(python3 -c 'import time; print(int(time.time() * 1000))')"
  duration_ms=$((finished_ms - started_ms))
  elapsed=$(( (duration_ms + 999) / 1000 ))
  test_rel="${test_script#$ROOT/}"
  test_name="$(basename "$test_script")"
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  if [ "$status" -eq 0 ]; then
    passed=$((passed + 1))
    printf 'FUZZ_RESULT|status=PASS|test=%s|exit_code=0|duration_ms=%s\n' \
      "$test_script" "$duration_ms"
    res_status="pass"
    cat_status="none"
  else
    failed=$((failed + 1))
    printf 'FUZZ_RESULT|status=FAIL|test=%s|exit_code=%s|duration_ms=%s\n' \
      "$test_script" "$status" "$duration_ms" >&2
    [ -z "$output" ] || printf '%s\n' "$output" | sed 's/^/  | /' >&2
    res_status="fail"
    cat_status="high"
  fi

  if [ -n "$JSONL_OUT" ]; then
    python3 -c '
import sys, json
out_path, session_id, run_idx, timestamp, name, path, status, exit_code, dur_ms, sev = sys.argv[1:11]
record = {
    "schema_version": "1.0",
    "run_id": f"fuzz-{session_id}-{run_idx}",
    "timestamp": timestamp,
    "engine": "fuzz_loop",
    "test_name": name,
    "test_path": path,
    "status": status,
    "exit_code": int(exit_code),
    "duration_ms": int(dur_ms),
    "turn_count": 1,
    "prompt_tokens": None,
    "completion_tokens": None,
    "total_tokens": None,
    "tokens_source": "unsupported",
    "classification": {
        "status": status,
        "category": "deterministic_synthetic_fuzz",
        "likely_cause": None if int(exit_code) == 0 else "synthetic_invariant_failure",
        "severity": sev,
    }
}
try:
    with open(out_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")
except Exception as e:
    sys.stderr.write(f"fuzz-loop: failed to write telemetry to {out_path}: {e}\n")
' "$JSONL_OUT" "$session_id" "$total" "$timestamp" "$test_name" "$test_rel" "$res_status" "$status" "$duration_ms" "$cat_status"
  fi
done < <(find "$TEST_DIR" -type f -name '*.sh' -print | LC_ALL=C sort)

summary_status=PASS
[ "$failed" -eq 0 ] || summary_status=FAIL
printf 'FUZZ_SUMMARY|status=%s|total=%s|passed=%s|failed=%s\n' \
  "$summary_status" "$total" "$passed" "$failed"
[ "$failed" -eq 0 ]
