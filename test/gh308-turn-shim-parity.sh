#!/usr/bin/env bash
# test/gh308-turn-shim-parity.sh — GH-308 audit: turn-shim behaviors present in Bash but missing from
# the Python twins that actually run (GH-264):
#   1. [Inert feature, RUNTIME] claude-turn.py never prepended the GH-68 cross-agent dependency-drift
#      brief — it was the ONLY Python turn shim missing rtl.drift_brief (codex/pi/agy/aider all had
#      it). So on the default lane the Claude builder silently lost the "a peer changed a shared
#      surface since your last turn" heads-up. Driven end-to-end on the DEFAULT lane below.
#   2. [Inert feature, STRUCTURAL parity] pi-turn.py and aider-turn.py rooted at xyz_root (the shim's
#      own install dir) instead of the CWD's git toplevel when *_TURN_ROOT was unset — the GH-296 bug
#      resolve_turn_root() was created to fix. codex/claude adopted it; pi/aider were missed. Runtime
#      proof was captured during the GH-308 audit (see PROJECT/2-WORKING/GH-308-...md); this locks the
#      regression by asserting every turn shim resolves ROOT the same way.
source "$(dirname "$0")/_setup.sh" gh308-turn-shim-parity
unset ALLOW_PATHS RELAY_FILE RELAY_TASK RELAY_AGENT RELAY_PEER RELAY_WORKTREE_ISOLATION
export TICK_BIN="$TICK"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHIM="$ROOT/relay-automation/claude-turn.sh"
PY_DIR="$ROOT/utils/py"

tick_a init >/dev/null
mkdir -p "$A/src"
printf 'module.exports = {};\n' >"$A/src/project.js"
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add src/project.js relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

# Stub `claude`: dumps its argv (which carries `-p <prompt>`) so we can inspect the turn brief, then
# performs a minimal real turn (claim/append/release) so the shim reaches exit 0.
STUB="$WORK/claude"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
printf '%s\n' "$*" > "$WORK/claude-args"
export TICK_REPO_ROOT="$A"
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
printf '\n### Round 1 · Builder (claude-stub)\n**Verdict:** Changes requested\n' >>"$RELAY_FILE"
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to gemini >/dev/null 2>&1
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to claude-builder >/dev/null; }

# ── (1) claude-turn.py drift brief on the DEFAULT lane ────────────────────────────────────
# Seed an UNREAD dependency-drift event authored by a PEER (codex) on a shared surface. claude-builder
# has not seen it, so its next turn's brief must carry the heads-up.
seed_token RELAY-TURN-drift
tick_a drift "src/project.js" --agent codex --task post-commit --prior-sha aaa --current-sha bbb --diff-lines 9 >/dev/null 2>&1

RELAY_AGENT=claude-builder RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-drift CLAUDE_AGENT=claude-builder \
  CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG=/dev/null \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
brief="$(cat "$WORK/claude-args" 2>/dev/null || true)"
[ "$rc" -eq 0 ] && pass "claude-turn default lane: turn still completes with a peer drift pending (exit 0)" \
  || fail "claude-turn default lane: turn failed (rc=$rc)"
if printf '%s' "$brief" | grep -qi 'dependency' && printf '%s' "$brief" | grep -q 'src/project.js'; then
  pass "claude-turn default lane: the GH-68 peer drift brief is prepended to the turn prompt"
else
  fail "claude-turn default lane: no drift brief in the turn prompt — the Bash-only feature is dead here: $brief"
fi

# ── (1b) NO drift pending → no drift block (not a false positive) ─────────────────────────
seed_token RELAY-TURN-nodrift
: > "$WORK/claude-args"
RELAY_AGENT=claude-builder RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-nodrift CLAUDE_AGENT=claude-builder \
  CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG=/dev/null \
  bash "$SHIM" >/dev/null 2>&1
brief2="$(cat "$WORK/claude-args" 2>/dev/null || true)"
grep -qi 'dependency.drift\|dependency-drift\|cross-agent dependency' <<<"$(printf '%s' "$brief2")" \
  && fail "claude-turn: emitted a drift block with no drift pending (false positive): $brief2" \
  || pass "claude-turn: no drift block when no peer drift is pending"

# ── (2) STRUCTURAL parity: every Python turn shim resolves ROOT via resolve_turn_root ─────
# Pre-port, pi-turn.py/aider-turn.py used `os.environ.get("<X>_TURN_ROOT", xyz_root)` (no git-toplevel
# fallback), so an unset override rooted at the shim's own dir. Lock all five to the same resolver.
check_root_resolver() { # <py-file> <ENV_VAR>
  local f="$PY_DIR/$1" var="$2"
  if grep -Fq "resolve_turn_root(os.environ.get(\"$var\")" "$f"; then
    pass "$1 resolves ROOT via resolve_turn_root (CWD git-toplevel fallback), like its Bash twin"
  else
    fail "$1 does NOT resolve ROOT via resolve_turn_root(os.environ.get(\"$var\")…) — root would fall back to xyz_root"
  fi
}
check_root_resolver "claude-turn.py" "CLAUDE_TURN_ROOT"
check_root_resolver "codex-turn.py"  "CODEX_TURN_ROOT"
check_root_resolver "pi-turn.py"     "PI_TURN_ROOT"
check_root_resolver "agy-turn.py"    "AGY_TURN_ROOT"
check_root_resolver "aider-turn.py"  "AIDER_TURN_ROOT"

# ── (3) STRUCTURAL parity: agy-turn.py propagates TICK_REPO_ROOT to the agy child on the
#        NON-worktree path too (Bash exports it unconditionally). Locked structurally: the
#        assignment must appear before the worktree-isolation branch, not only inside it.
agy_py="$PY_DIR/agy-turn.py"
uncond_line="$(grep -n 'run_env\["TICK_REPO_ROOT"\] = tick_repo_root' "$agy_py" | head -1 | cut -d: -f1)"
wt_line="$(grep -n 'RELAY_WORKTREE_ISOLATION' "$agy_py" | head -1 | cut -d: -f1)"
if [ -n "$uncond_line" ] && [ -n "$wt_line" ] && [ "$uncond_line" -lt "$wt_line" ]; then
  pass "agy-turn.py sets TICK_REPO_ROOT for the agy child unconditionally (before the worktree branch)"
else
  fail "agy-turn.py only sets TICK_REPO_ROOT inside the worktree branch — the non-worktree agy child loses it (uncond=$uncond_line wt=$wt_line)"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
