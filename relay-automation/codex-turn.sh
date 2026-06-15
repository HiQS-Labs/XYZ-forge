#!/usr/bin/env bash
set -euo pipefail
#
# codex-turn.sh — Option-A turn-taker shim: drive ONE relay turn for the Codex agent
# headlessly via `codex exec`, behind a hard path-allowlist safety boundary.
#
# Invoked by relay-drive.sh as the --agent-cmd, with env:
#   RELAY_FILE   — the relay thread file (always allowlisted)
#   RELAY_TASK   — the tick turn-token (default RELAY-TURN)
#   RELAY_AGENT  — the current actor (the token's claimer/handoff_to)
# Plus shim config:
#   CODEX_AGENT      — the agent id this shim drives; it NO-OPS unless RELAY_AGENT==CODEX_AGENT
#                      (so Claude turns stay window-driven; only Codex turns go headless)
#   ALLOW_PATHS      — comma-separated extra git paths the turn may change (e.g. the artifact)
#   CODEX_BIN        — codex binary (default: codex); tests inject a stub
#   CODEX_TURN_ROOT  — git root to guard (default: this repo); tests point at a fixture repo
#   CODEX_LOG        — where to write the codex transcript (default: stderr)
#
# Safety contract (Codex review 2026-06-15): the shim — NOT relay-drive.sh — owns the
# clean-tree boundary. Codex does the turn (tick token ops + edit the relay file) but
# runs NO git; the shim verifies only allowlisted paths changed (reverting any off-lane
# edit and FAILING the turn), stages only those, and commits **without pushing**
# (coordination is shared-local .tick/events/; tick does not depend on push).
#
# Exit: 0 acted/deferred · 5 codex failed · 6 off-allowlist edit (reverted) · 2 usage.

ROOT="${CODEX_TURN_ROOT:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}"
CODEX_BIN="${CODEX_BIN:-codex}"
die() { printf 'codex-turn: %s\n' "$*" >&2; exit 2; }

me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
codex_agent="${CODEX_AGENT:-}"
[[ -n "$me" ]] || die "RELAY_AGENT required"
[[ -n "$f" ]] || die "RELAY_FILE required"
[[ -n "$codex_agent" ]] || die "CODEX_AGENT required"

# 1. Dispatch only for the Codex agent; defer otherwise.
if [[ "$me" != "$codex_agent" ]]; then
  printf 'codex-turn: actor %s is not the Codex agent (%s) — deferring (window-driven)\n' "$me" "$codex_agent" >&2
  exit 0
fi

# Allowlist = relay file + ALLOW_PATHS (repo-root-relative paths).
allow=("$f")
IFS=',' read -ra _extra <<<"${ALLOW_PATHS:-}"
for p in "${_extra[@]:-}"; do [[ -n "$p" ]] && allow+=("$p"); done
# normalize to repo-root-relative (git status emits relative paths)
_n=(); for a in "${allow[@]}"; do _n+=("${a#"$ROOT"/}"); done; allow=("${_n[@]}")
in_allow() { local x="$1" a; for a in "${allow[@]}"; do [[ "$x" == "$a" ]] && return 0; done; return 1; }

# 2. Run the Codex turn headless. Codex does token ops + edits the relay file; NO git.
prompt="You are agent ${me}, taking your turn in a file-based relay. Read ${f} and follow its embedded '▶ TAKE YOUR TURN' steps for your role. Use ./bin/tick for the ${t} token (claim/ping, then release --to the other agent, or done + set STATUS: Approved when approving). Edit ONLY ${f}${ALLOW_PATHS:+ and: ${ALLOW_PATHS}}. Do NOT run git (no add/commit/push) and do NOT touch any other file — the harness commits for you."
"$CODEX_BIN" exec "$prompt" < /dev/null > "${CODEX_LOG:-/dev/stderr}" 2>&1 || { printf 'codex-turn: codex exec failed\n' >&2; exit 5; }

# 3. Enforce the allowlist on tracked-tree changes (.tick is gitignored, so token ops don't show).
violation=0
while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  path="${line:3}"                      # strip "XY " porcelain prefix
  if ! in_allow "$path"; then
    printf 'codex-turn: OFF-ALLOWLIST change: %s — reverting\n' "$path" >&2
    git -C "$ROOT" checkout -- "$path" 2>/dev/null || rm -rf "$ROOT/${path%/}"
    violation=1
  fi
done < <(git -C "$ROOT" status --porcelain)
((violation == 0)) || { printf 'codex-turn: off-lane edits reverted; failing the turn\n' >&2; exit 6; }

# 4. Stage ONLY the allowlist; commit file-scoped; NO push.
git -C "$ROOT" add -- "${allow[@]}" 2>/dev/null || true
if git -C "$ROOT" diff --cached --quiet; then
  printf 'codex-turn: %s turn produced no tracked changes (token-only move?)\n' "$me"
else
  git -C "$ROOT" commit -q -m "relay(${t}): ${me} turn (codex exec, headless; no push)"
  printf 'codex-turn: committed %s turn (file-scoped, no push)\n' "$me"
fi
