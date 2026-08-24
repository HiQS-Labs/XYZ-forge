#!/usr/bin/env bash
set -euo pipefail

# git-sandbox-guard.sh — GH-50: prove the repository config can be written before a
# branch-changing command gets a chance to rewrite the index or working tree.

usage() {
  cat >&2 <<'USAGE'
Usage: utils/git-sandbox-guard.sh [--repo <path>] [--operation <label>] [--] [command ...]

Preflight only when no command is supplied. When a command is supplied, run it only
after the repository's config and config-lock path both pass a real write probe.
USAGE
}

refuse() {
  echo "git-sandbox-guard: REFUSING — $*" >&2
  exit 2
}

repo="."
operation="git branch mutation"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      repo="$2"
      shift 2
      ;;
    --operation)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      operation="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

[ -n "$repo" ] || refuse "repository path is empty; '$operation' was not attempted (GH-50)"
[ -d "$repo" ] || refuse "repository '$repo' is not a directory; '$operation' was not attempted (GH-50)"

common_dir="$(git -C "$repo" rev-parse --git-common-dir 2>/dev/null)" ||
  refuse "cannot resolve the git common directory for '$repo'; '$operation' was not attempted (GH-50)"
case "$common_dir" in
  /*) common_abs="$common_dir" ;;
  *)
    common_abs="$(cd "$repo" && cd "$common_dir" 2>/dev/null && pwd -P)" ||
      refuse "cannot resolve git common directory '$common_dir'; '$operation' was not attempted (GH-50)"
    ;;
esac

config="$common_abs/config"
[ -f "$config" ] || refuse "git config '$config' is missing; '$operation' was not attempted (GH-50)"

# Opening the real file for a zero-byte append tests the exact sandbox permission without
# changing its bytes. Git's config writer also creates config.lock and renames it over config,
# so probe that path too. Noclobber makes a concurrent legitimate lock a loud refusal.
if ! { : >> "$config"; } 2>/dev/null; then
  refuse "git config '$config' is not writable; '$operation' was not attempted (GH-50)"
fi

config_lock="$config.lock"
if ! ( set -C; : > "$config_lock" ) 2>/dev/null; then
  refuse "git config lock '$config_lock' cannot be created; '$operation' was not attempted (GH-50)"
fi
if ! rm -f -- "$config_lock"; then
  refuse "git config lock probe '$config_lock' cannot be removed; '$operation' was not attempted (GH-50)"
fi

[ "$#" -gt 0 ] || exit 0
"$@"
