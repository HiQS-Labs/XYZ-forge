#!/usr/bin/env bash
set -euo pipefail
#
# poll.sh — Phase 4 hands-free poll driver (Option B: baton + poll).
# One TICK per invocation (drive it under `/loop`, e.g. `/loop 60s ...`).
# It computes a DECISION from coordination state and either dispatches a command
# or idles. See PROJECT/4-MISC/PHASE-4-PLAN.md.
#
# Two modes (one decision engine, shared tick claimability):
#   xyz   — runnable state = a build task (--task) claimable/resumable by --agent
#   relay — runnable state = the RELAY-TURN tick task (claimable/resumable by --agent);
#           the relay file's STATUS is read only as the terminal (Approved/Closed) signal
#
# Two distinct guard->dispatch paths (a parked turn is held by the OTHER window,
# so it cannot use the my-turn guard — recovery is a separate path):
#   runner path   : (my-turn) AND (artifact scope clean)        -> run --runner-cmd
#   watchdog path : (parked suspect) AND (--watchdog-authority)  -> run --watchdog-cmd
# Exactly ONE designated poller should hold --watchdog-authority (no double-escalate).
#
# Decisions: stop | nudge-cross-model | run-runner | run-watchdog | idle

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TICK_BIN="${TICK_BIN:-"$ROOT_DIR/bin/tick"}"
# Git root for the artifact-scoped clean-tree check. Defaults to the repo this
# script lives in; tests override via POLL_GIT_ROOT to point at a fixture repo.
GIT_ROOT="${POLL_GIT_ROOT:-$ROOT_DIR}"

usage() {
  cat <<'EOF'
Usage: relay-automation/poll.sh --mode <xyz|relay> --agent <id> [options]

Common:
  --mode xyz|relay        Which runnable adapter to use (required).
  --agent ID              This poller's agent id (required).
  --dry-run               Print the DECISION; do not dispatch.
  --analysis-file PATH    JSON `tick analyze` output (else runs `tick analyze --format json`).
  --watchdog-authority    This poller may run the watchdog path (designate exactly one).
  --deadline EPOCH        Self-expire: emit DECISION: stop once now >= EPOCH (unix seconds).
                          The /loop then CronDeletes itself (see relay skill "Self-closing loops").
  --runner-cmd CMD        Command run for a runnable turn (default: <root>/relay-automation/runner.sh).
  --watchdog-cmd CMD      Command run for a parked suspect (default: <root>/relay-automation/watchdog.sh).
  --help

relay mode (whose-turn = the RELAY-TURN tick task; STATUS read from the file):
  --relay-file PATH       Relay thread file (reads STATUS: for the terminal signal).
  --relay-task ID         The relay turn-token task (default: RELAY-TURN).
  --artifact PATH         Artifact under review (clean-tree scope; with the relay file).
  --claude-agents "a,b"   Agents that are Claude (can self-poll); a RELAY-TURN handed
                          to a non-Claude agent -> cross-model nudge.

xyz mode:
  --task TASK-ID          The task whose turn this is (my-turn + scope from `tick info`).

Exit codes: 0 = acted/idle, 10 = stop (relay closed), 2 = usage error.
EOF
}

die() { printf 'poll: %s\n' "$*" >&2; exit 2; }
require_command() { command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }

# Dispatch a configured command that may be EITHER a bare executable path —
# possibly absolute and containing spaces, e.g. a clone under ".../GH Repos/..."
# — OR a full shell command string (env-prefixed / shell-quoted by the caller).
# A bare path is run DIRECTLY so a space in it is not word-split; only a command
# string falls back to eval. Mirrors relay-drive.sh's --agent-cmd handling.
# (GH-12: the default RUNNER_CMD/WATCHDOG_CMD path holds a space → the old bare
# `eval "$RUNNER_CMD"` exec'd the wrong token, e.g. `/Users/.../GH: not found`.)
run_cmd() {
  if [[ -x "$1" ]]; then "$1"; else eval "$1"; fi
}

# ---- inputs --------------------------------------------------------------
MODE=""; AGENT=""; DRY_RUN=0; ANALYSIS_FILE=""; WATCHDOG_AUTHORITY=0
RUNNER_CMD=""; WATCHDOG_CMD=""
RELAY_FILE=""; ARTIFACT=""; CLAUDE_AGENTS=""; RELAY_TASK="RELAY-TURN"; DEADLINE=""
TASK=""

while (($# > 0)); do
  case "$1" in
    --mode) MODE="${2:-}"; shift 2 ;;
    --agent) AGENT="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --analysis-file) ANALYSIS_FILE="${2:-}"; shift 2 ;;
    --watchdog-authority) WATCHDOG_AUTHORITY=1; shift ;;
    --deadline) DEADLINE="${2:-}"; shift 2 ;;
    --runner-cmd) RUNNER_CMD="${2:-}"; shift 2 ;;
    --watchdog-cmd) WATCHDOG_CMD="${2:-}"; shift 2 ;;
    --relay-file) RELAY_FILE="${2:-}"; shift 2 ;;
    --relay-task) RELAY_TASK="${2:-}"; shift 2 ;;
    --artifact) ARTIFACT="${2:-}"; shift 2 ;;
    --claude-agents) CLAUDE_AGENTS="${2:-}"; shift 2 ;;
    --task) TASK="${2:-}"; shift 2 ;;
    --help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ "$MODE" == "xyz" || "$MODE" == "relay" ]] || { usage; die "--mode xyz|relay is required"; }
[[ -n "$AGENT" ]] || die "--agent is required"
RUNNER_CMD="${RUNNER_CMD:-"$ROOT_DIR/relay-automation/runner.sh"}"
WATCHDOG_CMD="${WATCHDOG_CMD:-"$ROOT_DIR/relay-automation/watchdog.sh"}"

# ---- state readers -------------------------------------------------------

# Parked suspects (structured, never the "none" text). Echoes count.
parked_count() {
  local json
  if [[ -n "$ANALYSIS_FILE" ]]; then
    [[ -f "$ANALYSIS_FILE" ]] || die "analysis file does not exist: $ANALYSIS_FILE"
    json="$(cat "$ANALYSIS_FILE")"
  else
    require_command node
    json="$("$TICK_BIN" analyze --format json)"
  fi
  printf '%s' "$json" | node -e '
    let raw=""; process.stdin.on("data",d=>raw+=d);
    process.stdin.on("end",()=>{ try{const r=JSON.parse(raw);process.stdout.write(String((r.parked_suspects||[]).length));}catch(e){process.stdout.write("0");} });
  '
}

# Read a "Key:" line value from the relay file (NEXT / STATUS).
relay_field() { sed -n "s/^$1:[[:space:]]*//p" "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }

# Artifact-scoped clean check (NOT repo-global). Returns 0 = clean.
scope_clean() {
  local -a scope=("$@")
  ((${#scope[@]})) || return 0
  git -C "$GIT_ROOT" status --porcelain -- "${scope[@]}" | grep -q . && return 1 || return 0
}

# Read tick task fields into globals T_STATUS/T_CLAIMER/T_HANDOFF/T_PATHS.
read_task() {
  local info
  info="$("$TICK_BIN" info "$1" 2>/dev/null || true)"
  T_STATUS="$(printf '%s\n' "$info"  | sed -n 's/^status:[[:space:]]*//p'     | head -1)"
  T_CLAIMER="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p'    | head -1)"
  T_HANDOFF="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -1)"
  T_PATHS="$(printf '%s\n' "$info"   | sed -n 's/^paths:[[:space:]]*//p'      | head -1)"
}

# Claimability-for-me from the T_* globals (shared by both modes):
#   open + (no handoff | handoff==me)  OR  claimed + claimer==me
tick_my_turn() {
  [[ "$T_STATUS" == "open"    && ( -z "$T_HANDOFF" || "$T_HANDOFF" == "$AGENT" ) ]] && return 0
  [[ "$T_STATUS" == "claimed" && "$T_CLAIMER" == "$AGENT" ]] && return 0
  return 1
}

is_claude_agent() {
  local a="$1" x
  [[ -z "$CLAUDE_AGENTS" ]] && return 1   # empty list: nobody is "known Claude" (avoids set -u empty-array expansion on bash 3.2)
  IFS=',' read -ra _ca <<<"$CLAUDE_AGENTS"
  for x in "${_ca[@]}"; do [[ "$x" == "$a" ]] && return 0; done
  return 1
}

# ---- compute guard booleans ---------------------------------------------
STOP=0; MY_TURN=0; CLEAN=1; CROSS_MODEL=0; CROSS_AGENT=""

PARKED=0
[[ "$(parked_count)" -gt 0 ]] && PARKED=1

if [[ "$MODE" == "relay" ]]; then
  [[ -n "$RELAY_FILE" ]] || die "relay mode requires --relay-file"
  [[ -f "$RELAY_FILE" ]] || die "relay file does not exist: $RELAY_FILE"
  # Terminal signal comes from the human-readable thread; whose-turn from tick.
  case "$(relay_field STATUS)" in Approved|Closed) STOP=1 ;; esac
  read_task "$RELAY_TASK"
  if tick_my_turn; then
    MY_TURN=1
    scope=("$RELAY_FILE"); [[ -n "$ARTIFACT" ]] && scope+=("$ARTIFACT")
    scope_clean "${scope[@]}" && CLEAN=1 || CLEAN=0
  elif [[ "$T_STATUS" == "open" && -n "$T_HANDOFF" && "$T_HANDOFF" != "$AGENT" ]] \
       && ! is_claude_agent "$T_HANDOFF"; then
    CROSS_MODEL=1; CROSS_AGENT="$T_HANDOFF"
  fi
else # xyz
  [[ -n "$TASK" ]] || die "xyz mode requires --task"
  read_task "$TASK"
  if tick_my_turn; then
    MY_TURN=1
    if [[ -n "$T_PATHS" ]]; then
      IFS=',' read -ra _sc <<<"$T_PATHS"
      scope_clean "${_sc[@]}" && CLEAN=1 || CLEAN=0
    fi
  fi
fi

# Self-expiry: once past the deadline, stop regardless of turn state.
EXPIRED=0
if [[ -n "$DEADLINE" ]] && (( $(date +%s) >= DEADLINE )); then EXPIRED=1; fi

# ---- decision engine -----------------------------------------------------
DECISION=""; REASON=""
if ((EXPIRED)); then
  DECISION="stop"; REASON="deadline reached (self-expire)"
elif ((STOP)); then
  DECISION="stop"; REASON="relay STATUS is terminal"
elif ((CROSS_MODEL)); then
  DECISION="nudge-cross-model"; REASON="turn belongs to non-Claude agent '$CROSS_AGENT'"
elif ((MY_TURN)) && ((CLEAN)); then
  DECISION="run-runner"; REASON="my turn and artifact scope clean"
elif ((MY_TURN)); then
  DECISION="idle"; REASON="my turn but artifact scope dirty"
elif ((PARKED)) && ((WATCHDOG_AUTHORITY)); then
  DECISION="run-watchdog"; REASON="parked suspect and I hold watchdog authority"
elif ((PARKED)); then
  DECISION="idle"; REASON="parked suspect but no watchdog authority"
else
  DECISION="idle"; REASON="nothing runnable"
fi

printf 'DECISION: %s (%s)\n' "$DECISION" "$REASON"

# ---- dispatch ------------------------------------------------------------
if ((DRY_RUN)); then
  [[ "$DECISION" == "stop" ]] && exit 10 || exit 0
fi

case "$DECISION" in
  run-runner)   run_cmd "$RUNNER_CMD" ;;
  run-watchdog) run_cmd "$WATCHDOG_CMD" ;;
  nudge-cross-model)
    printf 'poll: %s turn detected — manual nudge required: "take your turn on %s"\n' \
      "$CROSS_AGENT" "${RELAY_FILE:-<relay-file>}" >&2 ;;
  stop) exit 10 ;;
  idle) : ;;
esac
