#!/usr/bin/env bash
# test/relay-untracked-file-warn.sh — GH-32 #1: under RELAY_WORKTREE_ISOLATION=1 the turn-taker runs
# in a worktree at ROOT@HEAD, so a relay file that isn't committed at HEAD is INVISIBLE to it. The
# driver must WARN (with the remedy) — but never block, and stay silent when the file IS at HEAD or
# isolation is off. ($A is a git clone with an empty seed commit; relay files start uncommitted.)
source "$(dirname "$0")/_setup.sh" relay-untracked-file-warn

export TICK_BIN="$TICK"
DRIVE="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-drive.sh"

tick_a init >/dev/null

NOOP_STUB="$WORK/noop-stub.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$NOOP_STUB"; chmod +x "$NOOP_STUB"

seed_token() {  # <task> <relayfile>
  tick_a log task.created "$1" --agent claude-a --paths "$2" >/dev/null 2>&1
  tick_a claim   "$1" --agent claude-a --paths "$2" >/dev/null 2>&1
  tick_a release "$1" --agent claude-a --to reviewer >/dev/null 2>&1
}

# --- Case A: isolation on (default) + UNCOMMITTED relay file → warn fires with the remedy. ---
printf 'STATUS: In progress\n# body\n' >"$A/relayA.md"
seed_token RELAY-A relayA.md
outA="$(bash "$DRIVE" --relay-file "$A/relayA.md" --relay-task RELAY-A --agent-cmd "$NOOP_STUB" --round-cap 1 2>&1)"
printf '%s' "$outA" | grep -q "not committed at HEAD" \
  && pass "uncommitted relay file under isolation warns" || fail "expected untracked warn (out: $outA)"
printf '%s' "$outA" | grep -q "RELAY_WORKTREE_ISOLATION=0" \
  && pass "warn names the remedy" || fail "warn missing remedy (out: $outA)"

# --- Case B: isolation on + COMMITTED relay file → no warn (visible at HEAD). ---
printf 'STATUS: In progress\n# body\n' >"$A/relayB.md"
git -C "$A" add relayB.md >/dev/null 2>&1
git -C "$A" commit -q -m "commit relay file" >/dev/null 2>&1
seed_token RELAY-B relayB.md
outB="$(bash "$DRIVE" --relay-file "$A/relayB.md" --relay-task RELAY-B --agent-cmd "$NOOP_STUB" --round-cap 1 2>&1)"
printf '%s' "$outB" | grep -q "not committed at HEAD" \
  && fail "committed relay file should NOT warn (out: $outB)" \
  || pass "committed relay file does not warn"

# --- Case C: isolation OFF + uncommitted relay file → no warn regardless. ---
printf 'STATUS: In progress\n# body\n' >"$A/relayC.md"
seed_token RELAY-C relayC.md
outC="$(RELAY_WORKTREE_ISOLATION=0 bash "$DRIVE" --relay-file "$A/relayC.md" --relay-task RELAY-C --agent-cmd "$NOOP_STUB" --round-cap 1 2>&1)"
printf '%s' "$outC" | grep -q "not committed at HEAD" \
  && fail "isolation=0 should NOT warn (out: $outC)" \
  || pass "isolation off suppresses the warn"

# --- Case D: the warn is non-blocking — a true stall still exits 3 even with the warn present. ---
[ -n "$outA" ] && true   # outA came from a noop stub on RELAY-A (a genuine stall) and already ran
outD="$(bash "$DRIVE" --relay-file "$A/relayA.md" --relay-task RELAY-A --agent-cmd "$NOOP_STUB" --round-cap 1 2>&1)"; rcD=$?
[ "$rcD" -eq 3 ] && pass "warn does not block — true stall still exits 3" || fail "expected exit 3, got $rcD (out: $outD)"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
