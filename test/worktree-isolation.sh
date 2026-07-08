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
# turn returns); offlane = a SYNC off-lane write during the turn; greenfield = create an allowlisted
# file inside a brand-new dir; greenfield-offlane = that allowlisted create plus a genuinely off-lane dir.
STUB="$WORK/claude"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "$ALLOW_PATHS" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
TARGET_PATH="${ALLOW_PATHS%%,*}"
case "${STUB_MODE:-good}" in
  greenfield|greenfield-offlane)
    mkdir -p "$(dirname "$TARGET_PATH")"
    printf 'built in greenfield dir\n' > "$TARGET_PATH"
    ;;
  *)
    printf 'built by builder\n' >> artifact.txt      # legit allowlist edit (relative to CWD)
    ;;
esac
printf '\n### Round 1 · Builder\n' >> relay.md        # legit relay edit
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to reviewer >/dev/null 2>&1
if [ "${STUB_MODE:-good}" = good ]; then
  ( sleep 1; printf 'async junk\n' > offlane-async.txt ) &   # async side effect AFTER the turn
fi
[ "${STUB_MODE:-good}" = offlane ] && printf 'sync off-lane\n' > offlane-sync.txt
[ "${STUB_MODE:-good}" = greenfield-offlane ] && { mkdir -p greenfield-offlane; printf 'not allowed\n' > greenfield-offlane/nope.txt; }
# GH-107: a builder tool's own cache dir as an untracked side effect of an otherwise-clean turn
[ "${STUB_MODE:-good}" = toolcache ] && { mkdir -p .codebase-memory; printf 'index\n' > .codebase-memory/index.json; }
[ "${STUB_MODE:-good}" = customcache ] && { mkdir -p .mytool-cache; printf 'blob\n' > .mytool-cache/blob; }
printf '{"usage":{"input_tokens":1,"output_tokens":1},"total_cost_usd":0}\n'   # minimal cost JSON
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ local task="$1" allow_paths="${2:-artifact.txt}"; tick_a log task.created "$task" --agent claude --paths "$allow_paths" >/dev/null; tick_a claim "$task" --agent claude --paths "$allow_paths" >/dev/null 2>&1; tick_a release "$task" --agent claude --to claude >/dev/null 2>&1; }

run_shim(){ # <task> <stub-mode> <isolation 0|1> [allow-paths]
  local task="$1" stub="$2" iso="$3" allow_paths="${4:-artifact.txt}"
  ( cd "$A" && RELAY_AGENT=claude RELAY_FILE="$A/relay.md" RELAY_TASK="$task" \
      CLAUDE_AGENT=claude CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG="$WORK/claude.$task.json" \
      ALLOW_PATHS="$allow_paths" CLAUDE_BLOCK_CMDS="" STUB_MODE="$stub" RELAY_WORKTREE_ISOLATION="$iso" \
      bash -x "$SHIM" >/dev/null 2>&1 )
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

# --- (3) isolation ON, new allowlisted file in a new dir: allow the collapsed `?? dir/` ----------
# GH-59 regression: git status collapses an all-untracked dir to `greenfield-ok/`, while the allowlist
# carries the concrete file path (`greenfield-ok/output.txt`). The turn should treat the dir as allowed
# only because it is the true ancestor of that allowlisted file, then copy the file back and commit.
seed_token RELAY-TURN-greenfield "greenfield-ok/output.txt"
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-greenfield greenfield 1 "greenfield-ok/output.txt"; rc=$?
[ "$rc" -eq 0 ] && pass "greenfield allowlisted dir exits 0" || fail "greenfield rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "greenfield allowlisted dir committed cleanly" || fail "expected greenfield commit"
grep -q "built in greenfield dir" "$A/greenfield-ok/output.txt" && pass "greenfield allowlisted file copied back from collapsed dir" || fail "greenfield-ok/output.txt missing allowlisted content"
[ ! -e "$A/greenfield-offlane/nope.txt" ] && pass "greenfield case did not leak unrelated off-lane dir" || fail "unexpected greenfield-offlane leak"

# --- (4) isolation ON, unrelated new dir: still reject the genuine off-lane create ---------------
seed_token RELAY-TURN-greenfield-off "greenfield-new/output.txt"
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-greenfield-off greenfield-offlane 1 "greenfield-new/output.txt"; rc=$?
[ "$rc" -eq 6 ] && pass "genuine off-lane dir still exits 6" || fail "expected greenfield-offlane exit 6, got $rc"
[ ! -e "$A/greenfield-new/output.txt" ] && pass "off-lane greenfield turn copied back nothing" || fail "greenfield-new/output.txt should not copy back on off-lane fail"
[ ! -e "$A/greenfield-offlane/nope.txt" ] && pass "genuine off-lane dir never reached ROOT" || fail "greenfield-offlane/nope.txt leaked into ROOT!"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "genuine off-lane dir made NO commit" || fail "greenfield-offlane turn should not commit"

# --- (5) isolation OFF (default): in-ROOT path unchanged — regression baseline -------------------
seed_token RELAY-TURN-noiso
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-noiso good 0; rc=$?
[ "$rc" -eq 0 ] && pass "non-isolated good turn exits 0 (unchanged path)" || fail "non-isolated rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "non-isolated turn committed normally" || fail "expected a commit"
# clean up the async file the non-isolated turn legitimately produced in ROOT (known gap, not tested here)
sleep 1.5
rm -f "$A/offlane-async.txt"

# --- (6) isolation ON + a concurrent ROOT commit DURING the turn: PRESERVE it, don't reset+fail ----
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
    bash -x "$SHIM" ); rc=$?
[ "$rc" -ne 6 ] && pass "isolated turn + concurrent ROOT commit: NOT reset+exit-6 (GH-13/#14 preserve)" || fail "regressed: worktree turn reset on a moved ROOT HEAD (rc=$rc)"
# Capture-then-match (NOT `git log | grep -q`: grep -q closes the pipe on match → git SIGPIPE →
# pipefail reports failure even on a hit — the documented poll.sh commit_gate_ok pitfall).
peerlog="$(git -C "$A" log --oneline)"
case "$peerlog" in *"concurrent peer commit during turn"*) pass "concurrent ROOT commit PRESERVED (not orphaned)" ;; *) fail "peer commit was lost (orphaned by reset)" ;; esac
case "$(cat "$A/artifact.txt")" in *"built by builder"*) pass "builder's allowlist edit still copied back to ROOT" ;; *) fail "artifact.txt missing builder content after preserve" ;; esac

# --- (7) GH-107: built-in tool-cache dir (.codebase-memory/) no longer discards a clean turn -------
seed_token RELAY-TURN-toolcache
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-toolcache toolcache 1; rc=$?
[ "$rc" -eq 0 ] && pass "GH-107: built-in tool-cache side-effect does NOT fail the turn" || fail "toolcache rc=$rc (expected 0)"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "GH-107: turn with tool-cache side-effect still committed its allowlist" || fail "expected a commit despite tool-cache dir"
[ ! -e "$A/.codebase-memory" ] && pass "GH-107: ignored cache dir was discarded with the worktree, never copied to ROOT" || fail ".codebase-memory leaked into ROOT!"

# --- (8) GH-107: CONTAINMENT_IGNORE env extends the built-ins without a code change ----------------
seed_token RELAY-TURN-customcache
before="$(git -C "$A" rev-parse HEAD)"
CONTAINMENT_IGNORE=".mytool*" run_shim RELAY-TURN-customcache customcache 1; rc=$?
[ "$rc" -eq 0 ] && pass "GH-107: CONTAINMENT_IGNORE glob exempts a custom cache dir" || fail "customcache rc=$rc (expected 0)"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "GH-107: custom-ignored turn committed its allowlist" || fail "expected a commit with CONTAINMENT_IGNORE set"
[ ! -e "$A/.mytool-cache" ] && pass "GH-107: custom cache dir never reached ROOT" || fail ".mytool-cache leaked into ROOT!"

# --- (9) GH-107 control: the same non-built-in path WITHOUT CONTAINMENT_IGNORE still trips ---------
# (opt-in means opt-in: default behavior for a non-built-in untracked path is byte-for-byte unchanged;
# cases (2)/(4) above prove the plain off-lane baselines still fail exactly as before GH-107.)
seed_token RELAY-TURN-customcache-off
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-customcache-off customcache 1; rc=$?
[ "$rc" -eq 6 ] && pass "GH-107 control: non-built-in cache dir WITHOUT the env still exits 6" || fail "expected exit 6 without CONTAINMENT_IGNORE, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "GH-107 control: default-off turn made NO commit" || fail "default-off turn should not commit"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
