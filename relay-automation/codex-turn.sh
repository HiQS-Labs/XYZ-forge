#!/usr/bin/env bash
# FROZEN (GH-308): Python is authoritative — do not make behavior changes here.
# Historical Bash fallback only; update utils/py/codex-turn.py instead. See issue #308.
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
    exec python3 "$_xyz_root/utils/py/codex-turn.py" "$@"
  else
    echo "xyz: XYZ_PYTHON=1 but python3 missing or < 3.8 — falling back to Bash" >&2
  fi
fi
#
# codex-turn.sh — headless turn-taker for the CODEX agent. Thin dispatch wrapper over the
# shared safety core (relay-turn-lib.sh); the containment contract lives there.
#
# Invoked by relay-drive.sh as --agent-cmd, with env:
#   RELAY_FILE  — relay thread file (always allowlisted)
#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
# Shim config:
#   CODEX_AGENT     — the agent id this shim drives; NO-OPS unless RELAY_AGENT==CODEX_AGENT
#   ALLOW_PATHS     — comma-separated extra git paths the turn may change (e.g. the artifact)
#   RELAY_PEER      — optional: the other agent's id, so the turn hands off "--to <peer>" (else the
#                     prompt says "the other agent", which a live model may resolve to a role name)
#   CODEX_BIN       — codex binary (default: codex); tests inject a stub
#   CODEX_FLAGS     — autonomy flags for `codex exec` (default: -s workspace-write -c
#                     approval_policy=never — GH-106: the old bare `-s workspace-write` default still
#                     gated some actions behind an interactive approval prompt, which hangs forever in
#                     a headless run until RELAY_TURN_TIMEOUT_S kills it (exit 7), burning a lane
#                     attempt). If codex still blocks on some other prompt type, escalate with e.g.
#                     CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox' (removes codex's own
#                     sandbox entirely; this repo's containment then relies solely on
#                     relay-turn-lib.sh's worktree isolation, same as every other headless worker).
#   CODEX_TURN_ROOT — git root to guard (default: this repo); tests point at a fixture
#   CODEX_LOG       — where to write the codex transcript (default: GH-161 persistent path under
#                     rtl_transcript_root(ROOT)/logs/, gitignored; falls back to a $TMPDIR file on any
#                     resolver failure). Also exported as RTL_LOG so relay-turn-lib.sh's rtl_trace/
#                     rtl_log_always decision-point instrumentation lands in this same transcript.
#   RTL_TRACE       — 1 = also emit fine-grained decision-point trace lines (root resolution,
#                     allowlist match, worktree seed/copy-back, containment verdict) into CODEX_LOG.
#                     Default off — the routine successful path stays quiet unless requested.
#   RELAY_WORKTREE_ISOLATION — 1 = run the turn in a THROWAWAY git worktree of ROOT@HEAD (airtight
#                     async/side-effect containment; off-lane in the worktree → exit 6). Default OFF.
#
#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 900). A hung or
#                          runaway codex CLI is killed after this many seconds; the turn exits 7.
#
# Exit: 0 acted/deferred · 5 codex failed / token ownership missing · 6 off-allowlist edit
#       (reverted) · 7 timeout-killed · 2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=relay-turn-lib.sh
source "$HERE/relay-turn-lib.sh"

# Default ROOT to the CWD's git toplevel (the repo the operator is actually driving) so a
# NON-VENDORED run — this shim invoked from outside the target repo, e.g. straight from the swarm
# checkout — roots worktree isolation + artifact copyback at the TARGET, not this shim's own repo
# ($HERE/..). Explicit CODEX_TURN_ROOT still wins (fixtures); fall back to $HERE/.. off a git repo.
ROOT="${CODEX_TURN_ROOT:-"$(git rev-parse --show-toplevel 2>/dev/null || (cd "$HERE/.." && pwd))"}"
CODEX_BIN="${CODEX_BIN:-codex}"
die() { printf 'codex-turn: %s\n' "$*" >&2; exit 2; }

me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
codex_agent="${CODEX_AGENT:-}"
[[ -n "$me" ]] || die "RELAY_AGENT required"
[[ -n "$f" ]] || die "RELAY_FILE required"
[[ -n "$codex_agent" ]] || die "CODEX_AGENT required"

# Dispatch only for the Codex agent; defer otherwise (that window drives its own turn).
if [[ "$me" != "$codex_agent" ]]; then
  printf 'codex-turn: actor %s is not the Codex agent (%s) — deferring (window-driven)\n' "$me" "$codex_agent" >&2
  exit 0
fi

# Anchor tick coordination to the harness root (not just under worktree isolation): the turn-prompt
# and every token op must resolve .tick + bin/tick there regardless of the turn's CWD. Preserve an
# inherited TICK_REPO_ROOT from marathon-drive/relay-drive (notably a vendored .xyz run whose real
# harness root is the CONSUMER repo, not .xyz itself); default to ROOT only when the caller did not
# already pin it. (GH-171)
: "${TICK_REPO_ROOT:=$ROOT}"
export TICK_REPO_ROOT
# GH-161: resolve the transcript path and export RTL_LOG BEFORE rtl_init, so its own decision-trace
# line (and every later rtl_trace/rtl_log_always call) lands in this turn's transcript. Persistent by
# default (rtl_transcript_root-anchored, gitignored — see .gitignore); falls back to the historical
# PID-keyed tmp path on any resolver failure. CODEX_LOG stays fully operator-overridable.
CODEX_LOG="${CODEX_LOG:-$(rtl_default_log "$ROOT" codex-turn "$t")}"
export RTL_LOG="$CODEX_LOG"
rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
# GH-68 warn-only: prepend any UNREAD cross-agent dependency-drift heads-up to the turn brief, so a
# builder learns a peer changed a shared surface (kernel/projection/schema) since its last turn. No
# unread drift → empty → prompt unchanged. Never blocks. (decisions/2026-07-01-cross-agent-dep-conflict.md)
drift_brief="$(rtl_drift_brief "$me" "${TICK_REPO_ROOT:-$ROOT}")"
[[ -n "$drift_brief" ]] && prompt="${drift_brief}"$'\n'"${prompt}"

# GH-165: claim the specific handed-off task in the shim and prove ownership BEFORE launching Codex.
# GH-67 already backstops release/done after the commit, but that path is ownership-guarded by tick:
# if Codex edits the relay/artifacts without first becoming the claimer, rtl_enforce can only WARN
# and the lane deadlocks as apparent "no-progress". Claiming here is safe because `tick claim` is
# idempotent when this agent already holds the token.
claim_paths="${f#"$ROOT"/}"
if [[ -n "${ALLOW_PATHS:-}" ]]; then
  IFS=',' read -ra _claim_allow <<<"${ALLOW_PATHS}"
  for _ap in "${_claim_allow[@]}"; do
    _ap="${_ap#"${_ap%%[![:space:]]*}"}"
    _ap="${_ap%"${_ap##*[![:space:]]}"}"
    [[ -n "$_ap" ]] && claim_paths="$claim_paths,$_ap"
  done
fi
_tickroot="${TICK_REPO_ROOT:-$ROOT}"; _tickbin="$(rtl_tick_bin "$_tickroot")"
if [[ -x "$_tickbin" ]]; then
  TICK_REPO_ROOT="$_tickroot" "$_tickbin" claim "$t" --agent "$me" --paths "$claim_paths" >/dev/null 2>&1 || true
  _claimer="$(TICK_REPO_ROOT="$_tickroot" "$_tickbin" info "$t" 2>/dev/null | sed -n 's/^claimer:[[:space:]]*//p' | head -n1)"
  if [[ "$_claimer" != "$me" ]]; then
    printf 'codex-turn: could not establish token ownership of %s (claimer=%s, expected %s) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info %s`\n' "$t" "${_claimer:-none}" "$me" "$t" >&2
    exit 5
  fi
  TICK_REPO_ROOT="$_tickroot" "$_tickbin" ping "$t" --agent "$me" >/dev/null 2>&1 || true
fi

# Run the Codex turn headless (token ops + edit the relay file; NO git), then enforce the boundary.
# CODEX_FLAGS gives the turn enough autonomy to actually write on a fresh device (default sandbox is
# read-only); operator-overridable for tighter/looser policies.
# GH-106: default adds `-c approval_policy=never` to the sandbox flag so a headless run no longer
# hangs on an interactive approval prompt until RELAY_TURN_TIMEOUT_S kills it (exit 7). Keeps the
# workspace-write sandbox restriction (still can't touch outside the workspace) — fully overridable.
read -ra _cflags <<<"${CODEX_FLAGS:--s workspace-write -c approval_policy=never}"
codex_extra_flags=()
# Transcript: CODEX_LOG is already resolved above (persistent-by-default via rtl_default_log, or a
# tmp fallback — see the comment at the RTL_LOG export). Persists the transcript so the headless run
# is auditable. (Codex token-stats parsing is a follow-up — its usage format isn't probed yet, so
# cost.tokens for Codex turns stays a Phase-1 partial.)
rtl_before
turn_timeout="${RELAY_TURN_TIMEOUT_S:-900}"
bounded_rc=0

# Worktree isolation (opt-in; ROADMAP Part A Phase 3.6 — same wiring as claude-turn.sh / agy-turn.sh).
# When RELAY_WORKTREE_ISOLATION=1, run codex with CWD = a THROWAWAY git worktree of ROOT@HEAD, so any
# async/background write lands in a tree we delete, never ROOT. .tick stays SHARED via TICK_REPO_ROOT.
# Default OFF → the in-ROOT run below is byte-for-byte the prior behaviour.
wt=""; cwd_wrap=()
if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
  if wt="$(rtl_worktree_begin)"; then
    # TICK_REPO_ROOT already exported above (unconditional) — .tick stays SHARED with ROOT here.
    cwd_wrap=(bash -c 'cd "$1" || exit 127; shift; exec "$@"' bash "$wt")
    # GH-36: the isolated worktree is the primary workspace, so the shared token lock under
    # $TICK_REPO_ROOT/.tick is outside Codex's default workspace-write sandbox unless we add it.
    codex_extra_flags=(--add-dir "$TICK_REPO_ROOT/.tick")
    printf 'codex-turn: worktree isolation ON (%s)\n' "$wt" >&2
  else
    printf 'codex-turn: worktree isolation requested but `git worktree add` failed — failing turn\n' >&2
    exit 5
  fi
else
  # GH-263: the isolation=0 (default/opt-out) path used to add nothing here, on the assumption
  # that Codex's CWD already equals ROOT so $TICK_REPO_ROOT/.tick sits inside its workspace-write
  # sandbox for free. That assumption breaks in a vendored `.xyz/` install driven from `cd
  # $HARNESS` (relay-xyz's documented CWD): Codex's CWD is `.xyz`, so the parent-root .tick is
  # OUTSIDE its sandbox and the `tick claim` lock write EPERMs before the turn even starts. Reuse
  # the same GH-36 flag here so Codex's sandbox can always reach the shared token lock, whether or
  # not its CWD happens to already contain it (harmless no-op when CWD already covers .tick).
  codex_extra_flags=(--add-dir "$TICK_REPO_ROOT/.tick")
fi

# Billing guard: strip OPENAI_API_KEY from the codex subprocess env so a Codex turn ALWAYS bills
# against the ChatGPT-subscription login (`~/.codex/auth.json` auth_mode=chatgpt), never per-token API
# credits — even if some ambient session exported a key. Set CODEX_ALLOW_API_KEY=1 to opt back in.
codex_env=(env)
[[ "${CODEX_ALLOW_API_KEY:-0}" == "1" ]] || codex_env+=(-u OPENAI_API_KEY)
# GH-161: >> (append), not > (truncate) — rtl_init already wrote its trace line into CODEX_LOG above
# (RTL_LOG was exported before rtl_init ran); a truncating redirect here would silently wipe it. Still
# effectively a fresh file per turn under the persistent default (each run's filename embeds $$).
rtl_run_bounded "$turn_timeout" ${cwd_wrap[@]+"${cwd_wrap[@]}"} "${codex_env[@]}" "$CODEX_BIN" exec "${_cflags[@]}" ${codex_extra_flags[@]+"${codex_extra_flags[@]}"} "$prompt" < /dev/null >> "$CODEX_LOG" 2>&1 \
  || bounded_rc=$?

# Worktree teardown FIRST (regardless of rc). Copies the allowlist back to ROOT unless an off-lane
# change was detected → exit 6 (containment takes precedence over timeout 7 / failure 5).
if [[ -n "$wt" ]]; then
  rtl_worktree_end "$wt"
  if [[ "${RTL_WT_OFFLANE:-0}" == "1" ]]; then
    printf 'codex-turn: codex made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)\n' >&2
    exit 6
  fi
fi

if [[ "$bounded_rc" -eq 7 ]]; then
  printf 'codex-turn: codex exec exceeded %ss wall-clock cap — killed\n' "$turn_timeout" >&2
elif [[ "$bounded_rc" -ne 0 ]]; then
  printf 'codex-turn: codex exec failed (exit %s)\n' "$bounded_rc" >&2; exit 5
fi
# Always enforce containment even after a timeout-kill: a killed-mid-edit agent may have left
# off-lane changes. rtl_enforce may exit 6 (containment violation takes precedence over timeout 7).
rtl_enforce "$t" "$me" "$CODEX_LOG" "codex"
if [[ "$bounded_rc" -eq 7 ]]; then exit 7; fi
