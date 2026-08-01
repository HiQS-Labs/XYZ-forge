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
#   pdda.sh issue-doc-sync
#   pdda.sh governance          # repo-root governance-doc cross-reference + doc/code drift
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
# B2. quad-concepts (OPT-IN) — a "## Quad Concepts" section of 1..4 bullets for glance orientation.
# Structure-only by design: it checks the section EXISTS and has 1..4 bullets. Whether the bullets are
# good pain->fix concepts is a judgment left to the LLM readiness rubric (pdda-doc-ready.sh), not a
# brittle regex. Runs over the quad scope (2-WORKING + 1-INBOX/GH-* + 3-COMPLETED); a doc opts out with
# `quad_exempt: true`. Joins `run` only when the .pdda-quad / PDDA_QUAD lever is enabled (see cmd_run).
# ------------------------------------------------------------------------------------------------
check_quad_concepts() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-quad-concepts" rc=0
  local file n

  while IFS= read -r file; do
    # per-doc escape hatch (mirrors roadmap_exempt)
    pdda_frontmatter_true "$file" "quad_exempt" && continue

    # Bullet count of the first "## Quad Concepts" section via the shared parser (pdda_quad_section:
    # line 1 is the count, -1 if absent). See pdda-lib.sh for the boundary/fence/CRLF rules.
    n="$(pdda_quad_section "$file" | sed -n '1p')"
    # guard against an empty capture (unreadable file) so the numeric comparisons never see an empty operand.
    case "$n" in ''|*[!0-9-]*) n="-1" ;; esac

    if [ "$n" = "-1" ]; then
      pdda_record_finding error "$CHECK_NAME" "$file" 1 "missing '## Quad Concepts' section (add 1-4 pain->fix bullets, or set quad_exempt: true)" "add-quad-concepts"
      rc=1
    elif [ "$n" -eq 0 ]; then
      pdda_record_finding error "$CHECK_NAME" "$file" 1 "'## Quad Concepts' section has no bullets (need 1-4)" "fill-quad-concepts"
      rc=1
    elif [ "$n" -gt 4 ]; then
      pdda_record_finding error "$CHECK_NAME" "$file" 1 "'## Quad Concepts' has $n bullets (max 4 — keep it glanceable)" "trim-quad-concepts"
      rc=1
    fi
  done < <(pdda_list_quad_docs)

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

  cl_line="$(grep -Em1 '^##[[:space:]]+(\[[^][]*\][[:space:]]*[-–][[:space:]]*)?[0-9]{4}-[0-9]{2}-[0-9]{2}' "$PDDA_CHANGELOG" 2>/dev/null || true)"
  cl_date="$(printf '%s' "$cl_line" | grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"

  if [ -z "$cl_date" ] || ! pdda_is_real_date "$cl_date"; then
    pdda_record_finding warn "$CHECK_NAME" "$PDDA_CHANGELOG" 1 \
      "no dated '## YYYY-MM-DD' or '## [x.y.z] - YYYY-MM-DD' entry at the top of CHANGELOG.md — add an end-of-iteration entry" "add-dated-entry"
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
      if command -v gh >/dev/null 2>&1 && out="$(_pdda_gh_state_table)" && [ -n "$out" ]; then
        # Persist what we just fetched (GH-27). The Stop hook reads this file with
        # PDDA_ISSUE_SYNC_SOURCE=cache and makes no network call; with no writer on this path the cache
        # never existed, so the hook reported "all clear" over real drift. Best-effort: a failed cache
        # write must never break a lookup that already has its answer.
        pdda_write_gh_state_cache "$out" || :
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

# Explicit hand-off phrases anywhere in a status line. The lead-word test above is deliberately narrow
# (so "Phase 0 complete" mid-sentence never false-flags), but it is defeated by a self-contradictory
# status such as `Active — Phases 1-4 complete … Ready to close to 3-COMPLETED.` — every human reads
# that as done; the parser reads "active" and stops (GH-27 leak 2).
#
# These phrases are unambiguous operator hand-offs, not incidental progress notes. Matching is on the
# whole status, case-insensitively. Keep the list short and literal: a general "does this prose mean
# done?" parse is exactly the false-positive machine the lead-word anchor was built to avoid.
PDDA_STATUS_HANDOFF_PHRASES="ready to close|ready for 3-completed|ready to move to 3-completed|awaiting close"
_pdda_status_declares_handoff() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | grep -Eq "$PDDA_STATUS_HANDOFF_PHRASES"
}

check_issue_doc_sync() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-issue-doc-sync" rc=0
  local table file num state status_val leadword target rel_target

  table="$(_pdda_issue_state_table)"

  # --- (1) active plans: PROJECT/2-WORKING ---------------------------------------------------------
  while IFS= read -r file; do
    num="$(_pdda_doc_issue_number "$file")"
    # A doc with no `gh_issue:` is not issue-tracked; there is nothing to reconcile it against.
    # Deliberately NOT a finding: warning here would fire on every untracked plan doc in every
    # installed target on the first run — the exact self-inflicted-noise failure GH-15 fixed. Making
    # untracked plans declare themselves is worth doing behind an opt-in lever, not by default.
    [ -n "$num" ] || continue

    state="$(printf '%s\n' "$table" | awk -F'\t' -v n="$num" '$1 == n { print toupper($2); exit }')"
    if [ -z "$state" ]; then
      # A check that could not run is NOT a check that passed. Warn, so `run` and the Stop hook say so.
      pdda_record_finding warn "$CHECK_NAME" "$file" 1 \
        "issue #$num state unavailable (gh absent/offline and no cached state) — sync NOT evaluated; run: utils/pdda/pdda.sh gh-refresh" \
        "state-unavailable"
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

    # Direction (b): doc declares itself done while the issue is still OPEN. Two signals:
    #   - the status LEAD WORD is terminal ("Shipped — …")
    #   - or the status carries an explicit hand-off phrase anywhere ("Active — … Ready to close")
    # The second exists because the first is defeated by a self-contradictory status (GH-27 leak 2).
    status_val="$(pdda_trim "$(pdda_frontmatter_value "$file" status)")"
    leadword="$(_pdda_status_leadword "$status_val")"
    if [ -n "$leadword" ] && _pdda_is_terminal_word "$leadword"; then
      pdda_record_finding warn "$CHECK_NAME" "$file" 1 \
        "doc status reads '$leadword' (done) but issue #$num is still OPEN — close the issue or correct the status" \
        "reconcile-status"
    elif _pdda_status_declares_handoff "$status_val"; then
      pdda_record_finding warn "$CHECK_NAME" "$file" 1 \
        "doc status declares it is ready to close but issue #$num is still OPEN — recommend: git mv to 3-COMPLETED, then gh issue close $num" \
        "reconcile-status"
    fi
  done < <(pdda_list_working_docs)

  # --- (2) completed plans: PROJECT/3-COMPLETED ----------------------------------------------------
  # A doc that reached 3-COMPLETED IS the operator's assertion that the work is done — recorded in a
  # path, not in prose. A still-OPEN issue behind it is drift. Without this pass the check stops
  # watching a doc at the exact moment it completes, so the `git mv` recommended above is what blinds
  # it (GH-27 leak 1).
  while IFS= read -r file; do
    num="$(_pdda_doc_issue_number "$file")"
    [ -n "$num" ] || continue            # completed docs need not be issue-tracked; nothing to reconcile

    state="$(printf '%s\n' "$table" | awk -F'\t' -v n="$num" '$1 == n { print toupper($2); exit }')"
    if [ -z "$state" ]; then
      pdda_record_finding warn "$CHECK_NAME" "$file" 1 \
        "issue #$num state unavailable (gh absent/offline and no cached state) — sync NOT evaluated; run: utils/pdda/pdda.sh gh-refresh" \
        "state-unavailable"
      continue
    fi

    if [ "$state" = "OPEN" ]; then
      pdda_record_finding warn "$CHECK_NAME" "$file" 1 \
        "doc is in 3-COMPLETED but issue #$num is still OPEN — recommend: gh issue close $num" \
        "close-issue"
    fi
    # state=CLOSED in 3-COMPLETED is the fully reconciled end state: no finding.
  done < <(pdda_list_completed_docs)

  pdda_emit_summary "$CHECK_NAME" "$rc"
  return "$(pdda_gated_exit "$rc")"
}

# ------------------------------------------------------------------------------------------------
# J. releases (warn-only nudge; never blocks, even in full)
# ------------------------------------------------------------------------------------------------
# Validates RELEASES.md, the single forward-looking release-planning ledger (see PROJECT/PDDA.md
# "RELEASES.md — release ledger"). Deliberately light: this replaced a heavier per-tag-doc lifecycle
# (status Draft/RC/Published, linked marathons, linked issues, a GitHub release-tag cache) that
# proved like too much data to keep current for an initial release. Grows only as real need shows up.
#   (1) error — a "Release:" block has an empty version
#   (2) warn  — Target Date is set but not a valid YYYY-MM-DD date
#   (3) warn  — Target Date has passed and GH_URL is still empty (looks overdue/unshipped)
#   (4) warn  — Iterations is set but isn't a well-formed "<lo>-<hi>" version band
#   (5) warn  — a block's version falls inside another block's reserved Iterations band
check_releases() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-releases" rc=0
  local RELEASES_FILE_EFF="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
  local release status target_date codename description gh_url line_no target_epoch today_epoch
  local status_lc front_door shakedown license_file qa_field qa_label qa_value qa_value_lc
  local iterations milestone rows bands="" band_release band_lo band_hi band_line release_trimmed

  if [ ! -f "$RELEASES_FILE_EFF" ]; then
    pdda_record_finding info "$CHECK_NAME" "$RELEASES_FILE_EFF" 0 \
      "RELEASES.md not found — nothing to check" "skip"
    pdda_emit_summary "$CHECK_NAME" 0
    return "$(pdda_gated_exit 0)"
  fi

  # A ledger with no blocks at all (header-only, or empty) is a VALID state under this contract —
  # sparse is fine — so it reports exactly as clean as it did before this field pair existed. The
  # guard exists because the here-doc loops below would otherwise see one empty line and fake a
  # "block near line 0 has no version" error; it deliberately records NO finding of its own.
  rows="$(pdda_releases_list "$RELEASES_FILE_EFF")"
  if [ -z "$rows" ]; then
    pdda_emit_summary "$CHECK_NAME" 0
    return "$(pdda_gated_exit 0)"
  fi

  # Pass 1 — validate each Iterations band and remember the well-formed ones. A band reserves patch
  # numbers that deliberately never get their own block (PROJECT/PDDA.md "RELEASES.md — release
  # ledger"), which is what lets pass 2 test the admission rule mechanically instead of rhetorically.
  while IFS=$'\037' read -r release status target_date codename description gh_url \
    front_door shakedown license_file iterations milestone line_no; do
    iterations="$(pdda_trim "$iterations")"
    [ -n "$iterations" ] || continue
    if pdda_is_iteration_band "$iterations"; then
      bands="${bands}${release}"$'\037'"${iterations%%-*}"$'\037'"${iterations#*-}"$'\037'"${line_no}"$'\n'
    else
      pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
        "release '$release' Iterations '$iterations' is not a valid <lo>-<hi> version band (e.g. 0.2.0-0.2.4)" \
        "fix-iterations-band"
    fi
  done <<EOF
$rows
EOF

  while IFS=$'\037' read -r release status target_date codename description gh_url \
    front_door shakedown license_file iterations milestone line_no; do
    if [ -z "$(pdda_trim "$release")" ]; then
      pdda_record_finding error "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
        "a 'Release:' block near line $line_no has no version" "fix-release-value"
      rc=1
      continue
    fi

    # Admission rule, made mechanical: a version inside another block's reserved band is already
    # accounted for by that band, so a second block for it is by definition a duplicate. Only plain
    # dotted-numeric versions are testable this way; anything else is left to human judgment.
    #
    # A band's OWNER is inside its own band by construction (0.2.0 owns 0.2.0-0.2.4), so it must not
    # flag itself. Identity is the block's LINE, not its version text: comparing versions would let a
    # second, genuinely duplicate `Release: 0.2.0` block hide behind the owner's identical value —
    # exactly the case the check exists to catch.
    release_trimmed="$(pdda_trim "$release")"
    if pdda_is_dotted_version "$release_trimmed"; then
      while IFS=$'\037' read -r band_release band_lo band_hi band_line; do
        [ -n "$band_release" ] || continue
        [ "$band_line" != "$line_no" ] || continue
        [ "$(pdda_vercmp "$release_trimmed" "$band_lo")" != "-1" ] || continue
        [ "$(pdda_vercmp "$release_trimmed" "$band_hi")" != "1" ] || continue
        pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
          "release '$release_trimmed' is inside the Iterations band $band_lo-$band_hi reserved by release '$(pdda_trim "$band_release")' (line $band_line) — already accounted for; record it in CHANGELOG.md instead of giving it a block" \
          "in-band-release-block"
      done <<EOF
$bands
EOF
    fi

    # Front-door reviewed / Shakedown reviewed / License file: optional pre-release QA-gate
    # checkboxes, warn-only Yes/No like the rest of this check (see PROJECT/PDDA.md "RELEASES.md
    # — release ledger"). A blank value is fine (not yet answered); only a set-but-invalid value warns.
    for qa_field in "Front-door reviewed:$front_door" "Shakedown reviewed:$shakedown" "License file:$license_file"; do
      qa_label="${qa_field%%:*}"
      qa_value="$(pdda_trim "${qa_field#*:}")"
      [ -n "$qa_value" ] || continue
      qa_value_lc="$(printf '%s' "$qa_value" | tr '[:upper:]' '[:lower:]')"
      case "$qa_value_lc" in
        yes | no) ;;
        *) pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
             "release '$release' $qa_label value '$qa_value' is not exactly Yes or No" "fix-release-yesno-field" ;;
      esac
    done

    [ -n "$target_date" ] || continue

    if ! pdda_is_real_date "$target_date"; then
      pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
        "release '$release' Target Date '$target_date' is not a valid YYYY-MM-DD date" \
        "fix-target-date"
      continue
    fi

    # Status: Shipped is the sole "already shipped" signal (GH_URL only means a Release object
    # exists — draft or published — not that the release is out; see PROJECT/PDDA.md "RELEASES.md
    # — release ledger"). A populated GH_URL alone no longer skips this check.
    status_lc="$(printf '%s' "$(pdda_trim "$status")" | tr '[:upper:]' '[:lower:]')"
    [ "$status_lc" != "shipped" ] || continue

    # _pdda_cl_epoch is the changelog check's date->epoch helper, portable BSD/GNU; reused here
    # rather than duplicating the date-parsing logic for a second date-comparison check.
    target_epoch="$(_pdda_cl_epoch "$target_date")"
    today_epoch="$(_pdda_cl_epoch "$(pdda_today)")"
    if [ -n "$target_epoch" ] && [ -n "$today_epoch" ] && [ "$target_epoch" -lt "$today_epoch" ]; then
      pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
        "release '$release' Target Date '$target_date' has passed and Status isn't Shipped — overdue" \
        "overdue-release"
    fi
  done <<EOF
$rows
EOF

  pdda_emit_summary "$CHECK_NAME" "$rc"
  # Warn-only in spirit — never blocks, even in full mode (see PROJECT/PDDA.md section J). The one
  # error above is a malformed-doc guard, surfaced loudly, but deliberately never gates the exit code.
  return "$(pdda_gated_exit 0)"
}

# ------------------------------------------------------------------------------------------------
# releases-current (read-only roll-up; not part of PDDA_DETERMINISTIC_CHECKS — no findings, no gate)
# ------------------------------------------------------------------------------------------------
# A rough, non-authoritative answer to "what release is in progress right now" — for a human, or for
# another repo's tooling (e.g. the XYZ sibling harness) to shell out to rather than re-implementing
# RELEASES.md parsing itself. Lists every release whose Status is empty or not "Shipped" (Status is
# free-text and unvalidated, so this is a best-effort filter, not a gate — see PROJECT/PDDA.md).
cmd_releases_current() {
  local RELEASES_FILE_EFF="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
  local release status target_date codename description gh_url line_no status_lc any=0
  local front_door shakedown license_file iterations milestone

  if [ ! -f "$RELEASES_FILE_EFF" ]; then
    printf '%s not found — nothing to report\n' "$(pdda_relpath "$RELEASES_FILE_EFF")"
    return 0
  fi

  printf 'PDDA releases-current — in-progress entries in %s\n' "$(pdda_relpath "$RELEASES_FILE_EFF")"
  while IFS=$'\037' read -r release status target_date codename description gh_url \
    front_door shakedown license_file iterations milestone line_no; do
    [ -n "$(pdda_trim "$release")" ] || continue
    status_lc="$(printf '%s' "$(pdda_trim "$status")" | tr '[:upper:]' '[:lower:]')"
    [ "$status_lc" != "shipped" ] || continue

    any=1
    printf '\n• %s' "$release"
    [ -n "$codename" ] && printf ' (%s)' "$codename"
    printf ' — %s\n' "${status:-no Status set}"
    [ -n "$iterations" ] && printf '    Iterations: %s (reserved; these ship without their own block)\n' "$iterations"
    [ -n "$target_date" ] && printf '    Target Date: %s\n' "$target_date"
    [ -n "$milestone" ] && printf '    Milestone: %s\n' "$milestone"
    [ -n "$description" ] && printf '    %s\n' "$description"
    [ -n "$gh_url" ] && printf '    %s\n' "$gh_url"
  done < <(pdda_releases_list "$RELEASES_FILE_EFF")

  [ "$any" -eq 1 ] || printf '\n(no in-progress releases — every entry is Status: Shipped)\n'
  return 0
}
# ------------------------------------------------------------------------------------------------
# Targets the small, curated "read this to understand the repo's rules" doc set (ROUTER.md, AGENTS.md,
# GUIDING-PRINCIPLES.md, README.md, CLAUDE.md, PROJECT/PDDA.md, utils/pdda/PDDA-INSTALL.md) — not every
# markdown file in the tree (PROJECT/** plan docs have their own checks above). CLAUDE.md is in the
# default set because many installs carry one at the repo root beside AGENTS.md; a repo without one
# (like this one) just has it silently skipped. Override the set via PDDA_GOVERNANCE_DOCS
# (space-separated, repo-relative) and the index doc via PDDA_GOVERNANCE_INDEX (default ROUTER.md).
PDDA_GOVERNANCE_DOCS_DEFAULT="ROUTER.md AGENTS.md GUIDING-PRINCIPLES.md README.md CLAUDE.md PROJECT/PDDA.md utils/pdda/PDDA-INSTALL.md"
PDDA_GOVERNANCE_INDEX_DEFAULT="ROUTER.md"

# GH-15: two of the docs above (utils/pdda/PDDA-INSTALL.md, PROJECT/PDDA.md) are themselves shipped to
# every target install, but legitimately reference files install.sh deliberately does NOT copy there —
# the target's own repo-authored startup docs, canonical-only skill/companion-doc paths, and the pre-utils/pdda/
# legacy layout path. A fresh `install.sh . --mode observe` self-inflicted ~30 dead-reference/env-var
# warns from this exact mismatch on first run, drowning the target's own drift signal in PDDA-on-PDDA
# noise. This manifest was built from an actual dead-reference scan of a bare `install.sh` target
# (not retyped from the issue's illustrative list), so it matches real warns, not guesses. Scoped ONLY
# to the shipped docs named below — a repo-authored governance doc (this canonical repo's own ROUTER.md,
# AGENTS.md, ...) referencing one of these is still a real dead-reference bug and stays flagged.
#
# GH-23 P3 widened the scan from .md to .sh, which grew this manifest along three axes. Each entry was
# read off an actual scan of a bare `install.sh <scratch> --with-startup-docs` target, same method as
# above — 46 warns before, 0 after:
#   - canonical-only TOOLS a target never receives: install.sh (targets are installed, not installers),
#     the sync engine (excluded by pdda-sync-manifest.conf: targets are leaf nodes), templates/, test/.
#   - LEGACY flat-layout paths (utils/pdda.sh, ...) that PDDA-INSTALL.md names precisely BECAUSE they
#     must not exist — it is documenting the layout install.sh migrates away from. Their .md sibling
#     (utils/PDDA-INSTALL.md) was already exempt for this reason; the .sh ones only surfaced once the
#     suffix widened.
#   - config.sh, which belongs to git-pulse, a separate program. It is not ours and never will be here.
PDDA_GOV_SHIPPED_DOCS_DEFAULT="utils/pdda/PDDA-INSTALL.md PROJECT/PDDA.md"
PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS_DEFAULT="ROUTER.md AGENTS.md GUIDING-PRINCIPLES.md README.md CLAUDE.md .claude/skills/pdda/SKILL.md .claude/skills/governance-audit/SKILL.md .claude/skills/release/SKILL.md PROJECT/3-COMPLETED/PDDA-SYNC-TO-OTHER-REPOS.md utils/PDDA-INSTALL.md install.sh templates/ROUTER.target.md test/pdda-doc-health-hooks.sh pdda-sync.sh utils/pdda/pdda-sync.sh utils/pdda/pdda-manifest.sh utils/pdda.sh utils/pdda-lib.sh utils/pdda-doc-ready.sh utils/pdda-catchup.sh config.sh"
PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS_DEFAULT="PDDA_REGISTRY PDDA_GITPULSE_DIR PDDA_SYNC_MAX_SHRINK"

# Print "<line>\t<text>" for lines outside an exempt fence/blockquote — same carve-out convention as
# check_hardcoded_paths (fenced console/text/transcript blocks and blockquotes are not scanned).
_pdda_gov_scannable_lines() {
  awk '
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
    /^[[:space:]]*>/ { next }
    { print NR "\t" $0 }
  ' "$1"
}

# Extract candidate file references from one line. Three patterns, unioned then deduplicated:
#
#   (a) markdown-link targets       `](target.md)`  `](target.sh)`   optionally carrying a `#anchor`
#   (b) whole-span code refs        `` `target.md` ``  `` `target.sh` ``
#   (c) command-position paths      a *.sh token opening a code span or a scanned fence line
#
# Why (c) exists (GH-23). A router's most load-bearing references are the commands it tells an agent to
# run, and those never look like (a) or (b): they carry arguments. `` `.xyz/utils/marathon-plan.sh
# --help` `` and a bare `utils/pdda/pdda-sync.sh push` inside a ```bash fence both name a real file, yet
# neither closes its span right after the suffix. A router can therefore point every agent at a script
# that does not exist and no check would ever see it — which is exactly how the LTVera-Pandas install
# shipped a router full of scripts its target never received.
#
# Scope of (c) is deliberately narrow: the token must open the span or the line, which is where a shell
# command's *program* sits. A `.sh` word later in a sentence is prose, not a path claim. That keeps
# `` `pdda.sh run` `` from being read as two refs while still resolving `pdda.sh` itself.
#
# A leading `./` is stripped from (c): in command position `./install.sh` means "relative to the repo
# root I am standing in", not "relative to the doc that mentions it". Left intact, it would resolve
# against the referencing doc's directory and report a phantom dead ref for a script that plainly exists.
#
# Pattern (c) ends at whitespace, a backtick, end-of-line, or one of `,;:)"'` — the punctuation a command
# is written against in prose ("run x.sh, then y") or in a fence ("x.sh; y.sh"). A trailing `.` is
# deliberately NOT a terminator: it cannot be told apart from a suffix, and `deploy.sh.bak` would be
# extracted as `deploy.sh`. A sentence ending in a bare command name is the rarer case; a false flag on a
# real backup file is the worse one.
#
# Anchor-only links never match (no suffix) — this check validates file existence, not heading anchors.
# A bare `GH-<n>-*.md` name is filtered out: those are illustrative instances of the issue-doc naming
# convention (PDDA.md's own examples), not fixed cross-references to a real file.
#
# KNOWN GAP: an interpreter-wrapped invocation (`bash utils/x.sh`, `sudo ./x.sh`) still names a real path
# but the .sh sits in argument position, so (c) skips it. Closing it needs an interpreter allowlist plus
# negative controls (`bash -c "..."` must not flag); tracked separately rather than guessed at here.
_pdda_gov_extract_refs() {
  local text="$1"
  { printf '%s\n' "$text" \
      | grep -oE '\]\([^)[:space:]]+\.(md|sh)(#[A-Za-z0-9_-]*)?\)' \
      | sed -E 's/^\]\(//; s/\)$//'
    printf '%s\n' "$text" \
      | grep -oE '`[A-Za-z0-9_./-]+\.(md|sh)(#[A-Za-z0-9_-]*)?`' \
      | sed -E 's/^`//; s/`$//'
    printf '%s\n' "$text" \
      | grep -oE '(^|`)[[:space:]]*(\.{1,2}/)?[A-Za-z0-9_.][A-Za-z0-9_./-]*\.sh([[:space:]`,;:)"'"'"']|$)' \
      | sed -E 's/^`//; s/^[[:space:]]+//; s/[[:space:]`,;:)"'"'"']+$//; s|^\./||'
    # (d) interpreter-wrapped invocation: `bash x.sh`, `sudo ./x.sh`, `sh setup.sh`, `env FOO=1 ./x.sh`.
    # When a script is handed to an interpreter it leaves PROGRAM position (which (c) keys on) for
    # ARGUMENT position and (c) goes blind. An explicit allowlist of transparent wrappers — sudo, env
    # (with VAR=val assignments), and the interpreters bash/sh/zsh/source/. — is stripped to recover the
    # path. The leading char class rejects `-` (so `bash -c` is not a path) and `"`/`$` (so a quoted or
    # variable-expanded argument is never mistaken for a path claim). GH-33.
    printf '%s\n' "$text" \
      | grep -oE '(^|`)[[:space:]]*((sudo|source|bash|zsh|env|sh|\.)([[:space:]]+[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*)*[[:space:]]+)+(\.{1,2}/)?[A-Za-z0-9_.][A-Za-z0-9_./-]*\.sh([[:space:]`,;:)"'"'"']|$)' \
      | sed -E 's/^`//; s/^[[:space:]]+//; s/^((sudo|source|bash|zsh|env|sh|\.)([[:space:]]+[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*)*[[:space:]]+)+//; s/[[:space:]`,;:)"'"'"']+$//; s|^\./||'
  } | grep -Ev '(^|/)GH-[0-9]+-[^/]*\.md(#.*)?$' | LC_ALL=C sort -u
}

# Resolve a raw ref (its #anchor stripped) against repo root or the referencing file's directory.
# Prints nothing (and returns non-zero) for an external URL — the caller then skips it. A bare
# filename (no directory component) that doesn't resolve at its expected spot falls back to a
# repo-wide basename search — bare mentions (e.g. "blank.md", used generically across four lifecycle
# folders) aren't precise path claims, so only a filename absent everywhere counts as truly dead. A
# ref WITH a directory component stays a precise claim: if that exact path is wrong, that IS the bug
# (e.g. a doc pointing at PROJECT/2-WORKING/X.md after X.md was completed and moved to 3-COMPLETED/).
# Escape a literal string so it can be handed to `find -name` without being read as a glob pattern
# (backslash and the four fnmatch metacharacters). Used only for GH-34-safe bare-filename lookups.
_pdda_gov_glob_escape() {
  local s="$1" out="" i c
  for (( i = 0; i < ${#s}; i++ )); do
    c="${s:i:1}"
    case "$c" in
      '\'|'*'|'?'|'['|']') out+="\\$c" ;;
      *) out+="$c" ;;
    esac
  done
  printf '%s' "$out"
}

# Derive a bare name's cache key (a checksum of the name; collisions are possible and handled by the
# caller, which always verifies the stored name before trusting the stored path).
_pdda_gov_cache_key() {
  printf '%s' "$1" | cksum | awk '{print $1}'
}

_pdda_gov_resolve_ref() {
  local ref="$1" from_dir="$2" cache_dir="${3:-}" path candidate found p esc key name_file path_file cached_name cache_hit
  path="${ref%%#*}"
  case "$path" in
    http://*|https://*|//*) return 1 ;;
    /*) candidate="$PDDA_REPO_ROOT$path" ;;
    ./*|../*) candidate="$from_dir/$path" ;;
    */*) candidate="$PDDA_REPO_ROOT/$path" ;;
    *)
      candidate="$PDDA_REPO_ROOT/$path"
      if [ ! -f "$candidate" ]; then
        found=""
        cache_hit=0
        if [ -n "$cache_dir" ] && [ -d "$cache_dir" ]; then
          # GH-48 (round 4): check_governance already ran ONE whole-tree `find` for every unique bare
          # name across the whole run and populated this cache — a pure read here, no traversal. Each
          # entry is TWO files (the verbatim looked-up name + its resolved path/"-" sentinel), never one
          # file with an internal delimiter — the cache key is a 32-bit checksum, which *can* collide
          # for two different names, and a delimiter-based format would then either merge or corrupt
          # both entries. Two whole-file reads instead: read the stored name back and compare it to
          # `$path` before trusting the stored path.
          key="$(_pdda_gov_cache_key "$path")"
          name_file="$cache_dir/$key.name"
          path_file="$cache_dir/$key.path"
          if [ -f "$name_file" ]; then
            cached_name="$(cat "$name_file" 2>/dev/null)"
            if [ "$cached_name" = "$path" ]; then
              found="$(cat "$path_file" 2>/dev/null)"
              [ "$found" = "-" ] && found=""
              cache_hit=1
            fi
            # else: a genuine collision (this key's slot holds a DIFFERENT name) — fall through to the
            # single-name scan below rather than treating $path as confirmed-dead. Round 4 review caught
            # that the previous version stopped here and silently reported a real, colliding file dead.
          fi
        fi
        if [ "$cache_hit" != "1" ]; then
          # Either no usable batch cache (mktemp/find failed building it, check_governance didn't build
          # one, or this specific key collided with a different name) — fall back to a single-name
          # `find` so `$path` still resolves correctly. Slower than the batch cache for this one name,
          # but correctness-preserving; the batch cache is what the speed fix actually relies on for the
          # common (no collision, cache built fine) case. `$path` is glob-escaped (GH-34) so it still
          # can't be misread as a pattern, and no `-type` filter is applied (first traversal match wins,
          # any type — see check_governance's batch build for the full rationale, identical here).
          esc="$(_pdda_gov_glob_escape "$path")"
          found=""
          while IFS= read -r -d '' p; do
            found="$p"; break
          done < <(find "$PDDA_REPO_ROOT" -not -path '*/.git/*' -name "$esc" -print0 2>/dev/null)
        fi
        [ -n "$found" ] && candidate="$found"
      fi
      ;;
  esac
  printf '%s\n' "$candidate"
}

check_governance() {
  pdda_reset_counts
  local CHECK_NAME="pdda-check-governance" rc=0
  local docs="${PDDA_GOVERNANCE_DOCS:-$PDDA_GOVERNANCE_DOCS_DEFAULT}"
  local index_doc="${PDDA_GOVERNANCE_INDEX:-$PDDA_GOVERNANCE_INDEX_DEFAULT}"
  local shipped_docs="${PDDA_GOV_SHIPPED_DOCS:-$PDDA_GOV_SHIPPED_DOCS_DEFAULT}"
  local ref_exempt="${PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS:-$PDDA_GOV_SHIPPED_DOC_REF_EXEMPTIONS_DEFAULT}"
  local envvar_exempt="${PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS:-$PDDA_GOV_SHIPPED_DOC_ENVVAR_EXEMPTIONS_DEFAULT}"
  local doc file abs_file from_dir line_no text ref resolved base var line
  local present_docs="" index_abs is_shipped_doc ref_path

  for doc in $docs; do
    [ -f "$PDDA_REPO_ROOT/$doc" ] && present_docs="$present_docs $doc"
  done

  if [ -z "$(pdda_trim "$present_docs")" ]; then
    pdda_record_finding info "$CHECK_NAME" "$PDDA_REPO_ROOT" 0 \
      "no governance docs found in the configured set ($docs)" "skip"
    pdda_emit_summary "$CHECK_NAME" 0
    return "$(pdda_gated_exit 0)"
  fi

  # --- (1) dead references: every .md ref in a governance doc must resolve to a real file ---------
  # warn-only: markdown-reference extraction from free-form prose is inherently more heuristic than
  # the mechanical checks above (frontmatter, status-table), so a false flag costs one ignorable line
  # rather than blocking a build even in full mode — same calibration as check_stale/check_changelog.
  # GH-48 (round 4): batch-resolve every unique bare (no-directory-component) reference across ALL
  # scanned docs in exactly ONE whole-tree `find` call, before doing anything else — the DoD is one
  # traversal per check_governance run, not one per unique name (a per-name `find`, even memoized,
  # still multiplies with the number of DISTINCT dead names on a doc set with many different missing
  # bare mentions). Pass 1 below just extracts and collects candidate names (cheap text processing on
  # a handful of small governance docs — re-running it is not the expensive part, the tree walk is);
  # pass 2, further down, is the existing per-ref loop, unchanged except it now reads a fully-populated
  # cache instead of resolving anything itself.
  local gov_ref_cache_dir="" gov_names_file="" gov_uniq_names_file=""
  local gov_find_args gov_name gov_p gov_bn gov_key
  gov_ref_cache_dir="$(mktemp -d 2>/dev/null || true)"
  if [ -n "$gov_ref_cache_dir" ]; then
    gov_names_file="$(mktemp 2>/dev/null || true)"
    if [ -n "$gov_names_file" ]; then
      for doc in $present_docs; do
        abs_file="$PDDA_REPO_ROOT/$doc"
        is_shipped_doc=0
        case " $shipped_docs " in *" $doc "*) is_shipped_doc=1 ;; esac
        while IFS=$'\t' read -r line_no text; do
          [ -n "$line_no" ] || continue
          while IFS= read -r ref; do
            [ -n "$ref" ] || continue
            if [ "$is_shipped_doc" -eq 1 ]; then
              ref_path="${ref%%#*}"
              while :; do
                case "$ref_path" in
                  ../*) ref_path="${ref_path#../}" ;;
                  ./*) ref_path="${ref_path#./}" ;;
                  *) break ;;
                esac
              done
              case " $ref_exempt " in *" $ref_path "*) continue ;; esac
            fi
            case "$ref" in
              http://*|https://*|//*|/*|./*|../*|*/*) continue ;;   # not a bare-name fallback candidate
            esac
            ref_path="${ref%%#*}"
            [ -f "$PDDA_REPO_ROOT/$ref_path" ] && continue          # resolves directly, no lookup needed
            printf '%s\n' "$ref_path" >> "$gov_names_file"
          done <<< "$(_pdda_gov_extract_refs "$text")"
        done < <(_pdda_gov_scannable_lines "$abs_file")
      done
      if [ -s "$gov_names_file" ]; then
        gov_uniq_names_file="$(mktemp 2>/dev/null || true)"
        if [ -n "$gov_uniq_names_file" ]; then
          LC_ALL=C sort -u "$gov_names_file" > "$gov_uniq_names_file"
          gov_find_args=()
          while IFS= read -r gov_name; do
            [ -n "$gov_name" ] || continue
            [ ${#gov_find_args[@]} -gt 0 ] && gov_find_args+=(-o)
            gov_find_args+=(-name "$(_pdda_gov_glob_escape "$gov_name")")
          done < "$gov_uniq_names_file"
          if [ ${#gov_find_args[@]} -gt 0 ]; then
            while IFS= read -r -d '' gov_p; do
              gov_bn="${gov_p##*/}"
              gov_key="$(_pdda_gov_cache_key "$gov_bn")"
              [ -f "$gov_ref_cache_dir/$gov_key.name" ] && continue   # first traversal match wins
              printf '%s' "$gov_bn" > "$gov_ref_cache_dir/$gov_key.name"
              printf '%s' "$gov_p"  > "$gov_ref_cache_dir/$gov_key.path"
            done < <(find "$PDDA_REPO_ROOT" -not -path '*/.git/*' \( "${gov_find_args[@]}" \) -print0 2>/dev/null)
          fi
          # GH-48 (round 5 follow-up): `find` only ever reports MATCHES, so a genuinely dead name never
          # got a cache entry above — every confirmed-dead reference still re-triggered its own fallback
          # `find` in _pdda_gov_resolve_ref, the exact per-name traversal cost this fix exists to remove.
          # Second pass: any unique name still without an entry after the batch find truly has no match
          # anywhere (or lost a same-key collision to a different name, in which case it correctly falls
          # back on lookup regardless — same as a live colliding name) — cache it as a verified "-" miss
          # so a repeat mention of the same dead name doesn't re-scan either.
          while IFS= read -r gov_name; do
            [ -n "$gov_name" ] || continue
            gov_key="$(_pdda_gov_cache_key "$gov_name")"
            [ -f "$gov_ref_cache_dir/$gov_key.name" ] && continue
            printf '%s' "$gov_name" > "$gov_ref_cache_dir/$gov_key.name"
            printf '%s' "-"         > "$gov_ref_cache_dir/$gov_key.path"
          done < "$gov_uniq_names_file"
          rm -f "$gov_uniq_names_file"
        fi
      fi
      rm -f "$gov_names_file"
    fi
  fi
  for doc in $present_docs; do
    abs_file="$PDDA_REPO_ROOT/$doc"
    from_dir="$(dirname "$abs_file")"
    is_shipped_doc=0
    case " $shipped_docs " in *" $doc "*) is_shipped_doc=1 ;; esac
    while IFS=$'\t' read -r line_no text; do
      [ -n "$line_no" ] || continue
      while IFS= read -r ref; do
        [ -n "$ref" ] || continue
        if [ "$is_shipped_doc" -eq 1 ]; then
          # normalize away leading ./ or ../ so a relative mention (e.g. "../../PROJECT/3-COMPLETED/
          # PDDA-SYNC-TO-OTHER-REPOS.md") matches the same manifest entry as its repo-relative form
          ref_path="${ref%%#*}"
          while :; do
            case "$ref_path" in
              ../*) ref_path="${ref_path#../}" ;;
              ./*) ref_path="${ref_path#./}" ;;
              *) break ;;
            esac
          done
          case " $ref_exempt " in *" $ref_path "*) continue ;; esac
        fi
        resolved="$(_pdda_gov_resolve_ref "$ref" "$from_dir" "$gov_ref_cache_dir")" || continue
        [ -f "$resolved" ] && continue
        pdda_record_finding warn "$CHECK_NAME" "$abs_file" "$line_no" \
          "dead reference '$ref' — no file at $(pdda_relpath "$resolved")" "fix-dead-reference"
      done <<< "$(_pdda_gov_extract_refs "$text")"
    done < <(_pdda_gov_scannable_lines "$abs_file")
  done
  [ -n "$gov_ref_cache_dir" ] && rm -rf "$gov_ref_cache_dir"

  # --- (2) orphan governance docs: a present doc the index doc never points at --------------------
  index_abs="$PDDA_REPO_ROOT/$index_doc"
  if [ -f "$index_abs" ]; then
    for doc in $present_docs; do
      [ "$doc" = "$index_doc" ] && continue
      base="$(basename "$doc")"
      if ! grep -Fq "$base" "$index_abs"; then
        pdda_record_finding warn "$CHECK_NAME" "$PDDA_REPO_ROOT/$doc" 1 \
          "governance doc is not referenced anywhere in $index_doc — a cold agent following its read order won't discover it" \
          "add-index-pointer"
      fi
    done
  else
    pdda_record_finding info "$CHECK_NAME" "$index_abs" 0 \
      "governance index doc '$index_doc' not found; skipping orphan-doc check" "skip"
  fi

  # --- (3) subcommand drift: every pdda.sh dispatcher subcommand must be named in the index doc ---
  if [ -f "$index_abs" ]; then
    local subcommands sub
    subcommands="$(awk '
      /case "\$cmd" in/ { in_case = 1; next }
      in_case && /^esac/ { in_case = 0 }
      in_case && /^[[:space:]]*[A-Za-z*][A-Za-z0-9*_-]*(\|[A-Za-z0-9*_-]+)*\)/ {
        line = $0
        sub(/^[[:space:]]*/, "", line)
        sub(/\).*/, "", line)
        n = split(line, parts, "|")
        for (i = 1; i <= n; i++) print parts[i]
      }
    ' "$HERE/pdda.sh" | grep -Ev '^(run|help|-h|--help|\*)$' | LC_ALL=C sort -u)"

    for sub in $subcommands; do
      if ! grep -Eq "(^|[^A-Za-z0-9_-])${sub}([^A-Za-z0-9_-]|\$)" "$index_abs"; then
        pdda_record_finding error "$CHECK_NAME" "$index_abs" 1 \
          "pdda.sh subcommand '$sub' is not documented anywhere in $index_doc — keep the installer surface in lockstep (AGENTS.md #5)" \
          "document-subcommand"
        rc=1
      fi
    done
  fi

  # --- (4) env-var drift: a PDDA_* var named in a governance doc should exist in a shipped script ---
  # warn-only: PDDA_GOVERNANCE_INDEX_DEFAULT names ONLY the files a target install actually receives
  # (utils/pdda/*.sh + install.sh). PDDA-INSTALL.md itself ships to every target but also documents
  # utils/pdda/pdda-sync.sh (a canonical-only tool never copied to targets, per its own "Canonical install
  # set" list) — so a var like PDDA_SYNC_BACKUPS legitimately mentioned there will never resolve in a
  # target install. That's expected, not drift, so a false flag must cost one ignorable line, not a
  # blocked build (same calibration as the dead-reference check above).
  local shipped_vars doc_vars install_sh
  install_sh="$PDDA_REPO_ROOT/install.sh"
  shipped_vars="$(grep -ohE 'PDDA_[A-Z0-9_]+' "$HERE"/*.sh "$install_sh" 2>/dev/null | LC_ALL=C sort -u)"
  for doc in $present_docs; do
    abs_file="$PDDA_REPO_ROOT/$doc"
    is_shipped_doc=0
    case " $shipped_docs " in *" $doc "*) is_shipped_doc=1 ;; esac
    doc_vars="$(grep -ohE 'PDDA_[A-Z0-9_]+' "$abs_file" | LC_ALL=C sort -u)"
    for var in $doc_vars; do
      if [ "$is_shipped_doc" -eq 1 ]; then
        case " $envvar_exempt " in *" $var "*) continue ;; esac
      fi
      if ! printf '%s\n' "$shipped_vars" | grep -Fxq "$var"; then
        line="$(grep -nF "$var" "$abs_file" | head -1 | cut -d: -f1)"
        pdda_record_finding warn "$CHECK_NAME" "$abs_file" "${line:-1}" \
          "governance doc references env var '$var' which no shipped script in this install reads or sets" \
          "remove-or-implement-envvar"
      fi
    done
  done

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
pdda-check-releases:check_releases
pdda-check-governance:check_governance
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

  # Quad Concepts is opt-in and orthogonal to the mode: include its check in the suite only when the
  # .pdda-quad / PDDA_QUAD lever is enabled, so a default run's output is unchanged when it's off.
  local CHECKS="$PDDA_DETERMINISTIC_CHECKS"
  if quad_is_enabled; then
    CHECKS="$CHECKS
pdda-check-quad-concepts:check_quad_concepts"
  fi

  for entry in $CHECKS; do
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
  if [ "$EXIT_CODE" -ne 0 ] || [ "$PDDA_RUN_ERRORS" -gt 0 ]; then
    # Gate on the FINDINGS, not just the exit code (BUG-001b). In observe/light every check returns 0,
    # so gating on EXIT_CODE alone spent an LLM call reviewing docs that never passed structural hygiene
    # — the opposite of PDDA.md's "spend time only on docs that passed" rule.
    runner_say "skipped pdda-doc-ready — fix the deterministic findings above first (${FAILED:-$PDDA_RUN_ERROR_CHECKS})"
    pdda_log_activity info "pdda-doc-ready" "$PDDA_REPO_ROOT" 0 "readiness review skipped — deterministic checks reported errors:${FAILED:-$PDDA_RUN_ERROR_CHECKS}" "skip"
  elif "$HERE/pdda-doc-ready.sh"; then
    :
  else
    EXIT_CODE=1
    FAILED="$FAILED pdda-doc-ready"
  fi

  # Four outcomes, not three (GH-43, extending BUG-001b). "EXIT_CODE is 0" answers "did anything
  # block?", which outside full mode is always no. PDDA_RUN_ERRORS answers "did anything go wrong?".
  # Neither answers "did anything need attention?" — and that is what "all checks passed" asserts. A
  # run of nothing but warns took the else branch and printed success over its own findings, which is
  # how a doc could sit stale-flagged for 12 days while every run reported clean. Warns stay
  # non-blocking; only the closing line changes.
  runner_say ""
  if [ "$EXIT_CODE" -ne 0 ]; then
    runner_say "PDDA run complete: failures:$FAILED"
    pdda_log_activity error "pdda-run" "$PDDA_REPO_ROOT" 0 "PDDA run completed with failures:$FAILED" "finish"
  elif [ "$PDDA_RUN_ERRORS" -gt 0 ]; then
    runner_say "PDDA run complete: $PDDA_RUN_ERRORS error(s) found, not blocking in $PDDA_MODE mode —$PDDA_RUN_ERROR_CHECKS"
    runner_say "Run with PDDA_MODE=full (or .pdda-mode) once these are fixed, so they block."
    pdda_log_activity error "pdda-run" "$PDDA_REPO_ROOT" 0 \
      "PDDA run reported $PDDA_RUN_ERRORS error(s) in mode=$PDDA_MODE (non-blocking):$PDDA_RUN_ERROR_CHECKS" "finish"
  elif [ "$PDDA_RUN_WARNS" -gt 0 ]; then
    runner_say "PDDA run complete: no errors, $PDDA_RUN_WARNS warning(s) to review —$PDDA_RUN_WARN_CHECKS"
    pdda_log_activity warn "pdda-run" "$PDDA_REPO_ROOT" 0 \
      "PDDA run reported $PDDA_RUN_WARNS warning(s) and no errors:$PDDA_RUN_WARN_CHECKS" "finish"
  else
    runner_say "PDDA run complete: all checks passed"
    pdda_log_activity info "pdda-run" "$PDDA_REPO_ROOT" 0 "PDDA run completed successfully" "finish"
  fi

  pdda_rotate_activity   # keep PROJECT/PDDA-ACTIVITY.jsonl bounded

  # Mode gate: only "full" blocks (non-zero). In observe/light the checks already return 0.
  return "$(pdda_gated_exit "$EXIT_CODE")"
}

# ------------------------------------------------------------------------------------------------
# glance — a read-only portfolio roll-up: title + Quad Concepts for each active plan doc, so the whole
# 2-WORKING surface's pain coverage is visible on one screen. Not gated by the lever (a manual read).
# ------------------------------------------------------------------------------------------------
cmd_glance() {
  local file rel title sec n any=0
  printf '%s\n' "PDDA glance — Quad Concepts across PROJECT/2-WORKING"
  while IFS= read -r file; do
    any=1
    rel="$(pdda_relpath "$file")"
    title="$(pdda_trim "$(pdda_frontmatter_value "$file" "title")")"
    # strip one layer of surrounding YAML quotes for a clean line (title: "X" / 'X'). A block-scalar
    # title (title: > / |) would show only its indicator — titles are single-line by convention.
    case "$title" in
      \"*\") title="${title#\"}"; title="${title%\"}" ;;
      \'*\') title="${title#\'}"; title="${title%\'}" ;;
    esac
    sec="$(pdda_quad_section "$file")"
    n="${sec%%$'\n'*}"
    printf '\n• %s — %s\n' "$rel" "${title:-(untitled)}"
    if [ "$n" = "-1" ]; then
      printf '    (no ## Quad Concepts)\n'
    elif [ "$n" = "0" ]; then
      printf '    (## Quad Concepts present but empty)\n'
    else
      printf '%s\n' "$sec" | sed -n '2,$p' | while IFS= read -r b; do printf '    - %s\n' "$b"; done
    fi
  done < <(pdda_list_working_docs)
  [ "$any" -eq 1 ] || printf '\n(no active docs in PROJECT/2-WORKING)\n'
  return 0
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
  quad-concepts      opt-in: a "## Quad Concepts" section of 1-4 bullets (lever: .pdda-quad / PDDA_QUAD)
  glance             read-only roll-up: title + Quad Concepts for each PROJECT/2-WORKING doc
  hardcoded-paths    no machine-specific absolute paths in working docs
  roadmap            no execution detail leaks INTO ROADMAP.md
  roadmap-coverage   nothing active goes MISSING from ROADMAP.md
  changelog          end-of-iteration changelog nudge (warn-only)
  stale              flag stale working docs (flag-only; never moves)
  issue-doc-sync     flag 2-WORKING/GH-*.md docs drifted from their GitHub issue state (warn-only)
  releases           validate RELEASES.md — the release-planning ledger (warn-only nudge)
  releases-current   read-only roll-up: RELEASES.md entries whose Status isn't "Shipped" (rough, unvalidated)
  governance         repo-root governance-doc (ROUTER/AGENTS/CLAUDE/...) cross-reference + doc/code drift
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
  quad-concepts)    check_quad_concepts; exit "$?" ;;
  glance)           cmd_glance; exit "$?" ;;
  hardcoded-paths)  check_hardcoded_paths; exit "$?" ;;
  roadmap)          check_roadmap; exit "$?" ;;
  roadmap-coverage) check_roadmap_coverage; exit "$?" ;;
  changelog)        check_changelog; exit "$?" ;;
  stale)            check_stale; exit "$?" ;;
  issue-doc-sync)   check_issue_doc_sync; exit "$?" ;;
  releases)         check_releases; exit "$?" ;;
  releases-current) cmd_releases_current; exit "$?" ;;
  governance)       check_governance; exit "$?" ;;
  gh-refresh)       exec "$HERE/pdda-gh-refresh.sh" "$@" ;;
  doc-ready)        exec "$HERE/pdda-doc-ready.sh" "$@" ;;
  catchup)          exec "$HERE/pdda-catchup.sh" "$@" ;;
  help|-h|--help)   pdda_usage; exit 0 ;;
  *)                printf 'pdda.sh: unknown command %q\n\n' "$cmd" >&2; pdda_usage >&2; exit 2 ;;
esac
