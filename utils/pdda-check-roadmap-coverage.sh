#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda-lib.sh
. "$HERE/pdda-lib.sh"

CHECK_NAME="pdda-check-roadmap-coverage"
EXIT_CODE=0

# Deterministic layer of the PDDA.md "ROADMAP.md contract" — the *coverage* direction. Its sibling
# pdda-check-roadmap.sh guards that execution detail does not leak INTO the roadmap; this check guards
# the inverse so the ledger can never silently fall behind the working set or the parked intake queue.
# Coverage has two floors:
#   1. every active doc in PROJECT/2-WORKING must be reflected by a pointer in ROADMAP.md
#   2. every captured GH issue doc in PROJECT/1-INBOX (GH-*.md) must be parked in ROADMAP.md's queue
# A doc is "reflected" when ROADMAP.md contains its repo-relative path — the exact form the ledger
# links and the frontmatter synthesizes/supersedes lists use. A doc that legitimately should not appear
# in the ledger opts out with `roadmap_exempt: true` in its frontmatter (mirrors the pdda_hold escape
# hatch in pdda-stale-working-docs.sh). blank.md scaffolding is already excluded by the doc lister.
PDDA_ROADMAP="${PDDA_ROADMAP:-$PDDA_REPO_ROOT/ROADMAP.md}"

if [ ! -f "$PDDA_ROADMAP" ]; then
  pdda_record_finding error "$CHECK_NAME" "$PDDA_ROADMAP" 0 \
    "ROADMAP.md not found; cannot verify working-doc coverage" "add-roadmap"
  pdda_emit_summary "$CHECK_NAME" 1
  exit "$(pdda_gated_exit 1)"
fi

while IFS= read -r file; do
  if pdda_frontmatter_true "$file" "roadmap_exempt"; then
    pdda_record_finding info "$CHECK_NAME" "$file" 1 \
      "roadmap coverage check skipped because roadmap_exempt=true" "skip"
    continue
  fi

  rel="$(pdda_relpath "$file")"
  if grep -Fq "$rel" "$PDDA_ROADMAP"; then
    continue
  fi

  pdda_record_finding error "$CHECK_NAME" "$file" 1 \
    "active working doc has no pointer in ROADMAP.md ($rel) — add a one-line ledger entry linking it, or set roadmap_exempt: true" \
    "add-roadmap-pointer"
  EXIT_CODE=1
done < <(pdda_list_working_docs)

while IFS= read -r file; do
  if pdda_frontmatter_true "$file" "roadmap_exempt"; then
    pdda_record_finding info "$CHECK_NAME" "$file" 1 \
      "roadmap coverage check skipped because roadmap_exempt=true" "skip"
    continue
  fi

  rel="$(pdda_relpath "$file")"
  if grep -Fq "$rel" "$PDDA_ROADMAP"; then
    continue
  fi

  pdda_record_finding error "$CHECK_NAME" "$file" 1 \
    "captured GH issue doc is not parked in ROADMAP.md ($rel) — add a one-line queue entry linking it, or set roadmap_exempt: true" \
    "add-roadmap-queue"
  EXIT_CODE=1
done < <(pdda_list_inbox_issue_docs)

pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
exit "$(pdda_gated_exit "$EXIT_CODE")"
