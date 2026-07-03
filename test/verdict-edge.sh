#!/usr/bin/env bash
# GH-4 (PR #101 cross-model review): edge cases for the analyze verdict + collision accounting the
# happy-path work-stealing test doesn't cover — a handoff (released → done by ANOTHER agent), a
# still-open lane, a mid-window scope EXPANSION into a peer's live lane (the collision the old
# whole-window-final-snapshot missed), and the concurrency-target clamp.
source "$(dirname "$0")/_setup.sh" verdict-edge

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# run <events-dir> [ENVVAR=val] -> prints "verdict|all_lanes_done|collisions|concurrency_ok"
run() {
  local dir="$1"; shift
  env "$@" node -e '
    const { analyze } = require(process.env.PJ);
    const r = analyze(process.argv[1]);
    const c = r.verdict.checks;
    process.stdout.write([r.verdict.verdict, c.all_lanes_done, r.collisions.length, c.concurrency_ok].join("|"));
  ' "$dir"
}
export PJ="$ROOT/src/analyze"  # the node one-liner requires analyze (which requires project internally)

mkev() { # <dir> <sortable-fname> <json>
  mkdir -p "$1/.tick/events"; printf '%s' "$3" > "$1/.tick/events/$2.jsonl"
}

# --- Case A: handoff — TA released by alice then DONE by beta; concurrent TB by carol. all lanes done.
A="$WORK/handoff"; rm -rf "$A"
mkev "$A" 01-created-TA '{"ts":"2026-01-01T00:00:00.000Z","type":"task.created","task":"TA","agent":"d","paths":["a/**"]}'
mkev "$A" 01-created-TB '{"ts":"2026-01-01T00:00:00.100Z","type":"task.created","task":"TB","agent":"d","paths":["b/**"]}'
mkev "$A" 02-alice-claim-TA '{"ts":"2026-01-01T00:01:00.000Z","type":"task.claimed","task":"TA","agent":"alice","paths":["a/**"],"epoch":1}'
mkev "$A" 02-carol-claim-TB '{"ts":"2026-01-01T00:01:00.000Z","type":"task.claimed","task":"TB","agent":"carol","paths":["b/**"],"epoch":1}'
mkev "$A" 03-alice-rel-TA '{"ts":"2026-01-01T00:03:00.000Z","type":"task.released","task":"TA","agent":"alice","to_agent":"beta","epoch":1}'
mkev "$A" 04-beta-claim-TA '{"ts":"2026-01-01T00:03:30.000Z","type":"task.claimed","task":"TA","agent":"beta","paths":["a/**"],"epoch":2}'
mkev "$A" 05-carol-done-TB '{"ts":"2026-01-01T00:05:00.000Z","type":"task.done","task":"TB","agent":"carol"}'
mkev "$A" 06-beta-done-TA '{"ts":"2026-01-01T00:06:00.000Z","type":"task.done","task":"TA","agent":"beta"}'
GOT="$(run "$A")"
case "$GOT" in
  pass\|true\|0\|*) [ "${GOT%%|*}" != "fail" ] && [ "$(echo "$GOT" | cut -d'|' -f2)" = "true" ] \
    && pass "handoff: released-then-done-by-another counts as done (all_lanes_done, not false-failed) [$GOT]" \
    || fail "handoff false-failed: $GOT" ;;
esac

# --- Case B: still-open lane — TB never done -> all_lanes_done false -> verdict fail.
B="$WORK/open"; rm -rf "$B"
mkev "$B" 01-created-TA '{"ts":"2026-01-01T00:00:00.000Z","type":"task.created","task":"TA","agent":"d","paths":["a/**"]}'
mkev "$B" 01-created-TB '{"ts":"2026-01-01T00:00:00.100Z","type":"task.created","task":"TB","agent":"d","paths":["b/**"]}'
mkev "$B" 02-alice-claim-TA '{"ts":"2026-01-01T00:01:00.000Z","type":"task.claimed","task":"TA","agent":"alice","paths":["a/**"],"epoch":1}'
mkev "$B" 02-beta-claim-TB '{"ts":"2026-01-01T00:01:00.000Z","type":"task.claimed","task":"TB","agent":"beta","paths":["b/**"],"epoch":1}'
mkev "$B" 03-alice-done-TA '{"ts":"2026-01-01T00:05:00.000Z","type":"task.done","task":"TA","agent":"alice"}'
GOT="$(run "$B")"
[ "${GOT%%|*}" = "fail" ] && [ "$(echo "$GOT" | cut -d'|' -f2)" = "false" ] \
  && pass "still-open lane (TB never done) -> all_lanes_done false -> VERDICT fail [$GOT]" \
  || fail "still-open lane should fail: $GOT"

# --- Case C: mid-window scope EXPANSION collision — alice claims a/**, then expands into b/** WHILE
#     beta holds b/**. Final snapshot alone would still show a/**+b/**, but the point is the union
#     catches the overlap during the concurrent window. Must flag a collision -> verdict fail.
C="$WORK/scope"; rm -rf "$C"
mkev "$C" 01-created-TA '{"ts":"2026-01-01T00:00:00.000Z","type":"task.created","task":"TA","agent":"d","paths":["a/**"]}'
mkev "$C" 01-created-TB '{"ts":"2026-01-01T00:00:00.100Z","type":"task.created","task":"TB","agent":"d","paths":["b/**"]}'
mkev "$C" 02-alice-claim-TA '{"ts":"2026-01-01T00:01:00.000Z","type":"task.claimed","task":"TA","agent":"alice","paths":["a/**"],"epoch":1}'
mkev "$C" 02-beta-claim-TB '{"ts":"2026-01-01T00:01:00.000Z","type":"task.claimed","task":"TB","agent":"beta","paths":["b/**"],"epoch":1}'
mkev "$C" 03-alice-scope-TA '{"ts":"2026-01-01T00:02:00.000Z","type":"task.scope_changed","task":"TA","agent":"alice","paths":["a/**","b/**"],"epoch":1}'
mkev "$C" 04-beta-done-TB '{"ts":"2026-01-01T00:04:00.000Z","type":"task.done","task":"TB","agent":"beta"}'
mkev "$C" 05-alice-done-TA '{"ts":"2026-01-01T00:05:00.000Z","type":"task.done","task":"TA","agent":"alice"}'
GOT="$(run "$C")"
[ "$(echo "$GOT" | cut -d'|' -f3)" -ge 1 ] && [ "${GOT%%|*}" = "fail" ] \
  && pass "scope-expansion into a peer's live lane IS flagged as a collision (union, not final-snapshot) [$GOT]" \
  || fail "scope-expansion collision missed: $GOT"

# --- Case D: concurrency-target clamp — a 100%-concurrency board with TICK_CONCURRENCY_TARGET_PCT=120
#     must still be able to pass the concurrency gate (clamped to 100), not silently impossible.
# Claims are the first/last events so both agents span the ENTIRE run window -> 100% concurrency.
D="$WORK/clamp"; rm -rf "$D"
mkev "$D" 02-alice-claim-TA '{"ts":"2026-01-01T00:01:00.000Z","type":"task.claimed","task":"TA","agent":"alice","paths":["a/**"],"epoch":1}'
mkev "$D" 02-beta-claim-TB '{"ts":"2026-01-01T00:01:00.000Z","type":"task.claimed","task":"TB","agent":"beta","paths":["b/**"],"epoch":1}'
mkev "$D" 03-alice-done-TA '{"ts":"2026-01-01T00:06:00.000Z","type":"task.done","task":"TA","agent":"alice"}'
mkev "$D" 03-beta-done-TB '{"ts":"2026-01-01T00:06:00.000Z","type":"task.done","task":"TB","agent":"beta"}'
GOT="$(run "$D" TICK_CONCURRENCY_TARGET_PCT=120)"
[ "$(echo "$GOT" | cut -d'|' -f4)" = "true" ] \
  && pass "TICK_CONCURRENCY_TARGET_PCT=120 clamped to 100 — a 100% run still meets the gate [$GOT]" \
  || fail "clamp failed — >100 target made concurrency impossible: $GOT"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
