#!/usr/bin/env bash
# marathon-detail.sh <repo> — preview for ONE repo path (read-only).
#
# Prints:
#   - STATUS: / NEXT: lines from the newest phases/*/RELAY.md (if any)
#   - Last ~10 lines/events from the newest .tick/events/*marathon*.jsonl
#
# Writes NO state to any monitored repo.
set -euo pipefail

usage() {
  printf 'Usage: marathon-detail.sh <repo-path>\n' >&2
  exit 2
}

[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { usage; }
[ $# -ge 1 ] || usage

REPO="$1"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

section() { printf '\n--- %s ---\n' "$*"; }

# ---------------------------------------------------------------------------
# RELAY.md preview
# ---------------------------------------------------------------------------

if [ ! -d "$REPO" ]; then
  printf 'REPO: %s\n' "$REPO"
  printf 'STATE: GONE (path does not exist on disk)\n'
  exit 0
fi

printf 'REPO: %s\n' "$REPO"

# Newest phases/*/RELAY.md
PHASES_DIR="$REPO/phases"
RELAY_FILE=""
if [ -d "$PHASES_DIR" ]; then
  # shellcheck disable=SC2012
  RELAY_FILE="$(ls -t "$PHASES_DIR"/*/RELAY.md 2>/dev/null | head -1 || true)"
fi

if [ -n "$RELAY_FILE" ] && [ -f "$RELAY_FILE" ]; then
  section "RELAY.md: $(basename "$(dirname "$RELAY_FILE")")/RELAY.md"
  # Extract STATUS: and NEXT: lines (case-sensitive as used in relay templates).
  grep -E '^(STATUS|NEXT):' "$RELAY_FILE" 2>/dev/null || printf '(no STATUS:/NEXT: lines found)\n'
else
  section "RELAY.md"
  printf '(no phases/*/RELAY.md found)\n'
fi

# ---------------------------------------------------------------------------
# Recent tick events
# ---------------------------------------------------------------------------

EVENTS_DIR="$REPO/.tick/events"
MARATHON_JSONL=""
if [ -d "$EVENTS_DIR" ]; then
  # shellcheck disable=SC2012
  MARATHON_JSONL="$(ls -t "$EVENTS_DIR"/*marathon*.jsonl 2>/dev/null | head -1 || true)"
fi

section "Recent tick events"
if [ -n "$MARATHON_JSONL" ] && [ -f "$MARATHON_JSONL" ]; then
  printf 'File: %s\n' "$MARATHON_JSONL"
  tail -10 "$MARATHON_JSONL"
else
  printf '(no *marathon*.jsonl events found in %s)\n' "$EVENTS_DIR"
fi
