#!/usr/bin/env bash
# Synthetic Test: GH-295 pattern - pi_turn.py should gracefully fail if PI_MODEL is unset
unset PI_MODEL
export RELAY_AGENT="pi" RELAY_FILE="dummy.md" PI_AGENT="pi"
export OPENROUTER_API_KEY="dummy"
# We expect pi-turn.py to exit with code 5 (configuration error), not crash or exit 0.
python3 utils/py/pi-turn.py >/dev/null 2>&1
status=$?
if [ $status -ne 5 ]; then
  echo "FAIL: Expected exit code 5 when PI_MODEL is unset, got $status"
  exit 1
fi
echo "PASS"
exit 0
