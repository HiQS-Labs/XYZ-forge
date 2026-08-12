#!/usr/bin/env bash
# marathon-recover.sh [repo-path] — report crash residue without changing it.
#
# Cross-references each marathon phase's RELAY.md state, its tick approval event,
# and commits reachable from the target's current HEAD.  An Open/escalated phase
# with a landed commit but no marathon.phase.approved event is an ungated commit:
# the turn's work was committed before the marathon's pre-advance gate ran.
#
# Reads both marathon-system/ (current) and phases/ (legacy GH-484 location).
# Writes NO state to the target repo.
set -euo pipefail

usage() {
  printf 'Usage: marathon-recover.sh [repo-path]\n' >&2
  printf 'Report possible ungated marathon commits after an interrupted run.\n' >&2
  exit 2
}

case "${1:-}" in
  -h|--help) usage ;;
esac
[ "$#" -le 1 ] || usage

REPO="${1:-.}"
[ -d "$REPO" ] || { printf 'REPO: %s\nSTATE: GONE (path does not exist on disk)\n' "$REPO"; exit 0; }
REPO="$(cd "$REPO" && pwd)"

# Resolve this script's real directory (bash 3.2 / macOS safe — no readlink -f).
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"

# shellcheck source=relay-automation/driver-lock-lib.sh
. "$SELF_DIR/driver-lock-lib.sh"

status_for_relay() {
  local relay="$1" status
  status="$(sed -n 's/^STATUS:[[:space:]]*//p' "$relay" | head -1)"
  printf '%s' "${status:-missing}"
}

task_for_relay() {
  local relay="$1" task
  # Marathon writes this task identifier into the relay template's metadata line.
  task="$(sed -n 's/.*marathon-drive:.*task=\([^[:space:]]*\).*/\1/p' "$relay" | head -1)"
  printf '%s' "$task"
}

has_approved_event() {
  local task="$1" event line event_type event_task
  [ -d "$REPO/.tick/events" ] || return 1
  for event in "$REPO/.tick/events"/*.jsonl; do
    [ -f "$event" ] || continue
    # Extract both fields instead of interpolating a task identifier into a regex. Tick writes
    # compact JSON, while the whitespace classes keep manually retained logs readable too.
    while IFS= read -r line; do
      event_type="$(printf '%s\n' "$line" | sed -n 's/.*"type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
      event_task="$(printf '%s\n' "$line" | sed -n 's/.*"task"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
      if [ "$event_type" = 'marathon.phase.approved' ] && [ "$event_task" = "$task" ]; then
        return 0
      fi
    done < "$event"
  done
  return 1
}

reachable_phase_commit() {
  local task="$1" phase="$2" line
  git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  while IFS= read -r line; do
    case "$line" in
      *"relay(${task}): "*|*"marathon: phase ${phase} "*)
        printf '%s' "$line"
        return 0
        ;;
    esac
  done < <(git -C "$REPO" log --format='%H%x09%s' HEAD 2>/dev/null)
  return 1
}

print_lock_state() {
  local lock pid
  lock="$(driver_lock_path_for_repo "$REPO")"
  if [ ! -d "$lock" ]; then
    printf 'DRIVER LOCK: IDLE (no lock at %s)\n' "$lock"
    return
  fi

  pid=""
  [ -f "$lock/pid" ] && pid="$(tr -d '\r\n' < "$lock/pid" 2>/dev/null || true)"
  case "$pid" in
    ''|*[!0-9]*) printf 'DRIVER LOCK: STALE (missing or invalid pid; %s)\n' "$lock" ;;
    *)
      if kill -0 "$pid" 2>/dev/null; then
        printf 'DRIVER LOCK: LIVE (pid %s; %s)\n' "$pid" "$lock"
      else
        printf 'DRIVER LOCK: STALE (pid %s is not live; %s)\n' "$pid" "$lock"
      fi
      ;;
  esac
}

printf 'REPO: %s\n' "$REPO"
print_lock_state

phase_count=0
for phase_dir in "$REPO/marathon-system" "$REPO/phases"; do
  [ -d "$phase_dir" ] || continue
  for relay in "$phase_dir"/*/RELAY.md; do
    [ -f "$relay" ] || continue
    phase_count=$((phase_count + 1))
    phase="$(basename "$(dirname "$relay")")"
    status="$(status_for_relay "$relay")"
    task="$(task_for_relay "$relay")"

    printf '\nPHASE: %s\nSTATUS: %s\nRELAY: %s\n' "$phase" "$status" "$relay"
    if [ -z "$task" ]; then
      printf 'TASK: missing (cannot cross-reference tick events or commits)\n'
      continue
    fi
    printf 'TASK: %s\n' "$task"

    if has_approved_event "$task"; then
      printf 'APPROVAL: recorded (marathon.phase.approved)\n'
      continue
    fi
    printf 'APPROVAL: missing (no marathon.phase.approved event)\n'

    # Approved/Closed phases are terminal; an absent event is worth surfacing but is not the
    # crash-window finding this tool labels ungated.
    case "$status" in
      Approved|Closed)
        printf 'RECOVERY: no ungated finding (terminal relay status)\n'
        ;;
      *)
        if commit="$(reachable_phase_commit "$task" "$phase")"; then
          printf 'UNGATED COMMIT: %s\n' "$commit"
          printf 'RECOVERY: UNVERIFIED — re-run the phase gate or revert before trusting this commit.\n'
        else
          printf 'RECOVERY: no reachable phase commit found\n'
        fi
        ;;
    esac
  done
done

[ "$phase_count" -gt 0 ] || printf '\n(no marathon-system/*/RELAY.md or phases/*/RELAY.md found)\n'
