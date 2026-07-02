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
#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
#     [--phase-id <ID>]          which phase to drive: phases/<id>/ (default: p1; the orchestrator sets it)
#     [--relay-task <ID>]        tick task name (default: MARATHON-<PHASE_ID>-TURN)
#     [--artifact <PATHS>]       comma-separated repo-relative file(s) the builder may create/edit
#                                beyond the relay file (passed to the shims as ALLOW_PATHS). Omit for
#                                a relay-only phase (conversation → approval, no source edit).
#     [--require-clean]          hard-stop if the workspace has pre-existing changes (unattended runs)
#     [--dry-run]                render relay file and print tick seed cmd, then exit
#
# Environment overrides (for tests):
#   MARATHON_ROOT         — git repo root (default: parent of this script's dir)
#   MARATHON_RELAY_DRIVE  — relay-drive.sh path (default: this script's dir/relay-drive.sh)
#   MARATHON_AGENT_CMD    — --agent-cmd value (default: this script's dir/marathon-agent.sh)
#   TICK_BIN              — tick binary (default: <repo-root>/bin/tick)
#
# Exit: 0 phase approved + gate passed · 3 relay no-progress · 4 relay cap/mismatch ·
#        5 pre-advance gate failed · 6 containment violation (turn-taker reverted an off-lane edit) ·
#        2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${MARATHON_ROOT:-"$(cd "$HERE/.." && pwd)"}"
TICK_BIN="${TICK_BIN:-"$ROOT/bin/tick"}"
RELAY_DRIVE_BIN="${MARATHON_RELAY_DRIVE:-"$HERE/relay-drive.sh"}"
AGENT_CMD="${MARATHON_AGENT_CMD:-"$HERE/marathon-agent.sh"}"

if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
  # GH-49b: the lock lives in .git/ (never committed) for a normal clone; a vendored .xyz/ copy has no
  # .git/, so fall back to a hidden lock beside the scripts (the .xyz/ dir is itself gitignored in the
  # foreign repo, so it stays uncommitted just the same). Same lock NAME as relay-drive so a marathon
  # and a relay driver still mutually exclude in one clone. Unchanged when .git/ exists.
  if [[ -d "$ROOT/.git" ]]; then
    _lock="$ROOT/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
  else
    _lock="$ROOT/.relay-driver.lock";     _lock_label=".relay-driver.lock"
  fi
  if ! mkdir "$_lock" 2>/dev/null; then
    # GH-42 self-heal: the lock exists — reclaim it only if its holder is dead. A crashed/killed/
    # SIGKILL'd driver used to leave a stale lock that blocked every later run until a manual rmdir.
    _holder="$(cat "$_lock/pid" 2>/dev/null || true)"
    if [[ -n "$_holder" ]] && kill -0 "$_holder" 2>/dev/null; then
      printf 'marathon-drive: another driver is active in this repo (pid %s, lock: %s).\n' "$_holder" "$_lock_label" >&2
      printf 'marathon-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).\n' >&2
      exit 1
    fi
    printf 'marathon-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
    rm -rf "$_lock"
    mkdir "$_lock" 2>/dev/null || { printf 'marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
    # ponytail: tiny TOCTOU window (two drivers could both reclaim a stale lock); acceptable for a
    # single-operator clone — add an atomic PID-CAS only if true multi-operator concurrency appears.
  fi
  printf '%s\n' "$$" > "$_lock/pid"
  trap 'rm -rf "$_lock" 2>/dev/null || true' EXIT
  export RELAY_DRIVER_LOCKED=1
fi

die()  { printf 'marathon-drive: %s\n' "$*" >&2; exit 2; }
log()  { printf 'marathon-drive: %s\n' "$*"; }

XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$ROOT/utils/telemetry/append-xyz-completion.sh"}"

# GH-75: append ONE final-completion record for a run whose WHOLE completion IS this single-phase
# marathon-drive — i.e. a bare `marathon-drive.sh` run (harness:"marathon") or a swarm-preflight-
# originated run (harness:"swarm", tagged via XYZ_HARNESS_CONTEXT=swarm baked into the generated
# invocation). Stays SILENT when marathon.sh drives us per-phase (XYZ_HARNESS_CONTEXT=marathon-phase):
# marathon.sh emits the single whole-run record itself. Health is binary green/red (halt-on-first-
# failure has no distinct "escalated mid-chain" state). Best-effort — never changes marathon-drive's
# own exit code.
xyz_marathon_emit() {  # <health> <description>
  local ctx="${XYZ_HARNESS_CONTEXT:-}"
  [[ "$ctx" == "marathon-phase" ]] && return 0
  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
  local health="$1" desc="$2" harness title sid
  case "$ctx" in swarm) harness="swarm" ;; *) harness="marathon" ;; esac
  title="$(basename "$PHASE_BRIEF_FILE" .md 2>/dev/null)"; [[ -n "$title" ]] || title="$PHASE_ID"
  # sessionId: PHASE_ID defaults to "p1", which is a constant across every swarm/bare run — useless for
  # telling one run from another. Let the invoker override it (swarm-preflight bakes the per-run slug
  # into its generated command via XYZ_SESSION_ID); fall back to PHASE_ID otherwise (GH-75 review).
  sid="${XYZ_SESSION_ID:-$PHASE_ID}"
  "$XYZ_APPEND_BIN" "$harness" "$sid" "$health" "$title" "$desc" >/dev/null 2>&1 || true
}

usage() {
  cat <<'EOF'
Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]

  --phase-brief FILE      Phase brief markdown baked into the relay template (required).
  --reviewer AGENT        Reviewer agent id; must start with 'codex' or 'gemini' (required).
  --builder AGENT         Builder agent id (default: claude).
  --round-cap N           relay-drive turn cap (default: 5).
  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).
  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
  --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
  --relay-task ID         Tick task name (default: MARATHON-<PHASE_ID>-TURN).
  --artifact PATHS        Comma-separated repo-relative file(s) the builder may create/edit beyond
                          the relay file (ALLOW_PATHS for the turn-takers). Omit for a relay-only phase.
  --target-root DIR       Foreign git repo the BUILD lands in (GH-11). The relay thread + tick token
                          stay in this repo; forwarded to relay-drive.sh, and the pre-advance gate runs
                          with cwd = DIR. Omit for a same-repo phase.
  --require-clean         Hard-stop (exit 2) if the workspace has pre-existing changes before seeding.
  --dry-run               Render the relay file and print the tick seed; exit without running.
EOF
}

PHASE_BRIEF_FILE=""
BUILDER="claude"
REVIEWER=""
ROUND_CAP=5
PRE_ADVANCE_CMD=""   # resolved to default after ROOT is set
PHASES_DIR=""        # resolved to default after ROOT is set
PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
RELAY_TASK=""        # resolved to MARATHON-<PHASE_ID>-TURN after parsing, unless given
ARTIFACT_PATHS=""    # comma-separated repo-relative file(s) the builder may create/edit (beyond RELAY.md)
REQUIRE_CLEAN=0      # --require-clean: hard-stop if the workspace has pre-existing changes
DRY_RUN=0
TARGET_ROOT=""       # --target-root: foreign repo the BUILD lands in (GH-11). Relay thread stays in ROOT;
                     # forwarded to relay-drive.sh (which exports RELAY_TARGET_ROOT for artifact routing).

while (($# > 0)); do
  case "$1" in
    --phase-brief)     PHASE_BRIEF_FILE="${2:-}"; shift 2 ;;
    --builder)         BUILDER="${2:-}"; shift 2 ;;
    --reviewer)        REVIEWER="${2:-}"; shift 2 ;;
    --round-cap)       ROUND_CAP="${2:-}"; shift 2 ;;
    --pre-advance-cmd) PRE_ADVANCE_CMD="${2:-}"; shift 2 ;;
    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
    --phase-id)        PHASE_ID="${2:-}"; shift 2 ;;
    --relay-task)      RELAY_TASK="${2:-}"; shift 2 ;;
    --artifact)        ARTIFACT_PATHS="${2:-}"; shift 2 ;;
    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
    --require-clean)   REQUIRE_CLEAN=1; shift ;;
    --dry-run)         DRY_RUN=1; shift ;;
    --help)            usage; exit 0 ;;
    *)                 die "unknown argument: $1" ;;
  esac
done

[[ -n "$PHASE_BRIEF_FILE" ]] || { usage; die "--phase-brief FILE required"; }
[[ -f "$PHASE_BRIEF_FILE" ]] || die "phase brief not found: $PHASE_BRIEF_FILE"
[[ -n "$REVIEWER"         ]] || { usage; die "--reviewer AGENT required"; }
[[ -n "$BUILDER"          ]] || die "--builder cannot be empty"
[[ -n "$PHASE_ID"         ]] || die "--phase-id cannot be empty"
if [[ -n "$TARGET_ROOT" ]]; then
  git -C "$TARGET_ROOT" rev-parse --show-toplevel >/dev/null 2>&1 \
    || die "invalid --target-root (not a git repo): $TARGET_ROOT"
fi

PHASES_DIR="${PHASES_DIR:-"$ROOT/phases"}"
PRE_ADVANCE_CMD="${PRE_ADVANCE_CMD:-"bash $ROOT/validate.sh"}"
# Default the tick token name off the phase id (p1 → MARATHON-P1-TURN), keeping the Phase-3 default.
RELAY_TASK="${RELAY_TASK:-"MARATHON-$(printf '%s' "$PHASE_ID" | tr '[:lower:]' '[:upper:]')-TURN"}"

# Map builder/reviewer to _AGENT env vars for marathon-agent.sh routing. Both actors are routed to
# their shim by name prefix (claude/codex/agy/gemini), so the harness supports cross-model BUILDERS
# (e.g. agy) — not just Claude. Builder defaults to claude for back-compat.
export MARATHON_BUILDER="$BUILDER"
export MARATHON_REVIEWER="$REVIEWER"
export CLAUDE_AGENT="" CODEX_AGENT="" AGY_AGENT="" GEMINI_AGENT=""
route_agent() {  # <agent-id> → export the matching *_AGENT var marathon-agent.sh routes on
  case "$1" in
    claude*) export CLAUDE_AGENT="$1" ;;
    codex*)  export CODEX_AGENT="$1" ;;
    agy*)    export AGY_AGENT="$1" ;;
    gemini*) export GEMINI_AGENT="$1" ;;
    *)       die "agent '$1' not recognized — must start with claude/codex/agy/gemini" ;;
  esac
}
[[ "$BUILDER" == "$REVIEWER" ]] && die "builder and reviewer must be different agent ids (got '$BUILDER' for both)"
route_agent "$BUILDER"
route_agent "$REVIEWER"
# Reviewer must be a QA-capable model lane (codex/gemini/agy), never the Claude builder lane.
case "$REVIEWER" in codex*|gemini*|agy*) ;; *) die "reviewer '$REVIEWER' must start with codex/gemini/agy" ;; esac

# Artifact allowlist: when a phase targets real file(s), pass them as ALLOW_PATHS so the turn-takers
# may create/edit them. The shared safety core (relay-turn-lib.sh) reverts ANY edit outside this
# allowlist + the always-allowed relay file — so containment still holds; the builder just gains a
# real write surface. Without --artifact, ALLOW_PATHS stays unset and the phase is relay-only.
if [[ -n "$ARTIFACT_PATHS" ]]; then
  export ALLOW_PATHS="$ARTIFACT_PATHS"
fi

PHASE_DIR="$PHASES_DIR/$PHASE_ID"
RELAY_FILE="$PHASE_DIR/RELAY.md"
REL_RELAY="${RELAY_FILE#"$ROOT"/}"   # repo-root-relative path the agent edits / declares in claim --paths

# ── Step 0: clean-workspace check (Phase 3.6) ──────────────────────────────
# Stray pre-existing files distract an autonomous builder — a 2026-06-17 dogfood builder was pulled
# off-task by unrelated AUDIT/*.md briefs left in the tree. Surface them before seeding. Exclude the
# marathon's own paths (phases/, .tick/). --require-clean turns the warning into a hard stop for
# unattended runs (DRY_RUN skips it — nothing is committed).
if ((! DRY_RUN)); then
  dirty="$(git -C "$ROOT" status --porcelain 2>/dev/null \
    | awk '{ p=substr($0,4); if (p !~ /^phases\// && p !~ /^\.tick\//) print p }')"
  if [[ -n "$dirty" ]]; then
    log "WARNING: workspace is not clean — an autonomous builder can be distracted by stray files."
    while IFS= read -r p; do [[ -n "$p" ]] && log "  • $p"; done <<< "$dirty"
    ((REQUIRE_CLEAN)) && die "--require-clean set and the workspace has pre-existing changes (above)"
  fi
fi

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
  CLAIM_PATHS="${REL_RELAY},${ARTIFACT_PATHS}"
  BUILDER_IMPL_LINE="Implement the brief by creating/editing the artifact file(s): ${ARTIFACT_PATHS}"
  BUILDER_SCOPE_LINE="Edit ONLY these paths: ${REL_RELAY} and ${ARTIFACT_PATHS}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
  REVIEWER_READ_LINE="Read the latest builder block above AND review the artifact file(s) on disk: ${ARTIFACT_PATHS}."
  REVIEWER_SCOPE_LINE="Edit ONLY ${REL_RELAY} (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git."
else
  CLAIM_PATHS="${REL_RELAY}"
  BUILDER_IMPL_LINE="Record your work directly in this relay file (relay-only phase — no source file to edit)."
  BUILDER_SCOPE_LINE="Edit ONLY ${REL_RELAY}. Do NOT run git. Do NOT touch any other file — the harness commits for you."
  REVIEWER_READ_LINE="Read the latest builder block above."
  REVIEWER_SCOPE_LINE="Do NOT run git. Do NOT touch any other file."
fi

cat > "$RELAY_FILE" << RELAY_EOF
# Marathon Phase ${PHASE_ID}
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
git -C "$ROOT" commit -q -m "marathon: render phase ${PHASE_ID} relay (${RELAY_TASK})"
log "relay file committed: $RELAY_FILE"

# ── Step 3: seed tick token with handoff → builder ──────────────────────────

export TICK_REPO_ROOT="$ROOT"

reconcile_relay_task() {
  local info status handoff claimer
  if ! info="$("$TICK_BIN" info "$RELAY_TASK" 2>/dev/null)"; then
    return 0  # no prior task state to reconcile
  fi

  status="$(printf '%s\n' "$info" | sed -n 's/^status:[[:space:]]*//p' | head -n1)"
  handoff="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -n1)"
  claimer="$(printf '%s\n' "$info" | sed -n 's/^claimer:[[:space:]]*//p' | head -n1)"

  case "$status" in
    claimed)
      die "relay task $RELAY_TASK already has a live claim by ${claimer:-unknown}; refusing to reap a live claim"
      ;;
    open)
      [[ -n "$handoff" ]] || return 0
      case "$handoff" in
        "$BUILDER"|"$REVIEWER")
          # GH-56: a rerun can inherit an OPEN handoff from the previous pass. Clear only that stale
          # reservation by consuming it as its routed target, then releasing it unreserved. Never reap a
          # live claim here; parked claims are the watchdog's authority path.
          "$TICK_BIN" claim "$RELAY_TASK" --agent "$handoff" --paths "$REL_RELAY" > /dev/null
          "$TICK_BIN" release "$RELAY_TASK" --agent "$handoff" > /dev/null
          log "reconciled leaked open handoff: $RELAY_TASK (cleared stale reservation for $handoff)"
          ;;
        *)
          die "relay task $RELAY_TASK is open but reserved for unexpected agent '$handoff'"
          ;;
      esac
      ;;
  esac
}

reconcile_relay_task

"$TICK_BIN" log task.created "$RELAY_TASK" --agent marathon > /dev/null
"$TICK_BIN" claim           "$RELAY_TASK" --agent marathon --paths "$REL_RELAY" > /dev/null
"$TICK_BIN" release         "$RELAY_TASK" --agent marathon --to "$BUILDER" > /dev/null
log "tick token seeded: $RELAY_TASK → $BUILDER"

# ── Step 4: emit phase.start ────────────────────────────────────────────────

"$TICK_BIN" log marathon.phase.start "$RELAY_TASK" --agent marathon > /dev/null
log "phase start: running relay-drive --round-cap $ROUND_CAP"

# ── Step 5: run relay-drive (the loop — unmodified) ────────────────────────

# relay-drive runs a bare executable --agent-cmd path directly (space-safe, even ".../GH Repos/..."),
# falling back to eval only for command strings — so we pass the path as-is, no %q quoting needed.
relay_exit=0
target_root_args=()
[[ -n "$TARGET_ROOT" ]] && target_root_args=(--target-root "$TARGET_ROOT")
# GH-75: the nested relay loop reaches its own terminal exit once PER PHASE. Force its XYZ.json hook
# silent (XYZ_HARNESS_CONTEXT=marathon-phase) so a per-phase relay completion never emits its own
# record — this marathon-drive run (or marathon.sh above it) owns the single whole-run record. This is
# scoped to the relay-drive child only; marathon-drive's OWN context (swarm|unset) is left intact for
# its hook below.
RELAY_FILE="$RELAY_FILE" \
XYZ_HARNESS_CONTEXT=marathon-phase \
  "$RELAY_DRIVE_BIN" \
    --relay-file "$RELAY_FILE" \
    --relay-task "$RELAY_TASK" \
    --agent-cmd  "$AGENT_CMD" \
    --round-cap  "$ROUND_CAP" \
    ${target_root_args[@]+"${target_root_args[@]}"} \
  || relay_exit=$?

# ── Step 6: act on relay-drive exit code ───────────────────────────────────

escalate() {  # <reason> <relay-exit>
  local reason="$1" rexit="$2"
  cat > "$PHASE_DIR/ESCALATION.md" << ESC_EOF
# ESCALATION — Marathon Phase ${PHASE_ID}

phase: ${PHASE_ID}
task: ${RELAY_TASK}
relay-drive-exit: ${rexit}
reason: ${reason}
relay-file: ${REL_RELAY}
ESC_EOF
  git -C "$ROOT" add -- "$PHASE_DIR/ESCALATION.md"
  git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} escalation (${reason})"
  "$TICK_BIN" log marathon.phase.escalated "$RELAY_TASK" --agent marathon > /dev/null || true
  log "escalation written: $PHASE_DIR/ESCALATION.md (reason: $reason)"
}

save_transcript() {
  local date_dir; date_dir="$ROOT/relay-system/$(date +%Y-%m-%d)"
  mkdir -p "$date_dir"
  local ts; ts="$(date +%H%M%S)"
  local dest="$date_dir/marathon-${PHASE_ID}-${ts}.md"
  cp "$RELAY_FILE" "$dest"
  git -C "$ROOT" add -- "$dest"
  git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} transcript saved (${RELAY_TASK})"
  log "transcript saved: $dest"
}

case "$relay_exit" in
  0)
    # relay closed Approved. Run the pre-advance gate before emitting phase.approved.
    log "relay approved — running pre-advance gate: $PRE_ADVANCE_CMD"
    gate_exit=0
    # Gate belongs to the target repo when --target-root is set (e.g. a foreign repo's `npm test`).
    ( [[ -n "$TARGET_ROOT" ]] && cd "$TARGET_ROOT"; eval "$PRE_ADVANCE_CMD" ) || gate_exit=$?
    if [[ "$gate_exit" -ne 0 ]]; then
      log "pre-advance gate FAILED (exit $gate_exit) — escalating"
      escalate "pre-advance-failed" "$relay_exit"
      xyz_marathon_emit red "halted at phase ${PHASE_ID} — pre-advance gate failed"
      exit 5
    fi
    "$TICK_BIN" log marathon.phase.approved "$RELAY_TASK" --agent marathon > /dev/null || true
    save_transcript
    log "phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
    xyz_marathon_emit green "phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
    exit 0
    ;;
  3)
    log "relay escalated: no-progress (relay-drive exit 3)"
    escalate "no-progress" 3
    xyz_marathon_emit red "halted at phase ${PHASE_ID} — relay no-progress"
    exit 3
    ;;
  4)
    log "relay escalated: cap/close-mismatch (relay-drive exit 4)"
    escalate "cap-or-close-mismatch" 4
    xyz_marathon_emit red "halted at phase ${PHASE_ID} — relay cap/close-mismatch"
    exit 4
    ;;
  6)
    # A turn-taker shim hit an off-lane edit, reverted it, and failed the turn (exit 6) — the
    # containment boundary fired. This is a DEFINED escalation, not an "unexpected" crash: the
    # builder strayed but the safety core held. Record it like any other escalation. (Dogfood
    # 2026-06-17: an autonomous builder edited an off-lane file; rtl_enforce caught + reverted it.)
    log "relay escalated: containment violation — a turn-taker reverted an off-lane edit (exit 6)"
    escalate "containment-violation (off-lane edit reverted by a turn-taker)" 6
    xyz_marathon_emit red "halted at phase ${PHASE_ID} — containment violation (off-lane edit reverted)"
    exit 6
    ;;
  *)
    die "relay-drive exited with unexpected code $relay_exit"
    ;;
esac
