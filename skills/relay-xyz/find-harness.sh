#!/usr/bin/env bash
#
# find-harness.sh — device-agnostic locator for the xyz-3-agents-swarm relay harness.
#
# Prints the absolute path to the repo root that ships relay-automation/ (the relay
# harness: relay-drive.sh, the turn shims, poll.sh, bin/tick). It resolves WITHOUT any
# hardcoded machine path, so /relay-xyz works from any working directory — including a
# clone of a *different* repo — because this script ships INSIDE the harness repo
# (skills/relay-xyz/find-harness.sh) and resolves relative to its own real location,
# following symlinks (the skill is usually symlinked into ~/.claude/skills/relay-xyz).
#
# Usage:
#   find-harness.sh            # print the harness root, or error to stderr (exit 1)
#   find-harness.sh --root     # same as default
#   find-harness.sh --env      # print shell `export …` lines, safe to eval
#   find-harness.sh --check    # human-readable readiness checklist
#
# Resolution order (first hit wins):
#   1. $XYZ_HARNESS / $XYZ_REPO_ROOT          — explicit override
#   2. the current git repo root              — you're already standing in a harness clone
#   3. this script's own real location        — …/<repo>/skills/relay-xyz → <repo>
#
# bash 3.2-safe (macOS default): no `readlink -f`, no associative arrays.
set -u

_has_harness() { [ -n "${1:-}" ] && [ -x "$1/relay-automation/relay-drive.sh" ]; }

# --- resolve this script's real directory (symlink-safe) ---
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"

HARNESS=""
# 1. explicit override
for _o in "${XYZ_HARNESS:-}" "${XYZ_REPO_ROOT:-}"; do
  if _has_harness "$_o"; then HARNESS="$(cd "$_o" && pwd)"; break; fi
done
# 2. current git repo (preserves "operate on the clone I'm standing in")
if [ -z "$HARNESS" ]; then
  _g="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if _has_harness "$_g"; then HARNESS="$_g"; fi
fi
# 3. relative to this script (…/<repo>/skills/relay-xyz → <repo>) — fixes the
#    cross-repo case: the skill is global but the harness ships beside it.
if [ -z "$HARNESS" ]; then
  _cand="$(cd "$SELF_DIR/../.." >/dev/null 2>&1 && pwd || true)"
  if _has_harness "$_cand"; then HARNESS="$_cand"; fi
fi

if [ -z "$HARNESS" ]; then
  echo "find-harness: relay-automation/ harness not found." >&2
  echo "  Set XYZ_HARNESS=/path/to/your/xyz-3-agents-swarm clone and retry." >&2
  exit 1
fi

# --- capability probes (read-only; safe under any sandbox) ---
TICK="$HARNESS/bin/tick"; [ -x "$TICK" ] || TICK=""
_bin() { command -v "${1:-}" 2>/dev/null || true; }
CODEX_PATH="$(_bin "${CODEX_BIN:-codex}")"
AGY_PATH="$(_bin "${AGY_BIN:-agy}")"
_flag() { [ -n "${1:-}" ] && echo 1 || echo 0; }

case "${1:-}" in
  ""|--root)
    printf '%s\n' "$HARNESS"
    ;;
  --env)
    printf 'export HARNESS=%q\n'         "$HARNESS"
    printf 'export TICK_REPO_ROOT=%q\n'  "$HARNESS"
    [ -n "$TICK" ]       && printf 'export TICK=%q\n'       "$TICK"
    [ -n "$CODEX_PATH" ] && printf 'export CODEX_BIN=%q\n'  "$CODEX_PATH"
    [ -n "$AGY_PATH" ]   && printf 'export AGY_BIN=%q\n'    "$AGY_PATH"
    printf 'export RELAY_HAS_TICK=%s\n'  "$(_flag "$TICK")"
    printf 'export RELAY_HAS_CODEX=%s\n' "$(_flag "$CODEX_PATH")"
    printf 'export RELAY_HAS_AGY=%s\n'   "$(_flag "$AGY_PATH")"
    ;;
  --check)
    mark() { if [ -n "${1:-}" ]; then echo "  ok  $2  ($1)"; else echo "  --  $2  (not found)"; fi; }
    echo "relay harness readiness:"
    echo "  ok  harness  ($HARNESS)"
    mark "$TICK"       "tick CLI"
    mark "$CODEX_PATH" "codex CLI (Path A worker)"
    mark "$AGY_PATH"   "agy CLI   (Path A worker)"
    if [ -z "$CODEX_PATH" ] && [ -z "$AGY_PATH" ]; then
      echo "  !   no cross-model headless worker on PATH — only Path B (all-Claude poll) is available"
    fi
    ;;
  *)
    echo "usage: find-harness.sh [--root|--env|--check]" >&2
    exit 2
    ;;
esac
