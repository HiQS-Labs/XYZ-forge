#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda-lib.sh
. "$HERE/pdda-lib.sh"

CHECK_NAME="pdda-check-frontmatter"
EXIT_CODE=0
REQUIRED_KEYS="title status created updated owner goal"

while IFS= read -r file; do
  if ! pdda_has_frontmatter "$file"; then
    pdda_record_finding error "$CHECK_NAME" "$file" 1 "missing YAML frontmatter" "add-frontmatter"
    EXIT_CODE=1
    continue
  fi

  for key in $REQUIRED_KEYS; do
    if ! pdda_frontmatter_has_key "$file" "$key"; then
      pdda_record_finding error "$CHECK_NAME" "$file" 1 "missing required frontmatter key '$key'" "add-frontmatter-key"
      EXIT_CODE=1
      continue
    fi

    value="$(pdda_frontmatter_value "$file" "$key")"
    if [ -z "$(pdda_trim "$value")" ]; then
      pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter key '$key' is empty" "fill-frontmatter-key"
      EXIT_CODE=1
    fi
  done

  for date_key in created updated; do
    if pdda_frontmatter_has_key "$file" "$date_key"; then
      value="$(pdda_trim "$(pdda_frontmatter_value "$file" "$date_key")")"
      # tolerate YAML-quoted dates, e.g. created: "2026-06-15" or '2026-06-15'
      case "$value" in
        \"*\") value="${value#\"}"; value="${value%\"}" ;;
        \'*\') value="${value#\'}"; value="${value%\'}" ;;
      esac
      if ! printf '%s' "$value" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
        pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter key '$date_key' must use YYYY-MM-DD" "fix-date-format"
        EXIT_CODE=1
      elif ! pdda_is_real_date "$value"; then
        pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter key '$date_key' is not a real calendar date ($value)" "fix-date-value"
        EXIT_CODE=1
      fi
    fi
  done
done < <(pdda_list_working_docs)

pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
exit "$(pdda_gated_exit "$EXIT_CODE")"
