#!/usr/bin/env bash
# GH-299 Gen 4 synthesized reproducer — cluster 738c4aa1f77b7a53 (123 counterexample(s), phases fuzz, verdicts anomaly) (Synthesized by utils/py/repro_builder.py - GH-155 Phase 3)
# Synthesized by utils/py/repro_synth.py (GH-299 Phase 4).
# cluster=738c4aa1f77b7a53 members=123 original_argv=python3 utils/py/marathon_plan.py
# This suite PASSES while the defect reproduces; flip the assertion when the fix lands.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve root from explicit environment, baked root, or traversal fallback
ROOT="${XYZ_ROOT:-}"
if [ -z "$ROOT" ] || [ ! -d "$ROOT" ]; then
  ROOT="$(cd "$HERE/.." && pwd)"
fi

# Initialize sandbox and containment (GH-567)
WORK="$(mktemp -d "${TMPDIR:-/tmp}/repro.XXXXXX")"
cleanup() { [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"; }
trap cleanup EXIT

if [ -f "$ROOT/test/lib/fixture-guard.sh" ]; then
  . "$ROOT/test/lib/fixture-guard.sh"
  fixture_guard_init "$WORK"
fi

# Minimal reproduction environment
export XYZ_ROOT="$ROOT"

echo "== Executing minimal reproducer in $ROOT =="
STDOUT_FILE="$WORK/stdout.log"
STDERR_FILE="$WORK/stderr.log"

cd "$ROOT"

RC=0
python3 utils/py/marathon_plan.py > "$STDOUT_FILE" 2> "$STDERR_FILE" || RC=$?

STDOUT="$(cat "$STDOUT_FILE")"
STDERR="$(cat "$STDERR_FILE")"

echo "Command exited with code: $RC"

if [ "$RC" -ne 4 ]; then
  echo "FAIL: Expected exit code 4, got $RC"
  echo "STDOUT: $STDOUT"
  echo "STDERR: $STDERR"
  exit 1
fi

echo "PASS: Failure reproduced successfully with expected signature (rc=4)"
exit 0
