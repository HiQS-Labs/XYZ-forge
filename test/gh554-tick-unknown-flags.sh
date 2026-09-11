#!/usr/bin/env bash
# GH-554: every tick verb must reject unknown flags before it can read or
# mutate coordination state. The release cases reproduce the reported loss of
# ownership caused by a silently ignored `--status done`.
source "$(dirname "$0")/_setup.sh" gh554-tick-unknown-flags

event_count() {
  find "$A/.tick/events" -type f -name '*.jsonl' | wc -l | tr -d '[:space:]'
}

owner() {
  "$TICK" info T554 2>/dev/null | awk '/^claimer:/ { print $2 }'
}

assert_unknown_is_pure() {
  local name="$1"
  shift
  local before_count before_owner after_count after_owner out rc
  before_count="$(event_count)"
  before_owner="$(owner)"
  out="$("$TICK" "$@" 2>&1)"; rc=$?
  after_count="$(event_count)"
  after_owner="$(owner)"
  [ "$rc" -eq 2 ] \
    && pass "$name: unknown flag exits 2" \
    || fail "$name: unknown flag exit $rc (expected 2): $out"
  grep -q 'unknown flag' <<<"$out" \
    && pass "$name: usage diagnostic names the unknown flag" \
    || fail "$name: missing unknown-flag diagnostic: $out"
  [ "$after_count" = "$before_count" ] \
    && pass "$name: event count unchanged ($before_count)" \
    || fail "$name: event count changed $before_count -> $after_count"
  [ "$after_owner" = "$before_owner" ] \
    && pass "$name: ownership unchanged (${before_owner:-none})" \
    || fail "$name: ownership changed ${before_owner:-none} -> ${after_owner:-none}"
}

# An invalid init must not even create the state directory.
UNINITIALIZED="$WORK/uninitialized"
mkdir -p "$UNINITIALIZED"
out="$(TICK_REPO_ROOT="$UNINITIALIZED" "$TICK" init --bogus-flag 2>&1)"; rc=$?
[ "$rc" -eq 2 ] && pass 'init: unknown flag exits 2' || fail "init: exit $rc (expected 2): $out"
grep -q 'unknown flag' <<<"$out" && pass 'init: usage diagnostic names the unknown flag' || fail "init: missing diagnostic: $out"
[ ! -e "$UNINITIALIZED/.tick" ] && pass 'init: unknown flag creates no state directory' || fail 'init: unknown flag created state directory'

tick_a init >/dev/null
tick_a log task.created T554 --agent seed --paths 'src/**' >/dev/null
tick_a claim T554 --agent seed --paths 'src/**' >/dev/null

# The original reproduction must leave the claim held by seed and append no
# release event. A second arbitrary flag pins the general case.
assert_unknown_is_pure 'release --status done' release T554 --agent seed --status done
assert_unknown_is_pure 'release --bogus-flag' release T554 --agent seed --bogus-flag

# Cover every remaining state-mutating verb plus all read-only verbs. Their
# normal preconditions intentionally do not matter: flag rejection happens
# before a verb inspects task state.
assert_unknown_is_pure 'log' log task.created T554 --bogus-flag
assert_unknown_is_pure 'claim' claim T554 --agent seed --paths 'src/**' --bogus-flag
assert_unknown_is_pure 'take' take --agent seed --bogus-flag
assert_unknown_is_pure 'scope' scope T554 --agent seed --paths 'src/**' --bogus-flag
assert_unknown_is_pure 'break' break T554 --agent seed --reason no --bogus-flag
assert_unknown_is_pure 'done' done T554 --agent seed --bogus-flag
assert_unknown_is_pure 'ping' ping T554 --agent seed --bogus-flag
assert_unknown_is_pure 'reap' reap seed --bogus-flag
assert_unknown_is_pure 'drift' drift src/tick.js --agent seed --bogus-flag
assert_unknown_is_pure 'cost' cost T554 --agent seed --human-minutes 1 --bogus-flag
assert_unknown_is_pure 'analyze' analyze --bogus-flag
assert_unknown_is_pure 'project' project --bogus-flag
assert_unknown_is_pure 'fences' fences --bogus-flag
assert_unknown_is_pure 'next' next --agent seed --bogus-flag
assert_unknown_is_pure 'claims' claims --bogus-flag
assert_unknown_is_pure 'info' info T554 --bogus-flag

# Known options, equals syntax, and TICK_AGENT remain valid. `log` is chosen
# because it exercises the documented agent fallback and records it verbatim.
TICK_AGENT=from-env "$TICK" log task.created ENV554 --paths='env/**' --note='equals works' --priority=1 --epoch=1 >/dev/null
env_agent="$(node -e 'const fs = require("fs"); const d = process.argv[1]; const e = fs.readdirSync(d).filter(f => f.endsWith(".jsonl")).map(f => JSON.parse(fs.readFileSync(`${d}/${f}`, "utf8"))).find(e => e.task === "ENV554"); process.stdout.write(e.agent)' "$A/.tick/events")"
[ "$env_agent" = from-env ] \
  && pass 'known --flag=value options and TICK_AGENT fallback still work' \
  || fail "known options/fallback regressed (agent=${env_agent:-none})"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
