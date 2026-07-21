#!/usr/bin/env bash
set -euo pipefail

# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
# implementation below — Bash stays the supported default until the port is promoted.
if [[ "${XYZ_PYTHON-0}" == "1" ]]; then
  # UPGRADE.md §4 Phase-2 hardening (GH-255): (2a) `-` not `:-` so an explicit empty XYZ_PYTHON reads
  # as not-1 → Bash (load-bearing once the default flips to 1); (2b) require python3 >=3.8 and fall
  # back to Bash with a warning if it's missing/too-old, so a bad interpreter degrades, not bricks.
  if command -v python3 >/dev/null 2>&1 \
     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    export XYZ_ROOT="$_xyz_root"
    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    exec python3 "$_xyz_root/utils/py/relay_drive.py" "$@"
  else
    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
  fi
fi
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
#       escalated-to-human-by-design (STATUS: Escalated) · 5 = review-once: reviewer completed a turn
#       (non-approval handback — a successful single review, NOT a stall) ·
#       8 = lane parked (GH-45 attempt cap — no token seeded; re-fire with --force) · 2 = usage.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# GH-30 Phase 2: transcript-root resolver (rtl_transcript_root) — redirects relay-system/ to
# $XYZ_ARCHIVE_ROOT when set, else byte-for-byte "$ROOT_DIR/relay-system". Sourced beside this script.
source "$(dirname "${BASH_SOURCE[0]}")/relay-turn-lib.sh"
TICK_BIN="${TICK_BIN:-"$ROOT_DIR/bin/tick"}"
CONSULT_SH="${CONSULT_SH:-"$ROOT_DIR/relay-automation/consult.sh"}"
XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$ROOT_DIR/utils/telemetry/append-xyz-completion.sh"}"
XYZ_HEARTBEAT_BIN="${XYZ_HEARTBEAT_BIN:-"$ROOT_DIR/utils/telemetry/write-xyz-heartbeat.sh"}"

# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
# lane_attempt_gate appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
# token. --force bypasses for one fire and logs it. lane_attempt_reset clears the counter when a lane
# COMPLETES successfully (Approved), so the cap counts CONSECUTIVE failures and can never permanently
# wedge a lane (reviewer feedback: without a reset a default-keyed lane parks forever). A nested call
# (marathon-drive → relay-drive) is guarded by LANE_ATTEMPT_COUNTED so the same lane is counted (and
# reset) exactly once. Byte-consistent mirror in marathon-drive.sh; relay-turn-lib.sh/bin/tick untouched.
_lane_key() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'; }
lane_attempt_gate() {
  local root="$1" raw="$2" force="${3:-0}"
  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
  [ -n "$raw" ] || return 0
  local max="${LANE_MAX_ATTEMPTS:-2}"; case "$max" in ''|*[!0-9]*) max=2 ;; esac
  local key dir file count; key=$(_lane_key "$raw"); dir="$root/.tick/attempts"; file="$dir/$key"
  mkdir -p "$dir" 2>/dev/null || true
  count=0; [ -f "$file" ] && count=$(wc -l < "$file" 2>/dev/null | tr -d ' '); [ -n "$count" ] || count=0
  if [ "$force" = "1" ]; then
    printf 'lane-attempt-cap: --force override — lane %s at %s attempt(s) (cap %s), proceeding.\n' "$key" "$count" "$max" >&2
  elif [ "$count" -ge "$max" ]; then
    printf 'lane-attempt-cap: lane %s PARKED after %s attempt(s) (cap %s) — no relay token seeded.\n' "$key" "$count" "$max" >&2
    printf '  Re-anchor to the committed QUEUE lanes (AGENTS.md) or re-fire with --force. Attempts log: %s\n' "$file" >&2
    return 8
  fi
  printf '%s fire\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo fire)" >> "$file"
  return 0
}
lane_attempt_reset() {  # clear a lane's counter after it completes successfully (Approved)
  local root="$1" raw="$2"
  [ -n "${LANE_ATTEMPT_COUNTED:-}" ] && return 0
  [ -n "$raw" ] || return 0
  rm -f "$root/.tick/attempts/$(_lane_key "$raw")" 2>/dev/null || true
}

# GH-75: append ONE final-completion record to XYZ.json at the harness repo root when a STANDALONE
# /relay session terminates. Stays SILENT when this relay-drive runs nested inside a marathon/swarm
# phase — marathon-drive.sh sets XYZ_HARNESS_CONTEXT for the nested call (marathon-phase|swarm) and the
# outer harness owns the whole-run record, so a per-phase relay completion must not double-emit.
# Best-effort: a telemetry failure must never change the relay's own exit path.
xyz_relay_heartbeat_write() {
  case "${XYZ_HARNESS_CONTEXT:-relay}" in relay) ;; *) return 0 ;; esac
  [[ -x "$XYZ_HEARTBEAT_BIN" ]] || return 0
  local slug
  slug="$(basename "$RELAY_FILE" .md)"
  "$XYZ_HEARTBEAT_BIN" relay "$slug" >/dev/null 2>&1 || true
}

xyz_relay_emit() {  # <health>
  case "${XYZ_HARNESS_CONTEXT:-relay}" in relay) ;; *) return 0 ;; esac
  local health="$1" slug title s desc
  slug="$(basename "$RELAY_FILE" .md)"
  [[ -x "$XYZ_HEARTBEAT_BIN" ]] && XYZ_HEARTBEAT_CLEAR=1 "$XYZ_HEARTBEAT_BIN" relay "$slug" >/dev/null 2>&1 || true
  [[ -x "$XYZ_APPEND_BIN" ]] || return 0
  title="$(grep -m1 '^# ' "$RELAY_FILE" 2>/dev/null | sed 's/^#[[:space:]]*//; s/[[:space:]]*$//')" || true
  [[ -n "$title" ]] || title="$slug"
  s="$(file_status)"
  desc="Relay session ended: STATUS ${s:-unknown} (health ${health})."
  "$XYZ_APPEND_BIN" relay "$slug" "$health" "$title" "$desc" >/dev/null 2>&1 || true
}

# GH-152 (COST-OBSERVABILITY-PLAN.md Phase 6): auto-surface the `tick analyze` cost block at
# end-of-run so the operator stops needing a manual `tick analyze` pull to see what a driven run
# cost. Reuses `tick analyze`'s OWN human-format rendering VERBATIM (src/analyze.js renderHuman) —
# this driver recomputes NO cost number itself, so the floor `≥`/`coverage X/Y` markers on partial
# token coverage are exactly whatever the analyzer already emits (DRY, per the plan's QA gate).
# Default-on and strictly additive: only fires once RELAY_DRIVE_STARTED is set (i.e. a turn was
# actually about to be driven this invocation — never on --help/usage/lock-contention/lane-parked/
# --dry-run exits), and a failed/forced `tick analyze` is swallowed best-effort — it can never change
# the driven run's own exit code (wired via the EXIT trap below, which restores the original code).
# Opt out with RELAY_COST_SUMMARY=0.
: "${RELAY_COST_SUMMARY:=1}"
RELAY_DRIVE_STARTED=0
xyz_relay_cost_summary() {
  [[ "$RELAY_DRIVE_STARTED" == "1" ]] || return 0
  [[ "$RELAY_COST_SUMMARY" != "0" ]] || return 0
  local report block
  report="$("$TICK_BIN" analyze --format human 2>/dev/null)" || {
    printf 'relay-drive: tick analyze failed — end-of-run cost summary unavailable (RELAY_COST_SUMMARY=0 to silence)\n' >&2
    return 0
  }
  block="$(printf '%s\n' "$report" | sed -n '/^--- cost ---$/,$p')"
  [[ -n "$block" ]] || return 0
  printf '\nrelay-drive: end-of-run cost summary (tick analyze) —\n%s\n' "$block" >&2
}

if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
  # The driver lock lives in .git/ (never committed) for a normal harness clone. A GH-49 vendored
  # .xyz/ copy has no .git/, so mkdir'ing a lock there would fail — fall back to a hidden lock beside
  # the scripts (the .xyz/ dir is itself gitignored in the foreign repo, so it stays uncommitted just
  # the same). When .git/ exists the path is unchanged, so a normal clone behaves byte-identically.
  if [[ -d "$ROOT_DIR/.git" ]]; then
    _lock="$ROOT_DIR/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
  else
    _lock="$ROOT_DIR/.relay-driver.lock";     _lock_label=".relay-driver.lock"
  fi
  if ! mkdir "$_lock" 2>/dev/null; then
    # GH-42 self-heal: reclaim the lock only if its holder is dead. A crashed/killed driver used to
    # leave a stale lock that blocked every later run until a manual rmdir.
    _holder="$(cat "$_lock/pid" 2>/dev/null || true)"
    if [[ -n "$_holder" ]] && kill -0 "$_holder" 2>/dev/null; then
      printf 'relay-drive: another driver is active in this repo (pid %s, lock: %s).\n' "$_holder" "$_lock_label" >&2
      printf 'relay-drive: Concurrent runs in the same clone are unsafe (GH-42 ROOT HEAD hazard).\n' >&2
      exit 1
    fi
    printf 'relay-drive: reclaiming stale relay-driver.lock (holder pid %s not running).\n' "${_holder:-none}" >&2
    rm -rf "$_lock"
    mkdir "$_lock" 2>/dev/null || { printf 'relay-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
  fi
  printf '%s\n' "$$" > "$_lock/pid"
  # GH-152: the cost summary is wired into the SAME exit trap as the lock cleanup (the one place
  # every exit path already funnels through) rather than duplicated at each of the ~10 individual
  # `exit N` call sites in the round loop below — lower risk to this containment-sensitive script.
  # `_code` is captured FIRST and the trap re-exits with it explicitly: `xyz_relay_cost_summary`
  # (or the lock rm) failing/erroring under `set -e` inside a trap would otherwise silently
  # overwrite the script's real exit status with the trap's own (verified: a `false` after the
  # captured status inside a bash EXIT trap changes $? unless the trap re-asserts it) — so a
  # forced/failed analyze call can NEVER flip the driven run's reported result.
  _relay_drive_on_exit() {
    local _code=$?
    xyz_relay_cost_summary
    rm -rf "$_lock" 2>/dev/null || true
    exit "$_code"
  }
  trap _relay_drive_on_exit EXIT
  export RELAY_DRIVER_LOCKED=1
fi

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
  --artifact-file P   Seed an external read-only artifact (a cross-repo PR/diff or any file) into the
                      isolated worktree at .relay-artifacts/<basename> so the reviewer can READ it
                      without it being committed into the target repo. Requires worktree isolation
                      (the default). The reviewer may not edit it (an edit fails the turn). Implements #15.
  --review-once       Drive exactly ONE turn (a single review) and classify its outcome:
                      Approved/Closed -> 0; a completed non-approval handback ("changes
                      requested") -> 5 (NOT the stall's 3); reviewer-did-nothing stall -> 3;
                      Escalated -> 4. Forces --round-cap 1.
  --force             GH-45: bypass the per-lane attempt cap for this fire (re-fire a parked lane).
  --dry-run           Print the turn it WOULD drive next, then stop (no invocation).
  --help
EOF
}

die() { printf 'relay-drive: %s\n' "$*" >&2; exit 2; }

RELAY_FILE=""; AGENT_CMD=""; RELAY_TASK="RELAY-TURN"; ROUND_CAP=6; DRY_RUN=0; CONSULT_VERIFY=0; REVIEW_ONCE=0; ARTIFACT_FILE=""; FORCE=0
while (($# > 0)); do
  case "$1" in
    --relay-file) RELAY_FILE="${2:-}"; shift 2 ;;
    --agent-cmd) AGENT_CMD="${2:-}"; shift 2 ;;
    --relay-task) RELAY_TASK="${2:-}"; shift 2 ;;
    --round-cap) ROUND_CAP="${2:-}"; shift 2 ;;
    --target-root) TARGET_ROOT="${2:-}"; shift 2 ;;
    --consult-verify) CONSULT_VERIFY=1; shift ;;
    --review-once) REVIEW_ONCE=1; shift ;;
    --artifact-file) ARTIFACT_FILE="${2:-}"; shift 2 ;;
    --force) FORCE=1; shift ;;      # GH-45: bypass the per-lane attempt cap for this one fire
    --dry-run) DRY_RUN=1; shift ;;
    --help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[[ -n "$RELAY_FILE" ]] || { usage; die "--relay-file is required"; }
[[ -n "$AGENT_CMD" || "$DRY_RUN" -eq 1 ]] || { usage; die "--agent-cmd is required"; }

# --review-once drives a single review turn; its success oracle (a completed non-approval handback
# exits 5, not the stall's 3) replaces the multi-round no-progress/cap logic, so force the cap to 1.
((REVIEW_ONCE)) && ROUND_CAP=1

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

# GH-245 defect 1: a review turn (ALLOW_PATHS="") can only write the relay file. Under --target-root
# the turn's isolation worktree is based on the TARGET repo, so if the relay file resolves OUTSIDE that
# target root the reviewer physically cannot append its findings (codex rejects the out-of-project
# write) — the whole turn is completed and then discarded at full cost. Refuse fast at startup instead
# of spending the turn. The documented fix is to vendor the harness into the target repo so the relay
# file, harness and source share one writable root, then drop --target-root.
if ((REVIEW_ONCE)) && [[ -n "${TARGET_ROOT:-}" ]]; then
  _gh245_tr="$(cd "$TARGET_ROOT" 2>/dev/null && pwd -P)"
  _gh245_rf="$(cd "$(dirname "$RELAY_FILE")" 2>/dev/null && pwd -P)/$(basename "$RELAY_FILE")"
  if [[ -n "$_gh245_tr" && "$_gh245_rf" != "$_gh245_tr"/* ]]; then
    die "--target-root review turn cannot report: relay file '$RELAY_FILE' resolves outside the target root '$TARGET_ROOT', so a review turn (ALLOW_PATHS=\"\") has no writable path for its findings and the turn would be discarded after full cost. Vendor the harness into the target repo (relay-automation/xyz-vendor.sh '$TARGET_ROOT') and drop --target-root, or move the relay thread under the target root."
  fi
fi

# GH-45: per-lane attempt cap. A real build/review LOOP counts; a single --review-once turn and a
# dry-run do not (they can't rabbit-hole). Keyed on the relay task, stable across re-fires.
if ((DRY_RUN == 0)) && ((REVIEW_ONCE == 0)); then
  # Attempts live with the tick token (its repo), so tests that point TICK_REPO_ROOT at a temp dir
  # stay hermetic; a real standalone run falls back to this clone.
  lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT_DIR}" "$RELAY_TASK" "$FORCE" || exit $?
fi

# Containment default for unattended/driven runs: isolate the turn-taker in a throwaway worktree
# (ROOT@HEAD) so an off-task model's stray creations/renames can't reach the real tree. The leaf
# shims (codex/agy/claude-turn.sh) read RELAY_WORKTREE_ISOLATION; exporting it here makes every
# DRIVEN turn contained by default. Opt out per run with RELAY_WORKTREE_ISOLATION=0. (Direct/attended
# shim use keeps the leaf default OFF — only the orchestration layer defaults it ON.)
: "${RELAY_WORKTREE_ISOLATION:=1}"; export RELAY_WORKTREE_ISOLATION

# GH-32 #1 / GH-178 B2: under worktree isolation the turn-taker runs in a throwaway worktree — but
# it is NOT a bare HEAD checkout: relay-turn-lib.sh's rtl_worktree_begin() unconditionally seeds the
# relay file's CURRENT on-disk content into that worktree (it's always the first entry in RTL_ALLOW,
# regardless of HEAD-tracked status — relay-turn-lib.sh:247). So an uncommitted relay file is usually
# still visible to the reviewer; the original "will find nothing" claim was a false-positive
# generator for that common case (confirmed live 2026-07-07 night: a driven turn completed normally
# on an uncommitted relay file). The ONE case seeding does NOT cover: the relay file lives in a
# DIFFERENT git repo than the turn-taker's effective root (e.g. an XYZ_ARCHIVE_ROOT-redirected
# transcript) — rtl_init normalizes an out-of-root path to an absolute string the seed step's
# relative existence check won't match (GH-30 Phase 3), so it genuinely can be invisible there.
# Never block either way (a non-isolated run is free to use an uncommitted file, and a relay file
# outside any git repo is fine too).
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

  # Same-repo check: does the relay file's own repo match the effective root the turn-taker's
  # rtl_init will resolve RTL_ROOT to? (RELAY_TARGET_ROOT wins when set, else this script's own root.)
  local relay_toplevel effective_toplevel
  relay_toplevel="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)"
  effective_toplevel="$(git -C "${RELAY_TARGET_ROOT:-$ROOT_DIR}" rev-parse --show-toplevel 2>/dev/null)"

  if [[ -n "$relay_toplevel" && "$relay_toplevel" == "$effective_toplevel" ]]; then
    printf 'relay-drive: NOTE — relay file is not committed at HEAD: %s\n' "$rel" >&2
    printf '  RELAY_WORKTREE_ISOLATION=1 runs the turn-taker in a worktree at HEAD, but its own\n' >&2
    printf '  worktree-seeding step copies this file'"'"'s current content in regardless — this is\n' >&2
    printf '  usually fine. Commit it for a clean paper trail, or re-run with\n' >&2
    printf '  RELAY_WORKTREE_ISOLATION=0 if you want to rule out isolation entirely; neither is required.\n' >&2
  else
    printf 'relay-drive: WARNING — relay file is not committed at HEAD: %s\n' "$rel" >&2
    printf '  It lives in a DIFFERENT repo than the turn-taker'"'"'s root (archive-routed?), so the\n' >&2
    printf '  usual worktree-seeding fallback does NOT cover it — it may be genuinely INVISIBLE to\n' >&2
    printf '  the reviewer (it will find nothing and do no work). Remedy: commit the relay file\n' >&2
    printf '  first, or re-run with RELAY_WORKTREE_ISOLATION=0.\n' >&2
  fi
}
warn_if_relay_file_untracked

relay_setup_section_lines() {
  awk '
    /^##[[:space:]]+Setup[[:space:]]*$/ { in_setup=1; next }
    in_setup && /^##[[:space:]]+/ { exit }
    in_setup { print }
  ' "$RELAY_FILE"
}

relay_extract_markdown_paths() {  # <line>
  printf '%s\n' "$1" \
    | grep -oE '`[^`]+`|\*\*[^*]+\*\*' \
    | sed -e 's/^`//' -e 's/`$//' -e 's/^\*\*//' -e 's/\*\*$//'
}

relay_is_worktree_artifact_path() {  # <candidate>
  local candidate="$1"
  [[ -n "$candidate" ]] || return 1
  [[ "$candidate" != http://* && "$candidate" != https://* ]] || return 1
  [[ "$candidate" != ".relay-artifacts/"* ]] || return 1
  [[ "$candidate" != *"embedded below"* ]] || return 1
  [[ "$candidate" != *" "* && "$candidate" != *$'\t'* ]] || return 1
  [[ "$candidate" != *"{"* && "$candidate" != *"}"* && "$candidate" != *","* ]] || return 1
  [[ "$candidate" == /* || "$candidate" == */* || "$candidate" == .* || "$candidate" == *.* ]]
}

preflight_setup_artifact_paths() {
  local worktree_root setup_line candidate resolved
  worktree_root="${RELAY_TARGET_ROOT:-$(git -C "$(dirname "$RELAY_FILE")" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$ROOT_DIR")}"
  worktree_root="$(cd "$worktree_root" 2>/dev/null && pwd || printf '%s' "$worktree_root")"
  while IFS= read -r setup_line; do
    [[ "$setup_line" == *"Artifact under review:"* ]] || continue
    [[ "$setup_line" == *"embedded below"* ]] && continue
    while IFS= read -r candidate; do
      relay_is_worktree_artifact_path "$candidate" || continue
      case "$candidate" in
        /*) resolved="$candidate" ;;
        *)  resolved="$worktree_root/$candidate" ;;
      esac
      [[ -e "$resolved" ]] || die "artifact path not found in worktree: $candidate"
    done < <(relay_extract_markdown_paths "$setup_line")
  done < <(relay_setup_section_lines)
}

# GH-31 / #15: a read-only artifact under review. Absolutize it (the shim runs with a different CWD)
# and export it so relay-turn-lib seeds it into the isolated worktree. It only works under isolation —
# warn loudly if isolation is off, so the reviewer isn't left silently unable to see it.
if [[ -n "$ARTIFACT_FILE" ]]; then
  [[ -f "$ARTIFACT_FILE" ]] || die "artifact file not found: $ARTIFACT_FILE"
  case "$ARTIFACT_FILE" in
    /*) : ;;
    *)  ARTIFACT_FILE="$(cd "$(dirname "$ARTIFACT_FILE")" && pwd)/$(basename "$ARTIFACT_FILE")" ;;
  esac
  export RELAY_ARTIFACT_FILE="$ARTIFACT_FILE"
  [[ "$RELAY_WORKTREE_ISOLATION" != 0 ]] || \
    printf 'relay-drive: WARNING — --artifact-file needs worktree isolation to seed the artifact; with RELAY_WORKTREE_ISOLATION=0 the reviewer will not see it.\n' >&2
fi

file_status() { sed -n 's/^STATUS:[[:space:]]*//p' "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
# GH-245 defect 2: evidence a turn actually DID something, independent of token movement — the NEXT:
# handoff pointer and a content signature of the relay file. A review that appends findings changes
# the file content (and usually flips NEXT:) even when the reviewer leaves the token claimed; an empty
# token-only move changes neither. Used by the --review-once oracle so it classifies on work, not token.
next_pointer() { sed -n 's/^NEXT:[[:space:]]*//p' "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
relay_content_sig() { git hash-object "$RELAY_FILE" 2>/dev/null || cksum "$RELAY_FILE" 2>/dev/null | awk '{print $1}' || echo "?"; }
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
  rfsig="$(relay_content_sig)"   # GH-245: relay-file content signature BEFORE the turn (work evidence)
  nextp="$(next_pointer)"        # GH-245: NEXT: handoff pointer BEFORE the turn

  # Terminal CLOSE requires AGREEMENT: file STATUS terminal AND the RELAY-TURN
  # token no longer live (done/gone). file-terminal-but-token-live is a leaked
  # close — escalate, never report success. (Codex r1 Blocker.)
  if terminal_status "$s"; then
    if [[ -n "$actor" ]]; then
      printf 'relay-drive: STATUS %s but RELAY-TURN still live (%s/%s) — close mismatch, escalating\n' "$s" "$tstatus" "$actor" >&2
      exit 4
    fi
    printf 'relay-drive: relay terminated (STATUS: %s, token done) after %d turn(s)\n' "$s" "$round"
    lane_attempt_reset "${TICK_REPO_ROOT:-$ROOT_DIR}" "$RELAY_TASK"   # GH-45: success clears the attempt counter
    xyz_relay_emit green
    exit 0
  fi

  # Escalated = terminal by design (handback to human); the token may legitimately stay live, so this
  # is checked BEFORE the no-actor branch. A clean, distinct outcome — not a stall (GH-18 #5).
  if escalated_status "$s"; then
    printf 'relay-drive: relay escalated to human by design (STATUS: %s, token %s) after %d turn(s)\n' "$s" "${actor:-done}" "$round" >&2
    xyz_relay_emit orange
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

  preflight_setup_artifact_paths

  if ((DRY_RUN)); then
    printf 'relay-drive: WOULD drive turn for agent: %s (token %s, STATUS: %s)\n' "$actor" "$tstatus" "$s"; exit 0
  fi

  RELAY_DRIVE_STARTED=1   # GH-152: past this point a turn is really being driven — arm the cost summary
  xyz_relay_heartbeat_write
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
    # GH-30 Phase 2: consult-verify transcripts follow the resolver (honors XYZ_ARCHIVE_ROOT). The
    # relay thread + token stay in ROOT_DIR; only this transcript side can redirect. Capture the
    # resolver in its OWN assignment so its exit status isn't masked by the trailing $(date) — a
    # second command substitution in the same assignment would swallow a hard-error (cross-model
    # review Blocker) and silently use a bogus "/<date>" path. Hard-error loud.
    _cv_out_base="$(rtl_transcript_root "$ROOT_DIR")" || exit 1
    _cv_out_dir="$_cv_out_base/$(date +%F)"
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
  nrfsig="$(relay_content_sig)"   # GH-245: relay-file content signature AFTER the turn
  nnextp="$(next_pointer)"        # GH-245: NEXT: handoff pointer AFTER the turn
  # A by-design Escalated handback this turn is terminal, NOT a stall — even if the reviewer left the
  # token live. Catch it before the no-progress guard so it doesn't read as exit 3 (GH-18 #5).
  if escalated_status "$ns"; then
    printf 'relay-drive: relay escalated to human by design (STATUS: %s, token %s:%s) after %d turn(s)\n' "$ns" "$ntstatus" "$nactor" "$round" >&2
    xyz_relay_emit orange
    exit 4
  fi
  # --review-once: the single review turn is complete. Classify with a review oracle so a correct
  # "changes requested" handback is NOT conflated with a no-progress stall (GH-32 #2). Mirrors the
  # Escalated carve-out above — a reviewer that actually DID something is a success, not exit 3.
  if ((REVIEW_ONCE)); then
    # --review-once bypasses the loop's normal terminal/cap exits, so it needs its own XYZ.json emits
    # (approval → green, a completed changes-requested handback → orange, a genuine stall → red) — else
    # this repo's own recommended one-shot review flow would never record a completion (GH-75 review).
    if terminal_status "$ns"; then
      printf 'relay-drive: review-once — reviewer approved/closed (STATUS: %s) after 1 turn\n' "$ns"
      xyz_relay_emit green
      exit 0
    fi
    # GH-245 defect 2: classify on EVIDENCE OF A TURN — the relay file's content changed (findings
    # appended), the NEXT: pointer flipped, or the STATUS word changed — NOT on token movement alone.
    # A token-only move with an unchanged relay file is an empty turn (Run A: was mis-scored 5); a
    # relay-file append with the token left claimed is a real review (Run B: was mis-scored 3). Token
    # state is deliberately dropped from the oracle here — it is exactly the misleading signal.
    if [[ "$nrfsig" != "$rfsig" || "$nnextp" != "$nextp" || "$ns" != "$s" ]]; then
      printf 'relay-drive: review-once — reviewer completed a turn (STATUS: %s, token %s:%s; relay-file/NEXT changed); non-approval handback, not a stall\n' "$ns" "$ntstatus" "$nactor"
      xyz_relay_emit orange
      exit 5
    fi
    printf 'relay-drive: review-once — reviewer took no action (relay file unchanged, NEXT unchanged, STATUS still %s, token %s:%s) — genuine stall\n' "$ns" "$ntstatus" "$nactor" >&2
    xyz_relay_emit red
    exit 3
  fi

  if ! terminal_status "$ns" && [[ "$ntstatus:$nactor" == "$prev" ]]; then
    printf 'relay-drive: no progress after %s turn (token still %s) — escalating\n' "$actor" "$prev" >&2
    xyz_relay_emit red
    exit 3
  fi
done

# Cap reached: success only if file terminal AND token not live (same agreement).
s="$(file_status)"; IFS=$'\t' read -r tstatus actor < <(token_state)
if terminal_status "$s" && [[ -z "$actor" ]]; then
  printf 'relay-drive: relay terminated (STATUS: %s)\n' "$s"; xyz_relay_emit green; exit 0
fi
printf 'relay-drive: round cap (%d) exceeded (STATUS: %s, token actor: %s) — escalating\n' "$ROUND_CAP" "$s" "${actor:-none}" >&2
xyz_relay_emit red
exit 4
