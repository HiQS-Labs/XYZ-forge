#!/usr/bin/env bash
# sentinel-network-guard.sh — fail loud when bundled Sentinel scripts contain network primitives.
# With explicit arguments, scans those files/directories; otherwise scans the Tier-1 capture scripts.
set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$SCRIPT_NAME"
readonly RELAY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly NETWORK_PATTERN='curl|wget|nc[[:space:]]|gh[[:space:]]|/dev/tcp|http'

DEFAULT_SCAN_PATHS=(
  "$RELAY_DIR/harvest-findings.sh"
  "$RELAY_DIR/finding-new.sh"
)

if [[ "$#" -gt 0 ]]; then
  SCAN_PATHS=("$@")
else
  SCAN_PATHS=("${DEFAULT_SCAN_PATHS[@]}")
fi

FINDINGS=0

scan_file() {
  local file="$1" hits="" rc=0
  [[ "$file" == "$SCRIPT_PATH" || "$file" == */sentinel-overlay/* ]] && return 0

  hits="$(grep -nE -e "$NETWORK_PATTERN" "$file" 2>/dev/null)" || rc=$?
  if [[ "$rc" -gt 1 ]]; then
    echo "SENTINEL NETWORK: $file: scan error (grep exit $rc)" >&2
    FINDINGS=$((FINDINGS + 1))
    return 0
  fi
  [[ -z "$hits" ]] && return 0

  while IFS= read -r hit; do
    echo "SENTINEL NETWORK: $file:$hit" >&2
    FINDINGS=$((FINDINGS + 1))
  done <<< "$hits"
}

for path in "${SCAN_PATHS[@]}"; do
  if [[ -f "$path" ]]; then
    scan_file "$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
  elif [[ -d "$path" ]]; then
    while IFS= read -r file; do
      scan_file "$file"
    done < <(find "$path" -type f -name '*.sh' ! -path '*/sentinel-overlay/*' | sort)
  else
    echo "SENTINEL NETWORK: path not found: $path" >&2
    FINDINGS=$((FINDINGS + 1))
  fi
done

if [[ "$FINDINGS" -gt 0 ]]; then
  echo "$SCRIPT_NAME: $FINDINGS network finding(s) detected" >&2
  exit 1
fi

exit 0
