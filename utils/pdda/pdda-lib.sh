#!/usr/bin/env bash
set -u

PDDA_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Runtime lives in <repo>/utils/pdda/, so the repo root is two levels up from the lib dir.
PDDA_REPO_ROOT="${PDDA_REPO_ROOT:-$(cd "$PDDA_LIB_DIR/../.." && pwd)}"
PDDA_INBOX_DIR="${PDDA_INBOX_DIR:-$PDDA_REPO_ROOT/PROJECT/1-INBOX}"
PDDA_WORKING_DIR="${PDDA_WORKING_DIR:-$PDDA_REPO_ROOT/PROJECT/2-WORKING}"
PDDA_COMPLETED_DIR="${PDDA_COMPLETED_DIR:-$PDDA_REPO_ROOT/PROJECT/3-COMPLETED}"
PDDA_MISC_DIR="${PDDA_MISC_DIR:-$PDDA_REPO_ROOT/PROJECT/4-MISC}"
PDDA_ACTIVITY_LOG="${PDDA_ACTIVITY_LOG:-$PDDA_REPO_ROOT/PROJECT/PDDA-ACTIVITY.jsonl}"
# Cached GitHub issue-state file (TSV: "<number>\t<STATE>", '#'-comment lines ignored). Written by
# pdda-gh-refresh.sh; read by `pdda.sh issue-doc-sync` when gh is absent/offline. Gitignored runtime
# state, regenerated on demand — sits beside .pdda-mode at the repo root by default.
PDDA_GH_STATE_CACHE="${PDDA_GH_STATE_CACHE:-$PDDA_REPO_ROOT/.pdda-gh-state.tsv}"
PDDA_STALE_DAYS="${PDDA_STALE_DAYS:-4}"
PDDA_DRY_RUN="${PDDA_DRY_RUN:-0}"
# Output format for findings on stdout: "text" (human, default) or "json" (one JSON object per line,
# the same machine-readable shape as the activity log) — satisfies PDDA.md's composable output contract.
PDDA_FORMAT="${PDDA_FORMAT:-text}"
# Activity-log rotation ceiling (lines); pdda_rotate_activity trims to the last N. 0 = never rotate.
PDDA_ACTIVITY_MAX_LINES="${PDDA_ACTIVITY_MAX_LINES:-10000}"

# --- Enforcement mode (observe | light | full) -------------------------------------------------
# PDDA's adoption ramp (see PDDA.md "Enforcement modes"). Resolution order:
#   env PDDA_MODE  ->  first non-comment line of <repo>/.pdda-mode  ->  default "observe".
# Default is "observe" so a freshly-installed PDDA is non-destructive (sees everything, changes
# nothing, never fails a build); a project graduates to "light" then "full" deliberately.
#   observe : report findings only; every check/the suite exits 0.
#   light   : report findings (incl. stale-doc flags); still exit 0 (warn, don't block the build).
#   full    : report + exit non-zero on errors (strict; fully on rails).
pdda_resolve_mode() {
  local m="${PDDA_MODE:-}"
  if [ -z "$m" ] && [ -f "$PDDA_REPO_ROOT/.pdda-mode" ]; then
    m="$(awk 'NF && $0 !~ /^[[:space:]]*#/ { gsub(/[[:space:]]/,""); print; exit }' "$PDDA_REPO_ROOT/.pdda-mode" 2>/dev/null)"
  fi
  case "$m" in
    observe|light|full) printf '%s' "$m" ;;
    *) printf 'observe' ;;
  esac
}
PDDA_MODE="$(pdda_resolve_mode)"
# Stale docs are flag-only in every mode (see `pdda.sh stale`), so no mode mutates the tree.
# PDDA_DRY_RUN stays a reserved knob for any future opt-in move re-added behind pdda_hold + full.

# Gate a check's raw exit code by mode: only "full" lets an error block (non-zero exit). observe and
# light still report every finding but exit 0, so a fresh or transitioning install never fails a
# build while the project is being brought onto the rails. Each check ends with
#   exit "$(pdda_gated_exit "$EXIT_CODE")"
pdda_gated_exit() {
  if [ "$PDDA_MODE" = "full" ]; then printf '%s' "${1:-0}"; else printf '0'; fi
}

ERROR_COUNT=0
WARN_COUNT=0
INFO_COUNT=0

pdda_now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

pdda_today() {
  date +"%Y-%m-%d"
}

pdda_relpath() {
  case "$1" in
    "$PDDA_REPO_ROOT") printf '.\n' ;;
    "$PDDA_REPO_ROOT"/*) printf '%s\n' "${1#$PDDA_REPO_ROOT/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

pdda_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

pdda_json_escape() {
  node -e 'process.stdout.write(JSON.stringify(process.argv[1]).slice(1, -1))' "$1"
}

# Build one JSON object (the canonical finding shape) and print it to stdout.
pdda_json_line() {
  local severity="$1" check="$2" file="$3" line="$4" message="$5" action="$6"
  local rel_file
  rel_file="$(pdda_relpath "$file")"
  printf '{"timestamp":"%s","severity":"%s","check":"%s","file":"%s","line":%s,"message":"%s","action":"%s"}\n' \
    "$(pdda_now_iso)" \
    "$(pdda_json_escape "$severity")" \
    "$(pdda_json_escape "$check")" \
    "$(pdda_json_escape "$rel_file")" \
    "$line" \
    "$(pdda_json_escape "$message")" \
    "$(pdda_json_escape "$action")"
}

pdda_log_activity() {
  mkdir -p "$(dirname "$PDDA_ACTIVITY_LOG")"
  pdda_json_line "$@" >> "$PDDA_ACTIVITY_LOG"
}

# Trim the append-only activity log to the last PDDA_ACTIVITY_MAX_LINES entries (0 = never). Cheap,
# call once per run — keeps PROJECT/PDDA-ACTIVITY.jsonl from growing without bound under hourly cron.
pdda_rotate_activity() {
  local max="$PDDA_ACTIVITY_MAX_LINES" count
  [ "$max" -gt 0 ] 2>/dev/null || return 0
  [ -f "$PDDA_ACTIVITY_LOG" ] || return 0
  count="$(wc -l < "$PDDA_ACTIVITY_LOG" | tr -d '[:space:]')"
  if [ "${count:-0}" -gt "$max" ]; then
    tail -n "$max" "$PDDA_ACTIVITY_LOG" > "$PDDA_ACTIVITY_LOG.tmp" \
      && mv "$PDDA_ACTIVITY_LOG.tmp" "$PDDA_ACTIVITY_LOG"
  fi
}

pdda_record_finding() {
  local severity="$1"
  local check="$2"
  local file="$3"
  local line="$4"
  local message="$5"
  local action="$6"
  local rel_file
  local location=""

  rel_file="$(pdda_relpath "$file")"
  if [ "$line" -gt 0 ]; then
    location=":$line"
  fi

  case "$severity" in
    error) ERROR_COUNT=$((ERROR_COUNT + 1)) ;;
    warn) WARN_COUNT=$((WARN_COUNT + 1)) ;;
    *) INFO_COUNT=$((INFO_COUNT + 1)) ;;
  esac

  if [ "$PDDA_FORMAT" = "json" ]; then
    pdda_json_line "$severity" "$check" "$file" "$line" "$message" "$action"
  else
    printf '%s [%s] %s%s %s\n' \
      "$(printf '%s' "$severity" | tr '[:lower:]' '[:upper:]')" \
      "$check" \
      "$rel_file" \
      "$location" \
      "$message"
  fi

  pdda_log_activity "$severity" "$check" "$file" "$line" "$message" "$action"
}

pdda_emit_summary() {
  local check="$1"
  local exit_code="$2"
  local summary

  summary="errors=$ERROR_COUNT warns=$WARN_COUNT info=$INFO_COUNT"
  if [ "$PDDA_FORMAT" = "json" ]; then
    pdda_json_line "$( [ "$exit_code" -eq 0 ] && printf 'info' || printf 'error' )" \
      "$check" "$PDDA_REPO_ROOT" 0 "$summary" "summary"
  else
    printf 'SUMMARY [%s] %s\n' "$check" "$summary"
  fi
  pdda_log_activity \
    "$( [ "$exit_code" -eq 0 ] && printf 'info' || printf 'error' )" \
    "$check" \
    "$PDDA_REPO_ROOT" \
    0 \
    "$summary" \
    "summary"
}

# When PDDA_ONLY_FILE is set (the single-file lint used by the PostToolUse doc-health hook), each list
# returns just that file IF it falls under the list's directory — so every check transparently scopes
# to the one edited doc with no other change. Unset (the normal case) => full directory scan as before.
pdda_list_working_docs() {
  if [ -n "${PDDA_ONLY_FILE:-}" ]; then
    case "$PDDA_ONLY_FILE" in
      "$PDDA_WORKING_DIR"/*.md) [ -f "$PDDA_ONLY_FILE" ] && printf '%s\n' "$PDDA_ONLY_FILE" ;;
    esac
    return
  fi
  find "$PDDA_WORKING_DIR" -type f -name '*.md' ! -name 'blank.md' | LC_ALL=C sort
}

pdda_list_inbox_issue_docs() {
  if [ -n "${PDDA_ONLY_FILE:-}" ]; then
    case "$PDDA_ONLY_FILE" in
      "$PDDA_INBOX_DIR"/GH-*.md) [ -f "$PDDA_ONLY_FILE" ] && printf '%s\n' "$PDDA_ONLY_FILE" ;;
    esac
    return
  fi
  find "$PDDA_INBOX_DIR" -type f -name 'GH-*.md' ! -name 'blank.md' | LC_ALL=C sort
}

pdda_frontmatter_lines() {
  awk '
    NR == 1 { sub(/^\357\273\277/, "") }                 # strip a UTF-8 BOM if present
    !started && /^[[:space:]]*$/ { next }                # tolerate leading blank lines before ---
    !started { started = 1; if ($0 ~ /^---[[:space:]]*$/) { in_frontmatter = 1; next } else { exit } }
    in_frontmatter && /^---[[:space:]]*$/ { exit }
    in_frontmatter { print }
  ' "$1"
}

pdda_has_frontmatter() {
  awk '
    NR == 1 { sub(/^\357\273\277/, "") }
    !started && /^[[:space:]]*$/ { next }
    !started { started = 1; found = ($0 ~ /^---[[:space:]]*$/); exit }
    END { exit(found ? 0 : 1) }
  ' "$1"
}

pdda_frontmatter_has_key() {
  local file="$1"
  local key="$2"
  pdda_frontmatter_lines "$file" | grep -Eq "^${key}:[[:space:]]*"
}

pdda_frontmatter_value() {
  local file="$1"
  local key="$2"
  pdda_frontmatter_lines "$file" \
    | awk -F: -v key="$key" '$1 == key { sub(/^[^:]+:[[:space:]]*/, "", $0); print; exit }'
}

pdda_frontmatter_true() {
  local file="$1"
  local key="$2"
  local value

  value="$(pdda_frontmatter_value "$file" "$key" 2>/dev/null || true)"
  [ "$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')" = "true" ]
}

pdda_table_cells() {
  local row="$1"
  local cells

  cells="$row"
  cells="${cells#|}"
  cells="${cells%|}"
  IFS='|' read -r cell_one cell_two _extra <<EOF
$cells
EOF
  printf '%s\n' "$(pdda_trim "${cell_one:-}")"
  printf '%s\n' "$(pdda_trim "${cell_two:-}")"
}

pdda_normalize_header() {
  local header="$1"
  header="${header#|}"
  header="${header%|}"
  header="$(printf '%s' "$header" | sed -E 's/[[:space:]]*\|[[:space:]]*/|/g')"
  printf '%s\n' "$(pdda_trim "$header")"
}

pdda_file_mtime_epoch() {
  if stat -f '%m' "$1" >/dev/null 2>&1; then
    stat -f '%m' "$1"
  else
    stat -c '%Y' "$1"
  fi
}

# True if <YYYY-MM-DD> is a REAL calendar date (rejects 2026-13-45, 2026-02-30, ...). Portable BSD/GNU:
# detect `date -j` (BSD) once, else GNU `date -d`; require the parsed date to round-trip to the input
# (catches both hard-invalid → non-zero exit AND BSD's silent month/day rollover → mismatched output).
pdda_is_real_date() {
  local d="$1" out
  if date -j -f "%Y-%m-%d" "2000-01-01" "+%Y-%m-%d" >/dev/null 2>&1; then
    out="$(date -j -f "%Y-%m-%d" "$d" "+%Y-%m-%d" 2>/dev/null)" || return 1
  else
    out="$(date -d "$d" "+%Y-%m-%d" 2>/dev/null)" || return 1
  fi
  [ "$out" = "$d" ]
}

# --- GitHub issue-state fetch (shared by `pdda.sh issue-doc-sync` and pdda-gh-refresh.sh) ---------
# One definition of the live-state query + cache row format ("<number>\t<STATE>"), so the cache
# producer and consumer can never disagree on shape.

# Derive owner/repo from the origin remote so `gh` works regardless of the caller's CWD. Empty on
# failure (gh then auto-detects from CWD, or callers fall through to the cache).
_pdda_gh_repo_slug() {
  local url
  url="$(git -C "$PDDA_REPO_ROOT" remote get-url origin 2>/dev/null)" || return 0
  url="${url%.git}"
  case "$url" in
    *github.com[:/]*) printf '%s' "${url##*github.com}" | sed -E 's#^[:/]+##' ;;
    *) : ;;
  esac
}

# Live issue-state table from gh, as "<number>\t<STATE>" lines. Non-zero (and empty) when gh fails
# (absent, unauthenticated, or offline) — callers then degrade to the cached state file.
_pdda_gh_state_table() {
  local slug
  slug="$(_pdda_gh_repo_slug)"
  if [ -n "$slug" ]; then
    gh issue list -R "$slug" --state all --limit 1000 --json number,state \
      --jq '.[] | [.number, .state] | @tsv' 2>/dev/null
  else
    gh issue list --state all --limit 1000 --json number,state \
      --jq '.[] | [.number, .state] | @tsv' 2>/dev/null
  fi
}
