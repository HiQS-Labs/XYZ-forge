#!/usr/bin/env bash
set -euo pipefail
#
# marathon.sh — Phase 4 (M5): multi-phase orchestrator. Reads MARATHON.yaml, resolves depends_on
# order, and runs each phase through marathon-drive.sh (the unmodified single-phase loop). Advances
# on phase approval; HALTS on the first phase failure (relay no-progress / cap / gate / containment),
# leaving that phase's ESCALATION.md (written by marathon-drive) and NOT starting later phases.
# Emits marathon.complete only when every phase is approved.
#
# Per-phase round cap = 2 * max_review_rounds + 1 (turns ≠ rounds; the off-by-one kills phases early).
# Cross-phase context injection (M6) and MARATHON-STATE.md projection (M7) are deliberately deferred —
# the boundary events already land in .tick/events/ (phase.start/approved/escalated, marathon.complete).
#
# Usage:
#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder claude] [--phases-dir DIR]
#                                [--pre-advance-cmd CMD] [--dry-run]
#
# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
# brief→--phase-brief (required to run), artifact→--artifact, max_review_rounds→--round-cap.
#
# Environment overrides (for tests):
#   MARATHON_ROOT       — repo root (default: parent of this script's dir)
#   MARATHON_DRIVE      — marathon-drive.sh path (default: this script's dir/marathon-drive.sh)
#   MARATHON_YAML_BIN   — bin/marathon-yaml path (default: <repo-root>/bin/marathon-yaml)
#   TICK_BIN            — tick binary (default: <repo-root>/bin/tick)
# Real runs also inherit the turn-taker env (CLAUDE_BIN, *_TURN_ROOT, …), passed straight through.
#
# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${MARATHON_ROOT:-"$(cd "$HERE/.." && pwd)"}"
TICK_BIN="${TICK_BIN:-"$ROOT/bin/tick"}"
DRIVE_BIN="${MARATHON_DRIVE:-"$HERE/marathon-drive.sh"}"
YAML_BIN="${MARATHON_YAML_BIN:-"$ROOT/bin/marathon-yaml"}"

die() { printf 'marathon: %s\n' "$*" >&2; exit 2; }
log() { printf 'marathon: %s\n' "$*"; }

XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$ROOT/utils/telemetry/append-xyz-completion.sh"}"

# GH-75: the ONE whole-run completion record for a marathon.sh-orchestrated run. Each per-phase
# marathon-drive runs with XYZ_HARNESS_CONTEXT=marathon-phase (its own hook silent), so this is the
# only place a marathon.sh run is recorded — on BOTH the success tail AND the halt path, so a failed
# run isn't silently absent from XYZ.json (GH-75 review: an early halt used to skip the tail entirely,
# emitting nothing — worse than a bare marathon-drive halt, which does emit red). Best-effort.
xyz_marathon_run_emit() {  # <health> <description>
  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
  local plan; plan="$(basename "$PLAN")"; plan="${plan%.*}"; [[ -n "$plan" ]] || plan="marathon"
  "$XYZ_APPEND_BIN" marathon "$plan" "$1" "$plan" "$2" >/dev/null 2>&1 || true
}

PLAN=""; BUILDER="claude"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0
while (($# > 0)); do
  case "$1" in
    --plan)            PLAN="${2:-}"; shift 2 ;;
    --builder)         BUILDER="${2:-}"; shift 2 ;;
    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
    --dry-run)         DRY_RUN=1; shift ;;
    --help)            printf 'Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C] [--dry-run]\n'; exit 0 ;;
    *)                 die "unknown argument: $1" ;;
  esac
done
[[ -n "$PLAN" ]] || { die "--plan MARATHON.yaml required"; }
[[ -f "$PLAN" ]] || die "plan not found: $PLAN"
PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
export TICK_REPO_ROOT="$ROOT"

# Parse + validate + resolve order. A malformed/cyclic plan halts the whole run here (exit 2).
PLAN_TSV="$("$YAML_BIN" "$PLAN")" || die "plan parse failed (see above)"
[[ -n "$PLAN_TSV" ]] || die "plan has no phases"
phase_count="$(printf '%s\n' "$PLAN_TSV" | grep -c .)"
log "plan: $PLAN — $phase_count phase(s) in execution order"

idx=0
# Read TSV with a NON-whitespace field separator (US / \037): `IFS=$'\t' read` coalesces consecutive
# tabs (tab is whitespace-class), which would collapse empty columns and shift every field. Translate
# tabs → \037 so empty fields (no rounds / no depends_on / no artifact) are preserved positionally.
while IFS=$'\037' read -r id reviewer rounds depends_on brief artifact name; do
  [[ -n "$id" ]] || continue
  idx=$((idx + 1))
  rounds="${rounds:-2}"
  cap=$((2 * rounds + 1))
  [[ -n "$brief" ]] || die "phase $id: no 'brief:' in the plan — a phase needs a task to run"
  case "$brief" in /*) brief_path="$brief" ;; *) brief_path="$ROOT/$brief" ;; esac
  [[ -f "$brief_path" ]] || die "phase $id: brief file not found: $brief_path"

  log "── phase $idx/$phase_count: $id (reviewer=$reviewer, round-cap=$cap${artifact:+, artifact=$artifact}) ──"

  drive_args=( --phase-id "$id" --reviewer "$reviewer" --builder "$BUILDER"
               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
  [[ -n "$artifact" ]] && drive_args+=( --artifact "$artifact" )
  [[ -n "$PRE_ADVANCE_CMD" ]] && drive_args+=( --pre-advance-cmd "$PRE_ADVANCE_CMD" )
  if ((DRY_RUN)); then drive_args+=( --dry-run ); fi

  phase_exit=0
  # GH-75: mark each per-phase marathon-drive call so its (and its nested relay-drive's) XYZ.json hook
  # stays silent — this orchestrator emits a SINGLE harness:"marathon" whole-run record below, never
  # one per phase.
  MARATHON_ROOT="$ROOT" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
    bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
  if [[ "$phase_exit" -ne 0 ]]; then
    log "HALT: phase $id failed (marathon-drive exit $phase_exit) — chain stops; later phases NOT started"
    case "$phase_exit" in
      3) _halt_reason="relay no-progress" ;;
      4) _halt_reason="relay cap/close-mismatch" ;;
      5) _halt_reason="pre-advance gate failed" ;;
      6) _halt_reason="containment violation" ;;
      *) _halt_reason="marathon-drive exit $phase_exit" ;;
    esac
    xyz_marathon_run_emit red "halted at phase $idx of $phase_count ($id) — $_halt_reason"
    exit "$phase_exit"
  fi
done < <(printf '%s\n' "$PLAN_TSV" | tr '\t' '\037')

if ((DRY_RUN)); then
  log "dry-run complete: $phase_count phase(s) would run in order"
  exit 0
fi
"$TICK_BIN" log marathon.complete "MARATHON-RUN" --agent marathon > /dev/null 2>&1 || true

# GH-75: the whole-run success record (title/sessionId = plan name, "N of M phase(s) approved").
xyz_marathon_run_emit green "$phase_count of $phase_count phase(s) approved"

log "marathon complete — all $phase_count phase(s) approved"
exit 0
