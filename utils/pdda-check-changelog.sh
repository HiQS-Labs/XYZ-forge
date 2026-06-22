#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda-lib.sh
. "$HERE/pdda-lib.sh"

CHECK_NAME="pdda-check-changelog"
EXIT_CODE=0

# PDDA treats CHANGELOG.md as a FIRST-CLASS, end-of-iteration record (it replaced RECAP.md as the
# running provenance log). This check is a WARN-ONLY nudge: it never sets an error, so it never blocks
# a build — even in `full` mode. It only flags when CHANGELOG.md looks like it missed the latest
# iteration: its newest dated entry predates the latest git commit by more than
# PDDA_CHANGELOG_STALE_DAYS days. Whether an entry is actually *substantive* stays a human/LLM call.
PDDA_CHANGELOG="${PDDA_CHANGELOG:-$PDDA_REPO_ROOT/CHANGELOG.md}"
PDDA_CHANGELOG_STALE_DAYS="${PDDA_CHANGELOG_STALE_DAYS:-0}"

# YYYY-MM-DD -> epoch seconds (portable BSD/GNU); prints nothing on parse failure.
_cl_epoch() {
  local d="$1"
  if date -j -f "%Y-%m-%d" "2000-01-01" "+%s" >/dev/null 2>&1; then
    date -j -f "%Y-%m-%d" "$d" "+%s" 2>/dev/null
  else
    date -d "$d" "+%s" 2>/dev/null
  fi
}

if [ ! -f "$PDDA_CHANGELOG" ]; then
  pdda_record_finding warn "$CHECK_NAME" "$PDDA_CHANGELOG" 0 \
    "CHANGELOG.md not found — PDDA expects a first-class end-of-iteration changelog" "create-changelog"
  pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
  exit "$(pdda_gated_exit "$EXIT_CODE")"
fi

# Newest dated section heading (file is newest-first): first "## YYYY-MM-DD".
cl_line="$(grep -Em1 '^##[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}' "$PDDA_CHANGELOG" 2>/dev/null || true)"
cl_date="$(printf '%s' "$cl_line" | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"

if [ -z "$cl_date" ] || ! pdda_is_real_date "$cl_date"; then
  pdda_record_finding warn "$CHECK_NAME" "$PDDA_CHANGELOG" 1 \
    "no dated '## YYYY-MM-DD' entry at the top of CHANGELOG.md — add an end-of-iteration entry" "add-dated-entry"
  pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
  exit "$(pdda_gated_exit "$EXIT_CODE")"
fi

# Latest commit date (HEAD). No git history -> skip the freshness compare (info, not warn).
commit_date="$(git -C "$PDDA_REPO_ROOT" log -1 --format=%cd --date=short 2>/dev/null || true)"
if [ -z "$commit_date" ] || ! pdda_is_real_date "$commit_date"; then
  pdda_record_finding info "$CHECK_NAME" "$PDDA_CHANGELOG" 0 \
    "no git history to compare against; freshness not evaluated (newest entry $cl_date)" "skip"
  pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
  exit "$(pdda_gated_exit "$EXIT_CODE")"
fi

cl_epoch="$(_cl_epoch "$cl_date")"
commit_epoch="$(_cl_epoch "$commit_date")"
if [ -n "$cl_epoch" ] && [ -n "$commit_epoch" ] && [ "$commit_epoch" -gt "$cl_epoch" ]; then
  gap_days=$(( (commit_epoch - cl_epoch) / 86400 ))
  if [ "$gap_days" -gt "$PDDA_CHANGELOG_STALE_DAYS" ]; then
    pdda_record_finding warn "$CHECK_NAME" "$PDDA_CHANGELOG" 1 \
      "CHANGELOG newest entry ($cl_date) predates the latest commit ($commit_date) by $gap_days day(s) — add an end-of-iteration entry" "update-changelog"
  fi
fi

pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
exit "$(pdda_gated_exit "$EXIT_CODE")"
