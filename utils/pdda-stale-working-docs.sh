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
    pdda_record_finding info "$CHECK_NAME" "$file" 1 "stale flag skipped because pdda_hold=true" "skip"
    continue
  fi

  mtime_epoch="$(pdda_file_mtime_epoch "$file")"
  age_seconds=$((NOW_EPOCH - mtime_epoch))
  if [ "$age_seconds" -lt "$STALE_SECONDS" ]; then
    continue
  fi

  target_path="$(build_target_path "$file")"
  age_days=$((age_seconds / 86400))
  # ponytail: flag-only by design. The auto-move was this repo's ONLY destructive mechanic and never
  # once fired a real move (zero "moved" actions in PDDA-ACTIVITY.jsonl) — the value is the flag, not
  # the mv. A human runs one reversible `git mv` on a flagged doc. Re-add an opt-in move behind
  # pdda_hold + full mode ONLY if it ever earns the miles. Warn-max, so this check never blocks a build.
  pdda_record_finding warn "$CHECK_NAME" "$file" 1 "stale (${age_days}d old) — recommend: git mv $(pdda_relpath "$file") $(pdda_relpath "$target_path")" "flagged"
done < <(pdda_list_working_docs)

pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
exit "$(pdda_gated_exit "$EXIT_CODE")"
