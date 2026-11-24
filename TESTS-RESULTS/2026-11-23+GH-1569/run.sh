#!/usr/bin/env bash
# usage: run.sh SCRIPT GOALS_JSON [extra args]  — offline replay of build_queue.py --daily-goals 1568
S="$1"; G="$2"; shift 2
D="$(cd "$(dirname "$0")" && pwd)/inputs"
python3 "$S" --as-of 2026-11-20 --owner noelsaw1 --repo-slug HiQS-Labs/XYZ-forge --other-session 1400,1418 \
  --prs-json "$D/prs.json" --pr-meta-json "$D/pr-meta.json" --issues-json "$D/issues.json" \
  --daily-goals 1568 --daily-goals-json "$G" "$@"
