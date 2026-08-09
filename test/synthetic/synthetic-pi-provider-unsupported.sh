#!/usr/bin/env bash
export RELAY_AGENT="pi" RELAY_FILE="dummy.md" PI_AGENT="pi"
export PI_MODEL="fake"
export PI_PROVIDER="unsupported_provider_xyz"
export OPENROUTER_API_KEY="dummy"

# We expect pi-turn.py to exit with code 7 (unsupported provider), not crash or exit 0.
python3 utils/py/pi-turn.py >/dev/null 2>&1
status=$?

if [ $status -ne 7 ]; then
  echo "FAIL: Expected exit code 7 when PI_PROVIDER is unsupported_provider_xyz, got $status"
  exit 1
fi
echo "PASS"
exit 0
