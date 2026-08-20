#!/usr/bin/env bash
# Synthetic Test: GH-94 Script Serialization & Timeout Process Cleanup
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
RUNNER="$ROOT/utils/py/script_runner.py"

[ -x "$RUNNER" ] || {
  echo "FAIL: script_runner.py not executable at $RUNNER"
  exit 1
}

# 1. Test literal \n serialization normalization
output=$(python3 "$RUNNER" --code "import sys\nprint('SERIALIZATION_OK')" --json)
status=$?
if [ $status -ne 0 ]; then
  echo "FAIL: Escaped newline serialization test failed with status $status"
  exit 1
fi
echo "$output" | grep -q "SERIALIZATION_OK" || {
  echo "FAIL: Output did not contain expected normalized string. Got: $output"
  exit 1
}

# 2. Test nested quotes and metacharacters in bash mode
output=$(python3 "$RUNNER" --lang bash --code 'MSG="hello \"nested\" \$dollar"; echo "RESULT:$MSG"' --json)
status=$?
if [ $status -ne 0 ]; then
  echo "FAIL: Nested quotes test failed with status $status"
  exit 1
fi
echo "$output" | grep -q 'RESULT:hello \\"nested\\" \$dollar' || {
  echo "FAIL: Output did not preserve nested quotes. Got: $output"
  exit 1
}

# 3. Test syntax error recovery
output=$(python3 "$RUNNER" --code "def broken_syntax(" --json 2>/dev/null)
status=$?
if [ $status -eq 0 ]; then
  echo "FAIL: Expected non-zero exit code for syntax error, got 0"
  exit 1
fi
echo "$output" | grep -q '"status": "fail"' || {
  echo "FAIL: JSON status was not 'fail' for syntax error. Got: $output"
  exit 1
}

# 4. Test deterministic timeout & process-group termination
start_ts=$(date +%s)
output=$(python3 "$RUNNER" --code "import time\nwhile True:\n    time.sleep(0.1)" --timeout 2.0 --grace 0.5 --json)
status=$?
end_ts=$(date +%s)
elapsed=$((end_ts - start_ts))

if [ $status -ne 124 ]; then
  echo "FAIL: Expected exit code 124 on timeout, got $status"
  exit 1
fi

if [ $elapsed -lt 2 ] || [ $elapsed -gt 5 ]; then
  echo "FAIL: Timeout took unexpected duration ($elapsed s, expected 2-4s)"
  exit 1
fi

echo "$output" | grep -q '"timed_out": true' || {
  echo "FAIL: JSON output did not indicate timed_out: true. Got: $output"
  exit 1
}

pgid=$(echo "$output" | grep '"pgid":' | sed -E 's/.*"pgid": ([0-9]+).*/\1/')
if [ -n "$pgid" ]; then
  if kill -0 "-$pgid" 2>/dev/null; then
    echo "FAIL: Process group $pgid is still alive after timeout cleanup"
    exit 1
  fi
fi

echo "PASS: gh94-script-serialization"
exit 0
