#!/usr/bin/env bash
# worktree-isolation.sh — claude-turn.sh with RELAY_WORKTREE_ISOLATION=1 runs the builder in a
# THROWAWAY git worktree (ROADMAP Part A Phase 3.6, the airtight async/side-effect close). Async or
# off-lane writes land in the discarded tree, never ROOT; only the allowlist is copied back.
# The stub `claude` edits paths RELATIVE to its CWD (= the worktree when isolation is on), which is
# exactly the property isolation relies on. Shim is invoked with CWD=$A so the off (default) path is
# a fair regression baseline.
source "$(dirname "$0")/_setup.sh" worktree-isolation
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/claude-turn.sh"
tick_a init >/dev/null

# committed baseline: relay file + an artifact in ALLOW_PATHS; .tick gitignored.
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf 'seed\n' >"$A/artifact.txt"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md artifact.txt .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "seed" >/dev/null 2>&1

# Stub `claude`: edits RELATIVE paths (CWD = worktree when isolated). Token ops via $TICK (shared
# .tick). STUB_MODE: good = legit artifact edit + a BACKGROUND async off-lane write (fires AFTER the
# turn returns); offlane = a SYNC off-lane write during the turn.
STUB="$WORK/claude"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "artifact.txt" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
printf 'built by builder\n' >> artifact.txt          # legit allowlist edit (relative to CWD)
printf '\n### Round 1 · Builder\n' >> relay.md        # legit relay edit
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to reviewer >/dev/null 2>&1
if [ "${STUB_MODE:-good}" = good ]; then
  ( sleep 1; printf 'async junk\n' > offlane-async.txt ) &   # async side effect AFTER the turn
fi
[ "${STUB_MODE:-good}" = offlane ] && printf 'sync off-lane\n' > offlane-sync.txt
printf '{"usage":{"input_tokens":1,"output_tokens":1},"total_cost_usd":0}\n'   # minimal cost JSON
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ tick_a log task.created "$1" --agent claude --paths "artifact.txt" >/dev/null; tick_a claim "$1" --agent claude --paths "artifact.txt" >/dev/null 2>&1; tick_a release "$1" --agent claude --to claude >/dev/null 2>&1; }

run_shim(){ # <task> <stub-mode> <isolation 0|1>
  ( cd "$A" && RELAY_AGENT=claude RELAY_FILE="$A/relay.md" RELAY_TASK="$1" \
      CLAUDE_AGENT=claude CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG="$WORK/claude.$1.json" \
      ALLOW_PATHS="artifact.txt" CLAUDE_BLOCK_CMDS="" STUB_MODE="$2" RELAY_WORKTREE_ISOLATION="$3" \
      bash "$SHIM" >/dev/null 2>&1 )
}

# --- (1) isolation ON, good turn: async off-lane write is CONTAINED, allowlist committed ----------
seed_token RELAY-TURN-iso
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-iso good 1; rc=$?
sleep 2   # let the detached async write fire (t+1s) against the now-deleted worktree
[ "$rc" -eq 0 ] && pass "isolated good turn exits 0" || fail "isolated good turn rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "isolated turn committed the allowlist" || fail "expected a commit"
grep -q "built by builder" "$A/artifact.txt" && pass "legit allowlist edit copied back to ROOT" || fail "artifact.txt missing builder content"
[ ! -e "$A/offlane-async.txt" ] && pass "async off-lane write CONTAINED (never reached ROOT)" || fail "offlane-async.txt leaked into ROOT!"
[ "$(git -C "$A" worktree list | wc -l | tr -d ' ')" = "1" ] && pass "throwaway worktree cleaned up" || fail "worktree leaked"

# --- (2) isolation ON, sync off-lane edit: contained AND escalated (exit 6), ROOT untouched -------
seed_token RELAY-TURN-off
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-off offlane 1; rc=$?
[ "$rc" -eq 6 ] && pass "isolated off-lane edit -> exit 6 (contained + escalated)" || fail "expected exit 6, got $rc"
[ ! -e "$A/offlane-sync.txt" ] && pass "off-lane file never reached ROOT" || fail "offlane-sync.txt leaked into ROOT!"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "off-lane turn made NO commit (nothing copied back)" || fail "off-lane turn should not commit"
git -C "$A" diff --quiet -- artifact.txt relay.md && pass "off-lane turn left ROOT working tree unmodified (all-or-nothing copy-back)" || fail "off-lane turn dirtied ROOT (partial copy-back)"
[ "$(git -C "$A" worktree list | wc -l | tr -d ' ')" = "1" ] && pass "worktree cleaned up after off-lane fail" || fail "worktree leaked on off-lane"

# --- (3) isolation OFF (default): in-ROOT path unchanged — regression baseline -------------------
seed_token RELAY-TURN-noiso
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-noiso good 0; rc=$?
[ "$rc" -eq 0 ] && pass "non-isolated good turn exits 0 (unchanged path)" || fail "non-isolated rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "non-isolated turn committed normally" || fail "expected a commit"
# clean up the async file the non-isolated turn legitimately produced in ROOT (known gap, not tested here)
rm -f "$A/offlane-async.txt"

# --- (4) isolation ON + a concurrent ROOT commit DURING the turn: PRESERVE it, don't reset+fail ----
# Regression for GH-13/#14: RTL_WT_USED was set inside rtl_worktree_begin's `wt="$(...)"` subshell and
# LOST, so rtl_enforce wrongly took the in-ROOT reset+exit-6 path for worktree turns and discarded the
# whole build whenever ROOT HEAD moved (the 2026-06-29 codex marathon). Now re-asserted in
# rtl_worktree_end → the peer/harness commit is preserved and the turn commits its allowlist on top.
STUB2="$WORK/claude-peer"
cat >"$STUB2" <<STUB_EOF
#!/usr/bin/env bash
set -u
"\$TICK" claim "\$RELAY_TASK" --agent "\$RELAY_AGENT" --paths "artifact.txt" >/dev/null 2>&1
printf 'built by builder\n' >> artifact.txt
printf '\n### Round 1 · Builder\n' >> relay.md
"\$TICK" release "\$RELAY_TASK" --agent "\$RELAY_AGENT" --to reviewer >/dev/null 2>&1
# simulate a peer/harness commit landing on ROOT during the turn (the moved-ROOT-HEAD trigger)
git -C "$A" commit --allow-empty -q -m "concurrent peer commit during turn" >/dev/null 2>&1
printf '{"usage":{"input_tokens":1,"output_tokens":1},"total_cost_usd":0}\n'
exit 0
STUB_EOF
chmod +x "$STUB2"
seed_token RELAY-TURN-peer
( cd "$A" && RELAY_AGENT=claude RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-peer \
    CLAUDE_AGENT=claude CLAUDE_BIN="$STUB2" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG="$WORK/claude.peer.json" \
    ALLOW_PATHS="artifact.txt" CLAUDE_BLOCK_CMDS="" RELAY_WORKTREE_ISOLATION=1 \
    bash "$SHIM" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 6 ] && pass "isolated turn + concurrent ROOT commit: NOT reset+exit-6 (GH-13/#14 preserve)" || fail "regressed: worktree turn reset on a moved ROOT HEAD (rc=$rc)"
# Capture-then-match (NOT `git log | grep -q`: grep -q closes the pipe on match → git SIGPIPE →
# pipefail reports failure even on a hit — the documented poll.sh commit_gate_ok pitfall).
peerlog="$(git -C "$A" log --oneline)"
case "$peerlog" in *"concurrent peer commit during turn"*) pass "concurrent ROOT commit PRESERVED (not orphaned)" ;; *) fail "peer commit was lost (orphaned by reset)" ;; esac
case "$(cat "$A/artifact.txt")" in *"built by builder"*) pass "builder's allowlist edit still copied back to ROOT" ;; *) fail "artifact.txt missing builder content after preserve" ;; esac

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
