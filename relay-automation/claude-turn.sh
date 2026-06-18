#!/usr/bin/env bash
set -euo pipefail
#
# claude-turn.sh — headless turn-taker for the CLAUDE builder agent. Thin dispatch wrapper over the
# shared safety core (relay-turn-lib.sh) — the SAME containment contract as codex-turn.sh and
# gemini-turn.sh (decisions/2026-06-15-unattended-agent-containment.md).
#
# Builder role: Claude is the PRODUCER (write/revise the artifact). Reviewers (Codex, Gemini) use
# the tighter "Bash,Read" allowlist — no Write surface; rtl_enforce is the real guard regardless.
#
# Invoked by relay-drive.sh as --agent-cmd (typically via marathon-agent.sh), with env:
#   RELAY_FILE  — relay thread file (always allowlisted)
#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
# Shim config:
#   CLAUDE_AGENT      — the agent id this shim drives; NO-OPS unless RELAY_AGENT==CLAUDE_AGENT
#   ALLOW_PATHS       — comma-separated extra git paths the turn may change (the artifact being built)
#   RELAY_PEER        — optional: the other agent's id, for explicit --to <peer> handoff
#   CLAUDE_BIN        — claude CLI binary or wrapper (default: claude); tests inject a stub.
#   CLAUDE_MODEL      — model to PIN via --model (default: claude-sonnet-4-6). Without this the
#                       headless turn inherits the operator's ambient model — an Opus session blew
#                       the budget cap mid-build on 2026-06-18. Pin it so cost is deterministic.
#   CLAUDE_TURN_ROOT  — git root to guard (default: this repo); tests point at a fixture
#   CLAUDE_LOG        — where to write the claude transcript JSON (default: $TMPDIR/claude-turn-$$.json)
#   CLAUDE_MAX_TURNS  — max turns passed to --max-turns (default: 20; size from spike output)
#   CLAUDE_MAX_BUDGET — max cost passed to --max-budget-usd (default: 2.00; size from spike output)
#
# Auth: `claude -p` inherits the credentials stored by `claude login` (~/.claude/). A subscription
# login is sufficient — no API key needed. The binary must be installed and authenticated before
# running headless turns. JSON output schema (--output-format json): usage.{input_tokens,
# cache_read_input_tokens,output_tokens}, total_cost_usd, duration_ms, num_turns.
#
# Tool allowlist split:
#   builder (this shim)                   → "Bash,Read,Edit,Write"  (needs to mutate the artifact)
#   reviewers (codex-turn, gemini-turn)   → "Bash,Read"              (read-only; no write surface)
# rtl_enforce is the real guard either way; the allowlist is a second, tighter layer.
#
# Exit: 0 acted/deferred · 5 claude failed · 6 off-allowlist edit (reverted) · 2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=relay-turn-lib.sh
source "$HERE/relay-turn-lib.sh"

ROOT="${CLAUDE_TURN_ROOT:-"$(cd "$HERE/.." && pwd)"}"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
die() { printf 'claude-turn: %s\n' "$*" >&2; exit 2; }

me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
claude_agent="${CLAUDE_AGENT:-}"
[[ -n "$me" ]] || die "RELAY_AGENT required"
[[ -n "$f" ]] || die "RELAY_FILE required"
[[ -n "$claude_agent" ]] || die "CLAUDE_AGENT required"

# Dispatch only for the Claude agent; defer otherwise (that window drives its own turn).
if [[ "$me" != "$claude_agent" ]]; then
  printf 'claude-turn: actor %s is not the Claude agent (%s) — deferring (window-driven)\n' "$me" "$claude_agent" >&2
  exit 0
fi

rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"

# Transcript: $TMPDIR file, NOT the repo tree (the in-tree log guard deletes it).
# JSON format required: the cost block (usage.input_tokens / total_cost_usd / duration_ms)
# is only emitted with --output-format json.
CLAUDE_LOG="${CLAUDE_LOG:-${TMPDIR:-/tmp}/claude-turn-$$.json}"

# Model pin: `claude -p` otherwise inherits the operator's AMBIENT model (whatever the interactive
# session / global config selects). A headless builder must pin its own model, or its cost is
# hostage to that ambient choice — a real smoke run on 2026-06-18 inherited `claude-opus-4-8[1m]`
# and blew the $0.50 cap in 4 turns ($0.53) because the ceiling below was sized for Sonnet.
# Default to the spike's model; override with CLAUDE_MODEL for an intentionally heavier builder.
model="${CLAUDE_MODEL:-claude-sonnet-4-6}"

# Cost ceilings: sized from the M2 authenticated spike (2026-06-17, Sonnet 4.6).
# Real relay turn (minimal fixture): 7 turns, $0.172, 26s wall-clock, 207k cache-read + 1.4k output.
# --max-turns 12: observed 7; headroom for complex builder turns (multi-file edits, retries).
# --max-budget-usd 0.50: observed $0.17; ~3× margin for heavier content. The cache-read bulk
#   (~207k tokens) is cheap; output tokens ($15/M) dominate on complex turns.
# NOTE: these ceilings are valid only for the pinned model — raise --max-budget-usd if CLAUDE_MODEL
# points at a costlier model (e.g. Opus), or the turn will hard-stop mid-build like the 06-18 run.
max_turns="${CLAUDE_MAX_TURNS:-12}"
max_budget="${CLAUDE_MAX_BUDGET:-0.50}"

rtl_before
"$CLAUDE_BIN" -p "$prompt" \
  --model "$model" \
  --allowedTools "Bash,Read,Edit,Write" \
  --permission-mode acceptEdits \
  --output-format json \
  --max-turns "$max_turns" \
  --max-budget-usd "$max_budget" \
  < /dev/null > "$CLAUDE_LOG" 2>&1 \
  || { printf 'claude-turn: claude -p failed\n' >&2; exit 5; }
rtl_enforce "$t" "$me" "$CLAUDE_LOG" "claude"

# Best-effort cost capture: parse the claude CLI's JSON token stats and emit a cost.tokens event.
# NEVER fails the turn — the turn already committed; missing/unparseable stats → loud-partial signal.
# JSON path: .usage.input_tokens, .usage.output_tokens, .total_cost_usd (claude --output-format json)
if [[ -s "$CLAUDE_LOG" ]]; then
  tokens_in="$(python3 -c "import json,sys; d=json.load(open('$CLAUDE_LOG')); print(d.get('usage',{}).get('input_tokens',0)+d.get('usage',{}).get('cache_read_input_tokens',0))" 2>/dev/null || echo 0)"
  tokens_out="$(python3 -c "import json,sys; d=json.load(open('$CLAUDE_LOG')); print(d.get('usage',{}).get('output_tokens',0))" 2>/dev/null || echo 0)"
  if [[ "$tokens_in" -gt 0 || "$tokens_out" -gt 0 ]]; then
    "${TICK_BIN:-$ROOT/bin/tick}" cost "$t" --agent "$me" \
      --tokens-in "$tokens_in" --tokens-out "$tokens_out" --tool claude \
      || printf 'claude-turn: tokens not captured for %s\n' "$t" >&2
  else
    printf 'claude-turn: tokens not captured for %s (zero or no stats in transcript)\n' "$t" >&2
  fi
fi
