#!/usr/bin/env bash
set -u

PDDA_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Runtime lives in <repo>/utils/pdda/, so the repo root is two levels up from the lib dir.
PDDA_REPO_ROOT="${PDDA_REPO_ROOT:-$(cd "$PDDA_LIB_DIR/../.." && pwd)}"
PDDA_INBOX_DIR="${PDDA_INBOX_DIR:-$PDDA_REPO_ROOT/PROJECT/1-INBOX}"
PDDA_WORKING_DIR="${PDDA_WORKING_DIR:-$PDDA_REPO_ROOT/PROJECT/2-WORKING}"
PDDA_COMPLETED_DIR="${PDDA_COMPLETED_DIR:-$PDDA_REPO_ROOT/PROJECT/3-COMPLETED}"
PDDA_MISC_DIR="${PDDA_MISC_DIR:-$PDDA_REPO_ROOT/PROJECT/4-MISC}"
# Forward-looking release-planning ledger — a single root file (like ROADMAP.md/CHANGELOG.md), not
# a lifecycle bucket of per-tag docs. See PROJECT/PDDA.md "RELEASES.md — release ledger".
PDDA_RELEASES_FILE="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
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

# Cross-check totals for one `pdda.sh run`, accumulated by pdda_emit_summary. The per-check counters
# above are reset by every pdda_reset_counts, and a check's RETURN VALUE is gated to 0 outside full
# mode — so in observe/light a run of nothing but errors leaves cmd_run's EXIT_CODE at 0. Inferring
# "all checks passed" from that zero is BUG-001b: the mode gate is supposed to stop the run from
# BLOCKING, not to stop it from REPORTING. These totals survive the resets and ignore the gate, so the
# closing line can say what was actually found. Same family as GH-23 and GH-27: a check that could not
# run, or could not block, must never be scored as a check that passed.
PDDA_RUN_ERRORS=0
PDDA_RUN_WARNS=0
PDDA_RUN_ERROR_CHECKS=""
# GH-43: the warn total was accumulated below but never read, so a run whose findings were all
# warn-level printed "all checks passed". Same family, one step further out: PDDA_RUN_ERRORS answers
# "did anything go wrong", not "did anything need attention" — which is what that line asserts.
PDDA_RUN_WARN_CHECKS=""

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
  if command -v node >/dev/null 2>&1; then
    node -e 'process.stdout.write(JSON.stringify(process.argv[1]).slice(1, -1))' "$1"
  else
    # GH-48: node isn't guaranteed on PATH (e.g. a launchd/cron caller with a minimal PATH) — degrade
    # to a pure-shell escape instead of silently emitting nothing (which corrupted activity-log JSON).
    local s="$1" out="" i c ord
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\b'/\\b}"
    s="${s//$'\f'/\\f}"
    # JSON forbids any other raw C0 control byte (0x00-0x1F) in a string literal too — a real path or
    # message is very unlikely to carry one, but the degrade path must still emit valid JSON when it
    # does, not just for the common cases above. \0 can't occur (bash strings can't hold a NUL byte).
    for (( i = 0; i < ${#s}; i++ )); do
      c="${s:i:1}"
      ord="$(printf '%d' "'$c" 2>/dev/null)"
      if [ -n "$ord" ] && [ "$ord" -lt 32 ]; then
        printf -v c '\\u%04x' "$ord"
      fi
      out+="$c"
    done
    printf '%s' "$out"
  fi
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

  # Roll this check's findings into the run-level totals before the next pdda_reset_counts wipes them.
  PDDA_RUN_ERRORS=$((PDDA_RUN_ERRORS + ERROR_COUNT))
  PDDA_RUN_WARNS=$((PDDA_RUN_WARNS + WARN_COUNT))
  if [ "$ERROR_COUNT" -gt 0 ]; then
    PDDA_RUN_ERROR_CHECKS="$PDDA_RUN_ERROR_CHECKS $check"
  fi
  if [ "$WARN_COUNT" -gt 0 ]; then
    PDDA_RUN_WARN_CHECKS="$PDDA_RUN_WARN_CHECKS $check"
  fi

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

# Completed plans (3-COMPLETED). issue-doc-sync needs these: a doc that reached 3-COMPLETED is the
# operator's own assertion that the work is done, so a still-OPEN issue behind it is drift. Without
# this list the check stops watching a doc at the exact moment it completes — and the `git mv` the
# check itself recommends is what blinds it (GH-27).
pdda_list_completed_docs() {
  if [ -n "${PDDA_ONLY_FILE:-}" ]; then
    case "$PDDA_ONLY_FILE" in
      "$PDDA_COMPLETED_DIR"/*.md) [ -f "$PDDA_ONLY_FILE" ] && printf '%s\n' "$PDDA_ONLY_FILE" ;;
    esac
    return
  fi
  find "$PDDA_COMPLETED_DIR" -type f -name '*.md' ! -name 'blank.md' | LC_ALL=C sort
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

# Quad Concepts scope: active plans (2-WORKING), issue intake (1-INBOX/GH-*), and archived plans
# (3-COMPLETED — kept glanceable for cold-start recall, per the project-memory-layer reframing).
# Excludes 4-MISC. Honors PDDA_ONLY_FILE (the single-file lint path) exactly like the lists above.
pdda_list_quad_docs() {
  if [ -n "${PDDA_ONLY_FILE:-}" ]; then
    case "$PDDA_ONLY_FILE" in
      */blank.md) : ;;   # scaffold — never in scope (matches the bulk find's blank.md exclusion)
      "$PDDA_WORKING_DIR"/*.md|"$PDDA_INBOX_DIR"/GH-*.md|"$PDDA_COMPLETED_DIR"/*.md)
        [ -f "$PDDA_ONLY_FILE" ] && printf '%s\n' "$PDDA_ONLY_FILE" ;;
    esac
    return
  fi
  {
    find "$PDDA_WORKING_DIR"   -type f -name '*.md'    ! -name 'blank.md' 2>/dev/null
    find "$PDDA_INBOX_DIR"     -type f -name 'GH-*.md' ! -name 'blank.md' 2>/dev/null
    find "$PDDA_COMPLETED_DIR" -type f -name '*.md'    ! -name 'blank.md' 2>/dev/null
  } | LC_ALL=C sort
}

# Quad Concepts opt-in lever — ORTHOGONAL to PDDA_MODE (observe/light/full). The lever decides whether
# the quad-concepts check joins `pdda.sh run`; the mode still decides report-only vs blocking. Resolution
# mirrors the .sentinel-mode resolver: env PDDA_QUAD -> first non-comment line of <repo>/.pdda-quad ->
# default OFF. Any of 1/on/true/enabled/yes (case-insensitive) enables; everything else stays off.
quad_is_enabled() {
  local v="${PDDA_QUAD:-}"
  if [ -z "$v" ] && [ -f "$PDDA_REPO_ROOT/.pdda-quad" ]; then
    v="$(awk 'NF && $0 !~ /^[[:space:]]*#/ { gsub(/[[:space:]]/,""); print; exit }' "$PDDA_REPO_ROOT/.pdda-quad" 2>/dev/null)"
  fi
  case "$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]')" in
    1|on|true|enabled|yes) return 0 ;;
    *) return 1 ;;
  esac
}

# Shared Quad Concepts section parser (used by `pdda.sh quad-concepts` AND `pdda.sh glance` — one parser,
# no drift). Emits the bullet COUNT on line 1 (-1 if the section is absent), then each top-level,
# non-empty bullet's TEXT (marker stripped) on its own line. Boundaries: the FIRST "## Quad Concepts"
# header until the next h1/h2 heading or the first blank line AFTER a bullet; fenced code is skipped;
# CRLF is normalized; indented/nested and empty bullets do not count; only the first section is read.
pdda_quad_section() {  # <file>
  awk '
    { sub(/\r$/, "") }
    done { next }
    /^```/ { in_f = !in_f; next }
    in_f { next }
    !seen && /^##[ \t]+Quad[ \t]+Concepts[ \t]*$/ { in_q = 1; seen = 1; started = 0; next }
    in_q && /^#{1,2}[ \t]/            { in_q = 0; done = 1; next }
    in_q && started && /^[ \t]*$/     { in_q = 0; done = 1; next }
    in_q && /^[-*][ \t]+[^ \t]/       { b = $0; sub(/^[-*][ \t]+/, "", b); bl[++n] = b; started = 1; next }
    END { if (!seen) print -1; else print n + 0; for (i = 1; i <= n; i++) print bl[i] }
  ' "$1"
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

# Write a "<number>\t<STATE>" table to the gh-state cache, atomically (temp file + mv). ONE definition,
# shared by pdda-gh-refresh.sh (the explicit refresh command) and the `auto` lookup path in
# _pdda_issue_state_table (which fetches this exact table on every `pdda.sh run` and used to throw it
# away — GH-27). Returns non-zero on write failure; callers on the read path ignore that, because a
# failed cache write must never break a check that already has its answer in hand.
pdda_write_gh_state_cache() {  # <table>
  local table="$1" tmp="$PDDA_GH_STATE_CACHE.tmp.$$"
  {
    printf '# pdda gh-issue-state cache — regenerated by pdda-gh-refresh.sh or any live `pdda.sh` lookup; do not edit by hand\n'
    printf '# generated: %s\n' "$(pdda_now_iso)"
    printf '# format: <issue-number>\\t<STATE>  (STATE is OPEN or CLOSED)\n'
    [ -n "$table" ] && printf '%s\n' "$table"
  } > "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
  mv "$tmp" "$PDDA_GH_STATE_CACHE" 2>/dev/null || { rm -f "$tmp"; return 1; }
}

# --- RELEASES.md helpers -------------------------------------------------------------------------
# RELEASES.md is a single forward-looking planning ledger (like ROADMAP.md/CHANGELOG.md), not a
# bucket of per-tag docs — see PROJECT/PDDA.md "RELEASES.md — release ledger". Each release is a
# flat "Label: value" block; a block starts at a line matching ^Release: and runs until the next
# such line or EOF (blank lines between blocks are just visual spacing, not parsed).

# List releases as rows of
#   <release><US><status><US><target_date><US><codename><US><description><US><gh_url><US>
#   <front_door><US><shakedown><US><license_file><US><iterations><US><milestone><US><line>
# (US = ASCII unit separator 0x1F, not tab — bash's `read` collapses empty fields around literal
# tabs since tab counts as "IFS whitespace" regardless of IFS's contents, which would silently
# misalign every block with a blank Description/GH_URL, i.e. the common case here). One row per
# block, in file order. Prints nothing (silently) if the file doesn't exist.
#
# THIS ROW SHAPE IS INTERNAL, AND ADDING A FIELD IS A BREAKING CHANGE. Callers read it positionally
# with `read -r`, and there is no position that is safe to extend: a new field before <line> shifts
# <line> onto the wrong variable, and one after it makes bash's last-variable-absorbs-the-rest rule
# fold the extras into <line>. So <line> stays last as a record terminator, and every reader must be
# updated in the SAME change — `check_releases` and `cmd_releases_current` are the only two, and
# test/pdda-releases-iterations.sh pins the field count so a future addition can't drift silently.
# The stable, external surface for other tooling is `pdda.sh releases-current`, not this helper.
#
# `Status:` is free-text (Draft/Working/Shipped/... — whatever an operator writes) and unvalidated
# by design: it's a rough, non-authoritative signal for "what's in progress," not a gated lifecycle
# field. `Milestone:` is free-text for the same reason — it carries a GitHub milestone *title* so a
# release's scope can be queried (`gh issue list --milestone "<title>"`) instead of hand-listed here.
# `Front-door reviewed:`/`Shakedown reviewed:`/`License file:` are optional Yes/No QA-gate fields,
# and `Iterations:` is an optional reserved version band (`pdda.sh releases` warns on a malformed
# value for either). See PROJECT/PDDA.md "RELEASES.md — release ledger".
pdda_releases_list() {
  local file="$1"
  [ -f "$file" ] || return 0
  awk '
    function flush() {
      if (has_release) {
        printf "%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%s\037%d\n", release, status, target_date, codename, description, gh_url, front_door, shakedown, license_file, iterations, milestone, release_line
      }
      release=""; status=""; target_date=""; codename=""; description=""; gh_url=""
      front_door=""; shakedown=""; license_file=""; iterations=""; milestone=""
      release_line=0; has_release=0
    }
    /^Release:/             { flush(); v=$0; sub(/^Release:[[:space:]]*/, "", v); release=v; has_release=1; release_line=NR; next }
    /^Status:/              { v=$0; sub(/^Status:[[:space:]]*/, "", v); status=v; next }
    /^Iterations:/          { v=$0; sub(/^Iterations:[[:space:]]*/, "", v); iterations=v; next }
    /^Target Date:/         { v=$0; sub(/^Target Date:[[:space:]]*/, "", v); target_date=v; next }
    /^Codename:/             { v=$0; sub(/^Codename:[[:space:]]*/, "", v); codename=v; next }
    /^Milestone:/           { v=$0; sub(/^Milestone:[[:space:]]*/, "", v); milestone=v; next }
    /^Description:/         { v=$0; sub(/^Description:[[:space:]]*/, "", v); description=v; next }
    /^GH_URL:/               { v=$0; sub(/^GH_URL:[[:space:]]*/, "", v); gh_url=v; next }
    /^Front-door reviewed:/ { v=$0; sub(/^Front-door reviewed:[[:space:]]*/, "", v); front_door=v; next }
    /^Shakedown reviewed:/  { v=$0; sub(/^Shakedown reviewed:[[:space:]]*/, "", v); shakedown=v; next }
    /^License file:/        { v=$0; sub(/^License file:[[:space:]]*/, "", v); license_file=v; next }
    END { flush() }
  ' "$file"
}

# Compare two dotted-numeric versions; echoes -1 / 0 / 1 for a<b / a==b / a>b. Missing and
# non-numeric components read as 0. Deliberately NOT a semver implementation — it exists only to
# answer "does this version fall inside a reserved Iterations band", and callers gate it behind
# pdda_is_dotted_version so prerelease/date-shaped values never reach it.
pdda_vercmp() {
  awk -v a="$1" -v b="$2" '
    BEGIN {
      na = split(a, x, "."); nb = split(b, y, ".")
      n = (na > nb ? na : nb)
      for (i = 1; i <= n; i++) {
        ai = (i <= na ? x[i] + 0 : 0); bi = (i <= nb ? y[i] + 0 : 0)
        if (ai < bi) { print -1; exit }
        if (ai > bi) { print  1; exit }
      }
      print 0
    }'
}

# True if the value is a plain dotted-numeric version (1, 1.2, 0.2.14 — not v1.2.3, not 1.0.0-rc1).
pdda_is_dotted_version() {
  case "$1" in
    "" | *[!0-9.]* | .* | *. | *..*) return 1 ;;
  esac
  return 0
}

# True if the value is a well-formed reserved-iteration band: exactly "<lo>-<hi>", both plain
# dotted-numeric versions, lo <= hi. Strict on purpose — a band is only useful if the containment
# test in `pdda.sh releases` can be trusted, so anything ambiguous (a prerelease hyphen, a reversed
# range) warns rather than being silently half-parsed. See PROJECT/PDDA.md "RELEASES.md — release
# ledger" → `Iterations:`.
pdda_is_iteration_band() {
  local band="$1" lo hi
  case "$band" in *-*) ;; *) return 1 ;; esac
  lo="${band%%-*}"
  hi="${band#*-}"
  pdda_is_dotted_version "$lo" || return 1
  pdda_is_dotted_version "$hi" || return 1
  [ "$(pdda_vercmp "$lo" "$hi")" != "1" ] || return 1
  return 0
}
