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
#   CODEX_TURN_ROOT — git root to guard (default: this repo); tests point at a fixture
#   CODEX_LOG       — where to write the codex transcript (default: stderr)
#
# Exit: 0 acted/deferred · 5 codex failed · 6 off-allowlist edit (reverted) · 2 usage.

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

rtl_init "$ROOT" "$f" "${ALLOW_PATHS:-}"
prompt="$(rtl_turn_prompt "$me" "$f" "$t" "${ALLOW_PATHS:-}" "${RELAY_PEER:-}")"

# Run the Codex turn headless (token ops + edit the relay file; NO git), then enforce the boundary.
rtl_before
"$CODEX_BIN" exec "$prompt" < /dev/null > "${CODEX_LOG:-/dev/stderr}" 2>&1 \
  || { printf 'codex-turn: codex exec failed\n' >&2; exit 5; }
rtl_enforce "$t" "$me" "${CODEX_LOG:-}" "codex"
