#!/usr/bin/env bash
# adversarial-review.sh — §2.6. Gemma post-PR red-team: feed a PR's diff to the local model with an
# attack framing and (gated) post the critique as a PR comment. Inert by default: with no runtime.env
# and no stub, this is a no-op (no diff fetch, no model call, no comment).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$HERE/lib/config.sh"; . "$HERE/lib/classify.sh"; . "$HERE/lib/gh.sh"

PR="" DIFF_FILE=""
while [ $# -gt 0 ]; do case "$1" in
  --pr) PR="${2:-}"; shift 2;;
  --diff-file) DIFF_FILE="${2:-}"; shift 2;;   # test/offline seam: review a local diff
  -h|--help) echo "usage: adversarial-review.sh --pr N | --diff-file FILE"; exit 0;;
  *) echo "adversarial-review: unexpected arg: $1" >&2; exit 2;;
esac; done

if ! sentinel_active && [ -z "${SENTINEL_REDTEAM_STUB:-}" ]; then
  echo "adversarial-review: inert (no runtime.env / SENTINEL_ENABLE!=1) — no red-team (call-home off)" >&2
  exit 0
fi

# Obtain the change under review: a local diff file (offline) or the PR diff (gated gh).
diff=""
if [ -n "$DIFF_FILE" ] && [ -f "$DIFF_FILE" ]; then
  diff="$(cat "$DIFF_FILE")"
elif [ -n "$PR" ]; then
  diff="$(sentinel_gh pr diff "$PR" 2>/dev/null || true)"
fi
[ -n "$diff" ] || { echo "adversarial-review: no diff to review" >&2; exit 0; }

critique="$(sentinel_redteam "$diff" || true)"
[ -n "$critique" ] || { echo "adversarial-review: model returned nothing" >&2; exit 0; }

if [ -n "$PR" ]; then
  printf 'Sentinel adversarial red-team (local Gemma):\n\n%s\n' "$critique" \
    | sentinel_gh pr comment "$PR" --body-file - >/dev/null 2>&1 \
    || echo "adversarial-review: (GitHub comment skipped/inert)"
else
  printf '%s\n' "$critique"
fi
