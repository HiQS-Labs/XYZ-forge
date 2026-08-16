#!/usr/bin/env bash
# durable-log-lib.sh — GH-388: is this path somewhere evidence will still be after a reboot?
#
# The registry itself is NOT in this file. It is `relay-automation/non-durable-log-roots.conf`, read
# at runtime, and `utils/py/rtl.py::path_is_durable` reads the SAME file — so the two lanes cannot
# disagree, and there is no second list to go stale. `test/gh388-run-log-durability.sh` asserts both
# readers return the same verdict for the same paths, which is the only thing that keeps that claim
# true. Same shape as driver-lock-lib.sh (GH-448), for the same reason: a consumer that inlines its
# own version of this decision is the defect the shared file exists to kill.
#
# API:
#   xyz_non_durable_conf                — prints the path to the registry file
#   xyz_path_is_durable <path>          — exit 0 if durable, 1 if it resolves into a non-durable root
#   xyz_non_durable_reason <path>       — prints the matched prefix (empty if durable)
set -u

_XYZ_DURABLE_LIB_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

xyz_non_durable_conf() {
  printf '%s/relay-automation/non-durable-log-roots.conf' "$_XYZ_DURABLE_LIB_HOME"
}

# Resolve a path to its REAL location without requiring the path itself to exist yet — the log file
# is usually about to be created. Walk up to the nearest existing ancestor, canonicalize THAT, then
# re-append the tail. Canonicalizing matters: on macOS /tmp is a symlink to /private/tmp, so a
# logical-form check alone lets the same directory through under its other name.
_xyz_realish_path() {
  local p="$1" tail="" base
  case "$p" in /*) ;; *) p="$PWD/$p" ;; esac
  while [ -n "$p" ] && [ "$p" != "/" ] && [ ! -e "$p" ]; do
    base="$(basename "$p")"
    tail="${base}${tail:+/$tail}"
    p="$(dirname "$p")"
  done
  if [ -d "$p" ]; then
    p="$(cd "$p" 2>/dev/null && pwd -P)" || p="$1"
  fi
  printf '%s' "${p%/}${tail:+/$tail}"
}

xyz_non_durable_reason() {  # <path> — prints the matched non-durable prefix, or nothing
  local path real conf line prefix
  path="${1:-}"
  [ -n "$path" ] || return 0
  real="$(_xyz_realish_path "$path")"
  conf="$(xyz_non_durable_conf)"

  # TMPDIR is a value, not a literal a file can hold — see the conf's own note. Checked first so a
  # relocated TMPDIR is caught even when it points somewhere the static list never anticipated.
  if [ -n "${TMPDIR:-}" ]; then
    prefix="$(_xyz_realish_path "${TMPDIR%/}")"
    if [ -n "$prefix" ] && { [ "$real" = "$prefix" ] || case "$real" in "$prefix"/*) true ;; *) false ;; esac; }; then
      printf '%s' "$prefix"
      return 0
    fi
  fi

  [ -f "$conf" ] || return 0
  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -n "$line" ] || continue
    prefix="${line%/}"
    if [ "$real" = "$prefix" ] || case "$real" in "$prefix"/*) true ;; *) false ;; esac; then
      printf '%s' "$prefix"
      return 0
    fi
  done <"$conf"
  return 0
}

xyz_path_is_durable() {  # <path> — exit 0 durable, 1 non-durable
  local matched
  matched="$(xyz_non_durable_reason "${1:-}")"
  [ -z "$matched" ]
}
