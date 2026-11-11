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
# Routing config (comma-separated exact actor ids; unset skips that model):
#   CLAUDE_AGENT      — agent id that routes to claude-turn.sh
#   CODEX_AGENT       — agent id that routes to codex-turn.sh
#   AGY_AGENT         — comma-separated agent ids that route to agy-turn.sh (Antigravity CLI; permanent cross-model lane)
#   AIDER_AGENT       — agent id that routes to aider-turn.sh (Aider via OpenRouter; OpenAI-standard lane)
#   PI_AGENT          — agent id that routes to pi-turn.sh (Pi; explicit PI_MODEL required)
#   SMALLCODE_AGENT   — agent id that routes to smallcode-turn.sh (SmallCode)
#   COMMANDCODE_AGENT — agent id that routes to commandcode-turn.sh (Command Code / cmd)
#   DEEPSEEK_AGENT    — agent id that routes to deepseek-turn.sh (DeepSeek via dsh)
#   KIMI_AGENT        — agent id that routes to kimi-turn.sh (Kimi Code CLI; GH-1215)
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

# RELAY_PEER threading: builder's peer is the reviewer; reviewer's peer is the builder.
# A live turn that lacks an explicit peer can release to a literal role-string (Gemini 2026-06-15).
if [[ -n "${MARATHON_BUILDER:-}" && -n "${MARATHON_REVIEWER:-}" ]]; then
  if [[ "$me" == "$MARATHON_BUILDER" ]]; then
    export RELAY_PEER="$MARATHON_REVIEWER"
  else
    export RELAY_PEER="$MARATHON_BUILDER"
  fi
fi

# Match complete configured actors, then give the selected shim its scalar
# identity. Its own identity check must not silently defer a comma-list actor.
for lane in claude codex agy aider pi smallcode commandcode deepseek kimi; do
  slot="$(printf '%s' "$lane" | tr '[:lower:]' '[:upper:]')_AGENT"
  configured="${!slot:-}"
  [[ -n "$configured" ]] || continue
  IFS=, read -r -a actors <<< "$configured"
  for actor in "${actors[@]}"; do
    if [[ -n "$actor" && "$me" == "$actor" ]]; then
      export "$slot=$me"
      exec "$HERE/$lane-turn.sh"
    fi
  done
done
die "unknown agent '$me'; configure its provider *_AGENT slot"
