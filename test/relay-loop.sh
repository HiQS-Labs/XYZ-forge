#!/usr/bin/env bash
# GH-33 Phase 2: relay-loop.sh — adaptive-cadence wrapper over poll.sh.
# (i) default one-tick mode surfaces NEXT-POLL + dispatches; (ii) --sleep-loop
# stops on terminal STATUS and iterates until a flip-to-Approved. File turn-source
# (token-optional) keeps the fixtures simple.
source "$(dirname "$0")/_setup.sh" relay-loop

LOOP="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-loop.sh"
export TICK_BIN="$TICK"
tick_a init >/dev/null

printf 'STATUS: Open\nNEXT: alice\n# body\n'     >"$A/relay-mine.md"
printf 'STATUS: Approved\nNEXT: alice\n# body\n' >"$A/relay-done.md"
printf 'art\n' >"$A/art.md"
git -C "$A" add relay-mine.md relay-done.md art.md >/dev/null 2>&1
git -C "$A" commit -q -m "relay-loop fixtures" >/dev/null 2>&1

# file-source as alice; <wrapper-flags...> come before, poll args appended after.
loop(){ POLL_GIT_ROOT="$A" bash "$LOOP" "$@" --mode relay --agent alice --turn-source file; }

# (1) default one-tick: my turn + clean + --dry-run -> NEXT-POLL: 0, exit 0
out="$(loop --relay-file "$A/relay-mine.md" --artifact "$A/art.md" --dry-run 2>&1)"; rc=$?
{ printf '%s\n' "$out" | grep -q '^NEXT-POLL: 0$'; } && [ "$rc" -eq 0 ] \
  && pass "default tick: run-runner -> NEXT-POLL: 0, exit 0" || fail "expected NEXT-POLL 0 / exit 0 (rc=$rc): $out"

# (2) default one-tick: NEXT-POLL reflects the idle backoff for a not-my-turn relay
printf 'STATUS: Open\nNEXT: bob\n# body\n' >"$A/relay-other.md"
git -C "$A" add relay-other.md >/dev/null 2>&1; git -C "$A" commit -q -m other >/dev/null 2>&1
out="$(loop --relay-file "$A/relay-other.md" --artifact "$A/art.md" --claude-agents alice,bob --dry-run 2>&1)"
{ printf '%s\n' "$out" | grep -q '^NEXT-POLL: 300$'; } \
  && pass "default tick: idle (not my turn) -> NEXT-POLL: 300 (adaptive backoff)" || fail "expected NEXT-POLL 300: $out"

# (3) default one-tick dispatch: runner fires once on my-turn+clean
SENT="$WORK/ran.txt"; : >"$SENT"
loop --relay-file "$A/relay-mine.md" --artifact "$A/art.md" --runner-cmd "echo ran >>'$SENT'" >/dev/null 2>&1
[ "$(grep -c ran "$SENT")" -eq 1 ] && pass "default tick: runner dispatched once" || fail "runner should dispatch once"

# (4) --sleep-loop stops immediately on terminal STATUS (exit 10, no sleep/hang)
loop --sleep-loop --max-ticks 5 --relay-file "$A/relay-done.md" --artifact "$A/art.md" --dry-run >/dev/null 2>&1
[ "$?" -eq 10 ] && pass "sleep-loop: terminal STATUS -> exit 10 (no sleep)" || fail "sleep-loop should exit 10 on Approved"

# (5) --sleep-loop iterates then stops: the runner flips the relay to Approved on tick 1,
#     so tick 2 reads a terminal STATUS and the loop exits 10. Proves it actually loops.
SENT2="$WORK/ran2.txt"; : >"$SENT2"
FLIP="$WORK/flip.sh"
cat >"$FLIP" <<RS
#!/usr/bin/env bash
echo ran >>"$SENT2"
printf 'STATUS: Approved\nNEXT: alice\n# body\n' >"$A/relay-flip.md"
RS
chmod +x "$FLIP"
printf 'STATUS: Open\nNEXT: alice\n# body\n' >"$A/relay-flip.md"
git -C "$A" add relay-flip.md >/dev/null 2>&1; git -C "$A" commit -q -m flip >/dev/null 2>&1
POLL_GIT_ROOT="$A" bash "$LOOP" --sleep-loop --max-ticks 5 --min-delay 1 \
  --mode relay --agent alice --turn-source file \
  --relay-file "$A/relay-flip.md" --artifact "$A/art.md" --runner-cmd "$FLIP" >/dev/null 2>&1
rc=$?
[ "$(grep -c ran "$SENT2")" -ge 1 ] && [ "$rc" -eq 10 ] \
  && pass "sleep-loop: iterates (runner ran) then stops on flip-to-Approved (exit 10)" \
  || fail "expected loop iterate+stop (rc=$rc, ran=$(grep -c ran "$SENT2" 2>/dev/null))"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
