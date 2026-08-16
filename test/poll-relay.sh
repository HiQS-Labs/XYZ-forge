#!/usr/bin/env bash
# Phase 4(a): relay-drive.sh supervises a tick-native RELAY-TURN to termination.
# The fake turn-taker does REAL tick ops (claim/ping/release/done). The happy path
# is also the multi-turn re-handoff proof (one RELAY-TURN re-handed across 3 turns,
# staying exclusive + correctly re-targeted).
source "$(dirname "$0")/_setup.sh" poll-relay

DRIVE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"
TAKER="$WORK/taker.sh"
export TICK_BIN="$TICK"
tick_a init >/dev/null

# Fake turn-taker (invoked by the supervisor with RELAY_FILE/RELAY_TASK/RELAY_AGENT):
#   takes the token (claim+ping), appends a block, then per MODE+role:
#   normal     -> reviewer(RA): 1st turn release-to-producer (changes requested),
#                 2nd turn STATUS:Approved + `tick done` ; producer(PA): release-to-reviewer
#   loop       -> reviewer never approves (always release back) — drives the cap
#   noprogress -> claim+ping but never release/done
cat >"$TAKER" <<'TK'
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
me="$RELAY_AGENT"; t="$RELAY_TASK"; f="$RELAY_FILE"; mode="${MODE:-normal}"
other="$PA"; [ "$me" = "$PA" ] && other="$RA"
"$TICK" claim "$t" --agent "$me" --paths "z/**" >/dev/null 2>&1   # idempotent if already held
"$TICK" ping  "$t" --agent "$me" >/dev/null 2>&1
printf '\n### Turn · %s (mode=%s)\n' "$me" "$mode" >>"$f"
if [ "$mode" = noprogress ]; then exit 0; fi
if [ "$me" = "$RA" ]; then
  c="$WORK/rev.$t.n"; n=0; [ -f "$c" ] && n=$(cat "$c"); n=$((n+1)); echo "$n" >"$c"
  if [ "$n" -ge 2 ] && { [ "$mode" = normal ] || [ "$mode" = approvenodone ]; }; then
    sed -i.bak 's/^STATUS:.*/STATUS: Approved/' "$f"; rm -f "$f.bak"
    printf '**Verdict:** Approved\n' >>"$f"
    [ "$mode" = normal ] && "$TICK" done "$t" --agent "$me" >/dev/null 2>&1   # approvenodone: skip done -> leaked live token
  else
    printf '**Verdict:** Changes requested\n' >>"$f"
    "$TICK" release "$t" --agent "$me" --to "$other" >/dev/null 2>&1
  fi
else
  "$TICK" release "$t" --agent "$me" --to "$other" >/dev/null 2>&1
fi
git -C "$A" add "$f" >/dev/null 2>&1 || true
git -C "$A" commit -q -m "fake $me turn" >/dev/null 2>&1 || true
TK
chmod +x "$TAKER"

seed(){ # <task>  → relay file STATUS Open + RELAY-TURN handed to reviewer (ra) first
  printf 'STATUS: Open\n# relay body\n' >"$2"
  git -C "$A" add "$(basename "$2")" >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1
  tick_a log task.created "$1" --agent dispatcher >/dev/null
  tick_a claim "$1" --agent dispatcher --paths "z/**" >/dev/null
  tick_a release "$1" --agent dispatcher --to ra >/dev/null   # open + handoff_to ra
}
status_of(){ sed -n 's/^STATUS:[[:space:]]*//p' "$1" | head -1 | sed 's/[[:space:]]*$//'; }
blocks(){ grep -c '^### Turn ·' "$1" 2>/dev/null || true; }
task_status(){ tick_a info "$1" 2>/dev/null | sed -n 's/^status:[[:space:]]*//p' | head -1; }
AC(){ printf "PA=pa RA=ra MODE=%s bash '%s'" "$1" "$TAKER"; }

# --- (1) happy path: 3-turn re-handoff, closes Approved -------------------
R1="$A/relay1.md"; seed RELAY-TURN-1 "$R1"
bash "$DRIVE" --relay-file "$R1" --relay-task RELAY-TURN-1 --agent-cmd "$(AC normal)" --round-cap 8 >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && pass "drive returns 0 when relay closes Approved" || fail "expected 0, got $rc"
[ "$(status_of "$R1")" = "Approved" ] && pass "thread closed STATUS: Approved" || fail "STATUS not Approved"
[ "$(task_status RELAY-TURN-1)" = "done" ] && pass "RELAY-TURN token ended done (re-handed across turns)" || fail "token not done: $(task_status RELAY-TURN-1)"
[ "$(blocks "$R1")" -ge 3 ] && pass "multi-turn: >=3 turns on one re-handed RELAY-TURN" || fail "expected >=3 blocks, got $(blocks "$R1")"

# --- (2) no-progress escalation ------------------------------------------
R2="$A/relay2.md"; seed RELAY-TURN-2 "$R2"
bash "$DRIVE" --relay-file "$R2" --relay-task RELAY-TURN-2 --agent-cmd "$(AC noprogress)" --round-cap 8 >/dev/null 2>&1
[ "$?" -eq 3 ] && pass "no-progress turn escalates (exit 3)" || fail "expected exit 3"

# --- (3) round-cap escalation (never approves) ---------------------------
R3="$A/relay3.md"; seed RELAY-TURN-3 "$R3"
bash "$DRIVE" --relay-file "$R3" --relay-task RELAY-TURN-3 --agent-cmd "$(AC loop)" --round-cap 3 >/dev/null 2>&1
rc=$?
[ "$rc" -eq 4 ] && pass "round cap without Approved escalates (exit 4)" || fail "expected exit 4, got $rc"
[ "$(status_of "$R3")" != "Approved" ] && pass "never-approve relay did not close Approved" || fail "should not be Approved"

# --- (3b) close mismatch: STATUS Approved but token never `done` (Codex r1) ---
R5="$A/relay5.md"; seed RELAY-TURN-5 "$R5"
bash "$DRIVE" --relay-file "$R5" --relay-task RELAY-TURN-5 --agent-cmd "$(AC approvenodone)" --round-cap 8 >/dev/null 2>&1
rc=$?
[ "$rc" -eq 4 ] && pass "close mismatch (STATUS Approved, token not done) escalates (exit 4)" || fail "expected exit 4, got $rc"
[ "$(task_status RELAY-TURN-5)" = "claimed" ] && pass "leaked live token is NOT reported as a clean close" || fail "token should still be live, got: $(task_status RELAY-TURN-5)"

# --- (4) dry-run: names the actor, mutates nothing -----------------------
R4="$A/relay4.md"; seed RELAY-TURN-4 "$R4"
out="$(bash "$DRIVE" --relay-file "$R4" --relay-task RELAY-TURN-4 --dry-run 2>&1)"; rc=$?
echo "$out" | grep -q "WOULD drive turn for agent: ra" && pass "dry-run names the actor" || fail "dry-run missing actor: $out"
[ "$rc" -eq 0 ] && [ "$(blocks "$R4")" -eq 0 ] && pass "dry-run mutates nothing" || fail "dry-run should not mutate"

# --- (5) bare absolute --agent-cmd path WITH SPACES is invoked, not split (regression) ---
# The sibling-agent bug: a clone under ".../GH Repos/..." passed an absolute --agent-cmd; the old
# `eval "$AGENT_CMD"` split on the space → exec'd the wrong token → the turn-taker never ran. The fix:
# relay-drive runs a bare executable path DIRECTLY. We assert the taker actually ran (sentinel file) —
# the precise behaviour the bug broke; full-closure is already covered by cases 1–4. The taker does a
# real no-progress turn, so relay-drive escalates (exit 3) — we assert on the sentinel, not the exit.
SPACED_DIR="$WORK/dir with space"; mkdir -p "$SPACED_DIR"
STAKER="$SPACED_DIR/taker.sh"; SENTINEL="$WORK/spaced-taker-ran"
rm -f "$SENTINEL"
cat >"$STAKER" <<ST
#!/usr/bin/env bash
printf 'ran\n' > "$SENTINEL"
ST
chmod +x "$STAKER"
R6="$A/relay6.md"; seed RELAY-TURN-6 "$R6"
bash "$DRIVE" --relay-file "$R6" --relay-task RELAY-TURN-6 --agent-cmd "$STAKER" --round-cap 2 >/dev/null 2>&1
[ -f "$SENTINEL" ] \
  && pass "bare absolute --agent-cmd path with spaces is invoked directly (not split by eval)" \
  || fail "spaced bare agent-cmd was not invoked — relay-drive split the path instead of running it"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
