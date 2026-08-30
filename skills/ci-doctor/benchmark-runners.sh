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
If --find matches more than one line in the workflow file, ALL of them are
replaced for every variant (sed has no per-line targeting here) — make --find
specific enough to hit only the line(s) you mean.

Example:
  benchmark-runners.sh --repo HiQS-Labs/XYZ-forge --workflow ci.yml --base development \
    --find 'runs-on: ubuntu-latest' \
    --variant 'github-hosted=runs-on: ubuntu-latest' \
    --variant 'starsling-4vcpu=runs-on: starsling-ubuntu-24.04' \
    --job 'portability canary (ubuntu — advisory, never breakage)'
USAGE
}

REPO="" WORKFLOW="" BASE="" FIND="" JOB="" KEEP_BRANCHES=0
declare -a LABELS=() LINES=()

need_arg() { [ "$#" -ge 2 ] || { echo "ci-doctor: '$1' needs an argument" >&2; usage >&2; exit 2; }; }

while [ $# -gt 0 ]; do
  case "$1" in
    --repo) need_arg "$@"; REPO="$2"; shift 2 ;;
    --workflow) need_arg "$@"; WORKFLOW="$2"; shift 2 ;;
    --base) need_arg "$@"; BASE="$2"; shift 2 ;;
    --find) need_arg "$@"; FIND="$2"; shift 2 ;;
    --job) need_arg "$@"; JOB="$2"; shift 2 ;;
    --keep-branches) KEEP_BRANCHES=1; shift ;;
    --variant)
      need_arg "$@"
      case "$2" in
        *=*) ;;
        *) echo "ci-doctor: --variant expects LABEL=LINE (got '$2')" >&2; exit 2 ;;
      esac
      LABELS+=("${2%%=*}"); LINES+=("${2#*=}"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ci-doctor: unknown arg '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$REPO" ] && [ -n "$WORKFLOW" ] && [ -n "$BASE" ] && [ -n "$FIND" ] && [ "${#LABELS[@]}" -ge 1 ] \
  || { usage >&2; exit 2; }

gh auth status >/dev/null 2>&1 || { echo "ci-doctor: gh not authenticated — run 'gh auth login'" >&2; exit 1; }
git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "ci-doctor: run this from inside a git clone of $REPO" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "ci-doctor: python3 is required" >&2; exit 1; }
{ git diff --quiet && git diff --cached --quiet; } \
  || { echo "ci-doctor: local clone has uncommitted changes — commit or stash first" >&2; exit 1; }

STAMP="$(date +%s)"
declare -a RESULT_LABEL=() RESULT_SEC=() RESULT_CONCLUSION=() RESULT_URL=()

# Literal (non-regex) find/replace on every occurrence in the file — sed's `s|find|repl|` would
# treat both sides as BRE/replacement syntax, silently mis-handling `[...]`, `&`, `\`, or a
# literal `|` in either string (reported in review: a `runs-on: [self-hosted, linux]`-style line
# would either not match or match wrong, and the "variant" would commit byte-identical to base —
# exactly the meaningless-number failure mode this tool exists to prevent).
literal_replace() {
  awk -v f="$1" -v r="$2" '
    { out = ""; s = $0
      while ((i = index(s, f)) > 0) { out = out substr(s, 1, i-1) r; s = substr(s, i + length(f)) }
      print out s
    }' "$3"
}

back_to_base() {
  git checkout -q "$BASE" 2>/dev/null || git checkout -q --detach "origin/$BASE"
}

for i in "${!LABELS[@]}"; do
  label="${LABELS[$i]}"; line="${LINES[$i]}"
  slug="$(echo "$label" | tr -c 'a-zA-Z0-9' '-' | tr -s '-')"
  branch="ci-doctor-bench-${slug}-${STAMP}"

  echo "== [$label] preparing $branch ==" >&2
  git fetch origin "$BASE" --quiet
  git checkout -B "$branch" "origin/$BASE" --quiet

  if ! grep -qF "$FIND" "$WORKFLOW"; then
    echo "ci-doctor: '$FIND' not found verbatim in $WORKFLOW — skipping $label" >&2
    back_to_base
    continue
  fi
  count="$(grep -cF "$FIND" "$WORKFLOW" || true)"
  [ "$count" -gt 1 ] && echo "ci-doctor: NOTE — '$FIND' appears $count times; all occurrences replaced for $label" >&2

  literal_replace "$FIND" "$line" "$WORKFLOW" > "$WORKFLOW.tmp" && mv "$WORKFLOW.tmp" "$WORKFLOW"
  if ! grep -qF "$line" "$WORKFLOW"; then
    echo "ci-doctor: substitution did not apply for $label — skipping" >&2
    back_to_base
    continue
  fi

  git add "$WORKFLOW"
  git -c user.name=ci-doctor -c user.email=ci-doctor@local commit -q -m "ci-doctor benchmark: $label"
  git push -q -u origin "$branch"

  if ! dispatch_out="$(gh workflow run "$WORKFLOW" --repo "$REPO" --ref "$branch" 2>&1)"; then
    echo "ci-doctor: dispatch failed for $label — skipping: $dispatch_out" >&2
    back_to_base
    continue
  fi
  echo "$dispatch_out" >&2

  # Poll for the workflow_dispatch run this just created on this branch. --event scopes to
  # workflow_dispatch specifically: without it, a repo whose workflow also triggers on push (and
  # whose push trigger matches this branch name) could return that push-triggered "fast lane" run
  # instead — the exact GH-161 failure mode this tool exists to prevent.
  run_id=""
  for _ in $(seq 1 15); do
    run_id="$(gh run list --repo "$REPO" --branch "$branch" --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)"
    [ -n "$run_id" ] && break
    sleep 2
  done
  if [ -z "$run_id" ]; then
    echo "ci-doctor: could not find the dispatched run for $label — skipping" >&2
    back_to_base
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
else:
    print('no job named %r on this run — available: %s' % (sys.argv[1], [j['name'] for j in d['jobs']]), file=sys.stderr)
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

  back_to_base
  if [ "$KEEP_BRANCHES" -eq 0 ]; then
    git push -q origin --delete "$branch" 2>/dev/null || true
    git branch -D "$branch" --quiet 2>/dev/null || true
  fi
done

echo
echo "== ci-doctor benchmark results =="
if [ "${#RESULT_LABEL[@]}" -eq 0 ]; then
  echo "(no variant produced a result — see the skip/warning lines above)"
else
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
fi
