#!/usr/bin/env bash
# gh-prlist-wrapper.sh — a `gh` stand-in for the GH-564 review-ready scan (test seam).
#
# mock_gh_board.py speaks only `api graphql`. The review-ready scan also needs `gh pr list`, so
# this wrapper answers that one verb from a JSON fixture and execs the mock for everything else.
# Pointed at via XYZ_BOARD_SYNC_GH_BIN, exactly as the mock is.
#
#   GH549_PRLIST_JSON   file whose contents are returned verbatim for `pr list`
#   GH549_PRLIST_CALLS  every invocation's argv is appended here, one line per call, so a test
#                       can assert what --repo the scan actually passed
#   GH549_PRLIST_RC     exit code for `pr list` (default 0) — the fail-soft control
#   GH549_MOCK          path to mock_gh_board.py (default: beside this file's repo)
set -u
printf '%s\n' "$*" >> "${GH549_PRLIST_CALLS:-/dev/null}"
if [ "${1:-}" = "pr" ] && [ "${2:-}" = "list" ]; then
  rc="${GH549_PRLIST_RC:-0}"
  if [ "$rc" != "0" ]; then echo "gh-prlist-wrapper: simulated pr list failure" >&2; exit "$rc"; fi
  cat "${GH549_PRLIST_JSON:?GH549_PRLIST_JSON must name the fixture}"
  exit 0
fi
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec python3 "${GH549_MOCK:-$HERE/utils/py/mock_gh_board.py}" "$@"
