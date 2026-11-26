#!/usr/bin/env bash
# GH-1476 (holds only): drive the existing Day 1 replay (../2026-11-25+GH-1476-day1/control.txt)
# once per case against ONE disposable clone checked out at the commit under test.
# usage: bash run-cases.sh <label: base|change> <disposable-clone-root>
# Real `jog run` -> Preflight -> Marathon path; only the worker edge (relay-drive) is stubbed.
# Each case's log lands in ./<label>/<case>.log; the per-case fixture dir is deleted afterwards.
set -u
label="${1:?label}"; clone="${2:?clone root}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
control="$here/../2026-11-25+GH-1476-day1/control.txt"
mkdir -p "$here/$label"
# case | expected worker calls | expected reason prefix (0-call cases only) | jog verb (default run)
while IFS='|' read -r kind calls reason verb; do
  [ -n "$kind" ] || continue
  log="$here/$label/$kind.log"
  CASE_KIND="$kind" EXPECT_CALLS="$calls" EXPECT_REASON="$reason" JOG_VERB="${verb:-run}" \
    bash "$control" "$clone" > "$log" 2>&1 < /dev/null
  echo "control exit=$?" >> "$log"
  [ -s "$log" ] || { echo "EMPTY LOG for $kind" >&2; exit 1; }
  grep -E '^ASSERT' "$log" || echo "ASSERT case=$kind NOT-REPORTED"
  fixture="$(sed -n 's/^Fixture retained: //p' "$log" | tail -1)"
  case "$fixture" in /private/tmp/*|/tmp/*|/var/folders/*) rm -rf "$fixture" ;; esac
done <<'CASES'
ready|1|
inbox-ready|1|
dep-done|1|
issue-hold|0|hold: issue body HELD: marker
issue-label|0|hold: issue label status:held
capture-hold|0|hold: capture body HELD: marker
dep-open|0|hold: issue after #902
dep-fail|0|hold: issue after #902
issue-fail|0|hold-check-unavailable: live issue lookup failed
retry-ready|1||retry-build
retry-hold|0|hold: issue body HELD: marker|retry-build
CASES
