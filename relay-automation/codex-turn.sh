#!/usr/bin/env bash
set -euo pipefail
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
#   CODEX_LOG       — where to write the codex transcript (default: stderr)
#   RELAY_WORKTREE_ISOLATION — 1 = run the turn in a THROWAWAY git worktree of ROOT@HEAD (airtight
#                     async/side-effect containment; off-lane in the worktree → exit 6). Default OFF.
#
#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 300). A hung or
#                          runaway codex CLI is killed after this many seconds; the turn exits 7.
#
# Exit: 0 acted/deferred · 5 codex failed · 6 off-allowlist edit (reverted) · 7 timeout-killed · 2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=relay-turn-lib.sh
source "$HERE/relay-turn-lib.sh"

ROOT="${CODEX_TURN_ROOT:-"$(cd "$HERE/.." && pwd)"}"
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

# Anchor tick coordination to the harness root UNCONDITIONALLY (not just under worktree isolation):
# the turn-prompt and every token op must resolve .tick + bin/tick here regardless of the turn's CWD.
# Without this, a Codex turn whose CWD isn't ROOT (worktree-isolated, or a CLI that cd's) runs its
# tick calls against the wrong/absent .tick -> silent no-op -> the token never releases -> deadlock
# (relay review 2026-06-23 F1/F2). TICK_REPO_ROOT names the HARNESS clone (.tick lives here), which
# stays ROOT even when RELAY_TARGET_ROOT routes the ARTIFACT side elsewhere (GH-11).
export TICK_REPO_ROOT="$ROOT"
rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
# GH-68 warn-only: prepend any UNREAD cross-agent dependency-drift heads-up to the turn brief, so a
# builder learns a peer changed a shared surface (kernel/projection/schema) since its last turn. No
# unread drift → empty → prompt unchanged. Never blocks. (decisions/2026-07-01-cross-agent-dep-conflict.md)
drift_brief="$(rtl_drift_brief "$me" "${TICK_REPO_ROOT:-$ROOT}")"
[[ -n "$drift_brief" ]] && prompt="${drift_brief}"$'\n'"${prompt}"

# Run the Codex turn headless (token ops + edit the relay file; NO git), then enforce the boundary.
# CODEX_FLAGS gives the turn enough autonomy to actually write on a fresh device (default sandbox is
# read-only); operator-overridable for tighter/looser policies.
# GH-106: default adds `-c approval_policy=never` to the sandbox flag so a headless run no longer
# hangs on an interactive approval prompt until RELAY_TURN_TIMEOUT_S kills it (exit 7). Keeps the
# workspace-write sandbox restriction (still can't touch outside the workspace) — fully overridable.
read -ra _cflags <<<"${CODEX_FLAGS:--s workspace-write -c approval_policy=never}"
codex_extra_flags=()
# Transcript: default to a $TMPDIR file (NOT the repo tree — the in-tree log guard deletes it).
# Persists the transcript so the headless run is auditable. (Codex token-stats parsing is a follow-up
# — its usage format isn't probed yet, so cost.tokens for Codex turns stays a Phase-1 partial.)
CODEX_LOG="${CODEX_LOG:-${TMPDIR:-/tmp}/codex-turn-$$.log}"
rtl_before
turn_timeout="${RELAY_TURN_TIMEOUT_S:-300}"
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
    codex_extra_flags=(--add-dir "$ROOT/.tick")
    printf 'codex-turn: worktree isolation ON (%s)\n' "$wt" >&2
  else
    printf 'codex-turn: worktree isolation requested but `git worktree add` failed — failing turn\n' >&2
    exit 5
  fi
fi

# Billing guard: strip OPENAI_API_KEY from the codex subprocess env so a Codex turn ALWAYS bills
# against the ChatGPT-subscription login (`~/.codex/auth.json` auth_mode=chatgpt), never per-token API
# credits — even if some ambient session exported a key. Set CODEX_ALLOW_API_KEY=1 to opt back in.
codex_env=(env)
[[ "${CODEX_ALLOW_API_KEY:-0}" == "1" ]] || codex_env+=(-u OPENAI_API_KEY)
rtl_run_bounded "$turn_timeout" ${cwd_wrap[@]+"${cwd_wrap[@]}"} "${codex_env[@]}" "$CODEX_BIN" exec "${_cflags[@]}" ${codex_extra_flags[@]+"${codex_extra_flags[@]}"} "$prompt" < /dev/null > "$CODEX_LOG" 2>&1 \
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
