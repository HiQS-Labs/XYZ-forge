#!/usr/bin/env bash
cd "$HOME/XYZ-forge" || exit 1
echo "=== headings in relay-automation/README.md ==="
grep -n '^#\{1,4\} ' relay-automation/README.md | head -40
echo
echo "=== agy setup lines ==="
grep -n -i 'agy' relay-automation/README.md | grep -iE 'install|login|auth|whoami|antigravity|npm|curl' | head -30
