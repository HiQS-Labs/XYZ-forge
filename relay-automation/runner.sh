#!/usr/bin/env bash
set -euo pipefail

# GH-84
ROOT_DIR="${RUNNER_ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TICK_BIN="${TICK_BIN:-"$ROOT_DIR/bin/tick"}"

usage() {
  cat <<'EOF'
Usage: relay-automation/runner.sh --task TASK-ID --agent AGENT [options] -- artifact...

Skeleton only:
- claimability guard: open+handoff_to=agent => claim, claimed+claimer=agent => resume, else poll
- clean-tree gate limited to declared artifact paths
- verdict grep from agent output
- round cap for bounded retries

Options:
  --task TASK-ID          Task to drive.
  --agent AGENT           Agent id to assert against handoff/claimer state.
  --round-cap N           Maximum agent rounds before exiting (default: 3).
  --poll-seconds N        Sleep between poll rounds (default: 30).
  --log-file PATH         File whose contents are scanned for a VERDICT line.
  --agent-cmd CMD         Command to run for each agent turn; stdout is captured to --log-file.
  --help                  Show this message.
  --                      Remaining args are artifact paths checked for a clean tree.
EOF
}

die() {
  printf 'runner: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "missing command: $1"
}

task_info() {
  "$TICK_BIN" info "$TASK_ID"
}

read_task_field() {
  local field="$1"
  task_info | awk -F':' -v key="$field" '$1 == key { sub(/^[[:space:]]+/, "", $2); print $2; exit }'
}

claimability_mode() {
  local status handoff_to claimer
  status="$(read_task_field "status")"
  handoff_to="$(read_task_field "handoff-to" || true)"
  claimer="$(read_task_field "claimer" || true)"

  if [[ "$status" == "open" && "$handoff_to" == "$AGENT" ]]; then
    printf 'claim\n'
    return
  fi

  if [[ "$status" == "claimed" && "$claimer" == "$AGENT" ]]; then
    printf 'resume\n'
    return
  fi

  printf 'poll\n'
}

ensure_clean_artifacts() {
  if ((${#ARTIFACTS[@]} == 0)); then
    die "artifact scope is required after --"
  fi

  git -C "$ROOT_DIR" diff --quiet -- "${ARTIFACTS[@]}" \
    || die "artifact paths have unstaged changes"
  git -C "$ROOT_DIR" diff --cached --quiet -- "${ARTIFACTS[@]}" \
    || die "artifact paths have staged changes"
}

claim_task() {
  local task_paths
  task_paths="$(read_task_field "paths")"
  [[ -n "$task_paths" ]] || die "task $TASK_ID has no declared paths"
  "$TICK_BIN" claim "$TASK_ID" --agent "$AGENT" --paths "$task_paths" >/dev/null
  run_agent_turn
}

resume_task() {
  run_agent_turn
}

run_agent_turn() {
  [[ -n "$AGENT_CMD" ]] || die "--agent-cmd is required"
  bash -lc "$AGENT_CMD" >"$LOG_FILE"
}

handle_verdict() {
  local verdict_line="$1"
  case "$verdict_line" in
    "VERDICT: PASS")
      "$TICK_BIN" done "$TASK_ID" --agent "$AGENT" >/dev/null
      return 0
      ;;
    "VERDICT: FAIL")
      return 1
      ;;
    "VERDICT: PARKED")
      return 3
      ;;
    *)
      die "unexpected verdict line: $verdict_line"
      ;;
  esac
}

extract_verdict() {
  local verdict
  verdict="$(grep -E 'VERDICT:( PASS| FAIL| PARKED)\b' "$LOG_FILE" | tail -n 1 || true)"
  [[ -n "$verdict" ]] || die "missing VERDICT line in $LOG_FILE"
  printf '%s\n' "$verdict"
}

poll_once() {
  printf 'runner: %s not claimable for %s; polling again in %ss\n' "$TASK_ID" "$AGENT" "$POLL_SECONDS" >&2
  sleep "$POLL_SECONDS"
}

TASK_ID=""
AGENT=""
ROUND_CAP=3
POLL_SECONDS=30
LOG_FILE=""
AGENT_CMD=""
ARTIFACTS=()

while (($# > 0)); do
  case "$1" in
    --task)
      TASK_ID="${2:-}"
      shift 2
      ;;
    --agent)
      AGENT="${2:-}"
      shift 2
      ;;
    --round-cap)
      ROUND_CAP="${2:-}"
      shift 2
      ;;
    --poll-seconds)
      POLL_SECONDS="${2:-}"
      shift 2
      ;;
    --log-file)
      LOG_FILE="${2:-}"
      shift 2
      ;;
    --agent-cmd)
      AGENT_CMD="${2:-}"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    --)
      shift
      ARTIFACTS=("$@")
      break
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$TASK_ID" ]] || die "--task is required"
[[ -n "$AGENT" ]] || die "--agent is required"
[[ -n "$LOG_FILE" ]] || die "--log-file is required"
[[ -f "$LOG_FILE" ]] || die "log file does not exist: $LOG_FILE"
[[ -n "$AGENT_CMD" ]] || die "--agent-cmd is required"

require_command git
require_command bash
require_command grep
require_command "$TICK_BIN"

for ((round = 1; round <= ROUND_CAP; round++)); do
  ensure_clean_artifacts

  case "$(claimability_mode)" in
    claim)
      claim_task
      ;;
    resume)
      resume_task
      ;;
    poll)
      poll_once
      continue
      ;;
    *)
      die "unexpected claimability mode"
      ;;
  esac

  verdict="$(extract_verdict)"
  if handle_verdict "$verdict"; then
    exit 0
  fi

  rc=$?
  if ((rc == 3)); then
    exit 3
  fi
done

die "round cap exceeded after $ROUND_CAP attempts"
