#!/usr/bin/env bash
set -euo pipefail
#
# marathon-agent.sh — dispatcher for Marathon multi-phase loops. Routes a relay turn to the
# correct model shim based on RELAY_AGENT; lets relay-drive.sh use a single --agent-cmd for
# runs that mix Claude, Codex, and agy (Antigravity) turns.
#
# Invoked by relay-drive.sh as --agent-cmd, with env:
#   RELAY_FILE  — relay thread file
#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
#   RELAY_AGENT — current actor (determines which shim to exec)
# Routing config (all optional; leave unset to skip that model):
#   CLAUDE_AGENT      — agent id that routes to claude-turn.sh
#   CODEX_AGENT       — agent id that routes to codex-turn.sh
#   AGY_AGENT         — comma-separated agent ids that route to agy-turn.sh (Antigravity CLI; permanent cross-model lane)
#   AIDER_AGENT       — agent id that routes to aider-turn.sh (Aider via OpenRouter; OpenAI-standard lane)
#   PI_AGENT          — agent id that routes to pi-turn.sh (Pi; explicit PI_MODEL required)
#   SMALLCODE_AGENT   — agent id that routes to smallcode-turn.sh (SmallCode)
#   COMMANDCODE_AGENT — agent id that routes to commandcode-turn.sh (Command Code / cmd)
#   DEEPSEEK_AGENT    — agent id that routes to deepseek-turn.sh (DeepSeek via dsh)
# Peer threading (set by marathon-drive.sh — prevents "release to literal role-string" failure):
#   MARATHON_BUILDER  — builder agent id; when RELAY_AGENT matches this, RELAY_PEER = MARATHON_REVIEWER
#   MARATHON_REVIEWER — reviewer agent id; when RELAY_AGENT is the reviewer, RELAY_PEER = MARATHON_BUILDER
# All other env (ALLOW_PATHS, *_LOG, *_FLAGS, etc.) pass through to the shim.
#
# Exit: 0 no-op (deferred) · 2 usage / unknown agent · inherits shim exit codes.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
die() { printf 'marathon-agent: %s\n' "$*" >&2; exit 2; }

me="${RELAY_AGENT:-}"
[[ -n "$me"              ]] || die "RELAY_AGENT required"
[[ -n "${RELAY_FILE:-}"  ]] || die "RELAY_FILE required"

claude_agent="${CLAUDE_AGENT:-}"
codex_agent="${CODEX_AGENT:-}"
agy_agent="${AGY_AGENT:-}"
aider_agent="${AIDER_AGENT:-}"
pi_agent="${PI_AGENT:-}"
smallcode_agent="${SMALLCODE_AGENT:-}"
# GH-346 Phase 2 (allowlist #3): commandcode-turn.sh and deepseek-turn.sh have shipped and worked
# for a while, and marathon_drive.py's route_agent() was taught to export their *_AGENT vars — but
# THIS case had no branch for either, so a marathon that named them died here with "unknown agent"
# after the router had already accepted them. This is the site that made them non-runnable; fixing
# route_agent() alone would have shipped a lane that still could not dispatch.
commandcode_agent="${COMMANDCODE_AGENT:-}"
deepseek_agent="${DEEPSEEK_AGENT:-}"

# GH-368: a builder and reviewer may share the agy lane (for example `agy,agy-qa`).
# Route by exact membership rather than treating AGY_AGENT as one overwrite-prone actor slot.
agy_member=0
if [[ -n "$agy_agent" ]]; then
  IFS=, read -r -a agy_agents <<< "$agy_agent"
  for agy_candidate in "${agy_agents[@]}"; do
    if [[ "$me" == "$agy_candidate" ]]; then
      agy_member=1
      break
    fi
  done
fi

# RELAY_PEER threading: builder's peer is the reviewer; reviewer's peer is the builder.
# A live turn that lacks an explicit peer can release to a literal role-string (Gemini 2026-06-15).
if [[ -n "${MARATHON_BUILDER:-}" && -n "${MARATHON_REVIEWER:-}" ]]; then
  if [[ "$me" == "$MARATHON_BUILDER" ]]; then
    export RELAY_PEER="$MARATHON_REVIEWER"
  else
    export RELAY_PEER="$MARATHON_BUILDER"
  fi
fi

if [[ "$agy_member" -eq 1 ]]; then
  exec "$HERE/agy-turn.sh"
fi

case "$me" in
  "$claude_agent")
    [[ -n "$claude_agent" ]] || die "RELAY_AGENT='$me' matched an empty CLAUDE_AGENT — set CLAUDE_AGENT"
    exec "$HERE/claude-turn.sh"
    ;;
  "$codex_agent")
    [[ -n "$codex_agent" ]] || die "RELAY_AGENT='$me' matched an empty CODEX_AGENT — set CODEX_AGENT"
    exec "$HERE/codex-turn.sh"
    ;;
  "$aider_agent")
    [[ -n "$aider_agent" ]] || die "RELAY_AGENT='$me' matched an empty AIDER_AGENT — set AIDER_AGENT"
    exec "$HERE/aider-turn.sh"
    ;;
  "$pi_agent")
    [[ -n "$pi_agent" ]] || die "RELAY_AGENT='$me' matched an empty PI_AGENT — set PI_AGENT"
    exec "$HERE/pi-turn.sh"
    ;;
  "$smallcode_agent")
    [[ -n "$smallcode_agent" ]] || die "RELAY_AGENT='$me' matched an empty SMALLCODE_AGENT — set SMALLCODE_AGENT"
    exec "$HERE/smallcode-turn.sh"
    ;;
  "$commandcode_agent")
    [[ -n "$commandcode_agent" ]] || die "RELAY_AGENT='$me' matched an empty COMMANDCODE_AGENT — set COMMANDCODE_AGENT"
    exec "$HERE/commandcode-turn.sh"
    ;;
  "$deepseek_agent")
    [[ -n "$deepseek_agent" ]] || die "RELAY_AGENT='$me' matched an empty DEEPSEEK_AGENT — set DEEPSEEK_AGENT"
    exec "$HERE/deepseek-turn.sh"
    ;;
  *)
    die "unknown agent '$me'; set CLAUDE_AGENT/CODEX_AGENT/AGY_AGENT/AIDER_AGENT/PI_AGENT/SMALLCODE_AGENT/COMMANDCODE_AGENT/DEEPSEEK_AGENT to map it to a shim"
    ;;
esac
