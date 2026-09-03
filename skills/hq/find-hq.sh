#!/usr/bin/env bash
#
# find-hq.sh — device-agnostic locator for the HQ command-center scripts (GH-128, Phase 4).
#
# Prints the absolute path to utils/hq/hq.sh — the HQ dispatcher — so /hq runs from ANY
# working directory, including a session opened in a *different* repo. This is what closes the
# Phase 4 "user-level /hq" remainder: the skill no longer assumes the CWD is the harness repo.
#
# HQ is CENTRALIZED: hq.sh + hq-lib.sh read the $HOME registries and resolve targets across the
# whole device, so there is exactly ONE hq.sh — the copy that ships in this harness repo, beside
# this skill. Unlike relay-xyz's find-harness.sh there is no vendored per-repo ".xyz" HQ copy to
# reconcile, so resolution is deliberately simpler: explicit override, the current harness clone,
# or this script's own real (symlink-followed) location.
#
# Usage:
#   find-hq.sh            # print the absolute path to hq.sh (or error to stderr, exit 1)
#   find-hq.sh --sh       # same as default (explicit)
#   find-hq.sh --root     # print the harness repo root that ships utils/hq/
#   find-hq.sh --env      # print shell `export …` lines, safe to eval (HQ_ROOT, HQ_SH)
#   find-hq.sh --check    # human-readable readiness checklist
#
# Resolution order (first hit wins), each anchored on $HOME / the CWD / this script — never a
# hardcoded machine path:
#   1. $XYZ_HARNESS / $XYZ_REPO_ROOT   — explicit override (shared with find-harness.sh)
#   2. the current git repo root       — you're already standing in a harness clone
#   3. this script's own real location — …/<repo>/skills/hq → <repo> (the cross-repo case)
#
# bash 3.2-safe (macOS default): no `readlink -f`, no associative arrays.
set -u

_has_hq() { [ -n "${1:-}" ] && [ -x "$1/utils/hq/hq.sh" ]; }

# --- resolve this script's real directory (symlink-safe) ---
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ] || [ -L "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"   # …/skills/hq

_hp_lib="$SELF_DIR/../../relay-automation/harness-paths.sh"
if [ -f "$_hp_lib" ]; then
  # shellcheck source=relay-automation/harness-paths.sh
  . "$_hp_lib"
fi


ROOT=""
# 1. explicit override (same env vars find-harness.sh honors — one knob for the whole harness)
for _o in "${XYZ_HARNESS:-}" "${XYZ_REPO_ROOT:-}"; do
  if _has_hq "$_o"; then ROOT="$(cd "$_o" && pwd)"; break; fi
done
# 2. the current git repo (preserves "operate on the clone I'm standing in")
if [ -z "$ROOT" ]; then
  _g="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if _has_hq "$_g"; then ROOT="$(cd "$_g" && pwd)"; fi
fi
# 3. relative to this script (…/<repo>/skills/hq → <repo>) — the cross-repo case: the skill is
#    global (symlinked into ~/.claude/skills/hq) but hq.sh ships beside it in the harness clone.
if [ -z "$ROOT" ]; then
  _cand="$(cd "$SELF_DIR/../.." >/dev/null 2>&1 && pwd || true)"
  if _has_hq "$_cand"; then ROOT="$_cand"; fi
fi

if [ -z "$ROOT" ]; then
  echo "find-hq: utils/hq/hq.sh not found." >&2
  echo "  Set XYZ_HARNESS=/path/to/your/xyz-3-agents-swarm clone and retry." >&2
  exit 1
fi

HQ_SH="$ROOT/utils/hq/hq.sh"

case "${1:-}" in
  ""|--sh)
    printf '%s\n' "$HQ_SH"
    ;;
  --root)
    printf '%s\n' "$ROOT"
    ;;
  --env)
    printf 'export HQ_ROOT=%q\n' "$ROOT"
    printf 'export HQ_SH=%q\n'   "$HQ_SH"
    ;;
  --check)
    echo "HQ readiness:"
    echo "  ok  hq root  ($ROOT)"
    echo "  ok  hq.sh    ($HQ_SH)"
    if command -v sqlite3 >/dev/null 2>&1; then
      echo "  ok  sqlite3  (rebalance priority board / project cards enabled)"
    else
      echo "  --  sqlite3  (not found — 'hq next' + Rebalance priority degrade to empty)"
    fi
    # Rebalance registry: the semantic name catalog. Read-only; absence just narrows resolution.
    _rebal="${HQ_REBALANCE_DB:-$HOME/Documents/rebalance-OS/rebalance.db}"
    if [ -f "$_rebal" ]; then
      echo "  ok  rebalance registry  ($_rebal)"
    else
      echo "  --  rebalance registry  (not found: $_rebal — set HQ_REBALANCE_DB to override)"
    fi
    true   # --check is advisory: always exit 0, never block on a warning
    ;;
  *)
    echo "usage: find-hq.sh [--sh|--root|--env|--check]" >&2
    exit 2
    ;;
esac
