#!/usr/bin/env bash
cd "$HOME/XYZ-forge" || exit 1
echo "=== MARATHON.example.yaml ==="
cat relay-automation/MARATHON.example.yaml
echo
echo "=== marathon.sh usage ==="
sed -n '84,120p' relay-automation/marathon.sh
echo
echo "=== marathon.sh roots section of README ==="
sed -n '118,155p' relay-automation/README.md
