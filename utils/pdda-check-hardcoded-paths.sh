#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda-lib.sh
. "$HERE/pdda-lib.sh"

CHECK_NAME="pdda-check-hardcoded-paths"
EXIT_CODE=0

while IFS= read -r file; do
  matches="$(awk '
    # PDDA.md exempts only "quoted terminal output / explicitly marked transcript blocks" — so suppress
    # ONLY fences whose info-string is console/text/transcript, or a fence right after a
    # <!-- pdda:allow-paths --> marker. Ordinary code fences ARE scanned (paths must not hide in them).
    /^[[:space:]]*<!--[[:space:]]*pdda:allow-paths[[:space:]]*-->/ { allow_next = 1; next }
    /^```/ {
      if (in_fence) { in_fence = 0; fence_exempt = 0 }
      else {
        info = $0; sub(/^`+/, "", info); gsub(/[[:space:]]/, "", info); info = tolower(info)
        in_fence = 1
        fence_exempt = (allow_next || info == "console" || info == "text" || info == "transcript") ? 1 : 0
        allow_next = 0
      }
      next
    }
    in_fence && fence_exempt { next }
    /^[[:space:]]*>/ { next }
    /\/Users\// { print NR "\t/Users/"; next }
    /\/private\// { print NR "\t/private/"; next }
    /(^|[^[:alnum:]_])\/tmp\// { print NR "\t/tmp/"; next }
    /file:\/\// { print NR "\tfile://"; next }
    /(^|[^[:alnum:]_])[A-Za-z]:[\/\\]/ { print NR "\tdrive-letter path"; next }
  ' "$file")"
  awk_status=$?
  if [ "$awk_status" -ne 0 ]; then
    pdda_record_finding error "$CHECK_NAME" "$file" 1 "hardcoded-path scan failed" "fix-script"
    EXIT_CODE=1
    continue
  fi

  while IFS=$'\t' read -r line_number reason; do
    [ -n "$line_number" ] || continue
    pdda_record_finding error "$CHECK_NAME" "$file" "$line_number" "hardcoded path detected ($reason)" "replace-with-repo-relative-path"
    EXIT_CODE=1
  done <<EOF
$matches
EOF
done < <(pdda_list_working_docs)

pdda_emit_summary "$CHECK_NAME" "$EXIT_CODE"
exit "$(pdda_gated_exit "$EXIT_CODE")"
