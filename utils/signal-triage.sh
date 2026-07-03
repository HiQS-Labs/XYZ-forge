#!/usr/bin/env bash
# utils/signal-triage.sh — deterministic pre-capture signal classifier (GH-63)
#
# Classifies an inbound signal into exactly one of: bug / drift / enhancement / noise
# using FIRST-MATCH, SOURCE-KEYED rules. Identical input -> identical tag (no sentiment).
#
# Classification rubric (first match wins):
# ┌─────────┬──────────┬──────────────────────────────────────────────────────────────────────────┐
# │ Rule ID │ Category │ Match criteria                                                           │
# ├─────────┼──────────┼──────────────────────────────────────────────────────────────────────────┤
# │ rule-1  │ noise    │ signal duplicates an already-open GH issue (by issue number or title     │
# │         │          │ slug), OR is informational-only with no failure / parked / drift marker   │
# ├─────────┼──────────┼──────────────────────────────────────────────────────────────────────────┤
# │ rule-2  │ bug      │ deterministic failure of existing behaviour: validate.sh test FAIL,      │
# │         │          │ canary/fixture rejection, relay containment revert (exit 6), or           │
# │         │          │ security-scan failure (source: "security-scan" recorded — NOT a separate  │
# │         │          │ bucket per GP #7)                                                         │
# ├─────────┼──────────┼──────────────────────────────────────────────────────────────────────────┤
# │ rule-3  │ drift    │ reality diverges from declared state without a hard failure: watchdog    │
# │         │          │ parked_suspects[] record, pdda issue-doc-sync / roadmap-coverage          │
# │         │          │ mismatch, or dependency.drift signal                                      │
# ├─────────┼──────────┼──────────────────────────────────────────────────────────────────────────┤
# │ rule-4  │ enhance- │ manually filed request/idea with no failing gate and no drift marker     │
# │         │ ment     │                                                                           │
# └─────────┴──────────┴──────────────────────────────────────────────────────────────────────────┘
#
# Severity derived from category: bug->high, drift->medium, enhancement->low, noise->drop
# No confidence field (deterministic classifier, trivially 1.0 per GP #7).
# Never writes a .tick/ record (.tick/ is the coordination event log; triage notes are not events).
#
# Usage:
#   bash utils/signal-triage.sh --source <source> --id <signal-id> [options]
#
# Required flags:
#   --source <src>    Signal source. One of:
#                       validate-fail       validate.sh test FAIL
#                       security-scan       security scan finding
#                       relay-exit6         relay containment revert (exit 6)
#                       canary-reject       canary/fixture rejection
#                       watchdog-parked     watchdog parked_suspects[] record
#                       pdda-sync           pdda issue-doc-sync / roadmap-coverage mismatch
#                       dependency-drift    dependency.drift signal (GH-68)
#                       manual              manually filed request or bug report
#                       informational       informational-only record
#   --id <signal-id>  Unique signal ID (e.g. "validate-fail-test-signal-triage-2026-07-02")
#
# Optional flags:
#   --test <name>     For validate-fail: the failing test path/name
#   --detail <text>   Short detail string appended to evidence
#   --dedupe-of <n>   If the signal duplicates issue N, provide that issue number/slug here.
#                     Causes rule-1 (noise) to fire unconditionally.
#   --output-dir <d>  Override output root (default: relay-system/triage relative to repo root).
#                     Useful for tests to avoid polluting the repo.
#
# Output:
#   Prints the JSON note to stdout.
#   Writes the note to <output-dir>/<signal-id>.json (created with mkdir -p).
#
# Exit codes:
#   0 — classified and note written
#   2 — usage error (missing required args)

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

SIGNAL_SOURCE=""
SIGNAL_ID=""
TEST_NAME_ARG=""
DETAIL=""
DEDUPE_OF=""
OUTPUT_DIR="${REPO_ROOT}/relay-system/triage"

usage() {
  grep '^# ' "${BASH_SOURCE[0]}" | sed 's/^# //' | sed 's/^#//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)    SIGNAL_SOURCE="$2"; shift 2 ;;
    --id)        SIGNAL_ID="$2";     shift 2 ;;
    --test)      TEST_NAME_ARG="$2"; shift 2 ;;
    --detail)    DETAIL="$2";        shift 2 ;;
    --dedupe-of) DEDUPE_OF="$2";     shift 2 ;;
    --output-dir) OUTPUT_DIR="$2";   shift 2 ;;
    --help|-h)   usage; exit 0 ;;
    *) echo "$SCRIPT_NAME: unknown flag: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$SIGNAL_SOURCE" ]]; then
  echo "$SCRIPT_NAME: --source is required" >&2; exit 2
fi
if [[ -z "$SIGNAL_ID" ]]; then
  echo "$SCRIPT_NAME: --id is required" >&2; exit 2
fi

# ---------------------------------------------------------------------------
# Classification — first-match, source-keyed
# ---------------------------------------------------------------------------

CATEGORY=""
SEVERITY=""
EVIDENCE=""
DEDUPE_FIELD=""

# Sanitize SIGNAL_ID and DETAIL for JSON (escape double quotes and backslashes).
# Bash 3.2-compatible: use parameter expansion.
json_escape() {
  local s="$1"
  # Escape backslash first, then double-quote
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

SIG_ID_J="$(json_escape "$SIGNAL_ID")"
DETAIL_J="$(json_escape "$DETAIL")"
SOURCE_J="$(json_escape "$SIGNAL_SOURCE")"

# Rule 1 — noise: dedupe check (explicit --dedupe-of) OR informational-only source
if [[ -n "$DEDUPE_OF" ]]; then
  CATEGORY="noise"
  SEVERITY="drop"
  DEDUPE_ID_J="$(json_escape "$DEDUPE_OF")"
  EVIDENCE="rule-1-noise / duplicate-of:${DEDUPE_OF}"
  DEDUPE_FIELD="\"dedupe_of\": \"${DEDUPE_ID_J}\","
elif [[ "$SIGNAL_SOURCE" == "informational" ]]; then
  CATEGORY="noise"
  SEVERITY="drop"
  EVIDENCE="rule-1-noise / informational-only: no failure or parked/drift marker"
  DEDUPE_FIELD=""

# Rule 2 — bug: deterministic failure of existing behaviour
elif [[ "$SIGNAL_SOURCE" == "validate-fail" ]]; then
  CATEGORY="bug"
  SEVERITY="high"
  if [[ -n "$TEST_NAME_ARG" ]]; then
    EVIDENCE="rule-2-bug / validate-fail: ${TEST_NAME_ARG}"
  else
    EVIDENCE="rule-2-bug / validate-fail"
  fi
  if [[ -n "$DETAIL" ]]; then EVIDENCE="${EVIDENCE} | ${DETAIL}"; fi
  DEDUPE_FIELD=""

elif [[ "$SIGNAL_SOURCE" == "security-scan" ]]; then
  # Security findings fold into bug (NOT a separate bucket — GP #7)
  CATEGORY="bug"
  SEVERITY="high"
  EVIDENCE="rule-2-bug / security-scan"
  if [[ -n "$DETAIL" ]]; then EVIDENCE="${EVIDENCE}: ${DETAIL}"; fi
  DEDUPE_FIELD=""

elif [[ "$SIGNAL_SOURCE" == "relay-exit6" ]]; then
  CATEGORY="bug"
  SEVERITY="high"
  EVIDENCE="rule-2-bug / relay-containment-revert: exit-6"
  if [[ -n "$DETAIL" ]]; then EVIDENCE="${EVIDENCE} | ${DETAIL}"; fi
  DEDUPE_FIELD=""

elif [[ "$SIGNAL_SOURCE" == "canary-reject" ]]; then
  CATEGORY="bug"
  SEVERITY="high"
  EVIDENCE="rule-2-bug / canary-fixture-rejection"
  if [[ -n "$DETAIL" ]]; then EVIDENCE="${EVIDENCE}: ${DETAIL}"; fi
  DEDUPE_FIELD=""

# Rule 3 — drift: reality diverges from declared state without a hard failure
elif [[ "$SIGNAL_SOURCE" == "watchdog-parked" ]]; then
  CATEGORY="drift"
  SEVERITY="medium"
  EVIDENCE="rule-3-drift / watchdog-parked-suspects"
  if [[ -n "$DETAIL" ]]; then EVIDENCE="${EVIDENCE}: ${DETAIL}"; fi
  DEDUPE_FIELD=""

elif [[ "$SIGNAL_SOURCE" == "pdda-sync" ]]; then
  CATEGORY="drift"
  SEVERITY="medium"
  EVIDENCE="rule-3-drift / pdda-issue-doc-sync-or-roadmap-coverage-mismatch"
  if [[ -n "$DETAIL" ]]; then EVIDENCE="${EVIDENCE}: ${DETAIL}"; fi
  DEDUPE_FIELD=""

elif [[ "$SIGNAL_SOURCE" == "dependency-drift" ]]; then
  CATEGORY="drift"
  SEVERITY="medium"
  EVIDENCE="rule-3-drift / dependency-drift"
  if [[ -n "$DETAIL" ]]; then EVIDENCE="${EVIDENCE}: ${DETAIL}"; fi
  DEDUPE_FIELD=""

# Rule 4 — enhancement: manual request/idea with no failing gate and no drift marker
elif [[ "$SIGNAL_SOURCE" == "manual" ]]; then
  CATEGORY="enhancement"
  SEVERITY="low"
  EVIDENCE="rule-4-enhancement / manual-request-no-failing-gate"
  if [[ -n "$DETAIL" ]]; then EVIDENCE="${EVIDENCE}: ${DETAIL}"; fi
  DEDUPE_FIELD=""

else
  echo "$SCRIPT_NAME: unknown --source value: '$SIGNAL_SOURCE'" >&2
  echo "$SCRIPT_NAME: valid sources: validate-fail, security-scan, relay-exit6, canary-reject, watchdog-parked, pdda-sync, dependency-drift, manual, informational" >&2
  exit 2
fi

EVIDENCE_J="$(json_escape "$EVIDENCE")"

# ---------------------------------------------------------------------------
# Build JSON note
# ---------------------------------------------------------------------------

# Timestamp in ISO-8601 format (Bash 3.2-compatible via date)
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
TIMESTAMP_J="$(json_escape "$TIMESTAMP")"

if [[ -n "$DEDUPE_FIELD" ]]; then
  NOTE="$(cat <<EOF
{
  "signal_id": "${SIG_ID_J}",
  "source": "${SOURCE_J}",
  "category": "${CATEGORY}",
  "severity": "${SEVERITY}",
  "evidence": "${EVIDENCE_J}",
  ${DEDUPE_FIELD}
  "classified_at": "${TIMESTAMP_J}"
}
EOF
)"
else
  NOTE="$(cat <<EOF
{
  "signal_id": "${SIG_ID_J}",
  "source": "${SOURCE_J}",
  "category": "${CATEGORY}",
  "severity": "${SEVERITY}",
  "evidence": "${EVIDENCE_J}",
  "classified_at": "${TIMESTAMP_J}"
}
EOF
)"
fi

# ---------------------------------------------------------------------------
# Emit: stdout + canonical file
# ---------------------------------------------------------------------------

echo "$NOTE"

mkdir -p "$OUTPUT_DIR"
NOTE_PATH="${OUTPUT_DIR}/${SIGNAL_ID}.json"
printf '%s\n' "$NOTE" > "$NOTE_PATH"

echo "$SCRIPT_NAME: triage note written to $NOTE_PATH" >&2
