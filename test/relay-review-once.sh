#!/usr/bin/env bash
# test/relay-review-once.sh — GH-32 #2: a deliberate single review turn must be legible. With
# --review-once the driver drives exactly ONE turn and classifies the outcome with a review oracle:
#   - reviewer Approved/Closed                          -> exit 0
#   - reviewer completed a turn, requested changes      -> exit 5 (NOT the stall's 3)
#   - reviewer did nothing (genuine stall)              -> exit 3
#   - reviewer Escalated (by design)                    -> exit 4
# This is the fix for "a successful 'Changes requested' review looked identical to a stall (exit 3)".
source "$(dirname "$0")/_setup.sh" relay-review-once

export TICK_BIN="$TICK"
DRIVE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"
TICK_PATH="$TICK"

tick_a init >/dev/null

seed() {  # <task> <relayfile-basename>
  printf 'STATUS: In progress\n# body\n' >"$A/$2"
  tick_a log task.created "$1" --agent producer --paths "$2" >/dev/null 2>&1
  tick_a claim   "$1" --agent producer --paths "$2" >/dev/null 2>&1
  tick_a release "$1" --agent producer --to reviewer >/dev/null 2>&1
}

# --- Case A: reviewer requests changes and hands back to the producer → exit 5 (not 3). ---
seed RELAY-RC relayRC.md
RC_STUB="$WORK/rc-stub.sh"
cat >"$RC_STUB" <<EOF
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
"$TICK_PATH" claim RELAY-RC --agent reviewer >/dev/null 2>&1
tmp="\$(mktemp)"; sed 's/^STATUS:.*/STATUS: Changes requested/' "$A/relayRC.md" > "\$tmp" && mv "\$tmp" "$A/relayRC.md"
printf '\n### Reviewer · Round 1\nVERDICT: FAIL\nBasis: two issues found.\nChanges requested.\n' >> "$A/relayRC.md"
"$TICK_PATH" release RELAY-RC --agent reviewer --to producer >/dev/null 2>&1
exit 0
EOF
chmod +x "$RC_STUB"
outA="$(bash "$DRIVE" --relay-file "$A/relayRC.md" --relay-task RELAY-RC --agent-cmd "$RC_STUB" --review-once 2>&1)"; rcA=$?
[ "$rcA" -eq 5 ] && pass "changes-requested single review exits 5 (not the stall's 3)" || fail "expected 5, got $rcA (out: $outA)"
printf '%s' "$outA" | grep -qi "no progress" && fail "changes-requested read as no-progress (out: $outA)" || pass "changes-requested NOT reported as no-progress"

# --- Case B: reviewer approves → exit 0. ---
seed RELAY-AP relayAP.md
AP_STUB="$WORK/ap-stub.sh"
cat >"$AP_STUB" <<EOF
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
"$TICK_PATH" claim RELAY-AP --agent reviewer >/dev/null 2>&1
tmp="\$(mktemp)"; sed 's/^STATUS:.*/STATUS: Approved/' "$A/relayAP.md" > "\$tmp" && mv "\$tmp" "$A/relayAP.md"
printf '\n### Reviewer · Round 1\nVERDICT: PASS\nApproved.\n' >> "$A/relayAP.md"
"$TICK_PATH" done RELAY-AP --agent reviewer >/dev/null 2>&1
exit 0
EOF
chmod +x "$AP_STUB"
outB="$(bash "$DRIVE" --relay-file "$A/relayAP.md" --relay-task RELAY-AP --agent-cmd "$AP_STUB" --review-once 2>&1)"; rcB=$?
[ "$rcB" -eq 0 ] && pass "approved single review exits 0" || fail "expected 0, got $rcB (out: $outB)"

# --- Case C: reviewer does nothing → genuine stall → exit 3 (the guard we did not weaken). ---
seed RELAY-ST relayST.md
NOOP_STUB="$WORK/noop-stub.sh"; printf '#!/usr/bin/env bash\nexit 0\n' >"$NOOP_STUB"; chmod +x "$NOOP_STUB"
outC="$(bash "$DRIVE" --relay-file "$A/relayST.md" --relay-task RELAY-ST --agent-cmd "$NOOP_STUB" --review-once 2>&1)"; rcC=$?
[ "$rcC" -eq 3 ] && pass "a true stall still exits 3 under --review-once" || fail "expected 3, got $rcC (out: $outC)"

# --- Case D: reviewer escalates by design → exit 4 (carve-out still wins under --review-once). ---
seed RELAY-ES relayES.md
ES_STUB="$WORK/es-stub.sh"
cat >"$ES_STUB" <<EOF
#!/usr/bin/env bash
set -u
tmp="\$(mktemp)"; sed 's/^STATUS:.*/STATUS: Escalated/' "$A/relayES.md" > "\$tmp" && mv "\$tmp" "$A/relayES.md"
printf '\n### Reviewer · Round 1\nHanded back to human.\n' >> "$A/relayES.md"
exit 0
EOF
chmod +x "$ES_STUB"
outD="$(bash "$DRIVE" --relay-file "$A/relayES.md" --relay-task RELAY-ES --agent-cmd "$ES_STUB" --review-once 2>&1)"; rcD=$?
[ "$rcD" -eq 4 ] && pass "by-design Escalated still exits 4 under --review-once" || fail "expected 4, got $rcD (out: $outD)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
