#!/usr/bin/env bash
# GH-1610 Day 2: run every wake-control.sh case against ONE checked-out revision, one log per case.
# usage: bash run-controls.sh <label: base|change> <repo-under-test-root>
# Each case builds its own disposable fixture (tick-gh1610-wake.*) under a TMPDIR this driver creates;
# only that directory is removed afterwards (never a path read from a log). Fixtures are NOT retained.
# Cases whose name ends in `-red` are controls for the ASSERTION: a wrong expectation must print FAIL.
set -u
label="${1:?label}"; repo="${2:?repo root}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$here/$label"
while IFS='|' read -r kind expect mutate; do
  [ -n "$kind" ] || continue
  case_name="${kind%-red}"; case_name="${case_name%%-mutate-*}"
  own="$(mktemp -d "${TMPDIR:-/tmp}/gh1610-case.XXXXXX")" || exit 1
  log="$here/$label/$kind.log"
  CASE="$case_name" EXPECT_SUCC="$expect" MUTATE="${mutate:-}" TMPDIR="$own" bash "$here/wake-control.sh" "$repo" > "$log" 2>&1 < /dev/null
  echo "control exit=$?" >> "$log"
  line="$(grep -E '^ASSERT' "$log" || echo "ASSERT case=$kind NOT-REPORTED")"
  case "$kind" in
    *-red) case "$line" in *FAIL*) echo "$line  [red control: assertion fired as required]" ;; *) echo "$line  [RED CONTROL DID NOT FIRE]" ;; esac ;;
    *) echo "$line" ;;
  esac
  [ -n "$own" ] && [ -d "$own" ] && rm -rf "$own"
done <<'CASES'
task-local|
hold|
shared|
refusal|
exhausted|
shared-red|1
task-local-red|0
exhausted-red|0
refusal-red|1
exhausted-mutate-history-red||history
exhausted-mutate-failed-red||failed
CASES
