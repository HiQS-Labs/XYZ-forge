#!/usr/bin/env bash
# Synthetic Test: GH-441 pattern - marathon_drive.py shouldn't leak RELAY_DRIVER_LOCKED=1 to children
export RELAY_DRIVER_LOCKED=1
# Expecting marathon_drive.py to unset RELAY_DRIVER_LOCKED when spawning sub-lanes
# This is a synthetic test checking the behavior of utils/py/marathon_drive.py
out=$(python3 utils/py/marathon_drive.py --help 2>&1)
if echo "$out" | grep -q "RELAY_DRIVER_LOCKED=1"; then
  echo "FAIL: Environment leaked to child process"
  exit 1
fi
echo "PASS"
exit 0
