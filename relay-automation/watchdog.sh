#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TICK_BIN="${TICK_BIN:-"$ROOT_DIR/bin/tick"}"

usage() {
  cat <<'EOF'
Usage: relay-automation/watchdog.sh [options]

Skeleton only:
- run `tick analyze`
- detect parked tasks from the analysis output
- escalate parked tasks to a human channel
- optionally reap, but only behind an explicit authority flag

Options:
  --analysis-file PATH    Reuse captured `tick analyze` output instead of invoking it.
  --human-target LABEL    Human escalation target label (default: human-ops).
  --allow-reap            Enable the reap stub after escalation.
  --help                  Show this message.
EOF
}

die() {
  printf 'watchdog: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

collect_analysis() {
  if [[ -n "$ANALYSIS_FILE" ]]; then
    [[ -f "$ANALYSIS_FILE" ]] || die "analysis file does not exist: $ANALYSIS_FILE"
    cat "$ANALYSIS_FILE"
    return
  fi

  "$TICK_BIN" analyze
}

find_parked_lines() {
  grep -Ei '\bparked\b'
}

extract_task_id() {
  local line="$1"
  if [[ "$line" =~ (TASK-[A-Z0-9]+) ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return
  fi

  printf 'UNKNOWN\n'
}

escalate_to_human() {
  local task_id="$1"
  local evidence="$2"
  printf 'watchdog: escalate %s to %s\n' "$task_id" "$HUMAN_TARGET" >&2
  printf 'watchdog: stub only; replace with pager/chat/ticket integration once the escalation contract is finalized\n' >&2
  printf 'watchdog: evidence: %s\n' "$evidence" >&2
}

reap_task_stub() {
  local task_id="$1"
  printf 'watchdog: reap authority granted for %s\n' "$task_id" >&2
  printf 'watchdog: stub only; wire to the real reap workflow once policy is approved\n' >&2
}

ANALYSIS_FILE=""
HUMAN_TARGET="human-ops"
ALLOW_REAP=0

while (($# > 0)); do
  case "$1" in
    --analysis-file)
      ANALYSIS_FILE="${2:-}"
      shift 2
      ;;
    --human-target)
      HUMAN_TARGET="${2:-}"
      shift 2
      ;;
    --allow-reap)
      ALLOW_REAP=1
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

require_command grep
require_command "$TICK_BIN"

parked_lines="$(collect_analysis | find_parked_lines || true)"

if [[ -z "$parked_lines" ]]; then
  printf 'watchdog: no parked tasks detected\n'
  exit 0
fi

while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  task_id="$(extract_task_id "$line")"
  escalate_to_human "$task_id" "$line"

  if ((ALLOW_REAP)); then
    reap_task_stub "$task_id"
  fi
done <<<"$parked_lines"
