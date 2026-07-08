#!/usr/bin/env bash
# test/relay-untracked-file-warn.sh — GH-32 #1 / GH-178 B2: under RELAY_WORKTREE_ISOLATION=1 the
# turn-taker runs in an isolated worktree, but its own seeding step (rtl_worktree_begin) copies an
# uncommitted relay file's CURRENT content in regardless (relay-turn-lib.sh:247) — so for a relay
# file in the SAME repo as the turn-taker's root, it is usually still visible: the driver emits an
# informational NOTE, not an alarming "will find nothing" WARNING. That claim only holds for a
# relay file in a DIFFERENT repo (archive-routed), where seeding provably can't reach it — see
# test/relay-file-seeding-visibility.sh for the mechanical proof of both halves of this claim.
# The driver must never block either way, and stay silent when the file IS at HEAD or isolation is
# off. ($A is a git clone with an empty seed commit; relay files start uncommitted.)
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

# --- Case A: isolation on (default) + UNCOMMITTED relay file, SAME repo as the turn-taker's
# effective root → informational NOTE fires (seeding covers it), never the alarming "will find
# nothing" claim. --target-root "$A" makes $A the effective root (matching where the relay file
# lives) — without it, ROOT_DIR defaults to relay-drive.sh's OWN location (this real harness
# checkout), which would make even an in-$A file look cross-repo and defeat this case's purpose. ---
printf 'STATUS: In progress\n# body\n' >"$A/relayA.md"
seed_token RELAY-A relayA.md
outA="$(bash "$DRIVE" --relay-file "$A/relayA.md" --relay-task RELAY-A --agent-cmd "$NOOP_STUB" --round-cap 1 --target-root "$A" 2>&1)"
printf '%s' "$outA" | grep -q "not committed at HEAD" \
  && pass "uncommitted relay file under isolation notes it" || fail "expected untracked note (out: $outA)"
printf '%s' "$outA" | grep -q "NOTE —" \
  && pass "same-repo case is an informational NOTE, not a WARNING" || fail "expected NOTE tone (out: $outA)"
printf '%s' "$outA" | grep -q "will find nothing" \
  && fail "same-repo case should NOT claim the reviewer will find nothing — seeding covers it (out: $outA)" \
  || pass "same-repo case does not make the false 'will find nothing' claim"
printf '%s' "$outA" | grep -q "RELAY_WORKTREE_ISOLATION=0" \
  && pass "note still mentions the isolation-off option" || fail "note missing isolation-off mention (out: $outA)"

# --- Case A2: isolation on + UNCOMMITTED relay file, DIFFERENT repo than ROOT (archive-routed
# shape) → the strong WARNING still fires, since seeding provably can't reach it there. ---
printf 'STATUS: In progress\n# body in B\n' >"$B/relayA2.md"
seed_token RELAY-A2 relayA2.md
outA2="$(bash "$DRIVE" --relay-file "$B/relayA2.md" --relay-task RELAY-A2 --agent-cmd "$NOOP_STUB" --round-cap 1 2>&1)"
printf '%s' "$outA2" | grep -q "WARNING — relay file is not committed at HEAD" \
  && pass "cross-repo uncommitted relay file still gets the strong WARNING" || fail "expected strong WARNING for cross-repo case (out: $outA2)"
printf '%s' "$outA2" | grep -q "will find nothing" \
  && pass "cross-repo WARNING keeps the 'will find nothing' claim (still accurate there)" || fail "cross-repo WARNING lost its accurate claim (out: $outA2)"

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
