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
# Exit: 0 = relay closed Approved/Closed · 3 = no-progress (stall) · 4 = cap / closed-not-approved /
#       escalated-to-human-by-design (STATUS: Escalated) · 2 = usage.

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
  --target-root DIR   The target git repository root (must be an existing git repo).
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
    --target-root) TARGET_ROOT="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[[ -n "$RELAY_FILE" ]] || { usage; die "--relay-file is required"; }
[[ -n "$AGENT_CMD" || "$DRY_RUN" -eq 1 ]] || { usage; die "--agent-cmd is required"; }

if [[ -n "${TARGET_ROOT+set}" ]]; then
  [[ -n "$TARGET_ROOT" ]] || die "--target-root requires a non-empty path"   # else git -C '' falls back to CWD
  git -C "$TARGET_ROOT" rev-parse --show-toplevel >/dev/null 2>&1 \
    || die "invalid target root (not a git repo): $TARGET_ROOT"
  export RELAY_TARGET_ROOT="$TARGET_ROOT"
fi

# Resolve --relay-file AFTER --target-root is known. With --target-root the thread lives in the
# TARGET repo, so a repo-relative path must resolve relative to the target root, not the harness CWD
# (GH-18 #2): if it isn't found as given but exists under --target-root, use that. Absolute paths and
# CWD-relative paths that already resolve are unchanged. (ALLOW_PATHS is already target-relative — the
# shim resolves it against RELAY_TARGET_ROOT in relay-turn-lib.sh.)
if [[ ! -f "$RELAY_FILE" && -n "${TARGET_ROOT:-}" && "$RELAY_FILE" != /* && -f "$TARGET_ROOT/$RELAY_FILE" ]]; then
  RELAY_FILE="$TARGET_ROOT/$RELAY_FILE"
fi
[[ -f "$RELAY_FILE" ]] || die "relay file does not exist: $RELAY_FILE"

# Containment default for unattended/driven runs: isolate the turn-taker in a throwaway worktree
# (ROOT@HEAD) so an off-task model's stray creations/renames can't reach the real tree. The leaf
# shims (codex/agy/claude-turn.sh) read RELAY_WORKTREE_ISOLATION; exporting it here makes every
# DRIVEN turn contained by default. Opt out per run with RELAY_WORKTREE_ISOLATION=0. (Direct/attended
# shim use keeps the leaf default OFF — only the orchestration layer defaults it ON.)
: "${RELAY_WORKTREE_ISOLATION:=1}"; export RELAY_WORKTREE_ISOLATION

file_status() { sed -n 's/^STATUS:[[:space:]]*//p' "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
terminal_status() { case "$1" in Approved|Closed) return 0 ;; *) return 1 ;; esac; }
# Escalated is TERMINAL BY DESIGN: the reviewer handed back to a human (e.g. at the round cap),
# typically WITHOUT releasing the token. The explicit status IS the intent signal — a true stall
# leaves STATUS unchanged — so this is NOT a no-progress failure. Reported as a clean, distinct
# outcome (exit 4 = terminal/not-approved) so a correct handback doesn't read as a stall (GH-18 #5).
escalated_status() { case "$1" in Escalated) return 0 ;; *) return 1 ;; esac; }

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

  # Escalated = terminal by design (handback to human); the token may legitimately stay live, so this
  # is checked BEFORE the no-actor branch. A clean, distinct outcome — not a stall (GH-18 #5).
  if escalated_status "$s"; then
    printf 'relay-drive: relay escalated to human by design (STATUS: %s, token %s) after %d turn(s)\n' "$s" "${actor:-done}" "$round" >&2
    exit 4
  fi

  # file not terminal but the token is gone/done → also a mismatch.
  if [[ -z "$actor" ]]; then
    printf 'relay-drive: %s has no actor (token %s) but STATUS=%s — escalating\n' "$RELAY_TASK" "${tstatus:-missing}" "$s" >&2
    # A `done` token under a non-terminal thread is the classic reused-token collision (GH-18 #1):
    # a prior relay spent this id. Point at the fix so recovery isn't a scavenger hunt.
    [[ "$tstatus" == "done" ]] && printf "  → '%s' is spent from a prior relay; seed + drive with a fresh --relay-task (e.g. RELAY-%s)\n" "$RELAY_TASK" "$(basename "$RELAY_FILE" .md)" >&2
    exit 4
  fi

  if ((DRY_RUN)); then
    printf 'relay-drive: WOULD drive turn for agent: %s (token %s, STATUS: %s)\n' "$actor" "$tstatus" "$s"; exit 0
  fi

  prev="$tstatus:$actor"
  RELAY_FILE="$RELAY_FILE" RELAY_TASK="$RELAY_TASK" RELAY_AGENT="$actor"
  export RELAY_FILE RELAY_TASK RELAY_AGENT
  # Invoke the turn-taker. A bare executable path (even absolute or containing spaces, e.g. a clone
  # under ".../GH Repos/...") is run DIRECTLY so it survives spaces; a full command string
  # (env-prefixed, shell-quoted, or %q-escaped by a caller) falls back to eval. This fixes spaced
  # absolute --agent-cmd paths without breaking the command-string contract callers/tests rely on.
  if [[ -x "$AGENT_CMD" ]]; then
    "$AGENT_CMD"
  else
    eval "$AGENT_CMD"
  fi
  round=$((round + 1))

  # No-progress guard (skipped once terminal — the close check at loop top handles that).
  IFS=$'\t' read -r ntstatus nactor < <(token_state)
  ns="$(file_status)"
  # A by-design Escalated handback this turn is terminal, NOT a stall — even if the reviewer left the
  # token live. Catch it before the no-progress guard so it doesn't read as exit 3 (GH-18 #5).
  if escalated_status "$ns"; then
    printf 'relay-drive: relay escalated to human by design (STATUS: %s, token %s:%s) after %d turn(s)\n' "$ns" "$ntstatus" "$nactor" "$round" >&2
    exit 4
  fi
  if ! terminal_status "$ns" && [[ "$ntstatus:$nactor" == "$prev" ]]; then
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
