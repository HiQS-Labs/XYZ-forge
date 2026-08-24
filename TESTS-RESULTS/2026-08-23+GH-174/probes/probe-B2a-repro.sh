#!/usr/bin/env bash
# Reproducer for unknown (Synthesized by utils/py/repro_builder.py - GH-155 Phase 3)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve root from explicit environment, baked root, or traversal fallback
ROOT="${XYZ_ROOT:-/Users/noelsaw/Documents/GH Repos/xyz-gh155-ate-review}"
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
bash /Users/noelsaw/Documents/GH Repos/xyz-post-ate-fuzz-improvement-testing/relay-automation/agy-turn.sh --help > "$STDOUT_FILE" 2> "$STDERR_FILE" || RC=$?

STDOUT="$(cat "$STDOUT_FILE")"
STDERR="$(cat "$STDERR_FILE")"

echo "Command exited with code: $RC"

if [ "$RC" -ne 2 ]; then
  echo "FAIL: Expected exit code 2, got $RC"
  echo "STDOUT: $STDOUT"
  echo "STDERR: $STDERR"
  exit 1
fi

echo "PASS: Failure reproduced successfully with expected signature (rc=2)"
exit 0
