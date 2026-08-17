#!/usr/bin/env bash
# gh1-adoption-guard.sh — guard for require_fixture adoption (GH-10)

set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
LEDGER="$HERE/test/baselines/GH-1-adoption-ledger.md"

# The ledger must EXACTLY match this hash, preventing silent additions to the pending list.
# A mechanical adoption requires removing the suite from the ledger AND updating this hash.
# (Hash is of the suite paths only, one per line, sorted)
EXPECTED_HASH="dd64fb5ce020dd4c97f7ea5704b898739de7115026d5deb551919914751b10cb"

FAILED=0

LEDGER_LIST="$(grep "^- test/" "$LEDGER" | sed 's/^- //' | sort)"
ACTUAL_HASH="$(echo "$LEDGER_LIST" | shasum -a 256 | awk '{print $1}')"

if [ "$ACTUAL_HASH" != "$EXPECTED_HASH" ]; then
  echo "gh1-adoption-guard: LEDGER HASH MISMATCH. The list of pending suites was modified." >&2
  echo "gh1-adoption-guard: Expected: $EXPECTED_HASH" >&2
  echo "gh1-adoption-guard: Actual:   $ACTUAL_HASH" >&2
  FAILED=1
fi

for f in "$HERE"/test/*.sh; do
  [ -f "$f" ] || continue
  base="$(basename "$f")"
  
  if grep -q "mktemp" "$f" && grep -Eq "git -C|cd " "$f"; then
    if ! grep -q "require_fixture" "$f"; then
      if ! echo "$LEDGER_LIST" | grep -qx "test/$base"; then
        echo "gh1-adoption-guard: UNGUARDED SUITE NOT IN LEDGER: test/$base" >&2
        FAILED=1
      fi
    else
      # It HAS the guard. Ensure it is NOT in the ledger!
      if echo "$LEDGER_LIST" | grep -qx "test/$base"; then
        echo "gh1-adoption-guard: SUITE ADOPTED BUT STILL IN LEDGER: test/$base" >&2
        FAILED=1
      fi
    fi
  fi
done

if [ "$FAILED" -eq 1 ]; then
  exit 1
fi

echo "gh1-adoption-guard: OK (73 suites pending adoption, bounded ledger matches hash)"
exit 0
