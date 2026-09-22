#!/usr/bin/env bash
#
# find-pdda.sh — locate Forge's PDDA distribution source.
# Resolution: explicit PDDA_REPO/PDDA_HOME override, otherwise this skill's Forge tree.
# Usage: find-pdda.sh [--root|--env|--check|--help]
# A source contains utils/pdda/{pdda-install.sh,PDDA-INSTALL.md,pdda.sh}.
# Handles symlinked skills and foreign working directories; no sibling PDDA clone needed.
set -u

_is_pdda_repo() {
  [ -n "${1:-}" ] || return 1
  [ -f "$1/utils/pdda/pdda-install.sh" ] || return 1
  [ -f "$1/utils/pdda/PDDA-INSTALL.md" ] || return 1
  [ -f "$1/utils/pdda/pdda.sh" ] || return 1
  return 0
}
_canon_dir() { [ -n "${1:-}" ] && (cd "$1" >/dev/null 2>&1 && pwd); }

# --- resolve this script's real directory (symlink-safe) ---
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ] || [ -L "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"   # …/skills/4-occasional/vendor-stack

_hp_lib="$SELF_DIR/../../../relay-automation/harness-paths.sh"
if [ -f "$_hp_lib" ]; then
  # shellcheck source=relay-automation/harness-paths.sh
  . "$_hp_lib"
fi

# skills/4-occasional/vendor-stack → skills → <harness root>
HARNESS_ROOT="$(_canon_dir "$SELF_DIR/../../.." || true)"
HARNESS_PARENT="$(_canon_dir "$HARNESS_ROOT/.." || true)"

PDDA=""
RESOLVED_VIA=""

# Explicit overrides must identify the new Forge-owned installer. Never silently
# fall back from a stale override to another distribution source.
for _cand in "${PDDA_REPO:-}" "${PDDA_HOME:-}" "$HARNESS_ROOT"; do
  [ -n "$_cand" ] || continue
  _c="$(_canon_dir "$_cand" || true)"
  if _is_pdda_repo "$_c"; then
    PDDA="$_c"; RESOLVED_VIA="Forge installer"; break
  fi
  echo "find-pdda.sh: source lacks utils/pdda/pdda-install.sh: $_cand" >&2
  echo "Use an updated XYZ Forge checkout; the standalone PDDA source is retired." >&2
  exit 1
done

_mode="${1:---root}"
case "$_mode" in
  --root|"")
    if [ -n "$PDDA" ]; then printf '%s\n' "$PDDA"; exit 0; fi
    echo "find-pdda.sh: could not resolve a PDDA repo." >&2
    echo "  Set PDDA_REPO=/path/to/XYZ-forge, or use an updated XYZ Forge checkout." >&2
    exit 1
    ;;
  --env)
    if [ -n "$PDDA" ]; then printf 'export PDDA_REPO=%q\n' "$PDDA"; exit 0; fi
    echo "find-pdda.sh: could not resolve a PDDA repo." >&2
    exit 1
    ;;
  --check)
    echo "vendor-stack: PDDA resolver check"
    echo "  harness root : ${HARNESS_ROOT:-<unresolved>}"
    if [ -n "$PDDA" ]; then
      echo "  PDDA repo    : $PDDA  (via $RESOLVED_VIA)"
      echo "  install.sh   : $( [ -x "$PDDA/utils/pdda/pdda-install.sh" ] && echo executable || echo 'present (not +x)' )"
      exit 0
    fi
    echo "  PDDA repo    : <unresolved>"
    echo "  fix          : export PDDA_REPO=/path/to/XYZ-forge"
    exit 1
    ;;
  -h|--help)
    sed -n '2,30p' "$0"
    exit 0
    ;;
  *)
    echo "find-pdda.sh: unknown option: $_mode" >&2
    exit 2
    ;;
esac
