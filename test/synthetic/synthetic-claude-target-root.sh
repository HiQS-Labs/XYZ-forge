#!/usr/bin/env bash
# Synthetic Test: GH-380/GH-417 pattern - claude_turn.py should respect TARGET_ROOT
export TARGET_ROOT="/tmp/dummy-root"
# Expecting claude_turn.py to fail if TARGET_ROOT doesn't exist, rather than using cwd
python3 utils/py/claude_turn.py >/dev/null 2>&1
status=$?
if [ $status -eq 0 ]; then
  echo "FAIL: Expected claude_turn.py to fail when TARGET_ROOT is invalid"
  exit 1
fi
echo "PASS"
exit 0
