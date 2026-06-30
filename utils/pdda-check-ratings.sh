#!/usr/bin/env bash
# utils/pdda-check-ratings.sh — advisory check for the optional project ratings contract.
#
# Surfaces 2-WORKING docs that are missing a complexity/risk/effort rating (or carry an
# out-of-vocabulary value), so the marathon planner (utils/marathon-plan.sh) can sequence them.
#
# This is a NUDGE, never a gate: it only ever emits `warn` findings and never sets a non-zero
# exit — even in `full` mode — exactly like pdda-check-changelog.sh. Missing ratings hold a doc
# out of automated sequencing; they do not block the doc or the build. Generated docs
# (`generated_by:` set) and explicit opt-outs (`ratings_exempt: true`) are skipped.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda-lib.sh
. "$HERE/pdda-lib.sh"

CHECK_NAME="pdda-check-ratings"
RATING_KEYS="complexity risk effort"

is_valid_rating() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    low|medium|high) return 0 ;;
    *) return 1 ;;
  esac
}

while IFS= read -r file; do
  pdda_has_frontmatter "$file" || continue
  # Skip generated docs (e.g. the QUEUE-*.md the planner writes) and explicit opt-outs.
  pdda_frontmatter_has_key "$file" "generated_by" && continue
  pdda_frontmatter_true "$file" "ratings_exempt" && continue

  for key in $RATING_KEYS; do
    if ! pdda_frontmatter_has_key "$file" "$key"; then
      pdda_record_finding warn "$CHECK_NAME" "$file" 1 \
        "missing project rating '$key' — held out of marathon-plan sequencing until rated" "add-rating-key"
      continue
    fi
    value="$(pdda_trim "$(pdda_frontmatter_value "$file" "$key")")"
    if ! is_valid_rating "$value"; then
      pdda_record_finding warn "$CHECK_NAME" "$file" 1 \
        "rating '$key' has out-of-vocabulary value '$value' (expected low|medium|high)" "fix-rating-value"
    fi
  done

  if pdda_frontmatter_true "$file" "ratings_provisional"; then
    pdda_record_finding info "$CHECK_NAME" "$file" 1 \
      "ratings are provisional (auto-seeded) — confirm and drop ratings_provisional" "confirm-ratings"
  fi
done < <(pdda_list_working_docs)

pdda_emit_summary "$CHECK_NAME" 0
# Advisory only: always a clean exit, in every mode.
exit "$(pdda_gated_exit 0)"
