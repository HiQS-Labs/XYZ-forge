#!/usr/bin/env bash
# shim-worktree.sh — codex-turn.sh AND agy-turn.sh honour RELAY_WORKTREE_ISOLATION=1 the same way
# claude-turn.sh does (ROADMAP Part A Phase 3.6): the turn runs with CWD = a THROWAWAY git worktree, so
# an off-lane write lands in the discarded tree (never ROOT) and only the allowlist is copied back.
# The shared core (relay-turn-lib.sh rtl_worktree_begin/end) is exercised in depth by
# worktree-isolation.sh; THIS proves the two cross-model shims wire it correctly (default-OFF unchanged).
source "$(dirname "$0")/_setup.sh" shim-worktree
export TICK_BIN="$TICK"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
tick_a init >/dev/null

# committed baseline: relay file + an artifact in ALLOW_PATHS; .tick gitignored.
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf 'seed\n' >"$A/artifact.txt"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md artifact.txt .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "seed" >/dev/null 2>&1

# Generic stub for BOTH codex and agy: ignores its flags; edits paths RELATIVE to CWD (= the worktree
# when isolation is on, which is the property isolation relies on); prints a stdout line (agy's
# non-empty-output guard); token ops via the shared .tick (TICK_REPO_ROOT=$A). STUB_MODE: good = legit
# allowlist edit; offlane = a relative off-lane write that must be contained to the worktree.
STUB="$WORK/shimstub"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
printf 'shimstub: model response for %s\n' "$RELAY_AGENT"   # stdout -> non-empty transcript (agy guard)
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "artifact.txt" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
printf 'built\n' >> artifact.txt                  # legit allowlist edit (relative to CWD)
printf '\n### Round 1 · Builder\n' >> relay.md     # legit relay edit (relative to CWD)
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
[ "${STUB_MODE:-good}" = offlane ] && printf 'sync off-lane\n' > offlane-sync.txt   # relative off-lane
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ # <task> <to-agent>
  tick_a log task.created "$1" --agent claude-a --paths "artifact.txt" >/dev/null
  tick_a claim   "$1" --agent claude-a --paths "artifact.txt" >/dev/null 2>&1
  tick_a release "$1" --agent claude-a --to "$2" >/dev/null 2>&1
}

run_codex(){ # <task> <mode> <iso>
  ( cd "$A" && RELAY_AGENT=codex RELAY_FILE="$A/relay.md" RELAY_TASK="$1" CODEX_AGENT=codex \
      CODEX_BIN="$STUB" CODEX_TURN_ROOT="$A" CODEX_LOG="$WORK/c.$1.log" ALLOW_PATHS="artifact.txt" \
      STUB_MODE="$2" RELAY_WORKTREE_ISOLATION="$3" bash "$REPO/relay-automation/codex-turn.sh" >/dev/null 2>&1 )
}
run_agy(){ # <task> <mode> <iso>
  ( cd "$A" && RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK="$1" AGY_AGENT=agy \
      AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$WORK/a.$1.log" ALLOW_PATHS="artifact.txt" \
      STUB_MODE="$2" RELAY_WORKTREE_ISOLATION="$3" bash "$REPO/relay-automation/agy-turn.sh" >/dev/null 2>&1 )
}

check_shim(){ # <label> <run-fn> <agent>
  local label="$1" run="$2" agent="$3" before rc
  # (1) isolation ON, good turn: allowlist copied back + committed; worktree cleaned up.
  git -C "$A" checkout -- artifact.txt relay.md >/dev/null 2>&1
  seed_token "WT-$label-good" "$agent"
  before="$(git -C "$A" rev-parse HEAD)"
  "$run" "WT-$label-good" good 1; rc=$?
  [ "$rc" -eq 0 ] && pass "$label: isolated good turn exits 0" || fail "$label: isolated good rc=$rc"
  grep -q "built" "$A/artifact.txt" && pass "$label: legit allowlist edit copied back to ROOT" || fail "$label: artifact.txt missing builder content"
  [ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "$label: isolated turn committed the allowlist" || fail "$label: expected a commit"
  [ "$(git -C "$A" worktree list | wc -l | tr -d ' ')" = "1" ] && pass "$label: throwaway worktree cleaned up" || fail "$label: worktree leaked"
  # (2) isolation ON, off-lane (relative): contained + exit 6, ROOT untouched, no commit.
  git -C "$A" checkout -- artifact.txt relay.md >/dev/null 2>&1
  seed_token "WT-$label-off" "$agent"
  before="$(git -C "$A" rev-parse HEAD)"
  "$run" "WT-$label-off" offlane 1; rc=$?
  [ "$rc" -eq 6 ] && pass "$label: isolated off-lane edit -> exit 6 (contained + escalated)" || fail "$label: expected exit 6, got $rc"
  [ ! -e "$A/offlane-sync.txt" ] && pass "$label: off-lane write never reached ROOT" || fail "$label: offlane-sync.txt leaked into ROOT!"
  [ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "$label: off-lane turn made NO commit" || fail "$label: off-lane turn should not commit"
  # (3) isolation OFF (default): in-ROOT path unchanged — regression baseline.
  git -C "$A" checkout -- artifact.txt relay.md >/dev/null 2>&1
  seed_token "WT-$label-noiso" "$agent"
  before="$(git -C "$A" rev-parse HEAD)"
  "$run" "WT-$label-noiso" good 0; rc=$?
  [ "$rc" -eq 0 ] && pass "$label: non-isolated good turn exits 0 (unchanged path)" || fail "$label: non-isolated rc=$rc"
  [ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "$label: non-isolated turn committed normally" || fail "$label: expected a commit (OFF path)"
}

check_shim codex run_codex codex
check_shim agy   run_agy   agy

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
