#!/usr/bin/env bash
set -u
#
# relay-self-sufficiency.sh — verify that the ▶ TAKE YOUR TURN block in a minimal relay
# file template is sufficient for a context-free headless agent to complete a turn correctly.
#
# This test uses a REAL headless agent (agy or codex). It is skipped automatically when no
# live agent is found on PATH, or when RELAY_SELF_SUFFICIENCY_SKIP=1 is set.
#
# CI gate: set RELAY_SELF_SUFFICIENCY_SKIP=1 in keyless environments (no API key / network).
# Cost: one real API call per run (~10-60s turn depending on agent speed).
#
# FAIL criteria (checked by assertions below):
#   (A) Agent fails to claim/release — relay file not modified (path/env wrong in TAKE YOUR TURN)
#   (B) Agent omits required log fields — VERDICT: or Basis: missing from written block
#   (C) Agent writes off-allowlist files — shim exits non-zero (exit 6)

HERE="$(cd "$(dirname "$0")" && pwd)"
HARNESS="$(cd "$HERE/.." && pwd)"
TICK="$HARNESS/bin/tick"

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: relay-self-sufficiency =="

# --- Skip: CI gate or explicit opt-out ---
if [ "${RELAY_SELF_SUFFICIENCY_SKIP:-0}" = "1" ]; then
  echo "  SKIPPED: RELAY_SELF_SUFFICIENCY_SKIP=1 (CI gate — no live agent in this environment)"
  echo "  relay-self-sufficiency: 0 pass, 0 fail (skipped)"
  exit 0
fi

# --- Locate live headless agent (agy preferred; codex fallback) ---
LIVE_AGENT_BIN=""
LIVE_AGENT_ID=""
_agy_bin="${AGY_BIN:-}"
if [ -z "$_agy_bin" ]; then
  for c in agy "$HOME/.local/bin/agy"; do
    if [ -x "$c" ] || command -v "$c" >/dev/null 2>&1; then _agy_bin="$c"; break; fi
  done
fi
if [ -n "$_agy_bin" ]; then
  LIVE_AGENT_BIN="$_agy_bin"
  LIVE_AGENT_ID="agy"
fi
if [ -z "$LIVE_AGENT_BIN" ]; then
  _codex_bin="${CODEX_BIN:-}"
  [ -z "$_codex_bin" ] && command -v codex >/dev/null 2>&1 && _codex_bin="codex"
  if [ -n "$_codex_bin" ]; then
    LIVE_AGENT_BIN="$_codex_bin"
    LIVE_AGENT_ID="codex"
  fi
fi

if [ -z "$LIVE_AGENT_BIN" ]; then
  echo "  SKIPPED: no live headless agent (agy/codex not on PATH; set AGY_BIN or CODEX_BIN to override)"
  echo "  relay-self-sufficiency: 0 pass, 0 fail (skipped)"
  exit 0
fi

WORK="$(mktemp -d -t "tick-relay-self-sufficiency.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

REPO="$WORK/repo"
mkdir -p "$REPO/bin"

echo "  workdir: $WORK"
echo "  agent:   $LIVE_AGENT_BIN ($LIVE_AGENT_ID)"
echo "  (live API call — requires network + credentials; ~10-60s)"

# --- Set up isolated temp git repo (no CLAUDE.md, AGENTS.md, or ambient repo context) ---
git init -q "$REPO"
git -C "$REPO" config user.email "test@t"
git -C "$REPO" config user.name "test"

# .tick/ coordination state lives here; gitignore it so it's invisible to rtl_enforce.
printf '.tick/\n' > "$REPO/.gitignore"

# Seed relay file from the minimal fixture (no baton-pattern.md content).
RELAY_FILE="$REPO/relay.md"
cp "$HERE/fixtures/minimal-relay.md" "$RELAY_FILE"

git -C "$REPO" add .gitignore relay.md
git -C "$REPO" commit -q -m "seed minimal relay"

# Create a tick wrapper so the agent's tick invocation (built into rtl_turn_prompt as
# TICK_REPO_ROOT="$REPO" "$REPO/bin/tick") resolves to the real harness bin/tick while
# keeping all events in $REPO/.tick/ (not the harness). Node's require() follows the
# symlink's real path for src/ resolution, so a wrapper shell script is safer than a symlink.
cat > "$REPO/bin/tick" <<TICK_WRAPPER
#!/usr/bin/env bash
TICK_REPO_ROOT="$REPO" exec node "$HARNESS/bin/tick" "\$@"
TICK_WRAPPER
chmod +x "$REPO/bin/tick"

# --- Seed the relay task in the isolated repo's .tick/ ---
TASK="RELAY-SELF-SUFFICIENCY-$$"
TICK_REPO_ROOT="$REPO" "$TICK" log task.created "$TASK" --agent claude-a >/dev/null
TICK_REPO_ROOT="$REPO" "$TICK" claim "$TASK" --agent claude-a --paths relay.md >/dev/null
TICK_REPO_ROOT="$REPO" "$TICK" release "$TASK" --agent claude-a --to "$LIVE_AGENT_ID" >/dev/null

# --- Drive one real headless agent turn ---
AGY_LOG="$WORK/agent-turn.log"
turn_rc=0

# Run in a subshell cd'd to $REPO so the agent's relative paths (relay.md) resolve correctly
# against the isolated repo, not the harness CWD. This mirrors RELAY_WORKTREE_ISOLATION=1
# behavior (CWD = target repo) but without the worktree bug (GH-22).
(
  cd "$REPO"
  if [ "$LIVE_AGENT_ID" = "agy" ]; then
    RELAY_AGENT="$LIVE_AGENT_ID" RELAY_FILE="$RELAY_FILE" RELAY_TASK="$TASK" \
      AGY_AGENT="$LIVE_AGENT_ID" AGY_BIN="$LIVE_AGENT_BIN" \
      AGY_TURN_ROOT="$REPO" AGY_LOG="$AGY_LOG" \
      RELAY_WORKTREE_ISOLATION=0 TICK_REPO_ROOT="$REPO" \
      bash "$HARNESS/relay-automation/agy-turn.sh"
  else
    RELAY_AGENT="$LIVE_AGENT_ID" RELAY_FILE="$RELAY_FILE" RELAY_TASK="$TASK" \
      CODEX_AGENT="$LIVE_AGENT_ID" CODEX_BIN="$LIVE_AGENT_BIN" \
      CODEX_TURN_ROOT="$REPO" CODEX_LOG="$AGY_LOG" \
      RELAY_WORKTREE_ISOLATION=0 TICK_REPO_ROOT="$REPO" \
      bash "$HARNESS/relay-automation/codex-turn.sh"
  fi
) >/dev/null 2>&1 || turn_rc=$?

# --- Assertion (C): shim exited 0 (no off-allowlist edit, no agent crash) ---
if [ "$turn_rc" -eq 0 ]; then
  pass "(C) shim exit 0 — no off-allowlist edits, no agent failure"
else
  fail "(C) $LIVE_AGENT_ID shim exited $turn_rc"
  if [ -s "$AGY_LOG" ]; then
    echo "  --- agent transcript (tail 20 lines) ---" >&2
    tail -20 "$AGY_LOG" >&2
  fi
fi

# --- Assertion (A): relay file was modified AND task is no longer claimed by claude-a ---
relay_commit_count="$(git -C "$REPO" log --oneline relay.md 2>/dev/null | wc -l | tr -d ' ')"
task_claimer="$(TICK_REPO_ROOT="$REPO" "$TICK" info "$TASK" 2>/dev/null | grep '^claimer:' | awk '{print $2}' || true)"
if [ "$relay_commit_count" -gt 1 ] && [ "${task_claimer:-none}" != "claude-a" ]; then
  pass "(A) agent claimed token + wrote relay file (commit observed, token moved from claude-a)"
else
  if [ "$relay_commit_count" -le 1 ]; then
    fail "(A) relay file not modified — agent may have failed to claim/release (path assumptions wrong)"
  else
    fail "(A) relay file modified but token still claimed by claude-a — agent did not complete the handoff"
  fi
  echo "  Diagnostic: the TAKE YOUR TURN block's tick command may need adjustment." >&2
  echo "  Fix: update test/fixtures/minimal-relay.md and commit the diff." >&2
fi

# Read the Log section for field assertions
log_section=""
if [ -f "$RELAY_FILE" ]; then
  log_section="$(sed -e '1,/^## Log/d' "$RELAY_FILE")"
fi

# --- Assertion (B1): VERDICT: line present and valid ---
if echo "$log_section" | grep -qE '^VERDICT: (PASS|FAIL|PARKED)$'; then
  pass "(B1) VERDICT: field present and valid"
else
  verdict_val="$(echo "$log_section" | grep -E '^VERDICT:' | head -1 || true)"
  fail "(B1) VERDICT: field missing or invalid (found: '${verdict_val:-<none>}')"
  echo "  Diagnostic: agent did not write a VERDICT: line in the log block." >&2
  echo "  Fix: add clearer VERDICT: instruction to test/fixtures/minimal-relay.md." >&2
fi

# --- Assertion (B2): Basis: line present and non-empty ---
if echo "$log_section" | grep -qE '^Basis: .+'; then
  pass "(B2) Basis: field present and non-empty"
else
  basis_val="$(echo "$log_section" | grep -E '^Basis:' | head -1 || true)"
  fail "(B2) Basis: field missing or empty (found: '${basis_val:-<none>}')"
  echo "  Diagnostic: agent did not write a Basis: line in the log block." >&2
  echo "  Fix: add clearer Basis: instruction to test/fixtures/minimal-relay.md." >&2
fi

echo ""
echo "  relay-self-sufficiency: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
