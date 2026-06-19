#!/usr/bin/env bash
set -euo pipefail
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
#   AGY_LOG        — where to write the agy transcript (default: a $TMPDIR file)
#
# Auth/headless contract (validated 2026-06-18, agy from Antigravity.app):
#   -p "<prompt>"                  — non-interactive (headless) print mode
#   --dangerously-skip-permissions — auto-approve tool calls (shell for tick, edit for the relay file)
#   --print-timeout <dur>          — agy's own print-mode wait; pinned to the wall-clock cap so agy
#                                    returns on its own before the rtl watchdog has to kill it
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

# Transcript/log: default to a $TMPDIR file (NOT the repo tree — the in-tree log guard in
# relay-turn-lib.sh deletes any in-tree log). Persisted so the headless run is auditable. Unlike the
# Gemini shim there is no `-o json`, so this transcript is debug-only — no token stats to parse.
AGY_LOG="${AGY_LOG:-${TMPDIR:-/tmp}/agy-turn-$$.log}"

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
rtl_run_bounded "$turn_timeout" "$AGY_BIN" "${agy_args[@]}" -p "$prompt" < /dev/null > "$AGY_LOG" 2>&1 \
  || bounded_rc=$?
if [[ "$bounded_rc" -eq 7 ]]; then
  printf 'agy-turn: agy -p exceeded %ss wall-clock cap — killed\n' "$turn_timeout" >&2
elif [[ "$bounded_rc" -ne 0 ]]; then
  printf 'agy-turn: agy -p failed (exit %s)\n' "$bounded_rc" >&2; exit 5
fi
# Guard (a): silent-failure-under-sandbox. agy -p can exit 0 with EMPTY output when its backend is
# unreachable (sandboxed network). Treat that as a failed turn, NOT a successful no-op — otherwise an
# automated relay reads a blocked turn as "agent had nothing to do" and advances on a phantom success.
# (Only enforced on a clean exit; a timeout-kill at rc=7 is reported below after containment.)
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
