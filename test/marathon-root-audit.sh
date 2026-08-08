#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

# GH-401: this audit exists for GH-209 — "every test invocation of the marathon driver is
# MARATHON_ROOT-scoped" — but its scope was two hardcoded filenames. An unscoped `--dry-run`
# invocation in test/gh268-relay-cue-and-target-checks.sh therefore wrote phases/p1/RELAY.md into
# the HARNESS repo on every `bash validate.sh`, and the audit reported PASS the whole time: it was
# out of reach because of its FILENAME, not because it was safe. A guard whose coverage is a literal
# list silently stops covering the thing it was written for the moment someone adds a file.
#
# Audit every test script instead, and let discover_file_metadata/find_invocation_target decide what
# is actually an invocation — a file with none is simply skipped. The audit excludes only itself:
# it necessarily contains the driver path literals it matches on, so it would self-report.
FILES=()
for candidate in "$HERE"/*.sh; do
  [ "$candidate" = "${BASH_SOURCE[0]}" ] && continue
  [ "$(basename "$candidate")" = "$(basename "${BASH_SOURCE[0]}")" ] && continue
  FILES+=("$candidate")
done

safe_vars=()
alias_names=()
alias_targets=()
failures=0
checked=0

add_safe_var() {
  local candidate="$1"
  local existing
  for existing in "${safe_vars[@]}"; do
    [ "$existing" = "$candidate" ] && return 0
  done
  safe_vars+=("$candidate")
}

reset_safe_vars() {
  safe_vars=(A B)
}

is_safe_var() {
  local candidate="$1"
  local existing
  for existing in "${safe_vars[@]}"; do
    [ "$existing" = "$candidate" ] && return 0
  done
  return 1
}

reset_aliases() {
  alias_names=()
  alias_targets=()
}

set_alias() {
  local name="$1"
  local target="$2"
  local i
  for ((i = 0; i < ${#alias_names[@]}; i++)); do
    if [ "${alias_names[$i]}" = "$name" ]; then
      alias_targets[$i]="$target"
      return 0
    fi
  done
  alias_names+=("$name")
  alias_targets+=("$target")
}

get_alias_target() {
  local name="$1"
  local i
  for ((i = 0; i < ${#alias_names[@]}; i++)); do
    if [ "${alias_names[$i]}" = "$name" ]; then
      printf '%s\n' "${alias_targets[$i]}"
      return 0
    fi
  done
  return 1
}

line_has_safe_cwd() {
  local line="$1"
  local candidate
  if [[ "$line" =~ cd[[:space:]]+\"\$([A-Z][A-Z0-9_]*)\" ]]; then
    candidate="${BASH_REMATCH[1]}"
    is_safe_var "$candidate"
    return $?
  fi
  return 1
}

discover_file_metadata() {
  local file="$1"
  local line name target

  reset_safe_vars
  reset_aliases

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^([A-Z][A-Z0-9_]*)=\"\$WORK/ ]]; then
      add_safe_var "${BASH_REMATCH[1]}"
    fi

    if [[ "$line" =~ ^([A-Z][A-Z0-9_]*)=.*relay-automation/(marathon|marathon-drive)\.sh ]]; then
      name="${BASH_REMATCH[1]}"
      target="${BASH_REMATCH[2]}"
      set_alias "$name" "$target"
    fi
  done < "$file"
}

find_invocation_target() {
  local line="$1"
  local rest var target

  if [[ "$line" == *'./.xyz/relay-automation/marathon-drive.sh'* ]]; then
    printf '%s\n' "marathon-drive"
    return 0
  fi

  if [[ "$line" == *'./.xyz/relay-automation/marathon.sh'* ]]; then
    printf '%s\n' "marathon"
    return 0
  fi

  rest="${line#*bash \"\$}"
  if [ "$rest" != "$line" ]; then
    var="${rest%%\"*}"
    target="$(get_alias_target "$var" || true)"
    if [ -n "$target" ]; then
      printf '%s\n' "$target"
      return 0
    fi
  fi

  return 1
}

check_invocation_safety() {
  local idx="$1"
  shift
  local -a lines=("$@")
  local start j boundary_found=0
  local line="${lines[$idx]}"

  if [[ "$line" == *'MARATHON_ROOT='* ]]; then
    return 0
  fi

  if line_has_safe_cwd "$line"; then
    return 0
  fi

  for ((j = idx - 1; j >= 0; j--)); do
    if [[ "${lines[$j]}" == *'MARATHON_ROOT='* ]]; then
      return 0
    fi
    if line_has_safe_cwd "${lines[$j]}"; then
      return 0
    fi
    [[ "${lines[$j]}" =~ \\[[:space:]]*$ ]] || break
  done

  start=$((idx > 40 ? idx - 40 : 0))
  for ((j = idx - 1; j >= start; j--)); do
    if [[ "${lines[$j]}" =~ ^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]*\(\)[[:space:]]*\{ ]]; then
      start="$j"
      boundary_found=1
      break
    fi
    if [[ "${lines[$j]}" =~ ^[[:space:]]*\([[:space:]]*$ ]]; then
      start="$j"
      boundary_found=1
      break
    fi
  done

  [ "$boundary_found" -eq 1 ] || return 1

  for ((j = start; j < idx; j++)); do
    if [[ "${lines[$j]}" == *'MARATHON_ROOT='* ]]; then
      return 0
    fi
    if line_has_safe_cwd "${lines[$j]}"; then
      return 0
    fi
  done

  return 1
}

audit_file() {
  local file="$1"
  local -a lines=()
  local line target idx

  discover_file_metadata "$file"

  while IFS= read -r line || [ -n "$line" ]; do
    lines+=("$line")
  done < "$file"

  for ((idx = 0; idx < ${#lines[@]}; idx++)); do
    target="$(find_invocation_target "${lines[$idx]}" || true)"
    [ -z "$target" ] && continue
    checked=$((checked + 1))
    if check_invocation_safety "$idx" "${lines[@]}"; then
      printf 'PASS: %s:%d %s invocation is rooted or fixture-local\n' \
        "${file#$HERE/}" "$((idx + 1))" "$target"
    else
      printf 'FAIL: %s:%d %s invocation lacks MARATHON_ROOT and fixture-local cwd\n' \
        "${file#$HERE/}" "$((idx + 1))" "$target" >&2
      failures=$((failures + 1))
    fi
  done
}

for file in "${FILES[@]}"; do
  audit_file "$file"
done

if [ "$checked" -eq 0 ]; then
  echo "FAIL: no real marathon script invocations found to audit" >&2
  exit 1
fi

if [ "$failures" -ne 0 ]; then
  echo "FAIL: $failures unsafe marathon invocation(s) found" >&2
  exit 1
fi

echo "PASS: audited $checked real marathon invocation(s)"
