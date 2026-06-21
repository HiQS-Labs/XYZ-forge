#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda-lib.sh
. "$HERE/pdda-lib.sh"

CHECK_NAME="pdda-check-roadmap"
EXIT_CODE=0

# Deterministic layer of the PDDA.md "ROADMAP.md contract": ROADMAP.md is a pointer/ledger, not a
# plan body. This check flags ONLY unambiguous sprawl signals — task checklists and execution-detail
# headings that belong in a PROJECT/** doc, plus gross size. The fuzzy "deep execution notes that
# belong elsewhere" judgment stays with the LLM layer (pdda-doc-ready.sh ROADMAP rubric). It honors
# the contract's carve-out (a SHORT operational exception note is allowed) by never flagging prose or
# blockquotes — only checkboxes, Checklist/QA-checklist headings, and length.
PDDA_ROADMAP="${PDDA_ROADMAP:-$PDDA_REPO_ROOT/ROADMAP.md}"
ROADMAP_MAX_LINES="${PDDA_ROADMAP_MAX_LINES:-200}"
ROADMAP_MAX_HEADINGS="${PDDA_ROADMAP_MAX_HEADINGS:-25}"

if [ ! -f "$PDDA_ROADMAP" ]; then
  pdda_record_finding info "$CHECK_NAME" "$PDDA_ROADMAP" 0 "ROADMAP.md not found; nothing to check" "skip"
  pdda_emit_summary "$CHECK_NAME" 0
  exit "$(pdda_gated_exit 0)"
fi

# Scan with the same fence/blockquote exemptions as the hardcoded-paths check, so quoted terminal
# output or transcript blocks can legitimately contain checkbox- or heading-looking text.
findings="$(awk '
  /^[[:space:]]*```/ {
    if (in_fence) { in_fence=0; fexempt=0 }
    else {
      info=$0; sub(/^[[:space:]]*`+/,"",info); gsub(/[[:space:]]/,"",info); info=tolower(info)
      in_fence=1
      fexempt=(info=="console"||info=="text"||info=="transcript")?1:0
    }
    next
  }
  in_fence && fexempt { next }
  /^[[:space:]]*>/ { next }                                     # blockquote = allowed carve-out note
  # ERROR: GFM task-list item — a ledger does not carry task checkboxes
  /^[[:space:]]*[-*][[:space:]]+\[[ xX~-]\]/ { print "E\t" NR "\ttask-checklist item — phase checklists belong in a PROJECT/** doc, not ROADMAP"; next }
  # ERROR: execution-detail heading
  /^#+[[:space:]]+(Checklist|QA[[:space:]]+[Cc]hecklist)[[:space:]]*$/ { print "E\t" NR "\texecution-detail heading (\""$0"\") — move the phase/QA detail into the project doc"; next }
' "$PDDA_ROADMAP")"

while IFS=$'\t' read -r sev line msg; do
  [ -n "$sev" ] || continue
  if [ "$sev" = "E" ]; then
    pdda_record_finding error "$CHECK_NAME" "$PDDA_ROADMAP" "$line" "$msg" "move-detail-to-project-doc"
    EXIT_CODE=1
  fi
done <<EOF
$findings
EOF

# WARN: size / heading sprawl — a pointer file should stay small and flat.
line_count="$(wc -l < "$PDDA_ROADMAP" | tr -d '[:space:]')"
if [ "${line_count:-0}" -gt "$ROADMAP_MAX_LINES" ]; then
  pdda_record_finding warn "$CHECK_NAME" "$PDDA_ROADMAP" "$line_count" \
    "ROADMAP is $line_count lines (> $ROADMAP_MAX_LINES) — likely accumulating detail that belongs in PROJECT/** docs" "trim-to-pointer"
fi
heading_count="$(grep -cE '^#{2,3}[[:space:]]' "$PDDA_ROADMAP")"
if [ "${heading_count:-0}" -gt "$ROADMAP_MAX_HEADINGS" ]; then
  pdda_record_finding warn "$CHECK_NAME" "$PDDA_ROADMAP" 0 \
    "ROADMAP has $heading_count section headings (> $ROADMAP_MAX_HEADINGS) — pointer files stay flat; move sections into project docs" "trim-to-pointer"
fi

pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
exit "$(pdda_gated_exit "$EXIT_CODE")"
