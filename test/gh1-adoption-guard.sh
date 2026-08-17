#!/usr/bin/env bash
# gh1-adoption-guard.sh — guard for require_fixture adoption (GH-10)

set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
LEDGER="$HERE/test/baselines/GH-1-adoption-ledger.md"

FAILED=0

for f in "$HERE"/test/*.sh; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  
  if grep -q "mktemp" "$f" && grep -Eq "git -C|cd " "$f"; then
    if ! grep -q "require_fixture" "$f"; then
      if ! grep -q "^- test/$base$" "$LEDGER"; then
        echo "gh1-adoption-guard: UNGUARDED SUITE NOT IN LEDGER: test/$base" >&2
        FAILED=1
      fi
    else
      # It HAS the guard. Ensure it is NOT in the ledger!
      if grep -q "^- test/$base$" "$LEDGER"; then
        echo "gh1-adoption-guard: SUITE ADOPTED BUT STILL IN LEDGER: test/$base" >&2
        FAILED=1
      fi
    fi
  fi
done

if [ "$FAILED" -eq 1 ]; then
  exit 1
fi

echo "gh1-adoption-guard: OK (0 unaudited suites, ledger matches reality)"
exit 0
