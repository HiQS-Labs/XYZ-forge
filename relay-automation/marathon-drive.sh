#!/usr/bin/env bash
set -euo pipefail

# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
# implementation below — Bash stays the supported default until the port is promoted.
if [[ "${XYZ_PYTHON-1}" == "1" ]]; then
  # UPGRADE.md §4 Phase-2 hardening (GH-255): (2a) `-` not `:-` so an explicit empty XYZ_PYTHON reads
  # as not-1 → Bash (load-bearing once the default flips to 1); (2b) require python3 >=3.8 and fall
  # back to Bash with a warning if it's missing/too-old, so a bad interpreter degrades, not bricks.
  if command -v python3 >/dev/null 2>&1 \
     && python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
    _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    export XYZ_ROOT="$_xyz_root"
    export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
    exec python3 "$_xyz_root/utils/py/marathon_drive.py" "$@"
  else
    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
  fi
fi
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
#     [--builder    <AGENT_ID>]  builder agent (default: codex — GH-212: no per-call API charge;
#                                --builder claude spawns a billed headless Claude Code CLI
#                                subprocess instead — an explicit, cost-acknowledged opt-in)
#     [--round-cap  <N>]         relay-drive round cap (default: 5 = 2*2+1)
#     [--pre-advance-cmd <CMD>]  gate before phase.approved (default: bash validate.sh)
#     [--post-approve-cmd <CMD>] optional command after phase.approved + green telemetry (default: unset)
#     [--phases-dir <DIR>]       where to create phases/<id>/ (default: <repo-root>/phases)
#     [--phase-id <ID>]          which phase to drive: phases/<id>/ (default: p1; the orchestrator sets it)
#     [--relay-task <ID>]        tick task name (default: MARATHON-<PHASE_ID>-TURN)
#     [--artifact <PATHS>]       comma-separated repo-relative file(s) the builder may create/edit
#                                beyond the relay file (passed to the shims as ALLOW_PATHS). Omit for
#                                a relay-only phase (conversation → approval, no source edit).
#     [--require-clean]          hard-stop if the workspace has pre-existing changes (unattended runs)
#     [--requires-test <PATH>]   GH-249 requires_test contract field (opt-in): repo-relative test file
#                                that must be added/modified since this phase started, or the gate
#                                fails (exit 5) even if --pre-advance-cmd passed. Omit for phases with
#                                no test surface (docs-only, config-only) — default behavior unchanged.
#     [--dry-run]                render relay file and print tick seed cmd, then exit
#
# Environment overrides (for tests):
#   MARATHON_ROOT         — git repo root (default: parent of this script's dir)
#   MARATHON_RELAY_DRIVE  — relay-drive.sh path (default: this script's dir/relay-drive.sh)
#   MARATHON_AGENT_CMD    — --agent-cmd value (default: this script's dir/marathon-agent.sh)
#   TICK_BIN              — tick binary (default: <repo-root>/bin/tick)
#
# Exit: 0 phase approved + gate passed · 3 relay no-progress · 4 relay cap/mismatch ·
#        5 pre-advance gate failed (also covers a failed --requires-test check — see ESCALATION.md
#        reason: pre-advance-failed vs. requires-test-missing) ·
#        6 containment violation (turn-taker reverted an off-lane edit) ·
#        7 turn timeout / hang · 8 lane parked (GH-45 attempt cap — no token seeded; re-fire with
#        --force) · 9 post-approve command failed (phase remains approved) · 2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# _xyz_harness: the directory containing relay-automation/ (and bin/, src/, utils/).
# Vendored install: HERE is <target>/.xyz/relay-automation → _xyz_harness is <target>/.xyz
# (basename ".xyz"). ROOT = work root = where git ops, phases/, .tick/, validate.sh live.
_xyz_harness="$(cd "$HERE/.." && pwd)"
if [ "$(basename "$_xyz_harness")" = ".xyz" ]; then
  ROOT="${MARATHON_ROOT:-"$(cd "$_xyz_harness/.." && pwd)"}"
else
  ROOT="${MARATHON_ROOT:-"$_xyz_harness"}"
fi
# GH-30 Phase 2: transcript-root resolver (rtl_transcript_root) — redirects relay-system/ to
# $XYZ_ARCHIVE_ROOT when set, else byte-for-byte "$ROOT/relay-system". Sourced beside this script.
source "$HERE/relay-turn-lib.sh"
TICK_BIN="${TICK_BIN:-"$_xyz_harness/bin/tick"}"
RELAY_DRIVE_BIN="${MARATHON_RELAY_DRIVE:-"$HERE/relay-drive.sh"}"
AGENT_CMD="${MARATHON_AGENT_CMD:-"$HERE/marathon-agent.sh"}"

# GH-45 — QUEUE commitment contract: per-lane attempt cap (anti-rabbit-hole / WIP discipline).
# lane_attempt_gate appends one line per fire to .tick/attempts/<lane> and REFUSES to start a lane at
# >= LANE_MAX_ATTEMPTS (default 2, env-overridable) with exit 8 + a park message, seeding NO relay
# token. --force bypasses for one fire and logs it. lane_attempt_reset clears the counter when a lane
# COMPLETES successfully (Approved), so the cap counts CONSECUTIVE failures and can never permanently
# wedge a lane (reviewer feedback: without a reset a default-keyed lane parks forever). A nested call
# (marathon-drive → relay-drive) is guarded by LANE_ATTEMPT_COUNTED so the same lane is counted (and
# reset) exactly once. Byte-consistent mirror in relay-drive.sh; relay-turn-lib.sh/bin/tick untouched.
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

# GH-162 — debug-mantra auto-trigger. NOT part of the GH-45 byte-identical mirror block above
# (test/lane-attempt-cap.sh diffs _lane_key..lane_attempt_reset between the two drivers verbatim) —
# kept below it deliberately so that contract stays untouched.
#
# debug_mantra_prior_attempts is a READ-ONLY peek at the SAME .tick/attempts/<lane> file GH-45 already
# maintains (via _lane_key, defined above) — it never writes. lane_attempt_gate is still the only
# writer/park authority; this only answers "did the last attempt at this phase fail to reach Approved"
# so the render step below (Step 1) can decide whether to inject the debug-mantra note, which must
# happen BEFORE lane_attempt_gate's own call (Step 3) appends this fire's own line.
debug_mantra_prior_attempts() {  # <root> <lane-key-raw>
  local root="$1" raw="$2" key file count
  key=$(_lane_key "$raw"); file="$root/.tick/attempts/$key"
  count=0; [ -f "$file" ] && count=$(wc -l < "$file" 2>/dev/null | tr -d ' '); [ -n "$count" ] || count=0
  printf '%s' "$count"
}

# Renders the note injected into the relay file when a prior attempt exists; empty output on a first
# attempt (prior=0) — mirrors relay-turn-lib.sh's rtl_drift_brief "say nothing when there is nothing to
# say" convention, so a normal first-fire relay file is byte-identical to before this feature existed.
# Cites the last ESCALATION.md reason (if any) as the concrete breadcrumb, rather than inventing a new
# ledger — GH-162 Phase 0 found the harness already persists exactly this evidence.
debug_mantra_note() {  # <prior-count> <phase-dir> <debug-mantra-file>
  local prior="$1" phase_dir="$2" mantra_file="$3" reason=""
  [ "${prior:-0}" -ge 1 ] 2>/dev/null || return 0
  [ -f "$phase_dir/ESCALATION.md" ] && reason="$(sed -n 's/^reason:[[:space:]]*//p' "$phase_dir/ESCALATION.md" | head -1)"
  printf '\n## Debug mantra (auto-triggered — %s prior attempt(s) on this phase did not reach Approved)\n\n' "$prior"
  printf 'Before trying again, read %s and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.\n' "$mantra_file"
  if [ -n "$reason" ]; then
    printf 'Last recorded reason (%s/ESCALATION.md): `%s`. Read it before re-guessing.\n' "$phase_dir" "$reason"
  fi
}

# GH-222 (COST-OBSERVABILITY-PLAN.md Phase 6 follow-on): auto-surface the `tick analyze` cost block
# at end-of-run so a marathon-drive.sh phase (standalone or as one phase of a marathon.sh chain)
# stops needing a manual `tick analyze` pull to see what it cost. Mirrors relay-drive.sh's own
# xyz_relay_cost_summary() (GH-152) VERBATIM — same TICK_BIN analyze --format human call, same
# `--- cost ---` block extraction, no new cost computation here (DRY). relay-drive.sh's nested
# per-phase call is told RELAY_COST_SUMMARY=0 below (run_relay_drive/run_relay_review_once) so a
# single phase never shows the block twice (once from the nested relay-drive, once from here) — this
# script becomes the one place a driven phase's cost is surfaced, picking up the responsibility
# relay-drive.sh's own silenced-when-nested precedent (XYZ_HARNESS_CONTEXT) defers to the outer
# harness. A bare/swarm-fired single-phase run IS the whole run, so this fires exactly once at its
# own exit. Driven via marathon.sh, each phase's marathon-drive subprocess still prints its OWN
# cumulative total at ITS exit (marathon.sh is untouched by this fix and holds no cross-phase state
# to gate a single final print on) — since `tick analyze` is monotonically cumulative, the LAST
# phase's print is the whole chain's true final total; earlier phases' prints are an additive
# running-total view, not stale/duplicate data. Opt out entirely with MARATHON_COST_SUMMARY=0.
# Default-on and strictly additive: only fires once MARATHON_DRIVE_STARTED is set (i.e. this phase
# got past --help/usage/lock-contention/lane-parked/--dry-run and is really being driven), and a
# failed/forced `tick analyze` is swallowed best-effort — it can never change the driven run's own
# exit code (wired via the EXIT trap below, same one the lock cleanup uses).
: "${MARATHON_COST_SUMMARY:=1}"
# Sentinel Tier 1 (GH-281): opt-in debug capture. Default OFF — public-repo posture (no phone-home).
# When 1, harness signals append to a single PDDA-output-contract JSONL file at repo root.
: "${XYZ_DEBUG_LOG:=0}"
: "${DEBUG_LOG_FILE:=$ROOT/debug.log}"
MARATHON_DRIVE_STARTED=0
xyz_marathon_cost_summary() {
  [[ "$MARATHON_DRIVE_STARTED" == "1" ]] || return 0
  [[ "$MARATHON_COST_SUMMARY" != "0" ]] || return 0
  local report block
  report="$("$TICK_BIN" analyze --format human 2>/dev/null)" || {
    printf 'marathon-drive: tick analyze failed — end-of-run cost summary unavailable (MARATHON_COST_SUMMARY=0 to silence)\n' >&2
    return 0
  }
  block="$(printf '%s\n' "$report" | sed -n '/^--- cost ---$/,$p')"
  [[ -n "$block" ]] || return 0
  printf '\nmarathon-drive: end-of-run cost summary (tick analyze) —\n%s\n' "$block" >&2
}

if [[ "${RELAY_DRIVER_LOCKED:-0}" != "1" ]]; then
  # GH-49b: the lock lives in .git/ (never committed) for a normal clone; a vendored .xyz/ copy has no
  # .git/. In a linked worktree, .git is a file pointing at the shared gitdir, so resolve the real
  # common dir and place the lock there; otherwise --require-clean sees the driver's own bookkeeping as
  # untracked dirt inside the worktree. A vendored .xyz/ copy still falls back to a hidden lock beside
  # the scripts (the .xyz/ dir is itself gitignored in the foreign repo, so it stays uncommitted just
  # the same). Same lock NAME as relay-drive so a marathon and a relay driver still mutually exclude in
  # one clone.
  if [[ -d "$ROOT/.git" ]]; then
    _lock="$ROOT/.git/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
  elif [[ -f "$ROOT/.git" ]]; then
    _git_common_dir="$(git -C "$ROOT" rev-parse --git-common-dir 2>/dev/null || true)"
    if [[ -n "$_git_common_dir" ]]; then
      _lock="$_git_common_dir/relay-driver.lock"; _lock_label=".git/relay-driver.lock"
    else
      _lock="$ROOT/.relay-driver.lock";           _lock_label=".relay-driver.lock"
    fi
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
    # Sentinel Tier 1 (GH-281): the append helper isn't defined this early — inline a gated write.
    if [[ "${XYZ_DEBUG_LOG:-0}" == "1" ]]; then
      { printf '{"timestamp":"%s","severity":"info","check":"marathon.stale-lock","scope":"harness","repo":"%s","message":"stale driver lock reclaimed","action":"none (auto-healed)"}\n' \
          "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$ROOT" >> "${DEBUG_LOG_FILE:-$ROOT/debug.log}"; } 2>/dev/null || true
    fi
    rm -rf "$_lock"
    mkdir "$_lock" 2>/dev/null || { printf 'marathon-drive: could not acquire relay-driver.lock after reclaiming a stale one.\n' >&2; exit 1; }
    # ponytail: tiny TOCTOU window (two drivers could both reclaim a stale lock); acceptable for a
    # single-operator clone — add an atomic PID-CAS only if true multi-operator concurrency appears.
  fi
  printf '%s\n' "$$" > "$_lock/pid"
  # GH-222: the cost summary is wired into the SAME exit trap as the lock cleanup (the one place
  # every exit path already funnels through), mirroring relay-drive.sh's GH-152 wiring exactly.
  # `_code` is captured FIRST and the trap re-exits with it explicitly: `xyz_marathon_cost_summary`
  # (or the lock rm) failing/erroring under `set -e` inside a trap would otherwise silently overwrite
  # the script's real exit status with the trap's own — so a forced/failed analyze call can NEVER
  # flip the driven run's reported result.
  _marathon_drive_on_exit() {
    local _code=$?
    xyz_marathon_cost_summary
    rm -rf "$_lock" 2>/dev/null || true
    exit "$_code"
  }
  trap _marathon_drive_on_exit EXIT
  export RELAY_DRIVER_LOCKED=1
fi

die()  { printf 'marathon-drive: %s\n' "$*" >&2; exit 2; }
log()  { printf 'marathon-drive: %s\n' "$*"; }

XYZ_APPEND_BIN="${XYZ_APPEND_BIN:-"$_xyz_harness/utils/telemetry/append-xyz-completion.sh"}"
XYZ_HEARTBEAT_BIN="${XYZ_HEARTBEAT_BIN:-"$_xyz_harness/utils/telemetry/write-xyz-heartbeat.sh"}"

# GH-75: append ONE final-completion record for a run whose WHOLE completion IS this single-phase
# marathon-drive — i.e. a bare `marathon-drive.sh` run (harness:"marathon") or a swarm-preflight-
# originated run (harness:"swarm", tagged via XYZ_HARNESS_CONTEXT=swarm baked into the generated
# invocation). Stays SILENT when marathon.sh drives us per-phase (XYZ_HARNESS_CONTEXT=marathon-phase):
# marathon.sh emits the single whole-run record itself. Health is binary green/red (halt-on-first-
# failure has no distinct "escalated mid-chain" state). Best-effort — never changes marathon-drive's
# own exit code.
xyz_marathon_heartbeat_write() {
  [[ -x "$XYZ_HEARTBEAT_BIN" ]] || return 0
  local ctx="${XYZ_HARNESS_CONTEXT:-}" harness sid
  case "$ctx" in swarm) harness="swarm" ;; *) harness="marathon" ;; esac
  sid="${XYZ_SESSION_ID:-$PHASE_ID}"
  "$XYZ_HEARTBEAT_BIN" "$harness" "$sid" >/dev/null 2>&1 || true
}

xyz_marathon_heartbeat_clear() {
  [[ -x "$XYZ_HEARTBEAT_BIN" ]] || return 0
  local ctx="${XYZ_HARNESS_CONTEXT:-}" harness sid
  case "$ctx" in swarm) harness="swarm" ;; *) harness="marathon" ;; esac
  sid="${XYZ_SESSION_ID:-$PHASE_ID}"
  XYZ_HEARTBEAT_CLEAR=1 "$XYZ_HEARTBEAT_BIN" "$harness" "$sid" >/dev/null 2>&1 || true
}

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

# Sentinel Tier 1 (GH-281): append ONE PDDA-output-contract JSONL finding to $DEBUG_LOG_FILE.
# Opt-in (XYZ_DEBUG_LOG=1), default off. Writes only this one local file — no network, no
# PDDA-ACTIVITY.jsonl, no telemetry. NEVER fails the run.
_json_esc() {  # normalize all C0/DEL controls (UTF-8 safe), then escape backslash + quote
  local s="$1"; s="$(printf '%s' "$s" | tr '\000-\037\177' ' ')"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
  printf '%s' "$s"
}
xyz_debug_log_append() {  # <severity> <check> <message> [file] [action] [probe]
  [[ "${XYZ_DEBUG_LOG:-0}" == "1" ]] || return 0
  local sev="$1" chk="$2" msg="$3" file="${4:-}" action="${5:-}" probe="${6:-}" ts scope
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  scope="${TARGET_ROOT:+target:$TARGET_ROOT}"; scope="${scope:-harness}"
  printf '{"timestamp":"%s","severity":"%s","check":"%s","scope":"%s","repo":"%s","phase":"%s","task":"%s","file":"%s","line":"","message":"%s","action":"%s","probe":"%s"}\n' \
    "$ts" "$sev" "$chk" "$(_json_esc "$scope")" "$(_json_esc "${TARGET_ROOT:-$ROOT}")" "$(_json_esc "${PHASE_ID:-}")" "$(_json_esc "${RELAY_TASK:-}")" \
    "$(_json_esc "$file")" "$(_json_esc "$msg")" "$(_json_esc "$action")" "$(_json_esc "$probe")" \
    >> "$DEBUG_LOG_FILE" 2>/dev/null || true
}

file_status() { sed -n 's/^STATUS:[[:space:]]*//p' "$RELAY_FILE" | head -1 | sed 's/[[:space:]]*$//'; }
terminal_status() { case "$1" in Approved|Closed) return 0 ;; *) return 1 ;; esac; }
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

# GH-274: has this phase's relay ALREADY reached a terminal state (RELAY_FILE's STATUS is
# Approved/Closed) with its tick token ALREADY `done`? If so there is nothing left to
# (re)build or (re)review — the only reason to re-invoke marathon-drive.sh for it is to
# retry a flaky --pre-advance-cmd without touching the phase's own record. A `done` tick
# token can never be reopened (reconcile_relay_task's correct, existing behavior), so
# re-rendering + re-seeding here would only clobber the accurate terminal RELAY.md before
# failing anyway. Checked before Step 1's render (below); extends GH-207's already-satisfied
# detection (recover_already_satisfied_lane, triggered mid-relay on a no-progress reroute)
# to this separate post-terminal-gate-retry trigger.
satisfied_lane_terminal() {
  local s tstatus actor
  [[ -f "$RELAY_FILE" ]] || return 1
  s="$(file_status)"
  terminal_status "$s" || return 1
  IFS=$'\t' read -r tstatus actor < <(token_state)
  [[ "$tstatus" == "done" ]]
}

run_pre_advance_gate() {
  (
    if [[ -n "$TARGET_ROOT" ]]; then
      cd "$TARGET_ROOT"
    fi
    # GH-307: the gate is a correctness check on the REPO — not part of this run's provenance,
    # and it must not be able to see who is driving it. These tags otherwise leak into the gate
    # via this subshell and break tests that legitimately assert on them
    # (test/xyz-harness-hooks.sh reads XYZ_HARNESS_CONTEXT / XYZ_SESSION_ID; test/debug-mantra.sh
    # reads MARATHON_LANE_NS), which made `bash validate.sh` — the DOCUMENTED DEFAULT GATE —
    # impossible to pass inside a marathon. Keep this list identical to GATE_SCRUBBED_ENV in
    # utils/py/marathon_drive.py; the Python twin is what runs by default (XYZ_PYTHON-1).
    # Deliberately narrow: run-identity tags only, never repo/config inputs like MARATHON_ROOT,
    # TICK_BIN or TICK_REPO_ROOT, which a gate may legitimately need.
    unset XYZ_HARNESS_CONTEXT XYZ_SESSION_ID MARATHON_LANE_NS
    eval "$PRE_ADVANCE_CMD"
  )
}

run_post_approve_cmd() {
  (
    if [[ -n "$TARGET_ROOT" ]]; then
      cd "$TARGET_ROOT"
    fi
    eval "$POST_APPROVE_CMD"
  )
}

artifacts_exist_for_timeout() {
  local path
  [[ -n "$ARTIFACT_PATHS" ]] || return 1
  IFS=',' read -ra _artifact_paths <<<"$ARTIFACT_PATHS"
  for path in "${_artifact_paths[@]}"; do
    path="${path#"${path%%[![:space:]]*}"}"
    path="${path%"${path##*[![:space:]]}"}"
    [[ -n "$path" ]] || continue
    path_has_nonempty_phase_delta "$path" || return 1
  done
  return 0
}

# GH-249: the requires_test contract field. A brief's acceptance criteria calling for a new/updated
# test used to be advisory prose — --pre-advance-cmd only proves "existing tests still pass," not that
# this phase added the coverage its brief demanded. When --requires-test PATH is set, this check must
# ALSO pass before the phase can reach Approved: PATH must exist, be non-empty, and have changed since
# PRE_PHASE_HEAD (committed diff) or be newly untracked (a turn-taker edit not yet committed at gate
# time). Opt-in and additive — REQUIRES_TEST stays empty unless a caller sets --requires-test, so a
# run with no such flag is byte-for-byte the same gate behavior as before this feature existed.
path_has_nonempty_phase_delta() {  # <path> — true if non-empty and added/modified since PRE_PHASE_HEAD
  local path="$1" root="${TARGET_ROOT:-$ROOT}" abs git_path
  case "$path" in
    /*) abs="$path" ;;
    *)  abs="$root/$path" ;;
  esac
  [[ -s "$abs" ]] || return 1   # an empty/missing artifact proves nothing
  git_path="$path"
  [[ "$path" == /* && "$path" == "$root/"* ]] && git_path="${path#"$root/"}"
  if [[ -n "$PRE_PHASE_HEAD" ]] \
    && git -C "$root" diff --name-only "$PRE_PHASE_HEAD" -- "$git_path" 2>/dev/null | grep -q .; then
    return 0
  fi
  # A newly created file may still be untracked at gate time (harness commits happen inside the relay
  # loop, but nothing guarantees a same-cycle commit for every edit) — count that as a delta too.
  git -C "$root" status --porcelain -- "$git_path" 2>/dev/null | grep -qE '^(\?\?|A )' && return 0
  return 1
}

requires_test_delta() {  # <path> — true if <path> was added/modified since PRE_PHASE_HEAD
  path_has_nonempty_phase_delta "$1"
}

usage() {
  cat <<'EOF'
Usage: relay-automation/marathon-drive.sh --phase-brief FILE --reviewer AGENT [options]

  --phase-brief FILE      Phase brief markdown baked into the relay template (required).
  --reviewer AGENT        Reviewer agent id; must start with 'codex', 'gemini', or 'agy' (required).
  --builder AGENT         Builder agent id (default: codex — GH-212: no per-call API charge; bills
                          via the Codex/ChatGPT subscription, agy is the other cost-blind option).
                          --builder claude spawns a headless Claude Code CLI subprocess instead: a
                          SEPARATE, PER-CALL API-BILLED turn-taker — use it only as an explicit,
                          cost-acknowledged choice, not the default.
  --round-cap N           relay-drive turn cap (default: 5).
  --pre-advance-cmd CMD   Gate before phase.approved (default: bash validate.sh).
  --post-approve-cmd CMD  Optional command after phase.approved + green telemetry (default: unset).
                          Failure preserves approval, writes reason post-approve-failed, and exits 9.
  --phases-dir DIR        Where to create phases/<id>/ (default: <repo-root>/phases).
  --phase-id ID           Which phase to drive: phases/<id>/ (default: p1).
  --relay-task ID         Tick task name (default: MARATHON-<PHASE_ID>-TURN).
  --artifact PATHS        Comma-separated repo-relative file(s) the builder may create/edit beyond
                          the relay file (ALLOW_PATHS for the turn-takers). Omit for a relay-only phase.
  --target-root DIR       Foreign git repo the BUILD lands in (GH-11). The relay thread + tick token
                          stay in this repo; forwarded to relay-drive.sh, and the pre-advance gate runs
                          with cwd = DIR. Omit for a same-repo phase.
  --require-clean         Hard-stop (exit 2) if the workspace has pre-existing changes before seeding.
  --requires-test PATH    GH-249 requires_test contract field (opt-in): repo-relative test file that
                          must be added/modified by this phase, or the pre-advance gate fails (exit 5)
                          even when --pre-advance-cmd passed. Omit for phases with no test surface
                          (e.g. docs-only) — default gate behavior is unchanged without this flag.
  --force                 GH-45: bypass the per-lane attempt cap for this fire (re-fire a parked lane).
  --dry-run               Render the relay file and print the tick seed; exit without running.
EOF
}

PHASE_BRIEF_FILE=""
BUILDER="codex"
REVIEWER=""
ROUND_CAP=5
PRE_ADVANCE_CMD=""   # resolved to default after ROOT is set
POST_APPROVE_CMD=""  # optional command after approval + green telemetry; empty = disabled
PHASES_DIR=""        # resolved to default after ROOT is set
PHASE_ID="p1"        # which phase this invocation drives (phases/<id>/); the orchestrator sets it
RELAY_TASK=""        # resolved to MARATHON-<PHASE_ID>-TURN after parsing, unless given
ARTIFACT_PATHS=""    # comma-separated repo-relative file(s) the builder may create/edit (beyond RELAY.md)
REQUIRE_CLEAN=0      # --require-clean: hard-stop if the workspace has pre-existing changes
REQUIRES_TEST=""     # --requires-test PATH: GH-249 requires_test contract field (opt-in; empty = off)
FORCE=0              # --force: bypass the GH-45 per-lane attempt cap for this one fire
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
    --post-approve-cmd) POST_APPROVE_CMD="${2:-}"; shift 2 ;;
    --phases-dir)      PHASES_DIR="${2:-}"; shift 2 ;;
    --phase-id)        PHASE_ID="${2:-}"; shift 2 ;;
    --relay-task)      RELAY_TASK="${2:-}"; shift 2 ;;
    --artifact)        ARTIFACT_PATHS="${2:-}"; shift 2 ;;
    --target-root)     TARGET_ROOT="${2:-}"; shift 2 ;;
    --require-clean)   REQUIRE_CLEAN=1; shift ;;
    --requires-test)   REQUIRES_TEST="${2:-}"; shift 2 ;;
    --force)           FORCE=1; shift ;;
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

# GH-238: a vendored consumer normally has no root-level validate.sh.  Do not spend a builder and
# reviewer turn only to discover that the default gate cannot start after approval.  This is a
# deliberately non-executing probe: gates such as `test -f build/output` may only become true after
# the builder runs, so executing them here would turn valid gates into false preflight failures.
pre_advance_not_runnable() {  # <reason>
  die "pre-advance gate not runnable: '$PRE_ADVANCE_CMD' ($1). Pass --pre-advance-cmd '<runnable command>' to override it."
}
preflight_pre_advance_gate() {
  local command_name gate_shell script_arg gate_path gate_root
  gate_root="${TARGET_ROOT:-$ROOT}"

  bash -n -c "$PRE_ADVANCE_CMD" >/dev/null 2>&1 \
    || pre_advance_not_runnable "shell syntax is invalid"

  # The default (and the normal custom-script form) is `bash <script>`.  Check both the interpreter
  # and its script target; merely checking `bash` would miss the absent validate.sh that caused GH-238.
  if [[ "$PRE_ADVANCE_CMD" =~ ^[[:space:]]*(bash|/[^[:space:]]*/bash)[[:space:]]+([^[:space:]]+) ]]; then
    gate_shell="${BASH_REMATCH[1]}"
    script_arg="${BASH_REMATCH[2]}"
    command -v "$gate_shell" >/dev/null 2>&1 \
      || pre_advance_not_runnable "interpreter '$gate_shell' is not on PATH"
    case "$script_arg" in
      \"*\") script_arg="${script_arg#\"}"; script_arg="${script_arg%\"}" ;;
      \'*\') script_arg="${script_arg#\'}"; script_arg="${script_arg%\'}" ;;
    esac
    # `bash -c ...` and other interpreter options do not name a script file to preflight.
    [[ "$script_arg" == -* ]] && return 0
    gate_path="$script_arg"
    [[ "$gate_path" == /* ]] || gate_path="$gate_root/$gate_path"
    [[ -f "$gate_path" ]] \
      || pre_advance_not_runnable "script file does not exist: $gate_path"
    return 0
  fi

  # For command-style gates (for example `true`, `npm test`, or `test -f build/output`), checking
  # the leading command catches misspellings while preserving the gate's existing post-build meaning.
  read -r command_name _ <<< "$PRE_ADVANCE_CMD"
  [[ -n "$command_name" ]] || pre_advance_not_runnable "command is empty"
  if [[ "$command_name" == */* ]]; then
    gate_path="$command_name"
    [[ "$gate_path" == /* ]] || gate_path="$gate_root/$gate_path"
    [[ -x "$gate_path" ]] \
      || pre_advance_not_runnable "executable does not exist or is not executable: $gate_path"
  else
    command -v "$command_name" >/dev/null 2>&1 \
      || pre_advance_not_runnable "command '$command_name' is not on PATH"
  fi
}
# GH-238: a --dry-run renders the relay file and prints the tick seed, then exits — it never
# dispatches a builder or reviewer turn, so there is no wasted-turn cost to protect against and
# halting would be pure downside. It also breaks fixtures that drive unrelated paths in repos with
# no gate script (test/driver-lock.sh regressed exactly this way when the check halted every run).
# Still surface the problem, so --dry-run stays a useful plan sanity-check: the subshell contains
# pre_advance_not_runnable's die(), turning the halt into a warning on this path only.
if ((DRY_RUN)); then
  ( preflight_pre_advance_gate ) \
    || printf 'marathon-drive: (dry-run continues; a live run would halt here)\n' >&2
else
  preflight_pre_advance_gate
fi

# Default the tick token name off the phase id (p1 → MARATHON-P1-TURN), keeping the Phase-3 default.
RELAY_TASK="${RELAY_TASK:-"MARATHON-$(printf '%s' "$PHASE_ID" | tr '[:lower:]' '[:upper:]')-TURN"}"
LANE_STATE_KEY="${MARATHON_LANE_NS:-$PHASE_ID}"

# GH-249: snapshot HEAD (in the repo the artifact actually lands in — TARGET_ROOT when set, else ROOT)
# before this phase's first commit, so requires_test_delta (below) has a true "before this phase"
# baseline to diff against. Captured unconditionally — cheap, and unused unless --requires-test is set.
PRE_PHASE_HEAD="$(git -C "${TARGET_ROOT:-$ROOT}" rev-parse HEAD 2>/dev/null || true)"

# Map builder/reviewer to _AGENT env vars for marathon-agent.sh routing. Both actors are routed to
# their shim by name prefix (claude/codex/agy/gemini), so the harness supports cross-model BUILDERS
# (e.g. agy) — not just Claude. Builder defaults to claude for back-compat.
export MARATHON_BUILDER="$BUILDER"
export MARATHON_REVIEWER="$REVIEWER"
export CLAUDE_AGENT="" CODEX_AGENT="" AGY_AGENT="" AIDER_AGENT=""
route_agent() {  # <agent-id> → export the matching *_AGENT var marathon-agent.sh routes on
  case "$1" in
    claude*) export CLAUDE_AGENT="$1" ;;
    codex*)  export CODEX_AGENT="$1" ;;
    agy*)    export AGY_AGENT="$1" ;;
    aider*)  export AIDER_AGENT="$1" ;;
    *)       die "agent '$1' not recognized — must start with claude/codex/agy/aider" ;;
  esac
}
[[ "$BUILDER" == "$REVIEWER" ]] && die "builder and reviewer must be different agent ids (got '$BUILDER' for both)"
route_agent "$BUILDER"
route_agent "$REVIEWER"
# Reviewer must be a QA-capable model lane (codex/gemini/agy), never the Claude builder lane.
case "$REVIEWER" in codex*|gemini*|agy*) ;; *) die "reviewer '$REVIEWER' must start with codex/gemini/agy" ;; esac

# GH-117: probe the builder/reviewer binary's existence on PATH here — before ANY tick state
# mutation (task.created/claim/release at :386+ below) or even Step 0's clean-workspace check —
# on both --dry-run and live paths. A missing binary used to only surface deep inside the turn-taker
# dispatch, by which point the relay task was already seeded: a live dogfood run against rebalance-OS
# hit a missing `claude` builder and left MARATHON-P1-TURN permanently `open` (this repo's tick-token
# model can't reopen a spent task — recovering it needed #116's --retry flag or a manual phase rename).
# Failing here instead means a missing binary dies clean, with no spent token and no manual cleanup.
_probe_bin() {  # <bin> <role-label> <agent-id> — die if not found on PATH
  command -v "$1" >/dev/null 2>&1 \
    || die "$2 binary '$1' not found on PATH (--$2 agent '$3')"
}
_probe_claude_bin() {  # <role-label> — mirrors claude-turn.sh's own CLAUDE_BIN resolution (GH-58):
                       # explicit CLAUDE_BIN override, else `claude` on PATH, else the local Claude
                       # Code install fallback. Kept in lockstep so this probe never rejects a setup
                       # the real dispatch would still accept.
  if [[ -n "${CLAUDE_BIN:-}" ]]; then
    command -v "$CLAUDE_BIN" >/dev/null 2>&1 && return 0
  else
    command -v claude >/dev/null 2>&1 && return 0
    [[ -x "$HOME/.claude/local/claude" ]] && return 0
  fi
  die "$1 binary 'claude' not found on PATH (set CLAUDE_BIN or use a codex/agy --$1 agent)"
}
_probe_agent_bin() {  # <agent-id> <role-label>
  case "$1" in
    claude*) _probe_claude_bin "$2" ;;
    codex*)  _probe_bin "${CODEX_BIN:-codex}" "$2" "$1" ;;
    agy*)    _probe_bin "${AGY_BIN:-agy}"     "$2" "$1" ;;
    aider*)  _probe_bin "${AIDER_BIN:-aider}" "$2" "$1" ;;
  esac
}
_probe_agent_bin "$BUILDER"  builder
_probe_agent_bin "$REVIEWER" reviewer

# Artifact allowlist: when a phase targets real file(s), pass them as ALLOW_PATHS so the turn-takers
# may create/edit them. The shared safety core (relay-turn-lib.sh) reverts ANY edit outside this
# allowlist + the always-allowed relay file — so containment still holds; the builder just gains a
# real write surface. Without --artifact, ALLOW_PATHS stays unset and the phase is relay-only.
if [[ -n "$ARTIFACT_PATHS" ]]; then
  export ALLOW_PATHS="$ARTIFACT_PATHS"
else
  unset ALLOW_PATHS
fi

PHASE_DIR="$PHASES_DIR/$LANE_STATE_KEY"
RELAY_FILE="$PHASE_DIR/RELAY.md"
REL_RELAY="${RELAY_FILE#"$ROOT"/}"   # repo-root-relative path the agent edits / declares in claim --paths

# Bound early (moved ahead of Step 3's own copy below) so the GH-274 satisfied-lane check
# just below — and the escalate/complete_phase_success defs it may call — read/write tick
# state against the right repo even when a caller invoked us without pre-exporting it.
export TICK_REPO_ROOT="$ROOT"

# escalate/save_transcript/complete_phase_success are defined here (ahead of Step 1) instead
# of beside their Step 6 call sites so the GH-274 satisfied-lane short-circuit below — which
# must run BEFORE Step 1's render — can call complete_phase_success directly rather than
# duplicating its gate/requires-test/telemetry logic.
escalate() {  # <reason> <relay-exit>
  local reason="$1" rexit="$2"
  # Sentinel Tier 1 (GH-281): harvest a failed phase's Side Findings before they are lost.
  if [[ "${XYZ_DEBUG_LOG:-0}" == "1" && -x "$HERE/harvest-findings.sh" ]]; then
    "$HERE/harvest-findings.sh" --relay "$RELAY_FILE" \
      --scope "${TARGET_ROOT:+target:$TARGET_ROOT}" --repo "${TARGET_ROOT:-$ROOT}" \
      --out "${DEBUG_LOG_FILE:-$ROOT/debug.log}" >/dev/null 2>&1 || true
  fi
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
  xyz_debug_log_append error "marathon.escalation" "$reason (relay-drive-exit=$rexit)" \
    "$REL_RELAY" "promote to PROJECT/1-INBOX capture doc"
}

save_transcript() {
  # GH-30 Phase 2: resolve the transcript base (honors XYZ_ARCHIVE_ROOT; hard-errors if set-invalid).
  # Declare then assign separately so the resolver's exit code isn't masked by `local` under set -e.
  local date_dir _ts_base; _ts_base="$(rtl_transcript_root "$ROOT")" || return 1
  date_dir="$_ts_base/$(date +%Y-%m-%d)"
  mkdir -p "$date_dir"
  local ts; ts="$(date +%H%M%S)"
  local dest="$date_dir/marathon-${PHASE_ID}-${ts}.md"
  cp "$RELAY_FILE" "$dest"
  # Sentinel Tier 1 (GH-281): harvest Side Findings from the saved transcript.
  if [[ "${XYZ_DEBUG_LOG:-0}" == "1" && -x "$HERE/harvest-findings.sh" ]]; then
    "$HERE/harvest-findings.sh" --relay "$RELAY_FILE" \
      --scope "${TARGET_ROOT:+target:$TARGET_ROOT}" --repo "${TARGET_ROOT:-$ROOT}" \
      --out "${DEBUG_LOG_FILE:-$ROOT/debug.log}" >/dev/null 2>&1 || true
  fi
  git -C "$ROOT" add -- "$dest"
  if git -C "$ROOT" diff --cached --quiet -- "$dest"; then
    log "transcript unchanged: $dest"
  else
    git -C "$ROOT" commit -q -m "marathon: phase ${PHASE_ID} transcript saved (${RELAY_TASK})"
    log "transcript saved: $dest"
  fi
}

complete_phase_success() {
  local success_mode="${1:-approved}" gate_exit=0 post_approve_exit=0 success_text=""
  log "relay approved — running pre-advance gate: $PRE_ADVANCE_CMD"
  run_pre_advance_gate || gate_exit=$?
  if [[ "$gate_exit" -ne 0 ]]; then
    log "pre-advance gate FAILED (exit $gate_exit) — escalating"
    escalate "pre-advance-failed" 0
    xyz_marathon_heartbeat_clear
    xyz_marathon_emit red "halted at phase ${PHASE_ID} — pre-advance gate failed"
    exit 5
  fi
  if [[ -n "$REQUIRES_TEST" ]] && ! requires_test_delta "$REQUIRES_TEST"; then
    log "requires-test FAILED — no new/updated test detected at: $REQUIRES_TEST"
    escalate "requires-test-missing" 0
    xyz_marathon_heartbeat_clear
    xyz_marathon_emit red "halted at phase ${PHASE_ID} — required test not added/updated: $REQUIRES_TEST"
    exit 5
  fi
  if [[ "$success_mode" == "already-satisfied" ]]; then
    success_text="phase ${PHASE_ID} complete — lane_already_satisfied, reviewer approved, gate passed"
  else
    success_text="phase ${PHASE_ID} complete — STATUS: Approved, gate passed"
  fi
  "$TICK_BIN" log marathon.phase.approved "$RELAY_TASK" --agent marathon > /dev/null || true
  lane_attempt_reset "${TICK_REPO_ROOT:-$ROOT}" "$LANE_STATE_KEY"
  save_transcript
  xyz_marathon_heartbeat_clear
  log "$success_text"
  xyz_marathon_emit green "$success_text"
  if [[ -n "$POST_APPROVE_CMD" ]]; then
    log "phase approved — running post-approve command: $POST_APPROVE_CMD"
    run_post_approve_cmd || post_approve_exit=$?
    if [[ "$post_approve_exit" -ne 0 ]]; then
      log "post-approve command FAILED (exit $post_approve_exit) — phase remains approved; escalating closeout"
      escalate "post-approve-failed" 0
      exit 9
    fi
  fi
  exit 0
}

# ── Step 0.4 (GH-274): satisfied-lane short-circuit ────────────────────────
# A phase whose relay is already terminal AND whose tick token is already done needs no
# render/reseed/relay-drive at all — only the pre-advance gate (and requires-test, if set)
# re-run, exactly like any other already-satisfied completion. DRY_RUN is exempted: its whole
# point is to render + show the tick seed for inspection, and there is nothing to commit or
# seed on this path anyway.
if ((! DRY_RUN)) && satisfied_lane_terminal; then
  log "phase ${PHASE_ID} already reached a terminal relay (STATUS: $(file_status), token done) — skipping render/reseed, re-running only the pre-advance gate"
  MARATHON_DRIVE_STARTED=1
  complete_phase_success already-satisfied
fi

# GH-162: peek at prior attempts BEFORE rendering (read-only; lane_attempt_gate in Step 3 still owns
# the append/park write) so a re-fired phase's relay file can carry the debug-mantra note. Empty
# DEBUG_MANTRA_TEXT on a first fire (prior=0) — the render below is then byte-identical to before.
DEBUG_MANTRA_PRIOR="$(debug_mantra_prior_attempts "${TICK_REPO_ROOT:-$ROOT}" "$LANE_STATE_KEY")"
DEBUG_MANTRA_TEXT="$(debug_mantra_note "$DEBUG_MANTRA_PRIOR" "$PHASE_DIR" "$HERE/DEBUG-MANTRA.md")"

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
${DEBUG_MANTRA_TEXT}
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
5. SIDE FINDINGS: if you notice a bug, hazard, or missing test OUTSIDE your allowed paths, do NOT fix or touch it. Append a block to this relay file in exactly this shape:
   ### Side Finding
   - path: <repo-relative file>
   - symptom: <one line: what is wrong>
   - suspected_cause: <one line>
   - probe: <a single command that currently DEMONSTRATES the bug (exits nonzero or greps the bad evidence — it must detect the BUG, not the fix)>
   Off-lane edits are reverted by the harness; a Side Finding block is the only channel that survives.

---

▶ TAKE YOUR TURN (${REVIEWER} — REVIEWER role)

You are the REVIEWER for this phase. ${REVIEWER_READ_LINE}
1. Append a review block: \`### Round N · Reviewer · ${REVIEWER}\` followed by your assessment.
2. If changes needed: add \`**Verdict:** Changes requested\` then: ${TICK_CLI} release ${RELAY_TASK} --agent ${REVIEWER} --to ${BUILDER}
3. If satisfied: add \`**Verdict:** Approved\`, set \`STATUS: Approved\`, then: ${TICK_CLI} done ${RELAY_TASK} --agent ${REVIEWER}
4. Use this exact tick binary (run it from any directory) for all token operations: ${TICK_CLI}
   ${REVIEWER_SCOPE_LINE}
5. SIDE FINDINGS: if your review surfaces an out-of-scope bug, record it as a \`### Side Finding\` block (path / symptom / suspected_cause / probe) instead of requesting off-scope changes.
RELAY_EOF

if ((DRY_RUN)); then
  log "dry-run: relay file rendered at $RELAY_FILE"
  printf 'tick seed: log task.created %s + claim --agent marathon + release --to %s\n' "$RELAY_TASK" "$BUILDER"
  exit 0
fi

# ── Step 2: commit the relay file (rtl_before needs a clean HEAD) ───────────

git -C "$ROOT" add -- "$RELAY_FILE"
if git -C "$ROOT" diff --cached --quiet -- "$RELAY_FILE"; then
  log "relay file unchanged: $RELAY_FILE"
else
  git -C "$ROOT" commit -q -m "marathon: render phase ${PHASE_ID} relay (${RELAY_TASK})"
  log "relay file committed: $RELAY_FILE"
fi

# ── Step 3: seed tick token with handoff → builder ──────────────────────────

export TICK_REPO_ROOT="$ROOT"
# The outer marathon-drive invocation owns the lane attempt count. A leaked caller env var would skip
# counting entirely, so clear it here before the outer gate; the nested relay-drive below still gets
# an explicit one-shot LANE_ATTEMPT_COUNTED=1 in its child env to avoid double-counting.
unset LANE_ATTEMPT_COUNTED

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

# GH-45: per-lane attempt cap — refuse to start this phase once it has hit LANE_MAX_ATTEMPTS
# (keyed on the marathon-scoped lane-state key when present, else bare PHASE_ID), seeding no token;
# --force overrides. Counted here, so the nested relay-drive below (LANE_ATTEMPT_COUNTED=1) does not
# double-count this same lane.
_lag_rc=0; lane_attempt_gate "${TICK_REPO_ROOT:-$ROOT}" "$LANE_STATE_KEY" "$FORCE" || _lag_rc=$?
if [[ "$_lag_rc" -eq 8 ]]; then
  xyz_debug_log_append warn "marathon.lane-park" "lane $LANE_STATE_KEY parked at attempt cap" \
    "" "re-anchor to QUEUE lanes or re-fire with --force"
fi
[[ "$_lag_rc" -eq 0 ]] || exit "$_lag_rc"

reconcile_relay_task

"$TICK_BIN" log task.created "$RELAY_TASK" --agent marathon > /dev/null
"$TICK_BIN" claim           "$RELAY_TASK" --agent marathon --paths "$REL_RELAY" > /dev/null
"$TICK_BIN" release         "$RELAY_TASK" --agent marathon --to "$BUILDER" > /dev/null
log "tick token seeded: $RELAY_TASK → $BUILDER"

# ── Step 4: emit phase.start ────────────────────────────────────────────────

"$TICK_BIN" log marathon.phase.start "$RELAY_TASK" --agent marathon > /dev/null
xyz_marathon_heartbeat_write
log "phase start: running relay-drive --round-cap $ROUND_CAP"
MARATHON_DRIVE_STARTED=1   # GH-222: past this point a phase is really being driven — arm the cost summary

# ── Step 5: run relay-drive (the loop — unmodified) ────────────────────────

# relay-drive runs a bare executable --agent-cmd path directly (space-safe, even ".../GH Repos/..."),
# falling back to eval only for command strings — so we pass the path as-is, no %q quoting needed.
relay_exit=0
target_root_args=()
[[ -n "$TARGET_ROOT" ]] && target_root_args=(--target-root "$TARGET_ROOT")
run_relay_drive() {
  local relay_exit=0
  RELAY_FILE="$RELAY_FILE" \
  LANE_ATTEMPT_COUNTED=1 \
  XYZ_HARNESS_CONTEXT=marathon-phase \
  RELAY_COST_SUMMARY=0 \
    "$RELAY_DRIVE_BIN" \
      --relay-file "$RELAY_FILE" \
      --relay-task "$RELAY_TASK" \
      --agent-cmd  "$AGENT_CMD" \
      --round-cap  "$ROUND_CAP" \
      ${target_root_args[@]+"${target_root_args[@]}"} \
    || relay_exit=$?
  return "$relay_exit"
}

run_relay_review_once() {
  local relay_exit=0
  RELAY_FILE="$RELAY_FILE" \
  LANE_ATTEMPT_COUNTED=1 \
  XYZ_HARNESS_CONTEXT=marathon-phase \
  RELAY_COST_SUMMARY=0 \
    "$RELAY_DRIVE_BIN" \
      --relay-file "$RELAY_FILE" \
      --relay-task "$RELAY_TASK" \
      --agent-cmd  "$AGENT_CMD" \
      --review-once \
      ${target_root_args[@]+"${target_root_args[@]}"} \
    || relay_exit=$?
  return "$relay_exit"
}

TIMEOUT_ESCALATION_REASON="turn-timeout-or-hang"
TIMEOUT_EMIT_TEXT="halted at phase ${PHASE_ID} — turn timeout / hang"
recover_timeout_exit() {
  local gate_exit=0 relay_exit=0 s tstatus actor
  if ! artifacts_exist_for_timeout; then
    TIMEOUT_ESCALATION_REASON="timeout-no-artifact"
    TIMEOUT_EMIT_TEXT="halted at phase ${PHASE_ID} — timed-out builder produced no declared artifact"
    log "relay timed out (exit 7) before any declared artifact landed — treating it as a real hang"
    return 7
  fi

  log "relay timed out (exit 7) after declared artifact(s) appeared — probing the pre-advance gate: $PRE_ADVANCE_CMD"
  run_pre_advance_gate || gate_exit=$?
  if [[ "$gate_exit" -ne 0 ]]; then
    TIMEOUT_ESCALATION_REASON="timeout-gate-failed"
    TIMEOUT_EMIT_TEXT="halted at phase ${PHASE_ID} — timed-out builder artifact failed the pre-advance gate"
    log "timeout probe: pre-advance gate FAILED (exit $gate_exit) — treating it as a real halt"
    return 5
  fi

  s="$(file_status)"
  IFS=$'\t' read -r tstatus actor < <(token_state)
  if terminal_status "$s" && [[ -z "$actor" ]]; then
    log "timeout probe: relay already reached terminal agreement (STATUS: $s, token done) — continuing"
    return 0
  fi
  if [[ -z "$actor" ]]; then
    TIMEOUT_ESCALATION_REASON="timeout-no-live-actor"
    TIMEOUT_EMIT_TEXT="halted at phase ${PHASE_ID} — timed-out builder left no live reviewer handoff"
    log "timeout probe: artifact + gate were green, but $RELAY_TASK has no live actor (STATUS: $s) — cannot continue"
    return 7
  fi
  if [[ "$actor" == "$BUILDER" ]]; then
    TIMEOUT_ESCALATION_REASON="timeout-builder-still-owned-turn"
    TIMEOUT_EMIT_TEXT="halted at phase ${PHASE_ID} — timed-out builder never handed the relay to review"
    log "timeout probe: builder still owns $RELAY_TASK (STATUS: $s) — treating this as a real hang"
    return 7
  fi

  log "timeout probe: artifact + gate were green and $RELAY_TASK moved to $actor — resuming relay-drive from the post-timeout state"
  run_relay_drive || relay_exit=$?
  if [[ "$relay_exit" -eq 7 ]]; then
    TIMEOUT_ESCALATION_REASON="timeout-during-review-recovery"
    TIMEOUT_EMIT_TEXT="halted at phase ${PHASE_ID} — relay timed out again during review recovery"
  fi
  return "$relay_exit"
}
# GH-75: the nested relay loop reaches its own terminal exit once PER PHASE. Force its XYZ.json hook
# silent (XYZ_HARNESS_CONTEXT=marathon-phase) so a per-phase relay completion never emits its own
# record — this marathon-drive run (or marathon.sh above it) owns the single whole-run record. This is
# scoped to the relay-drive child only; marathon-drive's OWN context (swarm|unset) is left intact for
# its hook below.
run_relay_drive || relay_exit=$?
if [[ "$relay_exit" -eq 7 ]]; then
  if recover_timeout_exit; then
    relay_exit=0
  else
    relay_exit=$?
  fi
fi

# ── Step 6: act on relay-drive exit code ───────────────────────────────────
# escalate/save_transcript/complete_phase_success are defined earlier (ahead of Step 1) —
# see the GH-274 comment there — but still called from this case statement as before.

recover_already_satisfied_lane() {
  local gate_exit=0 review_exit=0 s tstatus actor
  [[ -n "$ARTIFACT_PATHS" ]] || return 3
  artifacts_exist_for_timeout || return 3

  log "relay stalled (exit 3) with declared artifact(s) already present — probing the pre-advance gate: $PRE_ADVANCE_CMD"
  run_pre_advance_gate || gate_exit=$?
  if [[ "$gate_exit" -ne 0 ]]; then
    log "already-satisfied probe: pre-advance gate FAILED (exit $gate_exit) — treating it as real no-progress"
    return 3
  fi

  s="$(file_status)"
  IFS=$'\t' read -r tstatus actor < <(token_state)
  if terminal_status "$s" && [[ -z "$actor" ]]; then
    log "already-satisfied probe: relay already reached terminal agreement (STATUS: $s, token done)"
    return 0
  fi
  case "$tstatus:$actor" in
    claimed:"$BUILDER")
      "$TICK_BIN" release "$RELAY_TASK" --agent "$BUILDER" --to "$REVIEWER" > /dev/null
      ;;
    open:"$BUILDER")
      "$TICK_BIN" claim "$RELAY_TASK" --agent "$BUILDER" --paths "$CLAIM_PATHS" > /dev/null
      "$TICK_BIN" release "$RELAY_TASK" --agent "$BUILDER" --to "$REVIEWER" > /dev/null
      ;;
    *)
      log "already-satisfied probe: artifact + gate are green, but current actor is ${actor:-none} (token ${tstatus:-missing}) — cannot auto-route to review"
      return 3
      ;;
  esac

  log "already-satisfied probe: routed the stalled builder turn to reviewer $REVIEWER for one approval pass"
  run_relay_review_once || review_exit=$?
  case "$review_exit" in
    0) return 0 ;;
    5)
      log "already-satisfied probe: reviewer declined approval — lane remains unsatisfied"
      return 3
      ;;
    *) return "$review_exit" ;;
  esac
}

case "$relay_exit" in
  0)
    complete_phase_success
    ;;
  3)
    if recover_already_satisfied_lane; then
      complete_phase_success already-satisfied
    fi
    relay_exit=$?
    log "relay escalated: no-progress (relay-drive exit 3)"
    escalate "no-progress" 3
    xyz_marathon_heartbeat_clear
    xyz_marathon_emit red "halted at phase ${PHASE_ID} — relay no-progress"
    exit 3
    ;;
  4)
    log "relay escalated: cap/close-mismatch (relay-drive exit 4)"
    escalate "cap-or-close-mismatch" 4
    xyz_marathon_heartbeat_clear
    xyz_marathon_emit red "halted at phase ${PHASE_ID} — relay cap/close-mismatch"
    exit 4
    ;;
  5)
    log "relay escalated: pre-advance gate failed"
    escalate "${TIMEOUT_ESCALATION_REASON:-pre-advance-failed}" 5
    xyz_marathon_heartbeat_clear
    xyz_marathon_emit red "${TIMEOUT_EMIT_TEXT:-halted at phase ${PHASE_ID} — pre-advance gate failed}"
    exit 5
    ;;
  6)
    # A turn-taker shim hit an off-lane edit, reverted it, and failed the turn (exit 6) — the
    # containment boundary fired. This is a DEFINED escalation, not an "unexpected" crash: the
    # builder strayed but the safety core held. Record it like any other escalation. (Dogfood
    # 2026-06-17: an autonomous builder edited an off-lane file; rtl_enforce caught + reverted it.)
    log "relay escalated: containment violation — a turn-taker reverted an off-lane edit (exit 6)"
    escalate "containment-violation (off-lane edit reverted by a turn-taker)" 6
    xyz_marathon_heartbeat_clear
    xyz_marathon_emit red "halted at phase ${PHASE_ID} — containment violation (off-lane edit reverted)"
    exit 6
    ;;
  7)
    log "relay escalated: timeout / hang (relay-drive exit 7)"
    escalate "$TIMEOUT_ESCALATION_REASON" 7
    xyz_marathon_heartbeat_clear
    xyz_marathon_emit red "$TIMEOUT_EMIT_TEXT"
    exit 7
    ;;
  *)
    die "relay-drive exited with unexpected code $relay_exit"
    ;;
esac
