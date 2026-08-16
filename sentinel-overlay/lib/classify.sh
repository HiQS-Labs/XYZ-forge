#!/usr/bin/env bash
# classify.sh — Gemma classifier wrapper. The ONLY place `ollama` is invoked in the overlay.
# Gated by sentinel_active. Stubbable for tests via SENTINEL_CLASSIFY_STUB (a command that reads a
# finding line on stdin and prints one class word). No config + no stub => inert (prints nothing, rc 1).
set -u
_CL_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$_CL_LIB/config.sh"

# sentinel_classify <json-finding-line> -> prints one of: bug|lesson|flaky|operator-error|wontfix
sentinel_classify() {
  local finding="$1"
  # Deterministic test seam: a stub short-circuits before any gate/egress.
  if [ -n "${SENTINEL_CLASSIFY_STUB:-}" ]; then
    printf '%s\n' "$finding" | $SENTINEL_CLASSIFY_STUB
    return $?
  fi
  sentinel_require_active "classify" || return 1
  local prompt out
  prompt="Classify this harness runtime finding as EXACTLY one lowercase word from: bug, lesson, flaky, operator-error, wontfix. Reply with only that word. Finding: $finding"
  out="$(printf '%s' "$prompt" | ollama run "${SENTINEL_MODEL:-gemma4:12b-mlx}" 2>/dev/null \
        | tr '[:upper:]' '[:lower:]' | grep -oE 'operator-error|wontfix|lesson|flaky|bug' | head -1)"
  [ -n "$out" ] && printf '%s\n' "$out" || printf 'bug\n'
}

# sentinel_redteam <diff-or-text> -> prints Gemma's adversarial critique. Gated; stubbable via
# SENTINEL_REDTEAM_STUB. The ONLY other ollama caller besides sentinel_classify.
sentinel_redteam() {
  local subject="$1"
  if [ -n "${SENTINEL_REDTEAM_STUB:-}" ]; then
    printf '%s\n' "$subject" | $SENTINEL_REDTEAM_STUB
    return $?
  fi
  sentinel_require_active "redteam" || return 1
  local prompt
  prompt="You are a skeptical reviewer. Find how this change regresses behavior, games its gate, inverts fix-probe polarity, or narrows the allowlist's real coverage. Be specific and terse. Change:
$subject"
  printf '%s' "$prompt" | ollama run "${SENTINEL_MODEL:-gemma4:12b-mlx}" 2>/dev/null
}
