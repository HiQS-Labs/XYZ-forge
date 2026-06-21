#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda-lib.sh
. "$HERE/pdda-lib.sh"

CHECK_NAME="pdda-stale-working-docs"
EXIT_CODE=0
NOW_EPOCH="$(date +%s)"
STALE_SECONDS=$((PDDA_STALE_DAYS * 86400))

build_target_path() {
  local source_file="$1"
  local base_name
  local target
  local stem
  local ext
  local suffix

  base_name="$(basename "$source_file")"
  target="$PDDA_MISC_DIR/$base_name"
  if [ ! -e "$target" ]; then
    printf '%s\n' "$target"
    return
  fi

  stem="${base_name%.*}"
  ext=""
  if [ "$stem" != "$base_name" ]; then
    ext=".${base_name##*.}"
  else
    stem="$base_name"
  fi
  suffix="$(date +"%Y%m%d-%H%M%S")"
  printf '%s/%s-stale-%s%s\n' "$PDDA_MISC_DIR" "$stem" "$suffix" "$ext"
}

while IFS= read -r file; do
  if pdda_frontmatter_true "$file" "pdda_hold"; then
    pdda_record_finding info "$CHECK_NAME" "$file" 1 "stale auto-move skipped because pdda_hold=true" "skip"
    continue
  fi

  mtime_epoch="$(pdda_file_mtime_epoch "$file")"
  age_seconds=$((NOW_EPOCH - mtime_epoch))
  if [ "$age_seconds" -lt "$STALE_SECONDS" ]; then
    continue
  fi

  target_path="$(build_target_path "$file")"
  age_days=$((age_seconds / 86400))
  if [ "$PDDA_DRY_RUN" = "1" ]; then
    pdda_record_finding warn "$CHECK_NAME" "$file" 1 "dry-run: would move stale doc (${age_days}d old) to $(pdda_relpath "$target_path")" "flagged"
    continue
  fi

  mkdir -p "$PDDA_MISC_DIR"
  if mv "$file" "$target_path"; then
    pdda_record_finding info "$CHECK_NAME" "$target_path" 1 "moved stale doc immediately (${age_days}d old) from $(pdda_relpath "$file")" "moved"
  else
    pdda_record_finding error "$CHECK_NAME" "$file" 1 "failed to move stale doc to $(pdda_relpath "$target_path")" "move-failed"
    EXIT_CODE=1
  fi
done < <(pdda_list_working_docs)

pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
exit "$(pdda_gated_exit "$EXIT_CODE")"
