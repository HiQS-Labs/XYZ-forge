#!/usr/bin/env bash
#
# find-pdda.sh — device-agnostic locator for the canonical PDDA source repo.
#
# Prints the absolute path to a PDDA clone (the repo that ships install.sh +
# utils/pdda/PDDA-INSTALL.md), so /vendor-stack can install PDDA into a target repo
# from any working directory without a hardcoded machine path. Mirrors the resolution
# discipline of skills/relay-xyz/find-harness.sh: it resolves relative to nothing it
# controls, so it works on any machine as long as a PDDA clone exists somewhere findable.
#
# Usage:
#   find-pdda.sh            # print the PDDA repo root, or error to stderr (exit 1)
#   find-pdda.sh --root     # same as default
#   find-pdda.sh --env      # print `export …` lines, safe to eval
#   find-pdda.sh --check    # human-readable readiness checklist
#
# Resolution order (first hit wins):
#   1. $PDDA_REPO / $PDDA_HOME                 — explicit override
#   2. sibling of the xyz harness root         — <harness-parent>/pdda (both under GitHub-Repos/…)
#   3. a small list of conventional clone paths under $HOME
#
# A directory qualifies as a PDDA repo only if it carries ALL of:
#   install.sh, utils/pdda/PDDA-INSTALL.md, utils/pdda/pdda.sh
#
# bash 3.2-safe (macOS default): no `readlink -f`, no associative arrays.
set -u

_is_pdda_repo() {
  [ -n "${1:-}" ] || return 1
  [ -f "$1/install.sh" ] || return 1
  [ -f "$1/utils/pdda/PDDA-INSTALL.md" ] || return 1
  [ -f "$1/utils/pdda/pdda.sh" ] || return 1
  return 0
}
_canon_dir() { [ -n "${1:-}" ] && (cd "$1" >/dev/null 2>&1 && pwd); }

# --- resolve this script's real directory (symlink-safe) ---
_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"   # …/skills/vendor-stack
# skills/vendor-stack → skills → <harness root>
HARNESS_ROOT="$(_canon_dir "$SELF_DIR/../.." || true)"
HARNESS_PARENT="$(_canon_dir "$HARNESS_ROOT/.." || true)"

PDDA=""
RESOLVED_VIA=""

# 1. explicit override
for _cand in "${PDDA_REPO:-}" "${PDDA_HOME:-}"; do
  [ -n "$_cand" ] || continue
  _c="$(_canon_dir "$_cand" || true)"
  if _is_pdda_repo "$_c"; then PDDA="$_c"; RESOLVED_VIA="env override"; break; fi
done

# 2. sibling of the xyz harness root
if [ -z "$PDDA" ] && [ -n "$HARNESS_PARENT" ]; then
  _c="$(_canon_dir "$HARNESS_PARENT/pdda" || true)"
  if _is_pdda_repo "$_c"; then PDDA="$_c"; RESOLVED_VIA="harness sibling"; fi
fi

# 3. conventional clone paths under $HOME
if [ -z "$PDDA" ]; then
  for _cand in \
    "$HOME/Documents/GitHub-Repos/pdda" \
    "$HOME/Documents/GitHub/pdda" \
    "$HOME/GitHub-Repos/pdda" \
    "$HOME/GitHub/pdda" \
    "$HOME/repos/pdda" \
    "$HOME/src/pdda" \
    "$HOME/pdda"; do
    _c="$(_canon_dir "$_cand" || true)"
    if _is_pdda_repo "$_c"; then PDDA="$_c"; RESOLVED_VIA="conventional path"; break; fi
  done
fi

_mode="${1:---root}"
case "$_mode" in
  --root|"")
    if [ -n "$PDDA" ]; then printf '%s\n' "$PDDA"; exit 0; fi
    echo "find-pdda.sh: could not resolve a PDDA repo." >&2
    echo "  Set PDDA_REPO=/path/to/your/pdda clone, or clone pdda beside your xyz harness." >&2
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
      echo "  install.sh   : $( [ -x "$PDDA/install.sh" ] && echo executable || echo 'present (not +x)' )"
      exit 0
    fi
    echo "  PDDA repo    : <unresolved>"
    echo "  fix          : export PDDA_REPO=/path/to/your/pdda clone"
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
