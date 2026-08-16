#!/usr/bin/env bash
set -euo pipefail
# collect-relay-system.sh — copy each XYZ-registered repo's relay-system/ subfolders
# into this repo's temp/ folder, grouped by repo name.
#
# Source of truth for "registered repo": the local XYZ install registry
# (~/.config/xyz/registry.tsv, same file relay-automation/xyz-sync.sh manages) —
# its `coordinated_repo` column names every repo this device has installed/vendored
# XYZ into. This script does NOT modify that registry or the source repos; it only
# reads relay-system/ and copies.
#
# Usage:
#   utils/collect-relay-system.sh [--dest <dir>]
#
# Defaults to temp/relay-system-collected/ relative to the repo root. Skips a
# registered repo if: its path no longer exists on disk, its registry row has no
# coordinated_repo ("-"), or it has no relay-system/ directory. Two registered
# repos with the same basename would collide in the dest grouping — not handled,
# not expected on one device.
#
# Exit codes: 0 normal (including zero matches) · 1 bad args · 2 registry missing

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
XYZ_REGISTRY="${XYZ_REGISTRY:-${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"

DEST="$REPO_ROOT/temp/relay-system-collected"
while [ $# -gt 0 ]; do
  case "$1" in
    --dest) DEST="$2"; shift 2 ;;
    -h|--help) echo "usage: collect-relay-system.sh [--dest <dir>]"; exit 0 ;;
    *) echo "collect-relay-system.sh: unknown argument: $1" >&2; exit 1 ;;
  esac
done

[ -f "$XYZ_REGISTRY" ] || { echo "collect-relay-system.sh: no XYZ registry at $XYZ_REGISTRY" >&2; exit 2; }

mkdir -p "$DEST"

seen=()
already_seen() {
  local want="$1" s
  for s in "${seen[@]:-}"; do [ "$s" = "$want" ] && return 0; done
  return 1
}

checked=0 copied_repos=0 copied_dirs=0

while IFS=$'\t' read -r install_dir _last_install tick_version source_commit coordinated_repo; do
  case "$install_dir" in ''|'#'*) continue ;; esac
  coordinated_repo="${coordinated_repo%$'\r'}"
  [ -n "$coordinated_repo" ] && [ "$coordinated_repo" != "-" ] || continue
  already_seen "$coordinated_repo" && continue
  seen+=("$coordinated_repo")
  checked=$((checked + 1))

  if [ ! -d "$coordinated_repo" ]; then
    echo "skip (missing on disk): $coordinated_repo"
    continue
  fi
  src="$coordinated_repo/relay-system"
  if [ ! -d "$src" ]; then
    echo "skip (no relay-system/): $coordinated_repo"
    continue
  fi
  # Never copy from this harness's own repo into itself.
  if [ "$(cd "$coordinated_repo" >/dev/null 2>&1 && pwd)" = "$REPO_ROOT" ]; then
    echo "skip (this repo): $coordinated_repo"
    continue
  fi

  repo_name="$(basename "$coordinated_repo")"
  out_dir="$DEST/$repo_name"
  mkdir -p "$out_dir"

  n=0
  for sub in "$src"/*; do
    [ -e "$sub" ] || continue
    cp -R "$sub" "$out_dir/"
    n=$((n + 1))
  done

  echo "copied: $coordinated_repo -> $out_dir ($n item(s))"
  copied_repos=$((copied_repos + 1))
  copied_dirs=$((copied_dirs + n))
done < "$XYZ_REGISTRY"

echo "---"
echo "registered repos checked: $checked; had relay-system/: $copied_repos; items copied: $copied_dirs"
echo "dest: $DEST"
