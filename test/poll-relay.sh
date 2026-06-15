#!/usr/bin/env bash
# Phase 4b: relay-drive.sh supervises a /relay thread to termination via a turn-taker.
source "$(dirname "$0")/_setup.sh" poll-relay

DRIVE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"
TAKER="$WORK/taker.sh"

# Fake turn-taker: appends a block, then moves NEXT/STATUS per MODE+role.
#   MODE=normal     -> Reviewer: 1st turn Changes requested (NEXT->Producer),
#                      2nd turn Approved (STATUS->Approved); Producer: NEXT->Reviewer.
#   MODE=loop       -> Reviewer always Changes requested (never approves).
#   MODE=noprogress -> appends a block but never moves NEXT/STATUS.
cat >"$TAKER" <<'TAKER_EOF'
#!/usr/bin/env bash
set -u
f="$RELAY_FILE"; role="$RELAY_ROLE"; mode="${MODE:-normal}"
cnt="$WORK/rev.$(basename "$f").n"; n=0; [ -f "$cnt" ] && n=$(cat "$cnt")
printf '\n### Turn · %s · faketaker (mode=%s)\n' "$role" "$mode" >>"$f"
if [ "$mode" = noprogress ]; then
  :
elif [ "$role" = Reviewer ]; then
  n=$((n+1)); echo "$n" >"$cnt"
  if [ "$mode" = normal ] && [ "$n" -ge 2 ]; then
    sed -i.bak 's/^STATUS:.*/STATUS: Approved/' "$f"
    sed -i.bak 's/^NEXT:.*/NEXT: — (closed)/' "$f"; rm -f "$f.bak"
    printf '**Verdict:** Approved\n' >>"$f"
  else
    sed -i.bak 's/^NEXT:.*/NEXT: Producer/' "$f"; rm -f "$f.bak"
    printf '**Verdict:** Changes requested\n' >>"$f"
  fi
else
  sed -i.bak 's/^NEXT:.*/NEXT: Reviewer/' "$f"; rm -f "$f.bak"
fi
git -C "$A" add "$f" >/dev/null 2>&1 || true
git -C "$A" commit -q -m "fake $role turn" >/dev/null 2>&1 || true
TAKER_EOF
chmod +x "$TAKER"

new_relay() { # <path>
  printf 'NEXT: Reviewer\nSTATUS: Open\n# relay body\n' >"$1"
  git -C "$A" add "$1" >/dev/null 2>&1 || true
  git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1 || true
}
status_of() { sed -n 's/^STATUS:[[:space:]]*//p' "$1" | head -1 | sed 's/[[:space:]]*$//'; }
blocks_in() { grep -c '^### Turn ·' "$1" 2>/dev/null || true; }

# --- (1) happy path: Changes requested then Approved, closes -------------
R1="$A/relay1.md"; new_relay "$R1"
bash "$DRIVE" --relay-file "$R1" --agent-cmd "MODE=normal bash '$TAKER'" --round-cap 6 >/dev/null 2>&1
rc=$?
[ "$rc" -eq 0 ] && pass "drive returns 0 when relay closes Approved" || fail "expected exit 0, got $rc"
[ "$(status_of "$R1")" = "Approved" ] && pass "thread closed on STATUS: Approved" || fail "STATUS not Approved: $(status_of "$R1")"
[ "$(blocks_in "$R1")" -eq 3 ] && pass "thread advanced 3 turns (Reviewer/Producer/Reviewer)" || fail "expected 3 turn blocks, got $(blocks_in "$R1")"

# --- (2) no-progress escalation -----------------------------------------
R2="$A/relay2.md"; new_relay "$R2"
bash "$DRIVE" --relay-file "$R2" --agent-cmd "MODE=noprogress bash '$TAKER'" --round-cap 6 >/dev/null 2>&1
rc=$?
[ "$rc" -eq 3 ] && pass "no-progress turn escalates (exit 3)" || fail "expected exit 3, got $rc"

# --- (3) round-cap escalation (never approves) --------------------------
R3="$A/relay3.md"; new_relay "$R3"
bash "$DRIVE" --relay-file "$R3" --agent-cmd "MODE=loop bash '$TAKER'" --round-cap 3 >/dev/null 2>&1
rc=$?
[ "$rc" -eq 4 ] && pass "round cap without Approved escalates (exit 4)" || fail "expected exit 4, got $rc"
[ "$(status_of "$R3")" != "Approved" ] && pass "never-approve relay did not close Approved" || fail "should not be Approved"

# --- (4) dry-run: names the turn, mutates nothing -----------------------
R4="$A/relay4.md"; new_relay "$R4"
out="$(bash "$DRIVE" --relay-file "$R4" --dry-run 2>&1)"; rc=$?
echo "$out" | grep -q "WOULD drive turn for role: Reviewer" && pass "dry-run names the next turn" || fail "dry-run missing WOULD line: $out"
[ "$rc" -eq 0 ] && [ "$(blocks_in "$R4")" -eq 0 ] && pass "dry-run mutates nothing" || fail "dry-run should not mutate (rc=$rc blocks=$(blocks_in "$R4"))"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
