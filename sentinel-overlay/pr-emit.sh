#!/usr/bin/env bash
# pr-emit.sh — §2.5. After a marathon phase is approved + gate-green, (gated) push the branch and
# open a PR into development, then move the capture doc to 3-COMPLETED. Inert by default: with no
# runtime.env it emits nothing (no push, no PR) and leaves the tree untouched.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/lib/config.sh"; . "$HERE/lib/gh.sh"

DOC="" BRANCH="" BASE="${SENTINEL_PR_BASE:-development}"
while [ $# -gt 0 ]; do case "$1" in
  --doc) DOC="${2:-}"; shift 2;;
  --branch) BRANCH="${2:-}"; shift 2;;
  --base) BASE="${2:-}"; shift 2;;
  -h|--help) echo "usage: pr-emit.sh --doc PATH --branch NAME [--base development]"; exit 0;;
  *) echo "pr-emit: unexpected arg: $1" >&2; exit 2;;
esac; done
[ -n "$BRANCH" ] || { echo "pr-emit: --branch required" >&2; exit 2; }

if ! sentinel_active; then
  echo "pr-emit: inert (no runtime.env / SENTINEL_ENABLE!=1) — no push, no PR (call-home off)" >&2
  exit 0
fi

# Gated network egress — the only sanctioned push/PR path.
sentinel_git_push -u origin "$BRANCH" || { echo "pr-emit: push failed" >&2; exit 1; }
title="Sentinel: $(basename "${DOC:-$BRANCH}" .md)"
sentinel_gh pr create --base "$BASE" --head "$BRANCH" --title "$title" \
  ${DOC:+--body-file "$DOC"} || { echo "pr-emit: PR creation failed" >&2; exit 1; }

# Local bookkeeping (no egress): move the doc to 3-COMPLETED once the PR is up.
if [ -n "$DOC" ] && [ -f "$DOC" ]; then
  mkdir -p PROJECT/3-COMPLETED
  git mv "$DOC" "PROJECT/3-COMPLETED/$(basename "$DOC")" 2>/dev/null || mv "$DOC" "PROJECT/3-COMPLETED/$(basename "$DOC")"
  echo "pr-emit: moved $(basename "$DOC") → 3-COMPLETED (add a ## Lessons Learned before completion)"
fi
