#!/usr/bin/env bash
# Phase 5 (5b): the bundled skill package extracts to the expected relay surface and
# every extracted script parses. (Proves the self-extract; tick provisioning is the E3
# capability gate documented in the SKILL.md, exercised separately by the relay tests.)
source "$(dirname "$0")/_setup.sh" skill-extract
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$ROOT/skill/relay-automation/relay-pkg.tar.gz"

[ -f "$PKG" ] && pass "relay-pkg.tar.gz present beside the skill" || fail "package missing — run skill/relay-automation/make-pkg.sh"

D="$WORK/extract"; mkdir -p "$D"
tar xzf "$PKG" -C "$D"

want="relay-automation/poll.sh relay-automation/runner.sh relay-automation/watchdog.sh \
relay-automation/relay-drive.sh relay-automation/codex-turn.sh relay-automation/README.md \
test/poll-driver.sh test/poll-relay.sh test/watchdog-relay.sh test/codex-turn.sh"
miss=0
for f in $want; do [ -f "$D/$f" ] || { echo "  missing: $f" >&2; miss=1; }; done
[ "$miss" = 0 ] && pass "all 10 packaged files extracted" || fail "package is missing files"

ok=1
for s in "$D"/relay-automation/*.sh "$D"/test/*.sh; do bash -n "$s" 2>/dev/null || { echo "  parse fail: $s" >&2; ok=0; }; done
[ "$ok" = 1 ] && pass "every extracted shell script is bash -n clean" || fail "an extracted script failed to parse"

# the extracted package matches the live sources (no drift)
if diff -q "$ROOT/relay-automation/poll.sh" "$D/relay-automation/poll.sh" >/dev/null; then
  pass "extracted poll.sh matches the live source (package not stale)"
else
  fail "packaged poll.sh differs from source — re-run make-pkg.sh"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
