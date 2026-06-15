#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TICK_BIN="${TICK_BIN:-"$ROOT_DIR/bin/tick"}"

usage() {
  cat <<'EOF'
Usage: relay-automation/watchdog.sh [options]

Skeleton only:
- run `tick analyze --format json`
- iterate the structured parked_suspects[] (no text grep -> no false positives)
- escalate parked tasks to a human channel
- optionally reap, but only behind an explicit authority flag

Options:
  --analysis-file PATH    Reuse captured `tick analyze --format json` output (JSON) instead of invoking it.
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

  "$TICK_BIN" analyze --format json
}

# Emit one TSV row (task<TAB>agent<TAB>max_gap_ms<TAB>heartbeats) per REAL parked
# suspect, read from the structured report. An empty parked_suspects[] yields no
# rows -> no escalation. This replaces the old `grep parked` text scan, which
# matched the healthy-run summary line "parked-claim suspects: none" and would
# escalate (and, with --allow-reap, reap) a HEALTHY run. (relay r1 Blocker, Codex.)
extract_parked_suspects() {
  node -e '
    let raw = "";
    process.stdin.on("data", d => raw += d);
    process.stdin.on("end", () => {
      let report;
      try { report = JSON.parse(raw); }
      catch (e) { console.error("watchdog: analysis is not valid JSON: " + e.message); process.exit(3); }
      for (const s of report.parked_suspects || []) {
        process.stdout.write([s.task, s.agent, s.max_gap_ms, s.heartbeats].join("\t") + "\n");
      }
    });
  '
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

require_command node
require_command "$TICK_BIN"

parked_suspects="$(collect_analysis | extract_parked_suspects)"

if [[ -z "$parked_suspects" ]]; then
  printf 'watchdog: no parked tasks detected\n'
  exit 0
fi

while IFS=$'\t' read -r task_id agent max_gap_ms heartbeats; do
  [[ -n "$task_id" ]] || continue
  evidence="agent=$agent max_gap_ms=$max_gap_ms heartbeats=$heartbeats"
  escalate_to_human "$task_id" "$evidence"

  if ((ALLOW_REAP)); then
    reap_task_stub "$task_id"
  fi
done <<<"$parked_suspects"
