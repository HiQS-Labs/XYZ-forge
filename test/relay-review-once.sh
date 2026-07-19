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

# --- Case E (GH-245 defect 2, "Run B"): reviewer APPENDS findings but LEAVES THE TOKEN CLAIMED and
#     does not change STATUS. The old oracle read token state alone, so a real review with the token
#     left claimed was mis-scored as a stall (exit 3). It must now exit 5 on relay-file content evidence. ---
seed RELAY-KT relayKT.md
KT_STUB="$WORK/kt-stub.sh"
cat >"$KT_STUB" <<EOF
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
"$TICK_PATH" claim RELAY-KT --agent reviewer >/dev/null 2>&1
printf '\n### Reviewer · Round 1\nVERDICT: FAIL\nBasis: six findings.\nChanges requested.\n' >> "$A/relayKT.md"
# deliberately DO NOT release the token and DO NOT change STATUS (reproduces GH-245 Run B)
exit 0
EOF
chmod +x "$KT_STUB"
outE="$(bash "$DRIVE" --relay-file "$A/relayKT.md" --relay-task RELAY-KT --agent-cmd "$KT_STUB" --review-once 2>&1)"; rcE=$?
[ "$rcE" -eq 5 ] && pass "GH-245: relay-file append with token left claimed exits 5, not stall 3" || fail "expected 5, got $rcE (out: $outE)"

# --- Case F (GH-245 defect 2, "Run A"): reviewer moves the token only (claim+release) and writes
#     NOTHING. The old oracle read token movement as success, so an empty turn was mis-scored exit 5.
#     It must now exit 3 — no relay-file, NEXT, or STATUS evidence of a real review. ---
seed RELAY-TO relayTO.md
TO_STUB="$WORK/to-stub.sh"
cat >"$TO_STUB" <<EOF
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
"$TICK_PATH" claim   RELAY-TO --agent reviewer >/dev/null 2>&1
"$TICK_PATH" release RELAY-TO --agent reviewer --to producer >/dev/null 2>&1
exit 0
EOF
chmod +x "$TO_STUB"
outF="$(bash "$DRIVE" --relay-file "$A/relayTO.md" --relay-task RELAY-TO --agent-cmd "$TO_STUB" --review-once 2>&1)"; rcF=$?
[ "$rcF" -eq 3 ] && pass "GH-245: token-only move with no relay-file change exits 3, not success 5" || fail "expected 3, got $rcF (out: $outF)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
