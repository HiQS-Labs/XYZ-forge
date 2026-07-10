#!/usr/bin/env bash
set -euo pipefail

# GH-112 opt-in Python mode: XYZ_PYTHON=1 reroutes this entry point to the Python port in
# utils/py/ (same CLI contract + exit codes). Default (unset/0) runs the canonical Bash
# implementation below — Bash stays the supported default until the port is promoted.
if [[ "${XYZ_PYTHON:-0}" == "1" ]]; then
  _xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  export XYZ_ROOT="$_xyz_root"
  export PYTHONPATH="$_xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
  exec python3 "$_xyz_root/utils/py/agy-turn.py" "$@"
fi
#
# agy-turn.sh — headless turn-taker for the ANTIGRAVITY CLI (`agy`). Thin dispatch wrapper over the
# shared safety core (relay-turn-lib.sh) — the SAME containment contract as codex-turn.sh /
# gemini-turn.sh, proving the boundary is model-agnostic
# (decisions/2026-06-15-unattended-agent-containment.md).
#
# WHY THIS EXISTS: permanent cross-model lane, replacing gemini-turn.sh. Gemini CLI was retired
# 2026-06-19. `agy` (Antigravity CLI) is authed off the signed-in Antigravity desktop app and is
# itself a multi-model gateway (Gemini / Claude / GPT-OSS via --model).
#
# Invoked by relay-drive.sh / marathon-agent.sh as --agent-cmd, with env:
#   RELAY_FILE  — relay thread file (always allowlisted)
#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
# Shim config:
#   AGY_AGENT      — the agent id this shim drives; NO-OPS unless RELAY_AGENT==AGY_AGENT
#   ALLOW_PATHS    — comma-separated extra git paths the turn may change (e.g. the artifact)
#   RELAY_PEER     — optional: the other agent's id, so the turn hands off "--to <peer>" (else the
#                    prompt says "the other agent", which a live model may resolve to a role name)
#   AGY_BIN        — agy binary (default: agy); tests inject a stub
#   AGY_MODEL      — optional model for the turn (e.g. "Gemini 3.1 Pro (High)"); unset ⇒ agy default
#   AGY_FLAGS      — optional extra flags appended to the agy invocation (advanced/override)
#   AGY_TURN_ROOT  — git root to guard (default: this repo); tests point at a fixture
#   AGY_LOG        — where to write the agy transcript (default: GH-161 persistent path under
#                    rtl_transcript_root(ROOT)/logs/, gitignored; falls back to a $TMPDIR file on any
#                    resolver failure). Also exported as RTL_LOG so relay-turn-lib.sh's rtl_trace/
#                    rtl_log_always decision-point instrumentation lands in this same transcript.
#   RTL_TRACE      — 1 = also emit fine-grained decision-point trace lines (root resolution, allowlist
#                    match, worktree seed/copy-back, containment verdict) into AGY_LOG. Default off.
#   AGY_AUTH_TIMEOUT_S — short wall-clock cap for the auth pre-flight probe (`agy whoami`);
#                        default 5. On failure/time-out the shim exits 5 with an `agy login` remedy.
#   RELAY_WORKTREE_ISOLATION — 1 = run the turn in a THROWAWAY git worktree of ROOT@HEAD (airtight
#                     async/side-effect containment; off-lane in the worktree → exit 6). Default OFF.
#
# Auth/headless contract (validated 2026-06-18, agy from Antigravity.app):
#   -p "<prompt>"                  — non-interactive (headless) print mode
#   --dangerously-skip-permissions — auto-approve tool calls (shell for tick, edit for the relay file)
#   --print-timeout <dur>          — agy's own print-mode wait; pinned to the wall-clock cap so agy
#                                    returns on its own before the rtl watchdog has to kill it
#   `agy whoami`                   — cheap pre-flight auth probe; if it fails or hangs, the shim skips
#                                    the lane fast with "run `agy login`" instead of letting `agy -p`
#                                    open an interactive auth prompt that deadlocks the headless turn
#
#   RELAY_TURN_TIMEOUT_S — per-turn wall-clock ceiling in seconds (default: 300). A hung or
#                          runaway agy CLI is killed after this many seconds; the turn exits 7.
#
# TWO agy-specific gotchas this shim guards (memory: agy-antigravity-cli):
#   (a) SILENT FAILURE UNDER A SANDBOX — when agy's backend network is blocked (e.g. Claude Code's
#       Bash sandbox) `agy -p` exits 0 with EMPTY output. An empty "successful" turn is a FALSE
#       success for an automated relay, so we treat empty-output-on-exit-0 as a hard failure (exit 5).
#       Run this shim with the sandbox OFF (like codex; memory: codex-cli-needs-sandbox-disabled).
#   (b) NO JSON / TOKEN OUTPUT — agy print mode has no `-o json` and no usage block, so there is NO
#       cost.tokens capture here (an agy lane is cost-blind — a floor, same Phase-1 partial as Codex).
#
# Exit: 0 acted/deferred · 5 agy failed or produced empty output · 6 off-allowlist edit (reverted) ·
#       7 timeout-killed · 2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=relay-turn-lib.sh
source "$HERE/relay-turn-lib.sh"

ROOT="${AGY_TURN_ROOT:-"$(cd "$HERE/.." && pwd)"}"
AGY_BIN="${AGY_BIN:-agy}"
die() { printf 'agy-turn: %s\n' "$*" >&2; exit 2; }
agy_auth_preflight() {
  local secs="${AGY_AUTH_TIMEOUT_S:-5}" out rc=0 line
  out="${TMPDIR:-/tmp}/agy-auth-$$.log"
  rtl_run_bounded "$secs" "$AGY_BIN" whoami < /dev/null > "$out" 2>&1 || rc=$?
  [[ "$rc" -eq 0 ]] && { rm -f "$out"; return 0; }
  if [[ "$rc" -eq 7 ]]; then
    printf 'agy-turn: agy auth pre-flight timed out after %ss; likely expired auth opening an interactive login. Run `agy login` in a normal terminal, then retry.\n' "$secs" >&2
  else
    printf 'agy-turn: agy auth pre-flight failed (exit %s). Run `agy login` in a normal terminal, then retry.\n' "$rc" >&2
  fi
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    printf 'agy-turn: auth pre-flight: %s\n' "$line" >&2
  done < <(sed -n '1,3p' "$out")
  rm -f "$out"
  return 1
}
agy_validate_model() {
  local model="${AGY_MODEL:-}" secs="${AGY_AUTH_TIMEOUT_S:-5}" out rc=0 line
  [[ -n "$model" ]] || return 0
  out="${TMPDIR:-/tmp}/agy-models-$$.log"
  rtl_run_bounded "$secs" "$AGY_BIN" models < /dev/null > "$out" 2>&1 || rc=$?
  if [[ "$rc" -ne 0 ]]; then
    if [[ "$rc" -eq 7 ]]; then
      printf 'agy-turn: agy models probe timed out after %ss while validating AGY_MODEL=%q. Refusing to fall back silently.\n' "$secs" "$model" >&2
    else
      printf 'agy-turn: agy models probe failed (exit %s) while validating AGY_MODEL=%q. Refusing to fall back silently.\n' "$rc" "$model" >&2
    fi
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      printf 'agy-turn: models probe: %s\n' "$line" >&2
    done < <(sed -n '1,3p' "$out")
    rm -f "$out"
    return 1
  fi
  while IFS= read -r line; do
    line="${line%$'\r'}"
    [[ "$line" == "$model" ]] && { rm -f "$out"; return 0; }
  done < "$out"
  printf 'agy-turn: requested AGY_MODEL=%q is unavailable on this agy account. Run `agy models` to choose a listed model; refusing to fall back silently.\n' "$model" >&2
  rm -f "$out"
  return 1
}

me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
agy_agent="${AGY_AGENT:-}"
[[ -n "$me" ]] || die "RELAY_AGENT required"
[[ -n "$f" ]] || die "RELAY_FILE required"
[[ -n "$agy_agent" ]] || die "AGY_AGENT required"

# Dispatch only for the agy agent; defer otherwise (that window drives its own turn).
if [[ "$me" != "$agy_agent" ]]; then
  printf 'agy-turn: actor %s is not the agy agent (%s) — deferring (window-driven)\n' "$me" "$agy_agent" >&2
  exit 0
fi

agy_auth_preflight || exit 5
agy_validate_model || exit 5
# Preserve an inherited harness tick root from the orchestrator (e.g. vendored .xyz marathon runs);
# default to this shim's ROOT only when the caller did not already pin TICK_REPO_ROOT. (GH-171)
: "${TICK_REPO_ROOT:=$ROOT}"
export TICK_REPO_ROOT
# GH-161: resolve the transcript path and export RTL_LOG BEFORE rtl_init (same reasoning as
# codex-turn.sh) so its decision-trace line, and every later rtl_trace/rtl_log_always call, lands in
# this turn's transcript. Persistent by default; falls back to the historical PID-keyed tmp path on
# any resolver failure. AGY_LOG stays fully operator-overridable.
AGY_LOG="${AGY_LOG:-$(rtl_default_log "$ROOT" agy-turn "$t")}"
export RTL_LOG="$AGY_LOG"
rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"

# Cross-repo footgun guard (consumer feedback KWFS-02 B2): agy reads file paths relative to its
# PROCESS CWD (the tooling repo), NOT AGY_TURN_ROOT. So in cross-repo mode — guarding a different
# repo than CWD — any RELATIVE TARGET path in the relay file resolves against the wrong tree and agy
# silently "finds nothing." Warn loudly (non-fatal); the fix is absolute TARGET paths. See CONSUMING.md.
_cwd_git_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -n "$_cwd_git_root" && "$(cd "$ROOT" 2>/dev/null && pwd)" != "$_cwd_git_root" ]]; then
  printf 'agy-turn: CROSS-REPO mode (AGY_TURN_ROOT=%s != CWD git root=%s) — agy resolves relative paths against CWD, not the target repo. List TARGET files by ABSOLUTE path in %s or agy will silently find nothing. (CONSUMING.md)\n' "$ROOT" "$_cwd_git_root" "$f" >&2
fi

prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"
# GH-68 warn-only: prepend any UNREAD cross-agent dependency-drift heads-up to the turn brief, so a
# builder learns a peer changed a shared surface (kernel/projection/schema) since its last turn. No
# unread drift → empty → prompt unchanged. Never blocks. (decisions/2026-07-01-cross-agent-dep-conflict.md)
drift_brief="$(rtl_drift_brief "$me" "${TICK_REPO_ROOT:-$ROOT}")"
[[ -n "$drift_brief" ]] && prompt="${drift_brief}"$'\n'"${prompt}"

# GH-171 follow-up: mirror the Codex/Aider claim-before-launch guard. A driven agy turn that edits the
# relay/artifact but never claims the specific handed-off token leaves GH-67's post-commit handoff with
# no authority, so the lane deadlocks as apparent "no-progress". Claiming here is idempotent when agy
# already holds the token.
claim_paths="${f#"$RTL_ROOT"/}"
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
    printf 'agy-turn: could not establish token ownership of %s (claimer=%s, expected %s) — refusing to run so the turn cannot commit with the token open under the old owner; inspect `tick info %s`\n' "$t" "${_claimer:-none}" "$me" "$t" >&2
    exit 5
  fi
  TICK_REPO_ROOT="$_tickroot" "$_tickbin" ping "$t" --agent "$me" >/dev/null 2>&1 || true
fi

# Transcript/log: AGY_LOG is already resolved above (persistent-by-default via rtl_default_log, or a
# tmp fallback — see the comment at the RTL_LOG export). Persisted so the headless run is auditable.
# Unlike the Gemini shim there is no `-o json`, so this transcript is debug-only — no token stats to
# parse.

# Build the agy invocation. --print-timeout is pinned to the wall-clock cap so agy returns on its own
# just before the rtl watchdog would kill it; --model and AGY_FLAGS are optional pass-throughs.
turn_timeout="${RELAY_TURN_TIMEOUT_S:-300}"
agy_args=(--dangerously-skip-permissions --print-timeout "${turn_timeout}s")
[[ -n "${AGY_MODEL:-}" ]] && agy_args+=(--model "$AGY_MODEL")
read -ra _aflags <<<"${AGY_FLAGS:-}"
[[ "${#_aflags[@]}" -gt 0 ]] && agy_args+=("${_aflags[@]}")

# Run the agy turn headless (token ops + edit the relay file; NO git), then enforce the boundary.
rtl_before
bounded_rc=0

# Worktree isolation (opt-in; ROADMAP Part A Phase 3.6 — same wiring as claude-turn.sh). When
# RELAY_WORKTREE_ISOLATION=1, run agy with CWD = a THROWAWAY git worktree of ROOT@HEAD, so any
# async/background write lands in a tree we delete, never ROOT. .tick coordination state stays SHARED
# via TICK_REPO_ROOT=ROOT. Default OFF → the in-ROOT run below is byte-for-byte the prior behaviour.
wt=""; cwd_wrap=()
if [[ "${RELAY_WORKTREE_ISOLATION:-0}" == "1" ]]; then
  if wt="$(rtl_worktree_begin)"; then
    cwd_wrap=(bash -c 'cd "$1" || exit 127; shift; exec "$@"' bash "$wt")
    printf 'agy-turn: worktree isolation ON (%s)\n' "$wt" >&2
  else
    printf 'agy-turn: worktree isolation requested but `git worktree add` failed — failing turn\n' >&2
    exit 5
  fi
fi

# GH-161: >> (append), not > (truncate) — rtl_init already wrote its trace line into AGY_LOG above
# (RTL_LOG was exported before rtl_init ran); a truncating redirect here would silently wipe it. Still
# effectively a fresh file per turn under the persistent default (each run's filename embeds $$).
rtl_run_bounded "$turn_timeout" ${cwd_wrap[@]+"${cwd_wrap[@]}"} "$AGY_BIN" "${agy_args[@]}" -p "$prompt" < /dev/null >> "$AGY_LOG" 2>&1 \
  || bounded_rc=$?

# Worktree teardown FIRST (regardless of rc — a killed/crashed agy may have left work or off-lane edits
# in the worktree). Copies the allowlist back to ROOT unless an off-lane change was detected → exit 6
# (containment takes precedence over timeout 7 / failure 5 / empty-output 5, per the exit contract).
if [[ -n "$wt" ]]; then
  rtl_worktree_end "$wt"
  if [[ "${RTL_WT_OFFLANE:-0}" == "1" ]]; then
    printf 'agy-turn: agy made off-lane edits in the isolated worktree — discarded; failing the turn (exit 6)\n' >&2
    exit 6
  fi
  # GH-178 B1: Verify agy grounding stayed contained to $WT.
  if [[ "$bounded_rc" -eq 0 && -s "$AGY_LOG" ]]; then
    # Filter out false-positive shapes before the $ROOT substring scan:
    #   [trace] lines (instrumentation, legitimately contain RTL_ROOT)
    #   TICK_REPO_ROOT="..." (harness-mandated tick-command narration, GH-183)
    #   file:// URIs and markdown link targets ](...) (file citations, GH-187)
    if grep -v -e '^\[trace\] ' -e 'TICK_REPO_ROOT=' -e 'file://' -e '](' "$AGY_LOG" 2>/dev/null | grep -qF "$ROOT" 2>/dev/null; then
      printf 'agy-turn: agy transcript cited the real repo root (%s) instead of the isolated worktree. This is an isolation breach. Failing the turn.\n' "$ROOT" >&2
      printf '\n[FAIL] agy isolation breach: transcript cited the real repo root instead of the worktree.\n' >> "$AGY_LOG"
      exit 5
    fi
  fi
fi

if [[ "$bounded_rc" -eq 7 ]]; then
  printf 'agy-turn: agy -p exceeded %ss wall-clock cap — killed\n' "$turn_timeout" >&2
elif [[ "$bounded_rc" -ne 0 ]]; then
  printf 'agy-turn: agy -p failed (exit %s)\n' "$bounded_rc" >&2; exit 5
fi
# Guard (a): silent-failure-under-sandbox. agy -p can exit 0 with EMPTY output when its backend is
# unreachable (sandboxed network). Treat that as a failed turn, NOT a successful no-op — otherwise an
# automated relay reads a blocked turn as "agent had nothing to do" and advances on a phantom success.
# (Only enforced on a clean exit; a timeout-kill at rc=7 is reported below after containment.)
# GH-161 KNOWN INTERACTION: this checks file SIZE, so RTL_TRACE=1 (which writes rtl_init's trace line
# into AGY_LOG before agy ever runs) makes AGY_LOG non-empty regardless of agy's own output, masking
# this guard for that one opt-in debug combination. Default posture (RTL_TRACE unset) is unaffected —
# rtl_trace is a no-op then, so AGY_LOG stays genuinely empty until agy writes to it.
if [[ "$bounded_rc" -eq 0 && ! -s "$AGY_LOG" ]]; then
  printf 'agy-turn: agy -p exited 0 but produced NO output — likely a blocked backend (run sandbox-OFF). Failing the turn.\n' >&2
  exit 5
fi
# Always enforce containment even after a timeout-kill: a killed-mid-edit agent may have left
# off-lane changes. rtl_enforce may exit 6 (containment violation takes precedence over timeout 7).
rtl_enforce "$t" "$me" "$AGY_LOG" "agy"
if [[ "$bounded_rc" -eq 7 ]]; then exit 7; fi

# NOTE: no cost.tokens capture — agy print mode emits no JSON/usage block (see header gotcha (b)).
# An agy lane is a cost floor, not a complete sum (same Phase-1 partial as the Codex lane).
