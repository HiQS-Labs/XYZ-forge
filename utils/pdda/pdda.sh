#!/usr/bin/env bash
set -u

# PDDA unified entry point. One dispatcher for every deterministic hygiene check plus the aggregate
# run. The LLM-assisted readiness review stays in its own file (utils/pdda/pdda-doc-ready.sh) — it is a
# different class of automation (opt-in, model-dependent, advisory/warn-max), per PROJECT/PDDA.md
# "Automation layers". Shared helpers live in utils/pdda/pdda-lib.sh.
#
# Usage:
#   pdda.sh run                 # run every deterministic check, then the LLM review (steps in order)
#   pdda.sh frontmatter         # one check (see SUBCOMMANDS below)
#   pdda.sh status-table
#   pdda.sh hardcoded-paths
#   pdda.sh roadmap
#   pdda.sh roadmap-coverage
#   pdda.sh changelog
#   pdda.sh stale
#   pdda.sh doc-ready           # delegates to utils/pdda/pdda-doc-ready.sh (the LLM layer)
#   pdda.sh help
#
# Mode/format/overrides are honored exactly as before via the env vars resolved in pdda-lib.sh
# (PDDA_MODE, PDDA_FORMAT, PDDA_WORKING_DIR, PDDA_ROADMAP, ...). Every check resets the finding
# counters on entry and emits its own SUMMARY, so per-check output is identical whether a check runs
# standalone (`pdda.sh frontmatter`) or as part of `pdda.sh run`.

HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/pdda/pdda-lib.sh
. "$HERE/pdda-lib.sh"

pdda_reset_counts() { ERROR_COUNT=0; WARN_COUNT=0; INFO_COUNT=0; }

# ------------------------------------------------------------------------------------------------
# A. frontmatter
# ------------------------------------------------------------------------------------------------
check_frontmatter() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-frontmatter" rc=0
  local REQUIRED_KEYS="title status created updated owner goal"
  local file key value date_key rating_key

  while IFS= read -r file; do
    if ! pdda_has_frontmatter "$file"; then
      pdda_record_finding error "$CHECK_NAME" "$file" 1 "missing YAML frontmatter" "add-frontmatter"
      rc=1
      continue
    fi

    for key in $REQUIRED_KEYS; do
      if ! pdda_frontmatter_has_key "$file" "$key"; then
        pdda_record_finding error "$CHECK_NAME" "$file" 1 "missing required frontmatter key '$key'" "add-frontmatter-key"
        rc=1
        continue
      fi

      value="$(pdda_frontmatter_value "$file" "$key")"
      if [ -z "$(pdda_trim "$value")" ]; then
        pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter key '$key' is empty" "fill-frontmatter-key"
        rc=1
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
          rc=1
        elif ! pdda_is_real_date "$value"; then
          pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter key '$date_key' is not a real calendar date ($value)" "fix-date-value"
          rc=1
        fi
      fi
    done

    # Optional triage ratings (PDDA.md "Triage ratings for medium-large work"). Validate ONLY when
    # present: whether a doc SHOULD carry them depends on it being medium-large — a judgment the LLM
    # layer flags, not this script. But a present value out of range is unambiguous => error. Effort,
    # complexity, and risk are integers 1 (low) .. 5 (highest); phases is a positive integer.
    for rating_key in effort complexity risk; do
      if pdda_frontmatter_has_key "$file" "$rating_key"; then
        value="$(pdda_trim "$(pdda_frontmatter_value "$file" "$rating_key")")"
        if ! printf '%s' "$value" | grep -Eq '^[1-5]$'; then
          pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter rating '$rating_key' must be an integer 1-5 (got '$value')" "fix-rating-value"
          rc=1
        fi
      fi
    done
    if pdda_frontmatter_has_key "$file" "phases"; then
      value="$(pdda_trim "$(pdda_frontmatter_value "$file" "phases")")"
      if ! printf '%s' "$value" | grep -Eq '^[1-9][0-9]*$'; then
        pdda_record_finding error "$CHECK_NAME" "$file" 1 "frontmatter 'phases' must be a positive integer (got '$value')" "fix-phases-value"
        rc=1
      fi
    fi
  done < <(pdda_list_working_docs)

  pdda_emit_summary "$CHECK_NAME" "$rc"
  return "$(pdda_gated_exit "$rc")"
}

# ------------------------------------------------------------------------------------------------
# B. status-table
# ------------------------------------------------------------------------------------------------
check_status_table() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-status-table" rc=0
  local EXPECTED_HEADER="What was just completed|What's next"
  local file metadata old_ifs header_line header_text row_line row_text
  local normalized_header cell_output cell_one cell_two

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
      rc=1
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
      rc=1
    fi

    cell_output="$(pdda_table_cells "$row_text")"
    cell_one="$(printf '%s\n' "$cell_output" | sed -n '1p')"
    cell_two="$(printf '%s\n' "$cell_output" | sed -n '2p')"

    if [ -z "$cell_one" ]; then
      pdda_record_finding error "$CHECK_NAME" "$file" "$row_line" "first status cell is blank" "fill-status-table"
      rc=1
    fi
    if [ -z "$cell_two" ]; then
      pdda_record_finding error "$CHECK_NAME" "$file" "$row_line" "second status cell is blank" "fill-status-table"
      rc=1
    fi
  done < <(pdda_list_working_docs)

  pdda_emit_summary "$CHECK_NAME" "$rc"
  return "$(pdda_gated_exit "$rc")"
}

# ------------------------------------------------------------------------------------------------
# C. hardcoded-paths
# ------------------------------------------------------------------------------------------------
check_hardcoded_paths() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-hardcoded-paths" rc=0
  local file matches awk_status line_number reason

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
      rc=1
      continue
    fi

    while IFS=$'\t' read -r line_number reason; do
      [ -n "$line_number" ] || continue
      pdda_record_finding error "$CHECK_NAME" "$file" "$line_number" "hardcoded path detected ($reason)" "replace-with-repo-relative-path"
      rc=1
    done <<EOF
$matches
EOF
  done < <(pdda_list_working_docs)

  pdda_emit_summary "$CHECK_NAME" "$rc"
  return "$(pdda_gated_exit "$rc")"
}

# ------------------------------------------------------------------------------------------------
# D. roadmap (no execution detail leaks INTO ROADMAP.md)
# ------------------------------------------------------------------------------------------------
check_roadmap() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-roadmap" rc=0
  local PDDA_ROADMAP="${PDDA_ROADMAP:-$PDDA_REPO_ROOT/ROADMAP.md}"
  local ROADMAP_MAX_LINES="${PDDA_ROADMAP_MAX_LINES:-200}"
  local ROADMAP_MAX_HEADINGS="${PDDA_ROADMAP_MAX_HEADINGS:-25}"
  local findings sev line msg line_count heading_count

  if [ ! -f "$PDDA_ROADMAP" ]; then
    pdda_record_finding info "$CHECK_NAME" "$PDDA_ROADMAP" 0 "ROADMAP.md not found; nothing to check" "skip"
    pdda_emit_summary "$CHECK_NAME" 0
    return "$(pdda_gated_exit 0)"
  fi

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
      rc=1
    fi
  done <<EOF
$findings
EOF

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

  pdda_emit_summary "$CHECK_NAME" "$rc"
  return "$(pdda_gated_exit "$rc")"
}

# ------------------------------------------------------------------------------------------------
# E. roadmap-coverage (nothing active goes MISSING from ROADMAP.md)
# ------------------------------------------------------------------------------------------------
check_roadmap_coverage() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-roadmap-coverage" rc=0
  local PDDA_ROADMAP="${PDDA_ROADMAP:-$PDDA_REPO_ROOT/ROADMAP.md}"
  local file rel

  if [ ! -f "$PDDA_ROADMAP" ]; then
    pdda_record_finding error "$CHECK_NAME" "$PDDA_ROADMAP" 0 \
      "ROADMAP.md not found; cannot verify working-doc coverage" "add-roadmap"
    pdda_emit_summary "$CHECK_NAME" 1
    return "$(pdda_gated_exit 1)"
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
    rc=1
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
    rc=1
  done < <(pdda_list_inbox_issue_docs)

  pdda_emit_summary "$CHECK_NAME" "$rc"
  return "$(pdda_gated_exit "$rc")"
}

# ------------------------------------------------------------------------------------------------
# F. changelog (warn-only nudge; never blocks, even in full)
# ------------------------------------------------------------------------------------------------
_pdda_cl_epoch() {  # YYYY-MM-DD -> epoch seconds (portable BSD/GNU); prints nothing on parse failure
  local d="$1"
  if date -j -f "%Y-%m-%d" "2000-01-01" "+%s" >/dev/null 2>&1; then
    date -j -f "%Y-%m-%d" "$d" "+%s" 2>/dev/null
  else
    date -d "$d" "+%s" 2>/dev/null
  fi
}

check_changelog() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-changelog" rc=0
  local PDDA_CHANGELOG="${PDDA_CHANGELOG:-$PDDA_REPO_ROOT/CHANGELOG.md}"
  local PDDA_CHANGELOG_STALE_DAYS="${PDDA_CHANGELOG_STALE_DAYS:-0}"
  local cl_line cl_date commit_date cl_epoch commit_epoch gap_days

  if [ ! -f "$PDDA_CHANGELOG" ]; then
    pdda_record_finding warn "$CHECK_NAME" "$PDDA_CHANGELOG" 0 \
      "CHANGELOG.md not found — PDDA expects a first-class end-of-iteration changelog" "create-changelog"
    pdda_emit_summary "$CHECK_NAME" "$rc"
    return "$(pdda_gated_exit "$rc")"
  fi

  cl_line="$(grep -Em1 '^##[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}' "$PDDA_CHANGELOG" 2>/dev/null || true)"
  cl_date="$(printf '%s' "$cl_line" | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"

  if [ -z "$cl_date" ] || ! pdda_is_real_date "$cl_date"; then
    pdda_record_finding warn "$CHECK_NAME" "$PDDA_CHANGELOG" 1 \
      "no dated '## YYYY-MM-DD' entry at the top of CHANGELOG.md — add an end-of-iteration entry" "add-dated-entry"
    pdda_emit_summary "$CHECK_NAME" "$rc"
    return "$(pdda_gated_exit "$rc")"
  fi

  commit_date="$(git -C "$PDDA_REPO_ROOT" log -1 --format=%cd --date=short 2>/dev/null || true)"
  if [ -z "$commit_date" ] || ! pdda_is_real_date "$commit_date"; then
    pdda_record_finding info "$CHECK_NAME" "$PDDA_CHANGELOG" 0 \
      "no git history to compare against; freshness not evaluated (newest entry $cl_date)" "skip"
    pdda_emit_summary "$CHECK_NAME" "$rc"
    return "$(pdda_gated_exit "$rc")"
  fi

  cl_epoch="$(_pdda_cl_epoch "$cl_date")"
  commit_epoch="$(_pdda_cl_epoch "$commit_date")"
  if [ -n "$cl_epoch" ] && [ -n "$commit_epoch" ] && [ "$commit_epoch" -gt "$cl_epoch" ]; then
    gap_days=$(( (commit_epoch - cl_epoch) / 86400 ))
    if [ "$gap_days" -gt "$PDDA_CHANGELOG_STALE_DAYS" ]; then
      pdda_record_finding warn "$CHECK_NAME" "$PDDA_CHANGELOG" 1 \
        "CHANGELOG newest entry ($cl_date) predates the latest commit ($commit_date) by $gap_days day(s) — add an end-of-iteration entry" "update-changelog"
    fi
  fi

  pdda_emit_summary "$CHECK_NAME" "$rc"
  return "$(pdda_gated_exit "$rc")"
}

# ------------------------------------------------------------------------------------------------
# G. stale (flag-only; never moves files, never blocks)
# ------------------------------------------------------------------------------------------------
_pdda_build_target_path() {
  local source_file="$1" base_name target stem ext suffix
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

check_stale() {
  pdda_reset_counts
  local CHECK_NAME="pdda-stale-working-docs" rc=0
  local NOW_EPOCH STALE_SECONDS file mtime_epoch age_seconds target_path age_days
  NOW_EPOCH="$(date +%s)"
  STALE_SECONDS=$((PDDA_STALE_DAYS * 86400))

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

    target_path="$(_pdda_build_target_path "$file")"
    age_days=$((age_seconds / 86400))
    # flag-only by design (see PROJECT/PDDA.md): a human runs one reversible `git mv`. Warn-max.
    pdda_record_finding warn "$CHECK_NAME" "$file" 1 "stale (${age_days}d old) — recommend: git mv $(pdda_relpath "$file") $(pdda_relpath "$target_path")" "flagged"
  done < <(pdda_list_working_docs)

  pdda_emit_summary "$CHECK_NAME" "$rc"
  return "$(pdda_gated_exit "$rc")"
}

# ------------------------------------------------------------------------------------------------
# H. issue-doc-sync (warn-only, flag-only; gh-degrades to a cached state file, never blocks)
# ------------------------------------------------------------------------------------------------
# The gh-fetch primitives (_pdda_gh_repo_slug, _pdda_gh_state_table) live in pdda-lib.sh so the
# cache producer (pdda-gh-refresh.sh) and this consumer share ONE definition of the cache format.

# Cached issue-state table ('#'-comment lines stripped). Empty when no cache file exists.
_pdda_cache_state_table() {
  [ -f "$PDDA_GH_STATE_CACHE" ] || return 0
  grep -v '^[[:space:]]*#' "$PDDA_GH_STATE_CACHE" 2>/dev/null
}

# Resolve the issue-state table from the best source, honoring PDDA_ISSUE_SYNC_SOURCE
# (auto|gh|cache; default auto = live gh when it succeeds, else the cached file). The Stop hook sets
# `cache` to stay fast and offline-tolerant; `pdda.sh run` uses `auto`. Prints "<number>\t<STATE>".
_pdda_issue_state_table() {
  local out
  case "${PDDA_ISSUE_SYNC_SOURCE:-auto}" in
    cache) _pdda_cache_state_table ;;
    gh)    _pdda_gh_state_table ;;
    auto|*)
      if command -v gh >/dev/null 2>&1 && out="$(_pdda_gh_state_table)"; then
        printf '%s' "$out"
      else
        _pdda_cache_state_table
      fi
      ;;
  esac
}

# Issue number for a doc: frontmatter gh_issue (preferred), else the GH-<n>- filename. Empty if neither.
_pdda_doc_issue_number() {
  local file="$1" num base
  num="$(pdda_trim "$(pdda_frontmatter_value "$file" gh_issue)")"
  case "$num" in \"*\") num="${num#\"}"; num="${num%\"}" ;; \'*\') num="${num#\'}"; num="${num%\'}" ;; esac
  num="${num#\#}"
  if printf '%s' "$num" | grep -Eq '^[0-9]+$'; then printf '%s' "$num"; return; fi
  base="$(basename "$file")"
  case "$base" in
    GH-[0-9]*) num="${base#GH-}"; num="${num%.md}"; num="${num%%-*}"   # strip .md first so a bare GH-<n>.md (no description) still resolves
      if printf '%s' "$num" | grep -Eq '^[0-9]+$'; then printf '%s' "$num"; fi ;;
  esac
}

# Leading alphabetic word of a doc's status (lowercased): "Active — Phase 0 complete" -> "active";
# "🟢 Shipped" -> "shipped". Anchors the (b) signal on the status field's first word, which declares
# the whole doc's state — so a mid-status mention like "Phase 0 complete" never false-flags.
_pdda_status_leadword() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | grep -oE '[a-z]+' | head -1
}

# Terminal status words that mean "this doc is done" (so a still-OPEN issue is the drift).
PDDA_TERMINAL_STATUS_WORDS="complete completed done shipped fixed closed merged resolved landed"
_pdda_is_terminal_word() {
  case " $PDDA_TERMINAL_STATUS_WORDS " in *" $1 "*) return 0 ;; esac
  return 1
}

check_issue_doc_sync() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-issue-doc-sync" rc=0
  local table file num state status_val leadword target rel_target
  table="$(_pdda_issue_state_table)"

  while IFS= read -r file; do
    num="$(_pdda_doc_issue_number "$file")"
    [ -n "$num" ] || continue            # not an issue-tracked doc — nothing to reconcile

    state="$(printf '%s\n' "$table" | awk -F'\t' -v n="$num" '$1 == n { print toupper($2); exit }')"
    if [ -z "$state" ]; then
      pdda_record_finding info "$CHECK_NAME" "$file" 1 \
        "issue #$num state unavailable (gh absent/offline and no cached state) — sync not evaluated" "skip"
      continue
    fi

    # Direction (a): issue CLOSED but the doc still sits in 2-WORKING => recommend the move (flag-only).
    if [ "$state" = "CLOSED" ]; then
      target="$PDDA_COMPLETED_DIR/$(basename "$file")"
      rel_target="$(pdda_relpath "$target")"
      pdda_record_finding warn "$CHECK_NAME" "$file" 1 \
        "issue #$num is CLOSED but the doc is still in 2-WORKING — recommend: git mv $(pdda_relpath "$file") $rel_target" \
        "move-to-completed"
      continue                            # closed-issue drift dominates; skip the (b) test
    fi

    # Direction (b): doc declares itself done (status lead word) while the issue is still OPEN.
    status_val="$(pdda_trim "$(pdda_frontmatter_value "$file" status)")"
    leadword="$(_pdda_status_leadword "$status_val")"
    if [ -n "$leadword" ] && _pdda_is_terminal_word "$leadword"; then
      pdda_record_finding warn "$CHECK_NAME" "$file" 1 \
        "doc status reads '$leadword' (done) but issue #$num is still OPEN — close the issue or correct the status" \
        "reconcile-status"
    fi
  done < <(pdda_list_working_docs)

  pdda_emit_summary "$CHECK_NAME" "$rc"
  return "$(pdda_gated_exit "$rc")"
}

# ------------------------------------------------------------------------------------------------
# run — the aggregate deterministic suite, then the LLM readiness review (in order)
# ------------------------------------------------------------------------------------------------
# Decoration -> stdout in text mode, stderr in json mode, so PDDA_FORMAT=json leaves stdout a clean
# JSON-lines stream for downstream parsers.
runner_say() { if [ "$PDDA_FORMAT" = "json" ]; then printf '%s\n' "$*" >&2; else printf '%s\n' "$*"; fi; }

# Deterministic checks, in the PDDA.md "Suggested hourly schedule" order. Format: "<label> <function>".
PDDA_DETERMINISTIC_CHECKS="
pdda-check-frontmatter:check_frontmatter
pdda-check-status-table:check_status_table
pdda-check-hardcoded-paths:check_hardcoded_paths
pdda-check-roadmap:check_roadmap
pdda-check-roadmap-coverage:check_roadmap_coverage
pdda-check-changelog:check_changelog
pdda-stale-working-docs:check_stale
pdda-check-issue-doc-sync:check_issue_doc_sync
"

cmd_run() {
  local EXIT_CODE=0 FAILED="" entry label fn MODE_NOTE

  case "$PDDA_MODE" in
    observe) MODE_NOTE="observe (report-only; never blocks)" ;;
    light)   MODE_NOTE="light (reports findings incl. stale flags; does not block)" ;;
    full)    MODE_NOTE="full (on rails; errors block with a non-zero exit)" ;;
    *)       MODE_NOTE="$PDDA_MODE" ;;
  esac
  runner_say "PDDA run starting — mode: $MODE_NOTE"
  pdda_log_activity info "pdda-run" "$PDDA_REPO_ROOT" 0 "starting deterministic PDDA run (mode=$PDDA_MODE)" "start"

  for entry in $PDDA_DETERMINISTIC_CHECKS; do
    label="${entry%%:*}"
    fn="${entry##*:}"
    runner_say ""
    runner_say "== $label =="
    if "$fn"; then
      :
    else
      EXIT_CODE=1
      FAILED="$FAILED $label"
    fi
  done

  # LLM-assisted readiness review — runs ONLY when the deterministic checks all passed, per PDDA.md
  # ("the LLM review should spend time only on docs that passed basic structural hygiene"). The
  # pdda-doc-ready.sh script also self-skips when PDDA_LLM_BIN is unset.
  runner_say ""
  runner_say "== pdda-doc-ready =="
  if [ "$EXIT_CODE" -ne 0 ]; then
    runner_say "skipped pdda-doc-ready — fix the deterministic failures above first ($FAILED)"
    pdda_log_activity info "pdda-doc-ready" "$PDDA_REPO_ROOT" 0 "readiness review skipped — deterministic checks failed:$FAILED" "skip"
  elif "$HERE/pdda-doc-ready.sh"; then
    :
  else
    EXIT_CODE=1
    FAILED="$FAILED pdda-doc-ready"
  fi

  if [ "$EXIT_CODE" -eq 0 ]; then
    runner_say ""
    runner_say "PDDA run complete: all checks passed"
    pdda_log_activity info "pdda-run" "$PDDA_REPO_ROOT" 0 "PDDA run completed successfully" "finish"
  else
    runner_say ""
    runner_say "PDDA run complete: failures:$FAILED"
    pdda_log_activity error "pdda-run" "$PDDA_REPO_ROOT" 0 "PDDA run completed with failures:$FAILED" "finish"
  fi

  pdda_rotate_activity   # keep PROJECT/PDDA-ACTIVITY.jsonl bounded

  # Mode gate: only "full" blocks (non-zero). In observe/light the checks already return 0.
  return "$(pdda_gated_exit "$EXIT_CODE")"
}

# ------------------------------------------------------------------------------------------------
# dispatcher
# ------------------------------------------------------------------------------------------------
pdda_usage() {
  cat <<'USAGE'
pdda.sh — Project-Driven Doc Automation entry point

Usage: pdda.sh <command>

Commands:
  run                aggregate: all deterministic checks, then the LLM readiness review (default)
  frontmatter        active-doc frontmatter contract
  status-table       exact two-column "## Status" table
  hardcoded-paths    no machine-specific absolute paths in working docs
  roadmap            no execution detail leaks INTO ROADMAP.md
  roadmap-coverage   nothing active goes MISSING from ROADMAP.md
  changelog          end-of-iteration changelog nudge (warn-only)
  stale              flag stale working docs (flag-only; never moves)
  issue-doc-sync     flag 2-WORKING/GH-*.md docs drifted from their GitHub issue state (warn-only)
  gh-refresh         refresh the cached GitHub issue-state file issue-doc-sync reads offline (needs gh)
  doc-ready          LLM readiness review (delegates to pdda-doc-ready.sh; opt-in via PDDA_LLM_BIN)
  catchup            LLM repo triage and ROUTER.md recommendations (delegates to pdda-catchup.sh)
  help               this message

Mode/format/path overrides come from the environment (PDDA_MODE, PDDA_FORMAT, PDDA_WORKING_DIR,
PDDA_ROADMAP, ...) and are documented in PROJECT/PDDA.md and utils/pdda/PDDA-INSTALL.md.
USAGE
}

cmd="${1:-run}"
[ "$#" -gt 0 ] && shift
case "$cmd" in
  run)              cmd_run; exit "$?" ;;
  frontmatter)      check_frontmatter; exit "$?" ;;
  status-table)     check_status_table; exit "$?" ;;
  hardcoded-paths)  check_hardcoded_paths; exit "$?" ;;
  roadmap)          check_roadmap; exit "$?" ;;
  roadmap-coverage) check_roadmap_coverage; exit "$?" ;;
  changelog)        check_changelog; exit "$?" ;;
  stale)            check_stale; exit "$?" ;;
  issue-doc-sync)   check_issue_doc_sync; exit "$?" ;;
  gh-refresh)       exec "$HERE/pdda-gh-refresh.sh" "$@" ;;
  doc-ready)        exec "$HERE/pdda-doc-ready.sh" "$@" ;;
  catchup)          exec "$HERE/pdda-catchup.sh" "$@" ;;
  help|-h|--help)   pdda_usage; exit 0 ;;
  *)                printf 'pdda.sh: unknown command %q\n\n' "$cmd" >&2; pdda_usage >&2; exit 2 ;;
esac
