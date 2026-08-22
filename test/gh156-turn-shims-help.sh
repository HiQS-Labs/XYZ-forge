#!/usr/bin/env bash
# GH-156: Verify that all 7 turn shims cleanly handle --help and -h without requiring RELAY_AGENT.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SHIMS=(
  "relay-automation/agy-turn.sh"
  "relay-automation/codex-turn.sh"
  "relay-automation/claude-turn.sh"
  "relay-automation/aider-turn.sh"
  "relay-automation/pi-turn.sh"
  "relay-automation/commandcode-turn.sh"
  "relay-automation/deepseek-turn.sh"
)

echo "== test: gh156-turn-shims-help =="

for shim in "${SHIMS[@]}"; do
  # Test --help
  rc=0
  out="$(env -i PATH="$PATH" bash "$ROOT/$shim" --help 2>&1)" || rc=$?
  if [ "$rc" -eq 0 ] && grep -qi "usage" <<<"$out" && grep -q "RELAY_AGENT" <<<"$out"; then
    pass "$shim --help exits 0 and prints usage"
  else
    fail "$shim --help failed (rc=$rc, out=$out)"
  fi

  # Test -h
  rc=0
  out="$(env -i PATH="$PATH" bash "$ROOT/$shim" -h 2>&1)" || rc=$?
  if [ "$rc" -eq 0 ] && grep -qi "usage" <<<"$out"; then
    pass "$shim -h exits 0 and prints usage"
  else
    fail "$shim -h failed (rc=$rc, out=$out)"
  fi
done

echo "  gh156-turn-shims-help: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
