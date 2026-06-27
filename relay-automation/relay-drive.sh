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
CONSULT_SH="${CONSULT_SH:-"$ROOT_DIR/relay-automation/consult.sh"}"

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
  --consult-verify    After each turn, invoke consult.sh to independently challenge the
                      turn-taker's VERDICT. Fires 1-2 real API calls per turn (codex +
                      gemini). Do NOT use in CI or budget-sensitive runs.
  --dry-run           Print the turn it WOULD drive next, then stop (no invocation).
  --help
EOF
}

die() { printf 'relay-drive: %s\n' "$*" >&2; exit 2; }

RELAY_FILE=""; AGENT_CMD=""; RELAY_TASK="RELAY-TURN"; ROUND_CAP=6; DRY_RUN=0; CONSULT_VERIFY=0
while (($# > 0)); do
  case "$1" in
    --relay-file) RELAY_FILE="${2:-}"; shift 2 ;;
    --agent-cmd) AGENT_CMD="${2:-}"; shift 2 ;;
    --relay-task) RELAY_TASK="${2:-}"; shift 2 ;;
    --round-cap) ROUND_CAP="${2:-}"; shift 2 ;;
    --target-root) TARGET_ROOT="${2:-}"; shift 2 ;;
    --consult-verify) CONSULT_VERIFY=1; shift ;;
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

# GH-32 #1: under worktree isolation the turn-taker runs in a throwaway worktree at ROOT@HEAD, so a
# relay file that isn't committed at HEAD is INVISIBLE to it (untracked-not-ignored — relay-system/ is
# tracked here except two specific files). The reviewer then "finds nothing" and silently does no work.
# Warn loudly with the exact remedy; never block (a non-isolated run is free to use an uncommitted file,
# and a relay file outside any git repo is fine too). Mirrors the cross-repo warning style in the shims.
warn_if_relay_file_untracked() {
  [[ "${RELAY_WORKTREE_ISOLATION:-1}" != 0 ]] || return 0
  local dir prefix rel
  dir="$(cd "$(dirname "$RELAY_FILE")" 2>/dev/null && pwd)" || return 0   # not a real dir → skip
  # --show-prefix yields the repo-root-relative path of $dir (empty at root); building the relative
  # path this way avoids subtracting an absolute toplevel, which breaks under macOS /var → /private/var
  # symlinks (logical pwd vs git's physical toplevel).
  prefix="$(git -C "$dir" rev-parse --show-prefix 2>/dev/null)" || return 0  # not in a git repo → skip
  rel="${prefix}$(basename "$RELAY_FILE")"
  git -C "$dir" cat-file -e "HEAD:$rel" 2>/dev/null && return 0           # present at HEAD → visible
  printf 'relay-drive: WARNING — relay file is not committed at HEAD: %s\n' "$rel" >&2
  printf '  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, so this untracked\n' >&2
  printf '  file is INVISIBLE to the reviewer (it will find nothing and do no work). Remedy: commit\n' >&2
  printf '  the relay file first, or re-run with RELAY_WORKTREE_ISOLATION=0.\n' >&2
}
warn_if_relay_file_untracked

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

  # --consult-verify: independent second opinion after each turn.
  # Invokes consult.sh (codex + gemini) to challenge the turn-taker's self-reported VERDICT.
  # On divergence: appends a conflict-warning advisory block, sets STATUS: Escalated, exits 4.
  if ((CONSULT_VERIFY)); then
    _cv_taker_verdict="$(sed -n '/^## Log/,$p' "$RELAY_FILE" | grep -E '^VERDICT: ' | tail -1 | sed 's/^VERDICT: //')"
    _cv_label="consult-verify-$(basename "$RELAY_FILE" .md)-r${round}"
    _cv_out_dir="$ROOT_DIR/relay-system/$(date +%F)"
    # Write prompt to a temp file — avoids nested variable expansion fragility inside $()
    _cv_prompt_file="$(mktemp -t cv-prompt.XXXXXX)"
    printf 'Review the most recent log block in this relay file. Does the turn-taker'"'"'s VERDICT match their stated evidence in the Basis: line? Reply with exactly one of: AGREE-PASS (verdict supported), AGREE-FAIL (verdict supported), or DISAGREE (verdict not supported by evidence). One token only.\n\n=== RELAY FILE ===\n' > "$_cv_prompt_file"
    cat "$RELAY_FILE" >> "$_cv_prompt_file"
    _cv_consult_out="$(CONSULT_ROOT="$ROOT_DIR" "$CONSULT_SH" \
      --prompt-file "$_cv_prompt_file" \
      --label "$_cv_label" \
      --out "$_cv_out_dir" 2>/dev/null)" || true
    rm -f "$_cv_prompt_file"

    # Parse advisor verdicts from transcript file paths in consult stdout ([ok] model -> path)
    _cv_diverged=0; _cv_advisor_summary=""
    while IFS= read -r _cv_line; do
      _cv_path="$(printf '%s\n' "$_cv_line" | sed -n 's/.*-> //p' | sed 's/[[:space:]]*$//')"
      [[ -z "$_cv_path" || ! -f "$_cv_path" ]] && continue
      _cv_model="$(printf '%s\n' "$_cv_line" | sed -n 's/.*\[ok\][[:space:]]*//p' | sed 's/[[:space:]]*->.*$//' | sed 's/[[:space:]]*$//')"
      _cv_response="$(grep -oE '(AGREE-PASS|AGREE-FAIL|DISAGREE)' "$_cv_path" | head -1 || true)"
      [[ -z "$_cv_response" ]] && _cv_response="(no verdict found)"
      _cv_advisor_summary+="${_cv_model:-advisor}: $_cv_response"$'\n'
      [[ "$_cv_response" == "DISAGREE" ]] && _cv_diverged=1
    done < <(printf '%s\n' "$_cv_consult_out")

    if ((_cv_diverged)); then
      printf 'relay-drive: consult-verify DIVERGENCE after %s turn (taker: %s)\n%s' \
        "$actor" "$_cv_taker_verdict" "$_cv_advisor_summary" >&2
      # Append conflict-warning advisory block (MUST include VERDICT: + Basis: for bin/validate-relay-block)
      printf '\n### consult-verify advisory — divergence detected (round %d)\n\nVERDICT: FAIL\nBasis: consult disagreed with turn-taker verdict "%s" (see transcripts)\n%s\nTurn-taker self-reported: %s\n' \
        "$round" "$_cv_taker_verdict" "$_cv_advisor_summary" "$_cv_taker_verdict" >> "$RELAY_FILE"
      # Set STATUS: Escalated
      sed -i '' 's/^STATUS:[[:space:]]*.*/STATUS: Escalated/' "$RELAY_FILE"
      _cv_relay_repo="$(git -C "$(dirname "$RELAY_FILE")" rev-parse --show-toplevel 2>/dev/null || echo "$ROOT_DIR")"
      git -C "$_cv_relay_repo" add "$RELAY_FILE" 2>/dev/null || true
      git -C "$_cv_relay_repo" commit -m "relay-drive: consult-verify divergence escalation (round $round)" 2>/dev/null || true
      printf 'relay-drive: relay escalated by consult-verify (STATUS: Escalated) after %d turn(s)\n' "$round" >&2
      exit 4
    else
      printf 'relay-drive: consult-verify AGREED after %s turn (taker: %s)\n' "$actor" "$_cv_taker_verdict" >&2
    fi
  fi

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
