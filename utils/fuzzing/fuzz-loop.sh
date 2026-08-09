#!/usr/bin/env bash
# Autonomous Fuzzing Loop
# Scans for failing synthetic tests and reports them.

set -euo pipefail

TEST_DIR="test/synthetic"
failing_tests=0

echo "Starting Autonomous Fuzzing Loop (Report Only)..."

for test_script in "$TEST_DIR"/*.sh; do
    if [ ! -f "$test_script" ]; then continue; fi

    echo "================================================="
    echo "Running synthetic test: $test_script"
    set +e
    out=$(bash "$test_script" 2>&1)
    status=$?
    set -e
    
    if [ $status -ne 0 ]; then
        echo "FAIL: $test_script"
        echo "$out"
        failing_tests=$((failing_tests + 1))
    else
        echo "PASS: $test_script"
    fi
done

echo "================================================="
if [ $failing_tests -gt 0 ]; then
    echo "Fuzz loop complete. Found $failing_tests failing tests."
    exit 1
else
    echo "Fuzz loop complete. All tests passed."
    exit 0
fi
