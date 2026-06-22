#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda-lib.sh
. "$HERE/pdda-lib.sh"

CHECK_NAME="pdda-check-status-table"
EXIT_CODE=0
EXPECTED_HEADER="What was just completed|What's next"

while IFS= read -r file; do
  metadata="$(awk '
    /^##[[:space:]]+Status[[:space:]]*$/ { in_status = 1; next }
    in_status && /^\|/ {
      count += 1
      if (count == 1) {
        header_line = NR
        header = $0
      } else if (count == 3) {
        print header_line "\034" header "\034" NR "\034" $0
        exit
      }
    }
    in_status && /^##[[:space:]]+/ { exit }
  ' "$file")"

  if [ -z "$metadata" ]; then
    pdda_record_finding error "$CHECK_NAME" "$file" 1 "missing usable '## Status' table" "add-status-table"
    EXIT_CODE=1
    continue
  fi

  old_ifs="$IFS"
  IFS=$'\034'
  set -- $metadata
  IFS="$old_ifs"
  header_line="$1"
  header_text="$2"
  row_line="$3"
  row_text="$4"

  normalized_header="$(pdda_normalize_header "$header_text")"
  if [ "$normalized_header" != "$EXPECTED_HEADER" ]; then
    pdda_record_finding error "$CHECK_NAME" "$file" "$header_line" "status-table header must be exactly '$EXPECTED_HEADER' (got '$normalized_header')" "normalize-status-table"
    EXIT_CODE=1
  fi

  cell_output="$(pdda_table_cells "$row_text")"
  cell_one="$(printf '%s\n' "$cell_output" | sed -n '1p')"
  cell_two="$(printf '%s\n' "$cell_output" | sed -n '2p')"

  if [ -z "$cell_one" ]; then
    pdda_record_finding error "$CHECK_NAME" "$file" "$row_line" "first status cell is blank" "fill-status-table"
    EXIT_CODE=1
  fi
  if [ -z "$cell_two" ]; then
    pdda_record_finding error "$CHECK_NAME" "$file" "$row_line" "second status cell is blank" "fill-status-table"
    EXIT_CODE=1
  fi
done < <(pdda_list_working_docs)

pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
exit "$(pdda_gated_exit "$EXIT_CODE")"
