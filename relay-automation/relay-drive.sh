#!/usr/bin/env bash
set -euo pipefail
#
# relay-drive.sh — Phase 4(a): supervise a /relay thread to termination, with the
# turn-token held as a tick **RELAY-TURN task** (claim / ping / release --to / done).
#
# This is the SUPERVISOR, not the turn-taker. Each turn is taken by --agent-cmd
# (a fake in tests; the baton/live window in Option B; a headless CLI in a future
# Option A). The turn-taker owns the work + thread mutation — it claims/resumes the
# RELAY-TURN task as RELAY_AGENT, `tick ping`s it, appends its block + sets the
# file's STATUS/verdict, then **`tick release RELAY-TURN --to <other>`** to hand off
# (or **`tick done RELAY-TURN`** + STATUS: Approved on the final turn), and commits.
#
# Whose-turn is the tick token (so the Phase-1 handoff-exclusive rule applies and the
# Phase-2 watchdog can see a stalled turn). The human-readable thread's STATUS is the
# terminal (Approved/Closed) signal. The supervisor only:
#   - reads the RELAY-TURN actor + the file STATUS to decide whether to continue,
#   - invokes the turn-taker for the current actor,
#   - enforces a round cap, and
#   - escalates on no-progress (token actor didn't move) instead of looping forever.
#
# Turn-taker env: RELAY_FILE, RELAY_TASK, RELAY_AGENT (the current actor).
# Exit: 0 = relay closed Approved/Closed · 3 = no-progress · 4 = cap / closed-not-approved · 2 = usage.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TICK_BIN="${TICK_BIN:-"$ROOT_DIR/bin/tick"}"

usage() {
  cat <<'EOF'
Usage: relay-automation/relay-drive.sh --relay-file PATH --agent-cmd CMD [options]

  --relay-file PATH   The relay thread (reads STATUS: as the terminal signal).
  --agent-cmd CMD     Turn-taker; invoked with env RELAY_FILE + RELAY_TASK + RELAY_AGENT.
                      Must take the turn on the RELAY-TURN task (claim/ping/append/
                      release --to <other> | done) and commit.
  --relay-task ID     The relay turn-token task (default: RELAY-TURN).
  --round-cap N       Max turns before escalating (default: 6).
  --dry-run           Print the turn it WOULD drive next, then stop (no invocation).
  --help
EOF
}

die() { printf 'relay-drive: %s\n' "$*" >&2; exit 2; }

RELAY_FILE=""; AGENT_CMD=""; RELAY_TASK="RELAY-TURN"; ROUND_CAP=6; DRY_RUN=0
while (($# > 0)); do
  case "$1" in
    --relay-file) RELAY_FILE="${2:-}"; shift 2 ;;
    --agent-cmd) AGENT_CMD="${2:-}"; shift 2 ;;
    --relay-task) RELAY_TASK="${2:-}"; shift 2 ;;
    --round-cap) ROUND_CAP="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[[ -n "$RELAY_FILE" ]] || { usage; die "--relay-file is required"; }
[[ -f "$RELAY_FILE" ]] || die "relay file does not exist: $RELAY_FILE"
[[ -n "$AGENT_CMD" || "$DRY_RUN" -eq 1 ]] || { usage; die "--agent-cmd is required"; }

file_status() { sed -n 's/^STATUS:[[:space:]]*//p' "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
terminal_status() { case "$1" in Approved|Closed) return 0 ;; *) return 1 ;; esac; }

# Current actor of the RELAY-TURN token: claimer (if claimed) else handoff_to (if
# open) else "" (done/missing). Echoes "<status>\t<actor>".
token_state() {
  local info status claimer handoff actor
  info="$("$TICK_BIN" info "$RELAY_TASK" 2>/dev/null || true)"
  status="$(printf '%s\n' "$info"  | sed -n 's/^status:[[:space:]]*//p'     | head -1)"
  claimer="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p'    | head -1)"
  handoff="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -1)"
  case "$status" in
    claimed) actor="$claimer" ;;
    open)    actor="$handoff" ;;
    *)       actor="" ;;
  esac
  printf '%s\t%s\n' "$status" "$actor"
}

round=0
while ((round < ROUND_CAP)); do
  s="$(file_status)"
  IFS=$'\t' read -r tstatus actor < <(token_state)

  # Terminal CLOSE requires AGREEMENT: file STATUS terminal AND the RELAY-TURN
  # token no longer live (done/gone). file-terminal-but-token-live is a leaked
  # close — escalate, never report success. (Codex r1 Blocker.)
  if terminal_status "$s"; then
    if [[ -n "$actor" ]]; then
      printf 'relay-drive: STATUS %s but RELAY-TURN still live (%s/%s) — close mismatch, escalating\n' "$s" "$tstatus" "$actor" >&2
      exit 4
    fi
    printf 'relay-drive: relay terminated (STATUS: %s, token done) after %d turn(s)\n' "$s" "$round"
    exit 0
  fi

  # file not terminal but the token is gone/done → also a mismatch.
  if [[ -z "$actor" ]]; then
    printf 'relay-drive: RELAY-TURN has no actor (token %s) but STATUS=%s — escalating\n' "${tstatus:-missing}" "$s" >&2
    exit 4
  fi

  if ((DRY_RUN)); then
    printf 'relay-drive: WOULD drive turn for agent: %s (token %s, STATUS: %s)\n' "$actor" "$tstatus" "$s"; exit 0
  fi

  prev="$tstatus:$actor"
  RELAY_FILE="$RELAY_FILE" RELAY_TASK="$RELAY_TASK" RELAY_AGENT="$actor"
  export RELAY_FILE RELAY_TASK RELAY_AGENT
  eval "$AGENT_CMD"
  round=$((round + 1))

  # No-progress guard (skipped once terminal — the close check at loop top handles that).
  IFS=$'\t' read -r ntstatus nactor < <(token_state)
  if ! terminal_status "$(file_status)" && [[ "$ntstatus:$nactor" == "$prev" ]]; then
    printf 'relay-drive: no progress after %s turn (token still %s) — escalating\n' "$actor" "$prev" >&2
    exit 3
  fi
done

# Cap reached: success only if file terminal AND token not live (same agreement).
s="$(file_status)"; IFS=$'\t' read -r tstatus actor < <(token_state)
if terminal_status "$s" && [[ -z "$actor" ]]; then
  printf 'relay-drive: relay terminated (STATUS: %s)\n' "$s"; exit 0
fi
printf 'relay-drive: round cap (%d) exceeded (STATUS: %s, token actor: %s) — escalating\n' "$ROUND_CAP" "$s" "${actor:-none}" >&2
exit 4
