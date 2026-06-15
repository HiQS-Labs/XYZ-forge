#!/usr/bin/env bash
set -euo pipefail
#
# relay-drive.sh — Phase 4b: supervise a /relay Producer<->Reviewer thread to
# termination (Option B: the turn itself is taken by the baton / live window).
#
# This is the SUPERVISOR, not the turn-taker. Each turn is taken by --agent-cmd
# (a fake in tests; the baton/live polling window in real Option B; a headless
# CLI in a future Option A). The turn-taker owns thread mutation — it appends its
# block, flips NEXT, sets STATUS, commits — exactly as the embedded relay
# "▶ TAKE YOUR TURN" instructions require. The supervisor only:
#   - reads NEXT / STATUS to decide whether to continue,
#   - invokes the turn-taker for whoever NEXT names,
#   - enforces a round cap, and
#   - escalates on no-progress (NEXT didn't move after a turn) instead of looping forever.
#
# Terminates when STATUS is Approved/Closed. Distinct from runner.sh (a single
# xyz build/agent turn with a PASS/FAIL/PARKED verdict).
#
# The turn-taker is invoked with env: RELAY_FILE, RELAY_ROLE (the NEXT role).
#
# Exit: 0 = relay closed Approved/Closed · 3 = no-progress escalation
#       · 4 = round cap exceeded without Approved · 2 = usage.

usage() {
  cat <<'EOF'
Usage: relay-automation/relay-drive.sh --relay-file PATH --agent-cmd CMD [options]

  --relay-file PATH   The relay thread to drive (reads/loops on NEXT: / STATUS:).
  --agent-cmd CMD     Turn-taker command; invoked with env RELAY_FILE + RELAY_ROLE.
                      It must take the turn (append block, flip NEXT, set STATUS, commit).
  --round-cap N       Max turns before escalating (default: 6).
  --dry-run           Print the turn it WOULD drive next, then stop (no invocation).
  --help
EOF
}

die() { printf 'relay-drive: %s\n' "$*" >&2; exit 2; }

RELAY_FILE=""; AGENT_CMD=""; ROUND_CAP=6; DRY_RUN=0
while (($# > 0)); do
  case "$1" in
    --relay-file) RELAY_FILE="${2:-}"; shift 2 ;;
    --agent-cmd) AGENT_CMD="${2:-}"; shift 2 ;;
    --round-cap) ROUND_CAP="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[[ -n "$RELAY_FILE" ]] || { usage; die "--relay-file is required"; }
[[ -f "$RELAY_FILE" ]] || die "relay file does not exist: $RELAY_FILE"
[[ -n "$AGENT_CMD" || "$DRY_RUN" -eq 1 ]] || { usage; die "--agent-cmd is required"; }

field() { sed -n "s/^$1:[[:space:]]*//p" "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
terminal_status() { case "$1" in Approved|Closed) return 0 ;; *) return 1 ;; esac; }
terminal_next() { [[ -z "$1" || "$1" == —* || "$1" == "-"* ]]; }   # "— (relay closed)" etc.

round=0
while ((round < ROUND_CAP)); do
  status="$(field STATUS)"
  if terminal_status "$status"; then
    printf 'relay-drive: relay terminated (STATUS: %s) after %d turn(s)\n' "$status" "$round"
    exit 0
  fi
  next="$(field NEXT)"
  if terminal_next "$next"; then
    # NEXT closed but STATUS not Approved/Closed — treat as done-but-not-approved.
    printf 'relay-drive: NEXT is terminal but STATUS=%s — stopping\n' "$status" >&2
    terminal_status "$status" && exit 0 || exit 4
  fi

  if ((DRY_RUN)); then
    printf 'relay-drive: WOULD drive turn for role: %s (STATUS: %s)\n' "$next" "$status"
    exit 0
  fi

  # Hand the turn to the turn-taker (baton / fake / CLI). It mutates the thread.
  RELAY_FILE="$RELAY_FILE" RELAY_ROLE="$next"
  export RELAY_FILE RELAY_ROLE
  eval "$AGENT_CMD"

  round=$((round + 1))

  # No-progress guard: the turn-taker must have moved NEXT (or terminated STATUS).
  new_next="$(field NEXT)"; new_status="$(field STATUS)"
  if [[ "$new_next" == "$next" ]] && ! terminal_status "$new_status"; then
    printf 'relay-drive: no progress after %s turn (NEXT still "%s") — escalating\n' "$next" "$next" >&2
    exit 3
  fi
done

# Cap reached. Success only if the relay actually closed Approved/Closed.
status="$(field STATUS)"
if terminal_status "$status"; then
  printf 'relay-drive: relay terminated (STATUS: %s)\n' "$status"
  exit 0
fi
printf 'relay-drive: round cap (%d) exceeded without Approved — escalating\n' "$ROUND_CAP" >&2
exit 4
