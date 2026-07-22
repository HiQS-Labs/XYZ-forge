#!/usr/bin/env bash
# finding-new.sh — manually append one PDDA-output-contract JSONL finding to debug.log. NO network.
# Usage: finding-new.sh [--scope S] [--severity error|warn|info] "one-line message"
set -u
SCOPE="harness" SEV="warn" TEXT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --scope) SCOPE="${2:-harness}"; shift 2 ;;
    --severity) SEV="${2:-warn}"; shift 2 ;;
    -h|--help) echo 'usage: finding-new.sh [--scope S] [--severity error|warn|info] "message"'; exit 0 ;;
    *) TEXT="$1"; shift ;;
  esac
done
[ -n "$TEXT" ] || { echo 'finding-new.sh: a one-line message is required' >&2; exit 2; }
case "$SEV" in error|warn|info) ;; *) echo "finding-new.sh: --severity must be error|warn|info" >&2; exit 2 ;; esac
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT="${DEBUG_LOG_FILE:-$ROOT/debug.log}"
esc(){ local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; printf '%s' "$s"; }
printf '{"timestamp":"%s","severity":"%s","check":"manual","scope":"%s","repo":"%s","message":"%s","action":"triage"}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SEV" "$SCOPE" "$ROOT" "$(esc "$TEXT")" >> "$OUT"
echo "appended: $OUT"
