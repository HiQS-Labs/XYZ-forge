#!/usr/bin/env bash
# GH-1476 (holds only): drive the existing Day 1 replay (../2026-11-25+GH-1476-day1/control.txt)
# once per case against ONE disposable clone checked out at the commit under test.
# usage: bash run-cases.sh <label: base|change> <disposable-clone-root>
# Real `jog run` / `jog retry-build` -> Preflight -> Marathon path; only the worker edge
# (relay-drive) is stubbed. Each case's log lands in ./<label>/<name>.log.
# Each case runs with a TMPDIR this driver created; only that directory is removed afterwards
# (never a path read from a log).
set -u
label="${1:?label}"; clone="${2:?clone root}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
control="$here/../2026-11-25+GH-1476-day1/control.txt"
mkdir -p "$here/$label"
# case | expected worker calls | expected reason prefix (0-call cases) | jog verb (default run) | MUTATE
# MUTATE rows are red controls for the assertions themselves: their ASSERT line MUST say FAIL.
while IFS='|' read -r kind calls reason verb mutate; do
  [ -n "$kind" ] || continue
  name="$kind${verb:+-$verb}${mutate:+-mutate-$mutate}"
  log="$here/$label/$name.log"
  own="$(mktemp -d "${TMPDIR:-/tmp}/gh1476-case.XXXXXX")" || exit 1
  CASE_KIND="$kind" EXPECT_CALLS="$calls" EXPECT_REASON="$reason" JOG_VERB="${verb:-run}" MUTATE="$mutate" TMPDIR="$own" \
    bash "$control" "$clone" > "$log" 2>&1 < /dev/null
  echo "control exit=$?" >> "$log"
  [ -s "$log" ] || { echo "EMPTY LOG for $name" >&2; exit 1; }
  line="$(grep -E '^ASSERT' "$log" || echo "ASSERT case=$name NOT-REPORTED")"
  if [ -n "$mutate" ]; then
    case "$line" in *FAIL*) echo "$line  [red control: assertion fired as required]" ;; *) echo "$line  [RED CONTROL DID NOT FIRE]" ;; esac
  else
    echo "$line"
  fi
  [ -n "$own" ] && [ -d "$own" ] && rm -rf "$own"
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
issue-malformed|0|hold-check-unavailable: live issue response incomplete
issue-badlabels|0|hold-check-unavailable: hold rules failed
ambiguous|0|hold-check-unavailable: ambiguous capture documents
retry-ready|1||retry-build
retry-hold|0|hold: issue body HELD: marker|retry-build
ambiguous|0|hold-check-unavailable: ambiguous capture documents|retry-build
capture-hold|0|hold: capture body HELD: marker||native
issue-hold|0|hold: issue body HELD: marker||capture
CASES
