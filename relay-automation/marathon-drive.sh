#!/usr/bin/env bash
set -euo pipefail
#
# marathon-drive.sh — Phase 3: single-phase headless relay loop.
#
# Renders phases/p1/RELAY.md from the phase brief, seeds the tick token (handoff → builder),
# calls relay-drive.sh unmodified, runs the pre-advance gate, emits phase events, and saves
# the transcript. Does NOT reimplement any loop logic — relay-drive.sh IS the loop.
#
# Usage:
#   relay-automation/marathon-drive.sh \
#     --phase-brief <FILE>       phase brief (markdown; baked into the relay template)
#     --reviewer    <AGENT_ID>   reviewer agent (codex* or gemini*)
#     [--builder    <AGENT_ID>]  builder agent (default: claude)
#     [--round-cap  <N>]         relay-drive round cap (default: 5 = 2*2+1)
#     [--pre-advance-cmd <CMD>]  gate before phase.approved (default: bash validate.sh)
#     [--phases-dir <DIR>]       where to create phases/p1/ (default: <repo-root>/phases)
#     [--relay-task <ID>]        tick task name (default: MARATHON-P1-TURN)
#     [--artifact <PATHS>]       comma-separated repo-relative file(s) the builder may create/edit
#                                beyond the relay file (passed to the shims as ALLOW_PATHS). Omit for
#                                a relay-only phase (conversation → approval, no source edit).
#     [--dry-run]                render relay file and print tick seed cmd, then exit
#
# Environment overrides (for tests):
#   MARATHON_ROOT         — git repo root (default: parent of this script's dir)
#   MARATHON_RELAY_DRIVE  — relay-drive.sh path (default: this script's dir/relay-drive.sh)
#   MARATHON_AGENT_CMD    — --agent-cmd value (default: this script's dir/marathon-agent.sh)
#   TICK_BIN              — tick binary (default: <repo-root>/bin/tick)
#
# Exit: 0 phase approved + gate passed · 3 relay no-progress · 4 relay cap/mismatch ·
#        5 pre-advance gate failed · 2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${MARATHON_ROOT:-"$(cd "$HERE/.." && pwd)"}"
TICK_BIN="${TICK_BIN:-"$ROOT/bin/tick"}"
RELAY_DRIVE_BIN="${MARATHON_RELAY_DRIVE:-"$HERE/relay-drive.sh"}"
AGENT_CMD="${MARATHON_AGENT_CMD:-"$HERE/marathon-agent.sh"}"

die()  { printf 'marathon-drive: %s\n' "$*" >&2; exit 2; }
log()  { printf 'marathon-drive: %s\n' "$*"; }

usage() {
  cat <<'EOF'
Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]

  --phase-brief FILE      Phase brief markdown baked into the relay template (required).
  --reviewer AGENT        Reviewer agent id; must start with 'codex' or 'gemini' (required).
  --builder AGENT         Builder agent id (default: claude).
  --round-cap N           relay-drive turn cap (default: 5).
  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).
  --phases-dir DIR        Where to create phases/p1/ (default: <repo-root>/phases).
  --relay-task ID         Tick task name (default: MARATHON-P1-TURN).
  --artifact PATHS        Comma-separated repo-relative file(s) the builder may create/edit beyond
                          the relay file (ALLOW_PATHS for the turn-takers). Omit for a relay-only phase.
  --dry-run               Render the relay file and print the tick seed; exit without running.
EOF
}

PHASE_BRIEF_FILE=""
BUILDER="claude"
REVIEWER=""
ROUND_CAP=5
PRE_ADVANCE_CMD=""   # resolved to default after ROOT is set
PHASES_DIR=""        # resolved to default after ROOT is set
RELAY_TASK="MARATHON-P1-TURN"
ARTIFACT_PATHS=""    # comma-separated repo-relative file(s) the builder may create/edit (beyond RELAY.md)
DRY_RUN=0

while (($# > 0)); do
  case "$1" in
    --phase-brief)     PHASE_BRIEF_FILE="${2:-}"; shift 2 ;;
    --builder)         BUILDER="${2:-}"; shift 2 ;;
    --reviewer)        REVIEWER="${2:-}"; shift 2 ;;
    --round-cap)       ROUND_CAP="${2:-}"; shift 2 ;;
    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
    --relay-task)      RELAY_TASK="${2:-}"; shift 2 ;;
    --artifact)        ARTIFACT_PATHS="${2:-}"; shift 2 ;;
    --dry-run)         DRY_RUN=1; shift ;;
    --help)            usage; exit 0 ;;
    *)                 die "unknown argument: $1" ;;
  esac
done

[[ -n "$PHASE_BRIEF_FILE" ]] || { usage; die "--phase-brief FILE required"; }
[[ -f "$PHASE_BRIEF_FILE" ]] || die "phase brief not found: $PHASE_BRIEF_FILE"
[[ -n "$REVIEWER"         ]] || { usage; die "--reviewer AGENT required"; }
[[ -n "$BUILDER"          ]] || die "--builder cannot be empty"

PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
PRE_ADVANCE_CMD="${PRE_ADVANCE_CMD:-"bash $ROOT/validate.sh"}"

# Map builder/reviewer to _AGENT env vars for marathon-agent.sh routing.
# Builder is always Claude in Phase 3; reviewer is Codex or Gemini (detected by name prefix).
export CLAUDE_AGENT="$BUILDER"
export MARATHON_BUILDER="$BUILDER"
export MARATHON_REVIEWER="$REVIEWER"
case "$REVIEWER" in
  codex*)  export CODEX_AGENT="$REVIEWER"; export GEMINI_AGENT="" ;;
  gemini*) export GEMINI_AGENT="$REVIEWER"; export CODEX_AGENT="" ;;
  *)       die "reviewer '$REVIEWER' not recognized — must start with 'codex' or 'gemini'" ;;
esac

# Artifact allowlist: when a phase targets real file(s), pass them as ALLOW_PATHS so the turn-takers
# may create/edit them. The shared safety core (relay-turn-lib.sh) reverts ANY edit outside this
# allowlist + the always-allowed relay file — so containment still holds; the builder just gains a
# real write surface. Without --artifact, ALLOW_PATHS stays unset and the phase is relay-only.
if [[ -n "$ARTIFACT_PATHS" ]]; then
  export ALLOW_PATHS="$ARTIFACT_PATHS"
fi

PHASE_DIR="$PHASES_DIR/p1"
RELAY_FILE="$PHASE_DIR/RELAY.md"

# ── Step 1: render phases/p1/RELAY.md ──────────────────────────────────────

mkdir -p "$PHASE_DIR"
BRIEF_TEXT="$(cat "$PHASE_BRIEF_FILE")"

# Bake the ABSOLUTE tick path into the relay. A headless turn's cwd is not guaranteed to be the
# repo root, so a relative "./bin/tick" is a guess — a real builder turn (2026-06-17) looked for it
# in the phase dir, logged "tick not present", and skipped the token handoff entirely (phase then
# escalated no-progress). An absolute path the agent can run from anywhere removes that failure mode.
TICK_CLI="$TICK_BIN"
case "$TICK_CLI" in /*) ;; *) TICK_CLI="$ROOT/$TICK_CLI" ;; esac

# Builder/reviewer instruction text + the tick claim --paths depend on whether this phase targets
# real artifact file(s) (--artifact) or is relay-only. Built here so the heredoc stays a flat template.
if [[ -n "$ARTIFACT_PATHS" ]]; then
  CLAIM_PATHS="phases/p1/RELAY.md,${ARTIFACT_PATHS}"
  BUILDER_IMPL_LINE="Implement the brief by creating/editing the artifact file(s): ${ARTIFACT_PATHS}"
  BUILDER_SCOPE_LINE="Edit ONLY these paths: phases/p1/RELAY.md and ${ARTIFACT_PATHS}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
  REVIEWER_READ_LINE="Read the latest builder block above AND review the artifact file(s) on disk: ${ARTIFACT_PATHS}."
  REVIEWER_SCOPE_LINE="Edit ONLY phases/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git."
else
  CLAIM_PATHS="phases/p1/RELAY.md"
  BUILDER_IMPL_LINE="Record your work directly in this relay file (relay-only phase — no source file to edit)."
  BUILDER_SCOPE_LINE="Edit ONLY phases/p1/RELAY.md. Do NOT run git. Do NOT touch any other file — the harness commits for you."
  REVIEWER_READ_LINE="Read the latest builder block above."
  REVIEWER_SCOPE_LINE="Do NOT run git. Do NOT touch any other file."
fi

cat > "$RELAY_FILE" << RELAY_EOF
# Marathon Phase 1
STATUS: Open
NEXT: ${BUILDER}

<!-- marathon-drive: task=${RELAY_TASK} builder=${BUILDER} reviewer=${REVIEWER} round-cap=${ROUND_CAP} -->

## Phase Brief

${BRIEF_TEXT}

---

▶ TAKE YOUR TURN (${BUILDER} — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. ${BUILDER_IMPL_LINE}
2. Append a build block to this relay file: \`### Round N · Builder · ${BUILDER}\` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): ${TICK_CLI}
   - ${TICK_CLI} claim ${RELAY_TASK} --agent ${BUILDER} --paths "${CLAIM_PATHS}"
   - ${TICK_CLI} ping ${RELAY_TASK} --agent ${BUILDER}
   - ${TICK_CLI} release ${RELAY_TASK} --agent ${BUILDER} --to ${REVIEWER}
4. ${BUILDER_SCOPE_LINE}

---

▶ TAKE YOUR TURN (${REVIEWER} — REVIEWER role)

You are the REVIEWER for this phase. ${REVIEWER_READ_LINE}
1. Append a review block: \`### Round N · Reviewer · ${REVIEWER}\` followed by your assessment.
2. If changes needed: add \`**Verdict:** Changes requested\` then: ${TICK_CLI} release ${RELAY_TASK} --agent ${REVIEWER} --to ${BUILDER}
3. If satisfied: add \`**Verdict:** Approved\`, set \`STATUS: Approved\`, then: ${TICK_CLI} done ${RELAY_TASK} --agent ${REVIEWER}
4. Use this exact tick binary (run it from any directory) for all token operations: ${TICK_CLI}
   ${REVIEWER_SCOPE_LINE}
RELAY_EOF

if ((DRY_RUN)); then
  log "dry-run: relay file rendered at $RELAY_FILE"
  printf 'tick seed: log task.created %s + claim --agent marathon + release --to %s\n' "$RELAY_TASK" "$BUILDER"
  exit 0
fi

# ── Step 2: commit the relay file (rtl_before needs a clean HEAD) ───────────

git -C "$ROOT" add -- "$RELAY_FILE"
git -C "$ROOT" commit -q -m "marathon: render phase 1 relay (${RELAY_TASK})"
log "relay file committed: $RELAY_FILE"

# ── Step 3: seed tick token with handoff → builder ──────────────────────────

export TICK_REPO_ROOT="$ROOT"
"$TICK_BIN" log task.created "$RELAY_TASK" --agent marathon > /dev/null
"$TICK_BIN" claim           "$RELAY_TASK" --agent marathon --paths "phases/p1/RELAY.md" > /dev/null
"$TICK_BIN" release         "$RELAY_TASK" --agent marathon --to "$BUILDER" > /dev/null
log "tick token seeded: $RELAY_TASK → $BUILDER"

# ── Step 4: emit phase.start ────────────────────────────────────────────────

"$TICK_BIN" log marathon.phase.start "$RELAY_TASK" --agent marathon > /dev/null
log "phase start: running relay-drive --round-cap $ROUND_CAP"

# ── Step 5: run relay-drive (the loop — unmodified) ────────────────────────

# relay-drive runs the turn-taker via `eval "$AGENT_CMD"`, so the value must be a shell-quoted
# command string — an un-quoted path with a space (".../GH Repos/...") would split on the space
# and try to exec the wrong token. printf %q makes the path eval-safe (relay-drive stays unmodified).
AGENT_CMD_Q="$(printf '%q' "$AGENT_CMD")"
relay_exit=0
RELAY_FILE="$RELAY_FILE" \
  "$RELAY_DRIVE_BIN" \
    --relay-file "$RELAY_FILE" \
    --relay-task "$RELAY_TASK" \
    --agent-cmd  "$AGENT_CMD_Q" \
    --round-cap  "$ROUND_CAP" \
  || relay_exit=$?

# ── Step 6: act on relay-drive exit code ───────────────────────────────────

escalate() {  # <reason> <relay-exit>
  local reason="$1" rexit="$2"
  cat > "$PHASE_DIR/ESCALATION.md" << ESC_EOF
# ESCALATION — Marathon Phase 1

phase: p1
task: ${RELAY_TASK}
relay-drive-exit: ${rexit}
reason: ${reason}
relay-file: phases/p1/RELAY.md
ESC_EOF
  git -C "$ROOT" add -- "$PHASE_DIR/ESCALATION.md"
  git -C "$ROOT" commit -q -m "marathon: phase 1 escalation (${reason})"
  "$TICK_BIN" log marathon.phase.escalated "$RELAY_TASK" --agent marathon > /dev/null || true
  log "escalation written: $PHASE_DIR/ESCALATION.md (reason: $reason)"
}

save_transcript() {
  local date_dir; date_dir="$ROOT/relay-system/$(date +%Y-%m-%d)"
  mkdir -p "$date_dir"
  local ts; ts="$(date +%H%M%S)"
  local dest="$date_dir/marathon-p1-${ts}.md"
  cp "$RELAY_FILE" "$dest"
  git -C "$ROOT" add -- "$dest"
  git -C "$ROOT" commit -q -m "marathon: phase 1 transcript saved (${RELAY_TASK})"
  log "transcript saved: $dest"
}

case "$relay_exit" in
  0)
    # relay closed Approved. Run the pre-advance gate before emitting phase.approved.
    log "relay approved — running pre-advance gate: $PRE_ADVANCE_CMD"
    gate_exit=0
    eval "$PRE_ADVANCE_CMD" || gate_exit=$?
    if [[ "$gate_exit" -ne 0 ]]; then
      log "pre-advance gate FAILED (exit $gate_exit) — escalating"
      escalate "pre-advance-failed" "$relay_exit"
      exit 5
    fi
    "$TICK_BIN" log marathon.phase.approved "$RELAY_TASK" --agent marathon > /dev/null || true
    save_transcript
    log "phase 1 complete — STATUS: Approved, gate passed"
    exit 0
    ;;
  3)
    log "relay escalated: no-progress (relay-drive exit 3)"
    escalate "no-progress" 3
    exit 3
    ;;
  4)
    log "relay escalated: cap/close-mismatch (relay-drive exit 4)"
    escalate "cap-or-close-mismatch" 4
    exit 4
    ;;
  *)
    die "relay-drive exited with unexpected code $relay_exit"
    ;;
esac
