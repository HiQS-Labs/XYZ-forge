#!/usr/bin/env bash
set -euo pipefail
#
# gemini-turn.sh — headless turn-taker for the GEMINI agent. Thin dispatch wrapper over the
# shared safety core (relay-turn-lib.sh) — the SAME containment contract as codex-turn.sh,
# proving the boundary is model-agnostic (decisions/2026-06-15-unattended-agent-containment.md).
#
# History: first drafted standalone by Gemini (fe0bd61), an exact parallel to codex-turn.sh.
# Reconciled here onto the shared core (boundary in ONE place, not duplicated) AND corrected the
# headless invocation: the Gemini CLI has NO `exec` subcommand — headless is `gemini -p`, and an
# unattended turn needs GCA auth + `--yolo` + `--skip-trust` (caught by live-running the CLI 0.46.0).
#
# Invoked by relay-drive.sh as --agent-cmd, with env:
#   RELAY_FILE  — relay thread file (always allowlisted)
#   RELAY_TASK  — tick turn-token (default RELAY-TURN)
#   RELAY_AGENT — current actor (the token's claimer/handoff_to)
# Shim config:
#   GEMINI_AGENT     — the agent id this shim drives; NO-OPS unless RELAY_AGENT==GEMINI_AGENT
#   ALLOW_PATHS      — comma-separated extra git paths the turn may change (e.g. the artifact)
#   RELAY_PEER       — optional: the other agent's id, so the turn hands off "--to <peer>" (else the
#                      prompt says "the other agent", which a live model may resolve to a role name)
#   GEMINI_BIN       — gemini binary (default: gemini); tests inject a stub
#   GEMINI_TURN_ROOT — git root to guard (default: this repo); tests point at a fixture
#   GEMINI_LOG       — where to write the gemini transcript (default: stderr)
#
# Auth/headless contract (validated 2026-06-15, gemini-cli 0.46.0):
#   GOOGLE_GENAI_USE_GCA=true  — personal Google login (free tier), reuses ~/.gemini/oauth_creds.json
#   -p "<prompt>"              — non-interactive (headless) mode
#   --yolo                     — auto-approve tool calls (shell for tick, edit for the relay file)
#   --skip-trust               — bypass the trusted-folder prompt in an automated environment
#
# Exit: 0 acted/deferred · 5 gemini failed · 6 off-allowlist edit (reverted) · 2 usage.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=relay-turn-lib.sh
source "$HERE/relay-turn-lib.sh"

ROOT="${GEMINI_TURN_ROOT:-"$(cd "$HERE/.." && pwd)"}"
GEMINI_BIN="${GEMINI_BIN:-gemini}"
die() { printf 'gemini-turn: %s\n' "$*" >&2; exit 2; }

me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
gemini_agent="${GEMINI_AGENT:-}"
[[ -n "$me" ]] || die "RELAY_AGENT required"
[[ -n "$f" ]] || die "RELAY_FILE required"
[[ -n "$gemini_agent" ]] || die "GEMINI_AGENT required"

# Dispatch only for the Gemini agent; defer otherwise (that window drives its own turn).
if [[ "$me" != "$gemini_agent" ]]; then
  printf 'gemini-turn: actor %s is not the Gemini agent (%s) — deferring (window-driven)\n' "$me" "$gemini_agent" >&2
  exit 0
fi

rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"

# Transcript/log: default to a $TMPDIR file (NOT the repo tree — the safety guard in
# relay-turn-lib.sh deletes any in-tree log). A persisted transcript is both the debug record AND
# the token source: `-o json` makes the CLI emit a stats block we parse for cost.tokens (Phase 1).
GEMINI_LOG="${GEMINI_LOG:-${TMPDIR:-/tmp}/gemini-turn-$$.json}"
GEMINI_OUTPUT_FORMAT="${GEMINI_OUTPUT_FORMAT:-json}"

# Run the Gemini turn headless (token ops + edit the relay file; NO git), then enforce the boundary.
rtl_before
GOOGLE_GENAI_USE_GCA="${GOOGLE_GENAI_USE_GCA:-true}" \
  "$GEMINI_BIN" --yolo --skip-trust -o "$GEMINI_OUTPUT_FORMAT" -p "$prompt" < /dev/null > "$GEMINI_LOG" 2>&1 \
  || { printf 'gemini-turn: gemini -p failed\n' >&2; exit 5; }
rtl_enforce "$t" "$me" "$GEMINI_LOG" "gemini"

# Best-effort cost capture (Phase 1, COST-OBSERVABILITY-PLAN): parse the CLI's own token stats and
# log a cost.tokens event. NEVER fails the turn — the turn already committed; a missing/unparseable
# stats block just means "tokens not captured" (the loud-partial signal), not a failed turn.
if [[ -s "$GEMINI_LOG" ]]; then
  "${TICK_BIN:-$ROOT/bin/tick}" cost "$t" --agent "$me" --from-gemini-json "$GEMINI_LOG" --tool gemini \
    || printf 'gemini-turn: tokens not captured for %s (no parseable stats in transcript)\n' "$t" >&2
fi
