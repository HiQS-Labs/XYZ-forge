#!/usr/bin/env bash
# test/relay-escalation-not-stall.sh — GH-18 #5: a by-design `STATUS: Escalated` handback must NOT
# read as a no-progress stall. The driver's success oracle must distinguish:
#   - escalated by design (reviewer set STATUS: Escalated, even if the token stayed live) → exit 4,
#     a clean "escalated to human by design" message — NOT exit 3.
#   - a true stall (STATUS unchanged + token didn't move) → still exit 3 "no progress".
source "$(dirname "$0")/_setup.sh" relay-escalation-not-stall

export TICK_BIN="$TICK"
DRIVE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"

tick_a init >/dev/null

# --- Case A: by-design escalation. A turn-taker that appends a block, sets STATUS: Escalated, and
# deliberately leaves the token with the reviewer (does NOT release) — the round-cap=1 handback. ---
printf 'STATUS: In progress\n# body\n' >"$A/relayA.md"
tick_a log task.created RELAY-A --agent claude-a --paths relayA.md >/dev/null 2>&1
tick_a claim   RELAY-A --agent claude-a --paths relayA.md >/dev/null 2>&1
tick_a release RELAY-A --agent claude-a --to reviewer     >/dev/null 2>&1

ESC_STUB="$WORK/esc-stub.sh"
cat >"$ESC_STUB" <<EOF
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
# reviewer updates the STATUS header to Escalated (in place, as a real turn-taker does) and appends
# its block, WITHOUT releasing the token (round cap) — the by-design handback to a human.
tmp="\$(mktemp)"
sed 's/^STATUS:.*/STATUS: Escalated/' "$A/relayA.md" > "\$tmp" && mv "\$tmp" "$A/relayA.md"
printf '\n### Reviewer · Round 1\nHanded back to human (round cap reached).\n' >> "$A/relayA.md"
exit 0
EOF
chmod +x "$ESC_STUB"

out="$(bash "$DRIVE" --relay-file "$A/relayA.md" --relay-task RELAY-A --agent-cmd "$ESC_STUB" --round-cap 1 2>&1)"; rc=$?
[ "$rc" -eq 4 ] && pass "by-design Escalated exits 4 (not the stall's 3)" || fail "expected exit 4, got $rc (out: $out)"
printf '%s' "$out" | grep -q "escalated to human by design" \
  && pass "by-design Escalated reports a clean handback message" || fail "missing by-design message (out: $out)"
printf '%s' "$out" | grep -qi "no progress" \
  && fail "by-design Escalated still reads as a no-progress stall (out: $out)" \
  || pass "by-design Escalated is NOT reported as no-progress"

# --- Case B: a genuine stall. Turn-taker does nothing — no block, no STATUS change, token unmoved.
# This MUST still exit 3 (the guard we did not weaken). ---
printf 'STATUS: In progress\n# body\n' >"$A/relayB.md"
tick_a log task.created RELAY-B --agent claude-a --paths relayB.md >/dev/null 2>&1
tick_a claim   RELAY-B --agent claude-a --paths relayB.md >/dev/null 2>&1
tick_a release RELAY-B --agent claude-a --to reviewer     >/dev/null 2>&1

NOOP_STUB="$WORK/noop-stub.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$NOOP_STUB"; chmod +x "$NOOP_STUB"

out2="$(bash "$DRIVE" --relay-file "$A/relayB.md" --relay-task RELAY-B --agent-cmd "$NOOP_STUB" --round-cap 1 2>&1)"; rc2=$?
[ "$rc2" -eq 3 ] && pass "a true stall still exits 3 (no-progress guard intact)" || fail "expected exit 3, got $rc2 (out: $out2)"

# --- Case C: a relay that STARTS already Escalated is recognized at the top of the loop. ---
printf 'STATUS: Escalated\n# body\n' >"$A/relayC.md"
tick_a log task.created RELAY-C --agent claude-a --paths relayC.md >/dev/null 2>&1
tick_a claim   RELAY-C --agent claude-a --paths relayC.md >/dev/null 2>&1
tick_a release RELAY-C --agent claude-a --to reviewer     >/dev/null 2>&1
out3="$(bash "$DRIVE" --relay-file "$A/relayC.md" --relay-task RELAY-C --agent-cmd "$NOOP_STUB" --round-cap 2 2>&1)"; rc3=$?
[ "$rc3" -eq 4 ] && pass "pre-escalated relay caught at loop top (exit 4)" || fail "expected exit 4, got $rc3 (out: $out3)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
