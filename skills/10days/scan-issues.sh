#!/usr/bin/env bash
#
# scan-issues.sh — deterministic GH issue window pull for the /10days skill.
#
# Lists OPEN issues updated (created, commented, labeled — anything that bumps
# `updated`) within an age window, sorted by issue number, as one JSON object per
# line. This script makes zero judgment calls (validity, reproducibility, "already
# done" are for the skill's subagent fan-out, not this script) — it exists so the
# window pull is byte-identical every run instead of a hand-typed `gh` one-liner.
#
#   bash skills/10days/scan-issues.sh [MAX_DAYS] [MIN_DAYS]
#
#   MAX_DAYS   how far back the window opens (default 10). Issues updated more than
#              MAX_DAYS ago are excluded.
#   MIN_DAYS   how close to today the window closes (default 0 = today). Issues
#              updated more recently than MIN_DAYS ago are excluded. Use this to
#              carve out a slice that doesn't overlap a window another run already
#              covered — e.g. `scan-issues.sh 14 11` = issues 11-14 days old, skipping
#              the last 10 days if another sweep already owns that range.
#
# Requires: gh (authenticated), run with the Bash sandbox disabled (gh needs
# keychain/TLS access it does not have inside the sandbox).
set -uo pipefail
# strict-mode: -e exempt — analysis tool; gh/date probes are expected-nonzero-safe, handled explicitly.

MAX_DAYS="${1:-10}"
MIN_DAYS="${2:-0}"

usage() { echo "usage: scan-issues.sh [MAX_DAYS] [MIN_DAYS]  (defaults: 10 0)" >&2; exit 2; }

[[ "$MAX_DAYS" =~ ^[0-9]+$ ]] || usage
[[ "$MIN_DAYS" =~ ^[0-9]+$ ]] || usage
(( MAX_DAYS > MIN_DAYS )) || { echo "scan-issues.sh: MAX_DAYS ($MAX_DAYS) must be greater than MIN_DAYS ($MIN_DAYS)" >&2; exit 2; }

command -v gh >/dev/null 2>&1 || { echo "scan-issues.sh: gh CLI not found on PATH" >&2; exit 2; }

# BSD date (macOS) then GNU date fallback — same pattern as utils/telemetry/extract-relay-telemetry.sh.
_date_days_ago() {
  date -u -v-"$1"d '+%Y-%m-%d' 2>/dev/null || date -u -d "$1 days ago" '+%Y-%m-%d'
}

SINCE="$(_date_days_ago "$MAX_DAYS")"   # older bound (window opens)
UNTIL="$(_date_days_ago "$MIN_DAYS")"   # newer bound (window closes)
[[ -n "$SINCE" && -n "$UNTIL" ]] || { echo "scan-issues.sh: could not compute window bounds" >&2; exit 2; }

if [[ "$MIN_DAYS" -eq 0 ]]; then
  SEARCH="updated:>=${SINCE}"
else
  SEARCH="updated:${SINCE}..${UNTIL}"
fi

gh issue list --state open --search "$SEARCH" --limit 200 \
  --json number,title,createdAt,updatedAt,labels,url \
  --jq 'sort_by(.number) | .[] | {number, title, createdAt, updatedAt, url, labels: [.labels[].name]}'
