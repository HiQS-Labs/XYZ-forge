#!/usr/bin/env bash
set -euo pipefail
#
# gemini-turn.sh — Option-A turn-taker shim: drive ONE relay turn for the Gemini agent
# headlessly via `gemini exec`, behind a hard path-allowlist safety boundary.
#
# Invoked by relay-drive.sh as the --agent-cmd, with env:
#   RELAY_FILE   — the relay thread file (always allowlisted)
#   RELAY_TASK   — the tick turn-token (default RELAY-TURN)
#   RELAY_AGENT  — the current actor (the token's claimer/handoff_to)
# Plus shim config:
#   GEMINI_AGENT      — the agent id this shim drives; it NO-OPS unless RELAY_AGENT==GEMINI_AGENT
#                      (so Claude turns stay window-driven; only Gemini turns go headless)
#   ALLOW_PATHS      — comma-separated extra git paths the turn may change (e.g. the artifact)
#   GEMINI_BIN        — gemini binary (default: gemini); tests inject a stub
#   GEMINI_TURN_ROOT  — git root to guard (default: this repo); tests point at a fixture repo
#   GEMINI_LOG        — where to write the gemini transcript (default: stderr)
#
# Safety contract (Gemini review 2026-06-15): the shim — NOT relay-drive.sh — owns the
# clean-tree boundary. Gemini does the turn (tick token ops + edit the relay file) but
# runs NO git; the shim verifies only allowlisted paths changed (reverting any off-lane
# edit and FAILING the turn), stages only those, and commits **without pushing**
# (coordination is shared-local .tick/events/; tick does not depend on push).
#
# Exit: 0 acted/deferred · 5 gemini failed · 6 off-allowlist edit (reverted) · 2 usage.

ROOT="${GEMINI_TURN_ROOT:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"}"
GEMINI_BIN="${GEMINI_BIN:-gemini}"
die() { printf 'gemini-turn: %s\n' "$*" >&2; exit 2; }

me="${RELAY_AGENT:-}"; f="${RELAY_FILE:-}"; t="${RELAY_TASK:-RELAY-TURN}"
gemini_agent="${GEMINI_AGENT:-}"
[[ -n "$me" ]] || die "RELAY_AGENT required"
[[ -n "$f" ]] || die "RELAY_FILE required"
[[ -n "$gemini_agent" ]] || die "GEMINI_AGENT required"

# 1. Dispatch only for the Gemini agent; defer otherwise.
if [[ "$me" != "$gemini_agent" ]]; then
  printf 'gemini-turn: actor %s is not the Gemini agent (%s) — deferring (window-driven)\n' "$me" "$gemini_agent" >&2
  exit 0
fi

# Allowlist = relay file + ALLOW_PATHS (repo-root-relative paths).
allow=("$f")
IFS=',' read -ra _extra <<<"${ALLOW_PATHS:-}"
for p in "${_extra[@]:-}"; do [[ -n "$p" ]] && allow+=("$p"); done
# normalize to repo-root-relative (git status emits relative paths)
_n=(); for a in "${allow[@]}"; do _n+=("${a#"$ROOT"/}"); done; allow=("${_n[@]}")
in_allow() { local x="$1" a; for a in "${allow[@]}"; do [[ "$x" == "$a" ]] && return 0; done; return 1; }

# 2. Run the Gemini turn headless. Gemini does token ops + edits the relay file; NO git.
prompt="You are agent ${me}, taking your turn in a file-based relay. Read ${f} and follow its embedded '▶ TAKE YOUR TURN' steps for your role. Use ./bin/tick for the ${t} token (claim/ping, then release --to the other agent, or done + set STATUS: Approved when approving). Edit ONLY ${f}${ALLOW_PATHS:+ and: ${ALLOW_PATHS}}. Do NOT run git (no add/commit/push) and do NOT touch any other file — the harness commits for you."
before_head="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo none)"
"$GEMINI_BIN" exec "$prompt" < /dev/null > "${GEMINI_LOG:-/dev/stderr}" 2>&1 || { printf 'gemini-turn: gemini exec failed\n' >&2; exit 5; }

# 2b. Commit-bypass guard (Gemini r1 Blocker): Gemini must NOT git. If it committed, its edits are
# hidden from `git status` — undo the commit(s) and fail, so off-lane changes can't slip in committed.
if [[ "$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo none)" != "$before_head" ]]; then
  git -C "$ROOT" reset --hard "$before_head" >/dev/null 2>&1 || true
  printf 'gemini-turn: Gemini committed during its turn (forbidden) — reset to %s, failing\n' "${before_head:0:8}" >&2
  exit 6
fi

# 3. Enforce the allowlist on tracked-tree changes (.tick is gitignored, so token ops don't show).
# Use -z (NUL-delimited, RAW unquoted paths) so filenames with spaces/special chars can't slip past
# the match or break the revert, and rename records (R/C, two NUL fields) are both checked (Gemini r1
# Blocker). The shim's own transcript log, if it lands inside the tree, is not a Gemini edit — drop it.
# NOTE (Gemini r1 Should): git-status does NOT report gitignored files; .tick is *intentionally*
# written by the turn, so we deliberately do NOT `git clean -Xdf` (that would destroy the coordination
# state). Ignored-file safety for an unattended agent belongs to the gemini sandbox, tracked as future.
log_rel="${GEMINI_LOG:+${GEMINI_LOG#"$ROOT"/}}"
violation=0
check_path() {
  local p="$1"
  [[ -n "$p" ]] || return 0
  if [[ -n "$log_rel" && "$p" == "$log_rel" ]]; then rm -f "$ROOT/$p"; return 0; fi
  in_allow "$p" && return 0
  printf 'gemini-turn: OFF-ALLOWLIST change: %s — reverting\n' "$p" >&2
  git -C "$ROOT" checkout -- "$p" 2>/dev/null || rm -rf "$ROOT/${p%/}"
  violation=1
}
while IFS= read -r -d '' entry; do
  [[ -n "$entry" ]] || continue
  xy="${entry:0:2}"; path="${entry:3}"
  case "$xy" in
    R*|C*) IFS= read -r -d '' src || true; check_path "$path"; check_path "$src" ;;
    *)     check_path "$path" ;;
  esac
done < <(git -C "$ROOT" status --porcelain -z)
((violation == 0)) || { printf 'gemini-turn: off-lane edits reverted; failing the turn\n' >&2; exit 6; }

# 4. Stage ONLY the allowlist; commit file-scoped; NO push.
git -C "$ROOT" add -- "${allow[@]}" 2>/dev/null || true
if git -C "$ROOT" diff --cached --quiet; then
  printf 'gemini-turn: %s turn produced no tracked changes (token-only move?)\n' "$me"
else
  git -C "$ROOT" commit -q -m "relay(${t}): ${me} turn (gemini exec, headless; no push)"
  printf 'gemini-turn: committed %s turn (file-scoped, no push)\n' "$me"
fi
