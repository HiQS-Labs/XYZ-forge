#!/usr/bin/env bash
# Ensure the committed relay skill tarball matches the live packaged sources byte-for-byte.
source "$(dirname "$0")/_setup.sh" relay-pkg-freshness
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/skills/relay-automation/relay-pkg.tar.gz"

[ -f "$PKG" ] && pass "relay-pkg.tar.gz present" || fail "package missing: $PKG"

D="$WORK/extract"
mkdir -p "$D"
tar xzf "$PKG" -C "$D"

drift=0
count=0
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  count=$((count + 1))
  if [ ! -f "$ROOT/$rel" ]; then
    echo "  missing live source: $rel" >&2
    drift=1
    continue
  fi
  if cmp -s "$ROOT/$rel" "$D/$rel"; then
    :
  else
    echo "  drift: $rel" >&2
    drift=1
  fi
done < <(tar tzf "$PKG")

[ "$count" -gt 0 ] && pass "tarball exposes $count packaged paths" || fail "tarball is empty"
[ "$drift" = 0 ] \
  && pass "every packaged file matches its live source" \
  || fail "relay-pkg.tar.gz is stale — run skills/relay-automation/make-pkg.sh"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
