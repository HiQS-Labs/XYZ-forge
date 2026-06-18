#!/usr/bin/env bash
set -euo pipefail
#
# marathon-agent.sh — dispatcher for Marathon multi-phase loops. Routes a relay turn to the
# correct model shim based on RELAY_AGENT; lets relay-drive.sh use a single --agent-cmd for
# runs that mix Claude, Codex, and Gemini turns.
#
# Invoked by relay-drive.sh as --agent-cmd, with env:
#   RELAY_FILE  — relay thread file
#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
#   RELAY_AGENT — current actor (determines which shim to exec)
# Routing config (all optional; leave unset to skip that model):
#   CLAUDE_AGENT      — agent id that routes to claude-turn.sh
#   CODEX_AGENT       — agent id that routes to codex-turn.sh
#   GEMINI_AGENT      — agent id that routes to gemini-turn.sh
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
gemini_agent="${GEMINI_AGENT:-}"

# RELAY_PEER threading: builder's peer is the reviewer; reviewer's peer is the builder.
# A live turn that lacks an explicit peer can release to a literal role-string (Gemini 2026-06-15).
if [[ -n "${MARATHON_BUILDER:-}" && -n "${MARATHON_REVIEWER:-}" ]]; then
  if [[ "$me" == "$MARATHON_BUILDER" ]]; then
    export RELAY_PEER="$MARATHON_REVIEWER"
  else
    export RELAY_PEER="$MARATHON_BUILDER"
  fi
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
  "$gemini_agent")
    [[ -n "$gemini_agent" ]] || die "RELAY_AGENT='$me' matched an empty GEMINI_AGENT — set GEMINI_AGENT"
    exec "$HERE/gemini-turn.sh"
    ;;
  *)
    die "unknown agent '$me'; set CLAUDE_AGENT/CODEX_AGENT/GEMINI_AGENT to map it to a shim"
    ;;
esac
