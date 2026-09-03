#!/usr/bin/env bash
# relay-automation/harness-paths.sh (GH-396 Phase 3) — single sourceable Bash library for root resolution.
#
# Provides:
#   xyz_resolve_self_dir <source_path>   — symlink-following directory resolver (macOS/bash 3.2 safe)
#   xyz_harness_home [start_path]        — dir containing relay-automation/ + utils/: repo root, or <repo>/.xyz
#   xyz_repo_root [path]                 — consumer repo root (parent of .xyz if vendored, else harness_home)
#   xyz_is_vendored [path]               — return 0 if vendored (.xyz), 1 otherwise
#   xyz_harness_tool [repo_root] <rel>   — resolve harness tool with repo-first mock shadow preference
#   xyz_emit_env_exports <harness> <caller_root> [vendored=0|1] [status] [commit]
#
# Note: Sources driver-lock-lib.sh if present beside this file.

xyz_resolve_self_dir() {
  local _src="${1:-${BASH_SOURCE[1]:-${BASH_SOURCE[0]:-$0}}}"
  local _dir
  while [ -h "$_src" ] || [ -L "$_src" ]; do
    _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
    _src="$(readlink "$_src")"
    case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
  done
  cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd
}

# Resolve location of this library file
_XYZ_HP_SELF_DIR="$(xyz_resolve_self_dir "${BASH_SOURCE[0]}")"

# Preserve driver-lock-lib dependency (find-harness.sh:76)
if [ -f "$_XYZ_HP_SELF_DIR/driver-lock-lib.sh" ]; then
  # shellcheck source=relay-automation/driver-lock-lib.sh
  . "$_XYZ_HP_SELF_DIR/driver-lock-lib.sh"
fi

xyz_harness_home() {
  local _start="${1:-}"
  if [ -n "$_start" ]; then
    (cd "$_start" >/dev/null 2>&1 && pwd -P)
    return
  fi
  (cd "$_XYZ_HP_SELF_DIR/.." >/dev/null 2>&1 && pwd -P)
}

xyz_is_vendored() {
  local _h="${1:-"$(xyz_harness_home)"}"
  [ "$(basename "$_h")" = ".xyz" ]
}

xyz_repo_root() {
  local _h="${1:-"$(xyz_harness_home)"}"
  if xyz_is_vendored "$_h"; then
    (cd "$_h/.." >/dev/null 2>&1 && pwd -P)
  else
    printf '%s\n' "$_h"
  fi
}

xyz_harness_tool() {
  local _r="" _rel="" _h=""
  if [ "$#" -ge 2 ]; then
    _r="$1"
    _rel="$2"
  else
    _r="$(xyz_repo_root)"
    _rel="${1:-}"
  fi
  if [ -n "$_rel" ] && [ -e "$_r/$_rel" ]; then
    printf '%s\n' "$_rel"
    return 0
  fi
  _h="$(xyz_harness_home)"
  if [ -n "$_rel" ] && [ -e "$_h/$_rel" ]; then
    printf '%s\n' "$_h/$_rel"
    return 0
  fi
  printf '%s\n' "$_rel"
}

xyz_emit_env_exports() {
  local _harness="${1:-}"
  local _caller_root="${2:-}"
  local _vendored="${3:-0}"
  local _status="${4:-}"
  local _commit="${5:-}"

  printf 'export HARNESS=%q\n' "$_harness"
  printf 'export TICK_REPO_ROOT=%q\n' "$_caller_root"
  printf 'export XYZ_VENDORED=%q\n' "$_vendored"
  printf 'export XYZ_CALLER_ROOT=%q\n' "$_caller_root"
  if [ -n "$_status" ]; then
    printf 'export XYZ_VENDORED_STATUS=%q\n' "$_status"
  fi
  if [ -n "$_commit" ]; then
    printf 'export XYZ_VENDORED_COMMIT=%q\n' "$_commit"
  fi
}
