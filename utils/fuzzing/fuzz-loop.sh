#!/usr/bin/env bash
# Autonomous Fuzzing Loop — execute every synthetic shell test and leave a concise, parseable log.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
TEST_DIR="${FUZZ_TEST_DIR:-$ROOT/test/synthetic}"

[ -d "$TEST_DIR" ] || {
  printf 'FUZZ_SUMMARY|status=ERROR|reason=missing-test-dir|test_dir=%s\n' "$TEST_DIR" >&2
  exit 2
}

total=0
passed=0
failed=0

printf 'FUZZ_START|test_dir=%s\n' "$TEST_DIR"

# find + sort catches nested synthetic suites too; process substitution keeps the counters in this
# shell (a pipeline would put the loop in a subshell and lose the totals).
while IFS= read -r test_script; do
  [ -n "$test_script" ] || continue
  total=$((total + 1))
  started="$(date +%s)"
  output="$(bash "$test_script" 2>&1)"
  status=$?
  finished="$(date +%s)"
  elapsed=$((finished - started))

  if [ "$status" -eq 0 ]; then
    passed=$((passed + 1))
    printf 'FUZZ_RESULT|status=PASS|test=%s|exit_code=0|duration_s=%s\n' \
      "$test_script" "$elapsed"
  else
    failed=$((failed + 1))
    printf 'FUZZ_RESULT|status=FAIL|test=%s|exit_code=%s|duration_s=%s\n' \
      "$test_script" "$status" "$elapsed" >&2
    [ -z "$output" ] || printf '%s\n' "$output" | sed 's/^/  | /' >&2
  fi
done < <(find "$TEST_DIR" -type f -name '*.sh' -print | LC_ALL=C sort)

summary_status=PASS
[ "$failed" -eq 0 ] || summary_status=FAIL
printf 'FUZZ_SUMMARY|status=%s|total=%s|passed=%s|failed=%s\n' \
  "$summary_status" "$total" "$passed" "$failed"
[ "$failed" -eq 0 ]
