#!/usr/bin/env bash
# Status of a marathon run in the throwaway target repo.
#   evidence/_env/marathon-status.sh <run-slug-prefix>     e.g. run2
T="$HOME/marathon-target"
cd "$T" || exit 1
pfx="${1:-run}"

echo "=== phases (${pfx}) ==="
found=0
for d in marathon-system/"${pfx}"*/; do
  [ -d "$d" ] || continue
  found=1
  id="$(basename "$d")"
  status="$(grep -m1 '^STATUS:' "$d/RELAY.md" 2>/dev/null || echo 'STATUS: <none>')"
  rounds="$(grep -c '^### Round' "$d/RELAY.md" 2>/dev/null || echo 0)"
  esc=""
  [ -f "$d/ESCALATION.md" ] && esc="  ESCALATION"
  [ -f "$d/PHASE-INTERRUPTED.md" ] && esc="$esc  INTERRUPTED"
  printf '  %-42s %-20s rounds=%-3s%s\n' "$id" "$status" "$rounds" "$esc"
done
[ "$found" = 1 ] || echo "  (no phase dirs yet)"

echo
echo "=== wall clock ==="
cat "$HOME/XYZ-forge/evidence/marathons/${pfx/run/run-}/04-wallclock.txt" 2>/dev/null || echo "  (none)"
echo "  now: $(date -Is)"

echo
echo "=== still running? ==="
if pgrep -f 'marathon\.sh --plan' >/dev/null 2>&1; then
  ps -eo etime,cmd | grep '[m]arathon\.sh --plan' | head -2 | cut -c1-100
else
  echo "  marathon process not running"
fi

echo
echo "=== src/ ==="
ls -1 src/ 2>/dev/null | sed 's/^/  /'

echo
echo "=== gate ==="
. "$HOME/XYZ-forge/evidence/_env/prelude.sh"
npm test 2>&1 | grep -E '^# (tests|pass|fail)' | sed 's/^/  /'
