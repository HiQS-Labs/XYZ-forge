#!/usr/bin/env bash
# harvest-findings.sh — extract `### Side Finding` blocks from a relay file and append them to
# debug.log as PDDA-output-contract JSONL findings. Read-only on the relay; append-only on
# debug.log; NO network. Best-effort — a broken harvest must never fail a phase.
# Usage: harvest-findings.sh --relay FILE [--scope S] [--repo R] [--out debug.log]
set -u
RELAY="" SCOPE="harness" REPO="" OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --relay) RELAY="${2:-}"; shift 2 ;;
    --scope) SCOPE="${2:-harness}"; shift 2 ;;
    --repo)  REPO="${2:-}"; shift 2 ;;
    --out)   OUT="${2:-}"; shift 2 ;;
    -h|--help) echo "usage: harvest-findings.sh --relay FILE [--scope S] [--repo R] [--out FILE]"; exit 0 ;;
    *) echo "harvest-findings.sh: unexpected arg: $1" >&2; exit 2 ;;
  esac
done
[ -n "$RELAY" ] && [ -f "$RELAY" ] || exit 0
[ -n "$SCOPE" ] || SCOPE="harness"
OUT="${OUT:-debug.log}"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"

awk -v ts="$TS" -v scope="$SCOPE" -v repo="$REPO" -v relay="$RELAY" '
  function esc(s){ gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); gsub(/[[:cntrl:]]/," ",s); return s }
  function flush(){
    if (!inblk) return
    printf("{\"timestamp\":\"%s\",\"severity\":\"warn\",\"check\":\"marathon.side-finding\",\"scope\":\"%s\",\"repo\":\"%s\",\"file\":\"%s\",\"line\":\"\",\"message\":\"%s%s\",\"action\":\"triage\",\"probe\":\"%s\"}\n",
      ts, esc(scope), esc(repo), esc(p), esc(sy), (sc!=""?"; suspected: " esc(sc):""), esc(pr))
    inblk=0; p=""; sy=""; sc=""; pr=""
  }
  /^###[ \t]+Side Finding/ { flush(); inblk=1; next }
  inblk && (/^#/ || /^---/) { flush() }
  inblk {
    if (match($0,/^-[ \t]*path:[ \t]*/))                 p =substr($0,RLENGTH+1)
    else if (match($0,/^-[ \t]*symptom:[ \t]*/))         sy=substr($0,RLENGTH+1)
    else if (match($0,/^-[ \t]*suspected_cause:[ \t]*/)) sc=substr($0,RLENGTH+1)
    else if (match($0,/^-[ \t]*probe:[ \t]*/))           pr=substr($0,RLENGTH+1)
  }
  END { flush() }
' "$RELAY" >> "$OUT" 2>/dev/null || true
exit 0
