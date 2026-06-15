#!/usr/bin/env bash
set -euo pipefail
#
# poll.sh — Phase 4 hands-free poll driver (Option B: baton + poll).
# One TICK per invocation (drive it under `/loop`, e.g. `/loop 60s ...`).
# It computes a DECISION from coordination state and either dispatches a command
# or idles. See relay-automation/PHASE-4-PLAN.md.
#
# Two modes (one decision engine, two "is-runnable?" adapters):
#   xyz   — runnable state is tick-native (a task claimable/resumable by --agent)
#   relay — runnable state is the relay thread's NEXT / STATUS
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
  --runner-cmd CMD        Command run for a runnable turn (default: <root>/relay-automation/runner.sh).
  --watchdog-cmd CMD      Command run for a parked suspect (default: <root>/relay-automation/watchdog.sh).
  --help

relay mode:
  --relay-file PATH       Relay thread file (reads NEXT: / STATUS:).
  --my-role ROLE          The role THIS agent plays (e.g. Producer | Reviewer).
  --artifact PATH         Artifact under review (clean-tree scope; with the relay file).
  --roles "R=agent,..."   Role->agent map, for cross-model detection (optional).
  --claude-agents "a,b"   Agents that are Claude (can self-poll), for cross-model detection.

xyz mode:
  --task TASK-ID          The task whose turn this is (my-turn + scope from `tick info`).

Exit codes: 0 = acted/idle, 10 = stop (relay closed), 2 = usage error.
EOF
}

die() { printf 'poll: %s\n' "$*" >&2; exit 2; }
require_command() { command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }

# ---- inputs --------------------------------------------------------------
MODE=""; AGENT=""; DRY_RUN=0; ANALYSIS_FILE=""; WATCHDOG_AUTHORITY=0
RUNNER_CMD=""; WATCHDOG_CMD=""
RELAY_FILE=""; MY_ROLE=""; ARTIFACT=""; ROLES=""; CLAUDE_AGENTS=""
TASK=""

while (($# > 0)); do
  case "$1" in
    --mode) MODE="${2:-}"; shift 2 ;;
    --agent) AGENT="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --analysis-file) ANALYSIS_FILE="${2:-}"; shift 2 ;;
    --watchdog-authority) WATCHDOG_AUTHORITY=1; shift ;;
    --runner-cmd) RUNNER_CMD="${2:-}"; shift 2 ;;
    --watchdog-cmd) WATCHDOG_CMD="${2:-}"; shift 2 ;;
    --relay-file) RELAY_FILE="${2:-}"; shift 2 ;;
    --my-role) MY_ROLE="${2:-}"; shift 2 ;;
    --artifact) ARTIFACT="${2:-}"; shift 2 ;;
    --roles) ROLES="${2:-}"; shift 2 ;;
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

# Map a role to its agent via --roles "R=agent,..."
role_agent() {
  local role="$1" pair k v
  IFS=',' read -ra _pairs <<<"$ROLES"
  for pair in "${_pairs[@]}"; do
    k="${pair%%=*}"; v="${pair#*=}"
    [[ "$k" == "$role" ]] && { printf '%s' "$v"; return; }
  done
}

is_claude_agent() {
  local a="$1" x
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
  [[ -n "$MY_ROLE" ]] || die "relay mode requires --my-role"
  next="$(relay_field NEXT)"; status="$(relay_field STATUS)"
  case "$status" in Approved|Closed) STOP=1 ;; esac
  if [[ "$next" == "$MY_ROLE" ]]; then
    MY_TURN=1
  elif [[ -n "$ROLES" && -n "$next" ]]; then
    ta="$(role_agent "$next")"
    if [[ -n "$ta" && "$ta" != "$AGENT" ]] && ! is_claude_agent "$ta"; then
      CROSS_MODEL=1; CROSS_AGENT="$ta"
    fi
  fi
  if ((MY_TURN)); then
    scope=("$RELAY_FILE"); [[ -n "$ARTIFACT" ]] && scope+=("$ARTIFACT")
    scope_clean "${scope[@]}" && CLEAN=1 || CLEAN=0
  fi
else # xyz
  [[ -n "$TASK" ]] || die "xyz mode requires --task"
  info="$("$TICK_BIN" info "$TASK" 2>/dev/null || true)"
  tstatus="$(printf '%s\n' "$info" | sed -n 's/^status:[[:space:]]*//p' | head -1)"
  tclaimer="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p' | head -1)"
  thandoff="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -1)"
  tpaths="$(printf '%s\n' "$info" | sed -n 's/^paths:[[:space:]]*//p' | head -1)"
  if [[ "$tstatus" == "open" && ( -z "$thandoff" || "$thandoff" == "$AGENT" ) ]]; then
    MY_TURN=1
  elif [[ "$tstatus" == "claimed" && "$tclaimer" == "$AGENT" ]]; then
    MY_TURN=1
  fi
  if ((MY_TURN)) && [[ -n "$tpaths" ]]; then
    IFS=',' read -ra _sc <<<"$tpaths"
    scope_clean "${_sc[@]}" && CLEAN=1 || CLEAN=0
  fi
fi

# ---- decision engine -----------------------------------------------------
DECISION=""; REASON=""
if ((STOP)); then
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
  run-runner)   eval "$RUNNER_CMD" ;;
  run-watchdog) eval "$WATCHDOG_CMD" ;;
  nudge-cross-model)
    printf 'poll: %s turn detected — manual nudge required: "take your turn on %s"\n' \
      "$CROSS_AGENT" "${RELAY_FILE:-<relay-file>}" >&2 ;;
  stop) exit 10 ;;
  idle) : ;;
esac
