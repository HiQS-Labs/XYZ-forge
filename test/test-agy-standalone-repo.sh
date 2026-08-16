#!/usr/bin/env bash
set -euo pipefail
# Mock test for standalone repo approach
rm -rf /tmp/wt-test
mkdir -p /tmp/wt-test
cd /tmp/wt-test
git init >/dev/null
echo "original" > file.txt
git add . >/dev/null
git commit -m "initial" >/dev/null

echo "modified" > file.txt
git status --porcelain -z
