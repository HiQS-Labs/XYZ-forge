#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TICK_BIN="${TICK_BIN:-"$ROOT_DIR/bin/tick"}"

usage() {
  cat <<'EOF'
Usage: relay-automation/watchdog.sh [options]

Watchdog liveness scan:
- run `tick analyze --format json`
- iterate the structured parked_suspects[] (no text grep -> no false positives)
- emit a structured escalation record for each parked task
- optionally reap, but only behind an explicit authority flag

Options:
  --analysis-file PATH    Reuse captured `tick analyze --format json` output (JSON) instead of invoking it.
  --human-target LABEL    Human escalation target label (default: human-ops).
  --channel MODE         Escalation sink: stdout or file (default: stdout).
  --escalation-log PATH  Append escalation records to PATH when --channel file is used.
  --allow-reap            Authority grant: after escalating, REAP each parked suspect — re-offer its
                          orphaned token via `tick reap <agent> --task <task>` (scoped, idempotent,
                          exactly-once). Default off = escalate-only. See decisions/2026-06-30-auto-reap-authority.md.
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

now_iso() {
  if [[ -n "${WATCHDOG_TS:-}" ]]; then
    printf '%s\n' "$WATCHDOG_TS"
    return
  fi

  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

build_escalation_record() {
  local task_id="$1"
  local agent="$2"
  local max_gap_ms="$3"
  local heartbeats="$4"
  local evidence="$5"
  local ts="$6"

  node -e '
    const [task, agent, maxGap, heartbeats, evidence, ts] = process.argv.slice(1);
    process.stdout.write(JSON.stringify({
      task,
      agent,
      max_gap_ms: Number(maxGap),
      heartbeats: Number(heartbeats),
      evidence,
      ts,
    }));
  ' "$task_id" "$agent" "$max_gap_ms" "$heartbeats" "$evidence" "$ts"
}

write_escalation_record() {
  local record="$1"

  case "$CHANNEL" in
    stdout)
      printf '%s\n' "$record"
      ;;
    file)
      [[ -n "$ESCALATION_LOG" ]] || die "--escalation-log is required when --channel file is used"
      printf '%s\n' "$record" >>"$ESCALATION_LOG"
      ;;
    *)
      die "invalid channel: $CHANNEL"
      ;;
  esac
}

escalate_to_human() {
  local task_id="$1"
  local agent="$2"
  local max_gap_ms="$3"
  local heartbeats="$4"
  local evidence="$5"
  local ts
  local record

  ts="$(now_iso)"
  record="$(build_escalation_record "$task_id" "$agent" "$max_gap_ms" "$heartbeats" "$evidence" "$ts")"
  write_escalation_record "$record"
}

# R2 auto-reap (decision: decisions/2026-06-30-auto-reap-authority.md). Re-offer a parked claim's
# orphaned token by releasing the dead claim — SCOPED to exactly this (agent, task), recorded as
# reaped `--by watchdog`. Idempotent: `tick reap` is a no-op (still exit 0) if <agent> no longer holds
# <task_id> (already re-offered / reclaimed), and once released the task is no longer a parked suspect,
# so a later pass won't re-reap it — exactly-once. Evidence is the caller's parked_suspects[] membership
# (max gap past the parked threshold); a live/heartbeating claim never reaches here. The release `tick
# reap` emits is epoch-stamped, so a revived same-id writer stays fenced (Phase 1 epoch fencing).
reap_task() {
  local task_id="$1"
  local agent="$2"
  local out
  if out="$("$TICK_BIN" reap "$agent" --by watchdog --task "$task_id" 2>&1)"; then
    printf 'watchdog: reap %s (held by %s) — %s\n' "$task_id" "$agent" "$out" >&2
  else
    printf 'watchdog: reap of %s (held by %s) FAILED: %s — left escalated for a human\n' "$task_id" "$agent" "$out" >&2
    return 1
  fi
}

ANALYSIS_FILE=""
HUMAN_TARGET="human-ops"
CHANNEL="stdout"
ESCALATION_LOG=""
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
    --channel)
      CHANNEL="${2:-}"
      shift 2
      ;;
    --escalation-log)
      ESCALATION_LOG="${2:-}"
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
  evidence="human_target=$HUMAN_TARGET max_gap_ms=$max_gap_ms heartbeats=$heartbeats"
  escalate_to_human "$task_id" "$agent" "$max_gap_ms" "$heartbeats" "$evidence"

  if ((ALLOW_REAP)); then
    # Best-effort recovery: the escalation above is the GUARANTEE; a failed reap is logged (inside
    # reap_task) but must not crash the watchdog or skip the remaining suspects. `|| true` keeps the
    # scan going and the exit clean — the human still has every escalation record.
    reap_task "$task_id" "$agent" || true
  fi
done <<<"$parked_suspects"
