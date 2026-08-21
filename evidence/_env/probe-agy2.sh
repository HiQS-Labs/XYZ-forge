#!/usr/bin/env bash
cd "$HOME/XYZ-forge" || exit 1
echo "=== relay-automation/README.md :: Set up Codex, agy, and Pi ==="
awk '/[Ss]et up Codex, agy, and Pi/{f=1} f{print NR": "$0} f&&/^## /&&NR>s{if(++c>1)exit}' relay-automation/README.md | head -120
