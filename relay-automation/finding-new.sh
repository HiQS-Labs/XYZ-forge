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
# JSON-escape every dynamic string: backslash, quote, and tab/newline/CR → space (a one-line
# manual finding must never emit a raw control char). Mirrors harvest-findings.sh's awk esc().
esc(){ local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\t'/ }"; s="${s//$'\n'/ }"; s="${s//$'\r'/ }"; printf '%s' "$s"; }
# Emit the full PDDA output-contract shape (10 keys), matching harvest-findings.sh so Tier-2 reads
# uniform lines; file/line/probe are empty for a manual finding.
printf '{"timestamp":"%s","severity":"%s","check":"manual","scope":"%s","repo":"%s","file":"","line":"","message":"%s","action":"triage","probe":""}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SEV" "$(esc "$SCOPE")" "$(esc "$ROOT")" "$(esc "$TEXT")" >> "$OUT"
echo "appended: $OUT"
