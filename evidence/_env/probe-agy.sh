#!/usr/bin/env bash
cd "$HOME/XYZ-forge" || exit 1
echo "=== README agy mentions ==="
grep -n -i 'agy' README.md | head -40
echo
echo "=== find-harness.sh agy detection ==="
grep -n -i 'agy' skills/relay-xyz/find-harness.sh | head -20
echo
echo "=== agy-turn.sh header ==="
sed -n '1,60p' relay-automation/agy-turn.sh 2>/dev/null
