#!/usr/bin/env bash
# ci-doctor: benchmark-runners.sh
#
# Dispatches one full-route CI run per named `runs-on` (or other config) variant
# and prints a wall-clock + conclusion comparison table. This is the one piece
# ci-speedup (the diagnosis half of ci-doctor) does not do: it analyzes EXISTING
# run history, it does not orchestrate NEW side-by-side comparison runs.
#
# ALWAYS forces workflow_dispatch (never relies on a push/PR event) so a repo's
# "fast lane" CI-route classification can't silently skip the real test suite
# and report a meaningless number — this bit us once by hand (GH-161).
#
# OPTIONAL enhancement, not a dependency: if you want to compare against a
# paid/managed runner vendor (e.g. StarSling's sized tiers -2/-8/-16/-32/-64,
# see docs.starsling.dev), just pass its runner label as one more --variant.
# This script has no StarSling-specific code and works identically with any
# `runs-on` value — GitHub-hosted only is a fully supported, first-class case.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: benchmark-runners.sh --repo OWNER/REPO --workflow WORKFLOW_FILE --base BASE_BRANCH \
         --find 'EXACT LINE TO REPLACE' \
         --variant 'LABEL=REPLACEMENT LINE' [--variant 'LABEL=REPLACEMENT LINE' ...] \
         [--job 'JOB DISPLAY NAME'] [--keep-branches]

Run from inside the target repo's local clone (plain git — no API workarounds).

Example:
  benchmark-runners.sh --repo HiQS-Suite/XYZ-forge --workflow ci.yml --base development \
    --find 'runs-on: ubuntu-latest' \
    --variant 'github-hosted=runs-on: ubuntu-latest' \
    --variant 'starsling-4vcpu=runs-on: starsling-ubuntu-24.04' \
    --job 'portability canary (ubuntu — advisory, never breakage)'
USAGE
}

REPO="" WORKFLOW="" BASE="" FIND="" JOB="" KEEP_BRANCHES=0
declare -a LABELS=() LINES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --workflow) WORKFLOW="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --find) FIND="$2"; shift 2 ;;
    --job) JOB="$2"; shift 2 ;;
    --keep-branches) KEEP_BRANCHES=1; shift ;;
    --variant) LABELS+=("${2%%=*}"); LINES+=("${2#*=}"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ci-doctor: unknown arg '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$REPO" ] && [ -n "$WORKFLOW" ] && [ -n "$BASE" ] && [ -n "$FIND" ] && [ "${#LABELS[@]}" -ge 1 ] \
  || { usage >&2; exit 2; }

gh auth status >/dev/null 2>&1 || { echo "ci-doctor: gh not authenticated — run 'gh auth login'" >&2; exit 1; }
git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "ci-doctor: run this from inside a git clone of $REPO" >&2; exit 1; }

STAMP="$(date +%s)"
declare -a RESULT_LABEL=() RESULT_SEC=() RESULT_CONCLUSION=() RESULT_URL=()

for i in "${!LABELS[@]}"; do
  label="${LABELS[$i]}"; line="${LINES[$i]}"
  slug="$(echo "$label" | tr -c 'a-zA-Z0-9' '-' | tr -s '-')"
  branch="ci-doctor-bench-${slug}-${STAMP}"

  echo "== [$label] preparing $branch ==" >&2
  git fetch origin "$BASE" --quiet
  git checkout -B "$branch" "origin/$BASE" --quiet

  if ! grep -qF "$FIND" "$WORKFLOW"; then
    echo "ci-doctor: '$FIND' not found verbatim in $WORKFLOW — skipping $label" >&2
    git checkout "$BASE" --quiet
    continue
  fi
  # Escape sed delimiter collisions by using a rare separator.
  sed -i.bak "s|$FIND|$line|" "$WORKFLOW" && rm -f "$WORKFLOW.bak"
  git add "$WORKFLOW"
  git commit -q -m "ci-doctor benchmark: $label"
  git push -q -u origin "$branch"

  dispatch_out="$(gh workflow run "$WORKFLOW" --repo "$REPO" --ref "$branch" 2>&1)"
  echo "$dispatch_out" >&2

  # Poll briefly for the run GitHub just created on this branch.
  run_id=""
  for _ in $(seq 1 15); do
    run_id="$(gh run list --repo "$REPO" --branch "$branch" --limit 1 --json databaseId,status --jq '.[0].databaseId' 2>/dev/null || true)"
    [ -n "$run_id" ] && break
    sleep 2
  done
  if [ -z "$run_id" ]; then
    echo "ci-doctor: could not find the dispatched run for $label — skipping" >&2
    git checkout "$BASE" --quiet
    continue
  fi

  echo "-> watching run $run_id ..." >&2
  gh run watch "$run_id" --repo "$REPO" --exit-status >/dev/null 2>&1 || true

  run_json="$(gh run view "$run_id" --repo "$REPO" --json conclusion,jobs)"
  if [ -n "$JOB" ]; then
    times="$(echo "$run_json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for j in d['jobs']:
    if j['name'] == sys.argv[1]:
        print(j['startedAt']); print(j['completedAt']); print(j['conclusion'])
        break
" "$JOB")"
  else
    times="$(echo "$run_json" | python3 -c "
import json, sys
d = json.load(sys.stdin)
starts = [j['startedAt'] for j in d['jobs'] if j.get('startedAt')]
ends = [j['completedAt'] for j in d['jobs'] if j.get('completedAt')]
print(min(starts) if starts else '')
print(max(ends) if ends else '')
print(d.get('conclusion',''))
")"
  fi

  start_ts="$(echo "$times" | sed -n '1p')"
  end_ts="$(echo "$times" | sed -n '2p')"
  conclusion="$(echo "$times" | sed -n '3p')"

  secs="?"
  if [ -n "$start_ts" ] && [ -n "$end_ts" ]; then
    secs="$(python3 -c "
from datetime import datetime
a = datetime.strptime('$start_ts', '%Y-%m-%dT%H:%M:%SZ')
b = datetime.strptime('$end_ts', '%Y-%m-%dT%H:%M:%SZ')
print(int((b - a).total_seconds()))
" 2>/dev/null || echo "?")"
  fi

  RESULT_LABEL+=("$label")
  RESULT_SEC+=("$secs")
  RESULT_CONCLUSION+=("$conclusion")
  RESULT_URL+=("https://github.com/$REPO/actions/runs/$run_id")

  git checkout "$BASE" --quiet
  if [ "$KEEP_BRANCHES" -eq 0 ]; then
    git push -q origin --delete "$branch" 2>/dev/null || true
    git branch -D "$branch" --quiet 2>/dev/null || true
  fi
done

echo
echo "== ci-doctor benchmark results =="
printf '%-24s %10s %-12s %s\n' "VARIANT" "WALL-CLOCK" "CONCLUSION" "RUN"
for i in "${!RESULT_LABEL[@]}"; do
  sec="${RESULT_SEC[$i]}"
  if [ "$sec" != "?" ]; then
    fmt="$(printf '%dm%02ds' $((sec / 60)) $((sec % 60)))"
  else
    fmt="?"
  fi
  printf '%-24s %10s %-12s %s\n' "${RESULT_LABEL[$i]}" "$fmt" "${RESULT_CONCLUSION[$i]}" "${RESULT_URL[$i]}"
done
