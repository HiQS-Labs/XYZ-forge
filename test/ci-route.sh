#!/usr/bin/env bash
# GH-509: deterministic route selection for docs, fast PR, and full integration gates.
source "$(dirname "$0")/_setup.sh" ci-route
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROUTER="$ROOT/utils/ci-route.sh"

route() {
  local event="$1"
  shift
  printf '%s\n' "$@" | bash "$ROUTER" "$event"
}

expect_route() {
  local label="$1" event="$2" expected_route="$3" expected_pdda="$4"
  shift 4
  local out
  out="$(route "$event" "$@")"
  if grep -Fqx "route=$expected_route" <<<"$out" \
    && grep -Fqx "pdda_needed=$expected_pdda" <<<"$out"; then
    pass "$label"
  else
    fail "$label: $out"
  fi
}

expect_route "markdown-only PR uses the docs gate" pull_request docs true README.md PROJECT/1-INBOX/NOTE.md
expect_route "ordinary code-only PR uses the fast gate without PDDA" pull_request fast false utils/hq/hq.sh
expect_route "mixed docs and ordinary code runs both fast tests and PDDA" pull_request fast true README.md utils/hq/hq.sh
expect_route "Tick/event changes require the full pre-merge gate" pull_request full true src/events.js
expect_route "relay containment changes require the full pre-merge gate" pull_request full true relay-automation/relay-turn-lib.sh
expect_route "Python-authoritative twin changes require the full pre-merge gate" pull_request full true utils/py/relay_drive.py
expect_route "worktree safety test changes require the full pre-merge gate" pull_request full true test/worktree-isolation.sh
expect_route "CI workflow changes require the full pre-merge gate" pull_request full true .github/workflows/ci.yml
expect_route "PDDA implementation changes run PDDA plus the full gate" pull_request full true utils/pdda/pdda.sh
shell_suffix=sh
deleted_test="test/removed-regression.${shell_suffix}"
expect_route "a deleted regression test fails closed into the full gate" pull_request full true "$deleted_test"
expect_route "pushes remain the full integration boundary" push full true
expect_route "scheduled runs remain the full fallback boundary" schedule full true

out="$(route pull_request utils/hq/hq.sh)"
grep -Fqx 'changed_tests=hq.sh' <<<"$out" \
  && pass "fast routes include a directly matching changed-area test" \
  || fail "fast route omitted its changed-area test: $out"

out="$(printf '' | bash "$ROUTER" pull_request)"
grep -Fqx 'route=full' <<<"$out" \
  && pass "an empty PR diff fails closed into the full gate" \
  || fail "empty PR diff did not fail closed: $out"

set +e
unknown_out="$(bash "$ROUTER" unsupported </dev/null 2>&1)"
unknown_rc=$?
set -e
[[ "$unknown_rc" -eq 2 && "$unknown_out" == *"unsupported event"* ]] \
  && pass "unknown events fail loudly" \
  || fail "unknown event result: rc=$unknown_rc out=$unknown_out"

echo "  ci-route: $PASS pass, $FAIL fail"
exit "$FAIL"
