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
#   relay-automation/marathon.sh --plan MARATHON.yaml [--builder codex] [--phases-dir DIR]
#                                [--pre-advance-cmd CMD] [--dry-run] [--retry PHASE-ID]
#
# GH-212: default builder is `codex` — no per-call API charge (bills via the Codex/ChatGPT
# subscription; agy is the other cost-blind option). `--builder claude` spawns a headless Claude
# Code CLI subprocess instead: a SEPARATE, PER-CALL API-BILLED turn-taker, distinct from an
# interactive session. Use it only as an explicit, cost-acknowledged choice.
#
# GH-212: a plan's `--plan` YAML (+ its phase briefs) must resolve under PROJECT/2-WORKING/ in the
# target repo — not a standalone top-level folder (e.g. marathon-plans/<slug>/) an agent might
# pattern-match from a prior repo. Exempt: paths under this harness's own home (MARATHON_HOME —
# covers shipped examples like MARATHON.example.yaml). Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
#
# GH-116: --retry <phase-id> recovers a phase whose relay task was left open/never-claimed
# (permanently spent, per this repo's claim-then-abandon constraint) WITHOUT manually renaming the
# phase id in MARATHON.yaml. It overrides just that one phase's --relay-task with the first unused
# MARATHON-<ID>-TURN-<N> suffix (N starts at 2, checked via `tick info`) — every other phase derives
# its task name exactly as before. marathon-drive.sh already supports --relay-task natively; this is
# purely a marathon.sh-side task-name override, no change to marathon-drive.sh itself.
#
# The MARATHON.yaml phase fields drive each marathon-drive call: id→--phase-id, reviewer→--reviewer,
# brief→--phase-brief (required to run), artifact→--artifact, turn_timeout_s→RELAY_TURN_TIMEOUT_S,
# max_review_rounds→--round-cap.
#
# Environment overrides (for tests):
#   MARATHON_HOME       — harness home (default: parent of this script's dir)
#   MARATHON_ROOT       — target repo root (default: `git -C "$PWD" rev-parse --show-toplevel`,
#                         falling back to MARATHON_HOME outside a git repo)
#   MARATHON_DRIVE      — marathon-drive.sh path (default: <harness-home>/relay-automation/marathon-drive.sh)
#   MARATHON_YAML_BIN   — bin/marathon-yaml path (default: <harness-home>/bin/marathon-yaml)
#   TICK_BIN            — tick binary (default: <harness-home>/bin/tick)
#   MARATHON_CLOSEOUT_BIN — marathon-closeout.sh path (default: <harness-home>/relay-automation/marathon-closeout.sh)
#   MARATHON_ALLOW_PLAN_OUTSIDE_WORKING — 1 permits a --plan outside PROJECT/2-WORKING/ (GH-212)
# Real runs also inherit the turn-taker env (CLAUDE_BIN, *_TURN_ROOT, …), passed straight through.
#
# Exit: 0 all phases approved · N the failing phase's marathon-drive exit code · 2 usage/parse error.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARATHON_HOME="${MARATHON_HOME:-"$(cd "$HERE/.." && pwd)"}"
if [[ -n "${MARATHON_ROOT:-}" ]]; then
  ROOT="$MARATHON_ROOT"
elif ROOT="$(git -C "${PWD:-.}" rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  ROOT="$MARATHON_HOME"
fi
TICK_BIN="${TICK_BIN:-"$MARATHON_HOME/bin/tick"}"
DRIVE_BIN="${MARATHON_DRIVE:-"$MARATHON_HOME/relay-automation/marathon-drive.sh"}"
YAML_BIN="${MARATHON_YAML_BIN:-"$MARATHON_HOME/bin/marathon-yaml"}"
CLOSEOUT_BIN="${MARATHON_CLOSEOUT_BIN:-"$MARATHON_HOME/relay-automation/marathon-closeout.sh"}"

die() { printf 'marathon: %s\n' "$*" >&2; exit 2; }
log() { printf 'marathon: %s\n' "$*"; }

XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$MARATHON_HOME/utils/telemetry/append-xyz-completion.sh"}"

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

usage() {
  cat <<'EOF'
Usage: marathon.sh --plan MARATHON.yaml [--builder A] [--phases-dir D] [--pre-advance-cmd C]
                    [--dry-run] [--force] [--retry PHASE-ID] [--closeout-pr]

  --plan PATH            MARATHON.yaml to run (required). Must resolve under PROJECT/2-WORKING/ in
                          the target repo (GH-212) — exempt: paths under this harness's own home
                          (shipped examples), or MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
  --builder AGENT         Builder agent id (default: codex — no per-call API charge; bills via the
                          Codex/ChatGPT subscription). --builder claude spawns a headless Claude
                          Code CLI subprocess instead: a SEPARATE, PER-CALL API-BILLED turn-taker —
                          an explicit, cost-acknowledged choice, not the default.
  --phases-dir DIR        Where to create <dir>/<id>/ (default: <repo-root>/marathon-system).
  --target-root DIR       Foreign git repo the BUILD lands in; forwarded to marathon-drive.sh (GH-11).
                          The relay thread, tick token, marathon-system/ and relay-system/ transcripts all stay
                          in THIS harness repo — only code changes land in DIR. Use this when the target
                          repo cannot track harness output (e.g. a public repo that gitignores marathon-system/
                          and relay-system/ on purpose): without it, marathon-drive's `git add` of
                          RELAY.md / ESCALATION.md / the transcript fails and the phase HALTs.
                          Plan and brief paths resolve against DIR when set.
  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh, per phase).
  --dry-run               Render each phase's relay file and print the tick seed; exit without running.
  --force                 GH-45: bypass the per-lane attempt cap for this run.
  --retry PHASE-ID        GH-116: retry one phase with a fresh relay-task suffix.
  --closeout-pr           Open (but never merge) a PR after a successful marathon. Closeout failure is logged
                          and does not change the successful marathon exit code.
EOF
}

PLAN=""; BUILDER="codex"; PHASES_DIR=""; PRE_ADVANCE_CMD=""; DRY_RUN=0; FORCE=0; RETRY_PHASE=""; CLOSEOUT_PR=0
TARGET_ROOT=""   # GH-11 passthrough: foreign repo the BUILD lands in; relay/transcripts stay in ROOT
while (($# > 0)); do
  case "$1" in
    --plan)            PLAN="${2:-}"; shift 2 ;;
    --builder)         BUILDER="${2:-}"; shift 2 ;;
    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
    --dry-run)         DRY_RUN=1; shift ;;
    --force)           FORCE=1; shift ;;   # GH-45: forward to each phase so a parked lane can be re-fired
    --retry)           RETRY_PHASE="${2:-}"; shift 2 ;;   # GH-116: retry one phase with a fresh relay-task suffix
    --closeout-pr)     CLOSEOUT_PR=1; shift ;;
    --help)            usage; exit 0 ;;
    *)                 die "unknown argument: $1" ;;
  esac
done
[[ -n "$PLAN" ]] || { die "--plan MARATHON.yaml required"; }
[[ -f "$PLAN" ]] || die "plan not found: $PLAN"

# GH-212: plan-location guard. A marathon's plan artifacts (this YAML + its phase briefs) belong
# under PROJECT/2-WORKING/<capture-doc>/, not a standalone top-level folder (e.g. marathon-plans/)
# an agent might pattern-match from a prior repo. Exempt: paths under this harness's own home
# (MARATHON_HOME) — shipped reference examples (e.g. MARATHON.example.yaml), not an agent-authored
# plan for a target repo. Override for a legitimate non-default location:
# MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1.
_plan_abs="$(cd "$(dirname "$PLAN")" && pwd -P)/$(basename "$PLAN")"
# Canonicalize with `pwd -P` unconditionally (relative AND already-absolute input): ROOT can come
# from `git rev-parse --show-toplevel` (symlink-resolved) or a raw MARATHON_ROOT env override
# (whatever form the caller passed), so either side of this comparison can be a logical (non -P)
# path — canonicalize both or a macOS /var -> /private/var checkout falsely flags every plan.
# symlinks (e.g. macOS /var -> /private/var), so a logical (non -P) comparison here would falsely
# flag every plan as "outside" on such a checkout (same pitfall swarm-preflight.sh works around).
# On a --target-root run the plan lives in the TARGET repo's PROJECT/2-WORKING/, not the harness's,
# so this guard must measure against that repo — otherwise every cross-repo plan falsely "resolves
# outside PROJECT/2-WORKING/" and dies. GH-212's intent is unchanged: the plan must sit under
# PROJECT/2-WORKING/ of whichever repo owns it.
_plan_base="${TARGET_ROOT:-$ROOT}"
_root_canon="$(cd "$_plan_base" 2>/dev/null && pwd -P || printf '%s' "$_plan_base")"
_home_canon="$(cd "$MARATHON_HOME" 2>/dev/null && pwd -P || printf '%s' "$MARATHON_HOME")"
_plan_rel_root="${_plan_abs#"$_root_canon"/}"
case "$_plan_rel_root" in
  PROJECT/2-WORKING/*) ;;   # in the expected home — proceed
  *)
    case "$_plan_abs" in
      "$_home_canon"/*) ;;   # harness-owned reference material — exempt
      *)
        if [[ "${MARATHON_ALLOW_PLAN_OUTSIDE_WORKING:-0}" != "1" ]]; then
          die "plan '$PLAN' resolves outside PROJECT/2-WORKING/ (got: $_plan_rel_root). Marathon plans (MARATHON.yaml + phase briefs) belong under PROJECT/2-WORKING/<capture-doc>/, not a standalone folder — see GUIDING-PRINCIPLES.md Conventions. Override: MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1."
        fi
        log "MARATHON_ALLOW_PLAN_OUTSIDE_WORKING=1 — proceeding with a plan outside PROJECT/2-WORKING/ ($_plan_rel_root)"
        ;;
    esac
    ;;
esac

# GH-484: default `marathon-system/`, matching `relay-system/`. This default is computed here
# INDEPENDENTLY of the driver's own — marathon.sh forwards --phases-dir explicitly on every phase
# (see the drive_args below), so the driver's default is never consulted on this path. Both must
# agree or a marathon.sh run and a direct marathon-drive run would write to different places.
PHASES_DIR="${PHASES_DIR:-"$ROOT/marathon-system"}"
export TICK_REPO_ROOT="$ROOT"

# Parse + validate + resolve order. A malformed/cyclic plan halts the whole run here (exit 2).
PLAN_TSV="$("$YAML_BIN" "$PLAN")" || die "plan parse failed (see above)"
[[ -n "$PLAN_TSV" ]] || die "plan has no phases"
PLAN_NAME="$(sed -n 's/^name:[[:space:]]*//p' "$PLAN" | head -n1 | sed 's/[[:space:]]*$//')"
phase_count="$(printf '%s\n' "$PLAN_TSV" | grep -c .)"
log "plan: $PLAN — $phase_count phase(s) in execution order"

idx=0
# Read TSV with a NON-whitespace field separator (US / \037): `IFS=$'\t' read` coalesces consecutive
# tabs (tab is whitespace-class), which would collapse empty columns and shift every field. Translate
# tabs → \037 so empty fields (no rounds / no depends_on / no artifact / no turn_timeout_s) are
# preserved positionally.
while IFS=$'\037' read -r id reviewer rounds depends_on brief artifact turn_timeout_s name; do
  [[ -n "$id" ]] || continue
  idx=$((idx + 1))
  rounds="${rounds:-2}"
  cap=$((2 * rounds + 1))
  lane_ns=""
  [[ -n "$PLAN_NAME" ]] && lane_ns="${PLAN_NAME}--${id}"
  [[ -n "$brief" ]] || die "phase $id: no 'brief:' in the plan — a phase needs a task to run"
  # Briefs live beside the plan, so they resolve against the repo the plan came from. On a
  # --target-root run that is the TARGET repo, not this harness — resolving against $ROOT would
  # look for the target's briefs inside the harness clone and die "brief file not found".
  brief_base="${TARGET_ROOT:-$ROOT}"
  case "$brief" in /*) brief_path="$brief" ;; *) brief_path="$brief_base/$brief" ;; esac
  [[ -f "$brief_path" ]] || die "phase $id: brief file not found: $brief_path"

  log "── phase $idx/$phase_count: $id (reviewer=$reviewer, round-cap=$cap${artifact:+, artifact=$artifact}${turn_timeout_s:+, turn-timeout=${turn_timeout_s}s}) ──"

  drive_args=( --phase-id "$id" --reviewer "$reviewer" --builder "$BUILDER"
               --phase-brief "$brief_path" --round-cap "$cap" --phases-dir "$PHASES_DIR" )
  [[ -n "$artifact" ]] && drive_args+=( --artifact "$artifact" )
  [[ -n "$TARGET_ROOT" ]] && drive_args+=( --target-root "$TARGET_ROOT" )
  [[ -n "$PRE_ADVANCE_CMD" ]] && drive_args+=( --pre-advance-cmd "$PRE_ADVANCE_CMD" )
  ((FORCE)) && drive_args+=( --force )   # GH-45: bypass the per-lane attempt cap for this run
  # GH-116: only the phase named by --retry gets a task-name override — every other phase still lets
  # marathon-drive.sh derive its default MARATHON-<ID>-TURN name, unaffected.
  if [[ -n "$RETRY_PHASE" && "$id" == "$RETRY_PHASE" ]]; then
    id_upper="$(printf '%s' "$id" | tr '[:lower:]' '[:upper:]')"
    retry_n=2
    # First unused suffix, not a hardcoded -2: keep bumping while that task name already exists
    # (tick info exits 0 once a task has any recorded state — spent or not, it's not reusable).
    while "$TICK_BIN" info "MARATHON-${id_upper}-TURN-${retry_n}" >/dev/null 2>&1; do
      retry_n=$((retry_n + 1))
    done
    retry_task="MARATHON-${id_upper}-TURN-${retry_n}"
    log "phase $id: --retry requested — overriding relay task to $retry_task (first unused suffix)"
    drive_args+=( --relay-task "$retry_task" )
  fi
  if ((DRY_RUN)); then drive_args+=( --dry-run ); fi

  phase_exit=0
  # GH-75: mark each per-phase marathon-drive call so its (and its nested relay-drive's) XYZ.json hook
  # stays silent — this orchestrator emits a SINGLE harness:"marathon" whole-run record below, never
  # one per phase.
  if [[ -n "$turn_timeout_s" ]]; then
    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
      RELAY_TURN_TIMEOUT_S="$turn_timeout_s" \
      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
  else
    MARATHON_ROOT="$ROOT" MARATHON_LANE_NS="$lane_ns" TICK_BIN="$TICK_BIN" XYZ_HARNESS_CONTEXT=marathon-phase \
      bash "$DRIVE_BIN" "${drive_args[@]}" || phase_exit=$?
  fi
  if [[ "$phase_exit" -ne 0 ]]; then
    log "HALT: phase $id failed (marathon-drive exit $phase_exit) — chain stops; later phases NOT started"
    case "$phase_exit" in
      3) _halt_reason="relay no-progress" ;;
      4) _halt_reason="relay cap/close-mismatch" ;;
      5) _halt_reason="pre-advance gate failed" ;;
      6) _halt_reason="containment violation" ;;
      7) _halt_reason="turn timeout / hang" ;;
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

if ((CLOSEOUT_PR)); then
  closeout_plan="${PLAN_NAME:-$(basename "${PLAN%.*}")}"
  closeout_event_dir="$ROOT/.tick/events"
  closeout_event_count=0
  closeout_event_types=""
  if [[ -d "$closeout_event_dir" ]]; then
    closeout_event_count="$(find "$closeout_event_dir" -type f -name '*.jsonl' -print | wc -l | tr -d '[:space:]')"
    closeout_event_types="$(find "$closeout_event_dir" -type f -name '*.jsonl' -print | LC_ALL=C sort | while IFS= read -r event_file; do
      sed -n 's/.*"type":"\([^"]*\)".*/\1/p' "$event_file"
    done | LC_ALL=C sort -u | paste -sd, -)"
  fi
  closeout_notes="Marathon plan: $closeout_plan
Phases approved: $phase_count/$phase_count
Tick events: $closeout_event_count${closeout_event_types:+ ($closeout_event_types)}"
  if ! bash "$CLOSEOUT_BIN" --repo "$ROOT" --open-only --title "Marathon: $closeout_plan" --notes "$closeout_notes"; then
    log "closeout PR failed after successful marathon; leaving marathon successful"
  fi
fi
"$TICK_BIN" log marathon.complete "MARATHON-RUN" --agent marathon > /dev/null 2>&1 || true

# GH-75: the whole-run success record (title/sessionId = plan name, "N of M phase(s) approved").
xyz_marathon_run_emit green "$phase_count of $phase_count phase(s) approved"

log "marathon complete — all $phase_count phase(s) approved"
exit 0
