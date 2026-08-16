#!/usr/bin/env bash
# Synthetic Test: GH-439 pattern - marathon_drive.py should fail if TARGET_ROOT is a worktree of the same repo
export TARGET_ROOT="$PWD"
# Expecting marathon_drive.py to detect that TARGET_ROOT is the same repo (even if a worktree) and exit
python3 utils/py/marathon_drive.py --target-root "$TARGET_ROOT" >/dev/null 2>&1
status=$?
if [ $status -eq 0 ]; then
  echo "FAIL: Expected marathon_drive.py to fail when TARGET_ROOT is the same repo"
  exit 1
fi
echo "PASS"
exit 0
