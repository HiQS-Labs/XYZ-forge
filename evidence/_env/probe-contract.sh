#!/usr/bin/env bash
cd "$HOME/XYZ-forge" || exit 1
echo "=== docs with a Swarm Preflight Contract ==="
grep -rln 'Swarm Preflight Contract' PROJECT/ 2>/dev/null | head -10
echo
echo "=== an example block ==="
f=$(grep -rln 'Swarm Preflight Contract' PROJECT/ 2>/dev/null | head -1)
echo "FILE: $f"
awk '/Swarm Preflight Contract/{f=1} f{print} f&&/^```$/{c++; if(c>=1 && seen)exit; if(c>=1)seen=1}' "$f" | head -60
echo
echo "=== swarm-preflight.sh usage ==="
sed -n '90,110p' utils/swarm-preflight.sh
