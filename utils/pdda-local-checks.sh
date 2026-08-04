#!/usr/bin/env bash
# utils/pdda-local-checks.sh — PDDA checks this repo owns, deliberately OUTSIDE utils/pdda/.
#
# WHY THIS FILE EXISTS
# --------------------
# `utils/pdda/**` is sync-managed from Hypercart-Dev-Tools/pdda (see utils/pdda/PDDA-SOURCE.md): a
# sync replaces those files wholesale. On 2026-08-03 the sync in `cfd56b0` did exactly that and
# **silently deleted two shipped guardrails** this repo had added to the upstream script:
#
#   * GH-189  — a doc in PROJECT/3-COMPLETED/ whose frontmatter status is still non-terminal.
#               (`non-terminal`: 4 occurrences in pdda.sh before the sync, 0 after.)
#   * GH-284 Phase 3 — a dated, unshipped release with no `Milestone:` join key.
#               (`Milestone` validation: present before, reduced to a bare printf after.)
#
# Their tests stayed, so `validate.sh` and CI went red — and stayed red on `development` from
# `cfd56b0` onward, with the failures read as "pre-existing noise" rather than as two features
# having been deleted. Nothing else in the repo implemented either behaviour; the only surviving
# statement of them was the tests asserting behaviour that no longer existed.
#
# Restoring them inside `utils/pdda/` would guarantee the same loss on the next sync. So they live
# here: repo-owned, outside the sync surface, sourcing the upstream library for its helpers (all of
# which survived) so the checks stay faithful to the originals rather than reimplemented.
#
# The findings are byte-identical to the deleted ones on purpose — the remediation text is what an
# operator acts on, and changing it would silently invalidate the tests that pin it.
#
# Upstream is the better long-term home for both (it adopted this repo's `Milestone:` FIELD when
# asked, just not its validation). Until it adopts the checks too, this file is the contract.
#
# Usage:
#   utils/pdda-local-checks.sh completed-status    # GH-189
#   utils/pdda-local-checks.sh roadmap-issue-state # GH-189 (ledger side)
#   utils/pdda-local-checks.sh release-milestone   # GH-284 Phase 3
#   utils/pdda-local-checks.sh run                 # both (default)
#
# Exit: 0 clean (warn-only checks never gate) · 2 usage. Honors the same PDDA_* env as pdda.sh.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PDDA_LIB="$HERE/pdda/pdda-lib.sh"

if [ ! -f "$PDDA_LIB" ]; then
  printf 'pdda-local-checks: cannot find %s — is the PDDA runtime installed?\n' "$PDDA_LIB" >&2
  exit 2
fi
# shellcheck source=/dev/null
. "$PDDA_LIB"

# ── Helpers that live in pdda.sh, not pdda-lib.sh ─────────────────────────────────────────────────
# `pdda.sh` cannot be sourced — it dispatches on argv and would execute a check. These four are
# copied from it verbatim (as at cfd56b0) so this file depends only on the LIBRARY, not on the CLI's
# internals. That is deliberate: an upstream refactor that moves or renames a private `_pdda_*`
# helper is exactly the class of change that deleted these checks in the first place, and a copy
# cannot be taken away by a sync. The cost is drift if upstream changes the semantics of "terminal
# word"; `test/pdda-local-checks.sh` pins the list so that drift shows up as a failure, not silence.
pdda_reset_counts() { ERROR_COUNT=0; WARN_COUNT=0; INFO_COUNT=0; }

_pdda_status_leadword() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | grep -oE '[a-z]+' | head -1
}

PDDA_TERMINAL_STATUS_WORDS="complete completed done shipped fixed closed merged resolved landed"
_pdda_is_terminal_word() {
  case " $PDDA_TERMINAL_STATUS_WORDS " in *" $1 "*) return 0 ;; esac
  return 1
}

_pdda_doc_issue_number() {
  local file="$1" num base
  num="$(pdda_trim "$(pdda_frontmatter_value "$file" gh_issue)")"
  case "$num" in \"*\") num="${num#\"}"; num="${num%\"}" ;; \'*\') num="${num#\'}"; num="${num%\'}" ;; esac
  num="${num#\#}"
  if printf '%s' "$num" | grep -Eq '^[0-9]+$'; then printf '%s' "$num"; return; fi
  base="$(basename "$file")"
  case "$base" in
    GH-[0-9]*) num="${base#GH-}"; num="${num%.md}"; num="${num%%-*}"
      if printf '%s' "$num" | grep -Eq '^[0-9]+$'; then printf '%s' "$num"; fi ;;
  esac
}

# ── Ported: helpers the sync deleted or that live in the un-sourceable CLI ─────────────────────────
# Extracted mechanically (brace-balanced) rather than retyped, so these are byte-faithful.

# _pdda_roadmap_ledger_lines — DELETED by cfd56b0; recovered from cfd56b0^
_pdda_roadmap_ledger_lines() {
  local roadmap="$1"
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
    /^[[:space:]]*>/ { next }             # blockquote = allowed carve-out note, same as check_roadmap
    /\[#[0-9]+\]\(https:\/\/[^)]*\/issues\/[0-9]+\)/ { print NR "\t" $0 }
  ' "$roadmap"
}

# _pdda_cache_state_table — lives in pdda.sh (un-sourceable CLI); copied from current
_pdda_cache_state_table() {
  [ -f "$PDDA_GH_STATE_CACHE" ] || return 0
  grep -v '^[[:space:]]*#' "$PDDA_GH_STATE_CACHE" 2>/dev/null
}

# _pdda_issue_state_table — lives in pdda.sh (un-sourceable CLI); copied from current
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

# check_roadmap_issue_state — DELETED by cfd56b0 along with its whole subcommand
check_roadmap_issue_state() {
  pdda_reset_counts
  local CHECK_NAME="pdda-local-check-roadmap-issue-state" rc=0
  local PDDA_ROADMAP="${PDDA_ROADMAP:-$PDDA_REPO_ROOT/ROADMAP.md}"
  local table line_no line num state is_terminal is_nonterminal

  if [ ! -f "$PDDA_ROADMAP" ]; then
    pdda_record_finding info "$CHECK_NAME" "$PDDA_ROADMAP" 0 "ROADMAP.md not found; nothing to check" "skip"
    pdda_emit_summary "$CHECK_NAME" 0
    return "$(pdda_gated_exit 0)"
  fi

  table="$(_pdda_issue_state_table)"

  while IFS=$'\t' read -r line_no line; do
    [ -n "$line_no" ] || continue

    is_terminal=0
    is_nonterminal=0
    case "$line" in *"✅"*) is_terminal=1 ;; esac
    printf '%s' "$line" | grep -qiE '\bshipped\b' && is_terminal=1
    case "$line" in *"🆕"*) is_nonterminal=1 ;; esac
    printf '%s' "$line" | grep -qiE '\bcaptured\b|ready to fire' && is_nonterminal=1

    # Ambiguous (both fired, or neither) => no reliable signal on this line; skip it entirely.
    [ "$is_terminal" -eq "$is_nonterminal" ] && continue

    while IFS= read -r num; do
      [ -n "$num" ] || continue
      state="$(printf '%s\n' "$table" | awk -F'\t' -v n="$num" '$1 == n { print toupper($2); exit }')"
      if [ -z "$state" ]; then
        pdda_record_finding info "$CHECK_NAME" "$PDDA_ROADMAP" "$line_no" \
          "issue #$num state unavailable (gh absent/offline and no cached state) — sync not evaluated" "skip"
        continue
      fi

      if [ "$is_terminal" -eq 1 ] && [ "$state" = "OPEN" ]; then
        pdda_record_finding warn "$CHECK_NAME" "$PDDA_ROADMAP" "$line_no" \
          "ledger entry reads shipped/done (✅/SHIPPED) but issue #$num is still OPEN — reconcile the ledger entry or close the issue" \
          "reconcile-roadmap-status"
      fi
      if [ "$is_nonterminal" -eq 1 ] && [ "$state" = "CLOSED" ]; then
        pdda_record_finding warn "$CHECK_NAME" "$PDDA_ROADMAP" "$line_no" \
          "issue #$num is CLOSED but the ledger entry's status marker is still non-terminal (e.g. 🆕/captured/ready to fire) — update the ledger entry" \
          "reconcile-roadmap-status"
      fi
    done < <(printf '%s\n' "$line" | grep -oE '\[#[0-9]+\]\(https://[^)]*/issues/[0-9]+\)' | grep -oE '^\[#[0-9]+\]' | sed -E 's/[^0-9]//g')
  done < <(_pdda_roadmap_ledger_lines "$PDDA_ROADMAP")

  pdda_emit_summary "$CHECK_NAME" "$rc"
  return "$(pdda_gated_exit "$rc")"
}


# ── GH-189 · a completed doc whose status never caught up ─────────────────────────────────────────
# Ported verbatim from pdda.sh direction (c) as it stood at cfd56b0^. The original's reasoning, kept
# because it is the reason this check has no other home: moving a doc into 3-COMPLETED removes it
# from pdda_list_working_docs()'s scan set forever, so this is the ONLY place that ever looks at a
# completed doc again. A doc landing there implies "done"; a still-non-terminal status is the drift.
check_completed_status() {
  pdda_reset_counts
  local CHECK_NAME="pdda-local-check-completed-status" rc=0
  local file num status_val leadword

  while IFS= read -r file; do
    num="$(_pdda_doc_issue_number "$file")"
    [ -n "$num" ] || continue            # not an issue-tracked doc — nothing to reconcile

    status_val="$(pdda_trim "$(pdda_frontmatter_value "$file" status)")"
    leadword="$(_pdda_status_leadword "$status_val")"
    if [ -n "$leadword" ] && ! _pdda_is_terminal_word "$leadword"; then
      pdda_record_finding warn "$CHECK_NAME" "$file" 1 \
        "doc is in 3-COMPLETED (issue #$num) but frontmatter status still reads '$leadword' (non-terminal) — reconcile the status or move the doc back to 2-WORKING" \
        "reconcile-status"
    fi
  done < <(pdda_list_completed_docs)

  pdda_emit_summary "$CHECK_NAME" "$rc"
  return "$(pdda_gated_exit "$rc")"
}

# ── GH-284 Phase 3 · the release → issue-set join key ─────────────────────────────────────────────
# Ported verbatim from check_releases as it stood at cfd56b0^. Upstream still PARSES `Milestone:`
# (pdda_releases_list emits it) and documents it as "optional — free-text, unvalidated"; this repo
# needs it validated because it is the key that resolves a release to a set of issues, which is what
# lets a release drive marathon selection at all.
check_release_milestone() {
  pdda_reset_counts
  local CHECK_NAME="pdda-local-check-release-milestone" rc=0
  local RELEASES_FILE_EFF="${PDDA_RELEASES_FILE:-$PDDA_REPO_ROOT/RELEASES.md}"
  local release status target_date codename description gh_url line_no
  local front_door shakedown license_file iterations milestone status_lc rows

  if [ ! -f "$RELEASES_FILE_EFF" ]; then
    pdda_record_finding info "$CHECK_NAME" "$RELEASES_FILE_EFF" 0 \
      "RELEASES.md not found — nothing to check" "skip"
    pdda_emit_summary "$CHECK_NAME" 0
    return "$(pdda_gated_exit 0)"
  fi

  # A ledger with no blocks is a VALID state (sparse is fine, and RELEASES.md is optional per
  # GH-381) — report exactly as clean as an absent file, and record no finding of our own.
  rows="$(pdda_releases_list "$RELEASES_FILE_EFF")"
  if [ -z "$rows" ]; then
    pdda_emit_summary "$CHECK_NAME" 0
    return "$(pdda_gated_exit 0)"
  fi

  while IFS=$'\037' read -r release status target_date codename description gh_url \
    front_door shakedown license_file iterations milestone line_no; do
    [ -n "$(pdda_trim "$release")" ] || continue
    status_lc="$(printf '%s' "$(pdda_trim "$status")" | tr '[:upper:]' '[:lower:]')"

    # Scoped to blocks carrying a Target Date so the shipped example block (and any placeholder)
    # stays quiet: a dated entry is a real planned release, which is exactly when the linkage is
    # needed. Shipped releases are exempt — backfilling a milestone onto history buys nothing.
    if [ -n "$(pdda_trim "$target_date")" ] && [ "$status_lc" != "shipped" ] \
       && [ -z "$(pdda_trim "$milestone")" ]; then
      pdda_record_finding warn "$CHECK_NAME" "$RELEASES_FILE_EFF" "$line_no" \
        "release '$release' has a Target Date but no 'Milestone:' — without it the release cannot resolve to a set of issues (gh issue list --milestone ...), so it cannot drive marathon selection" \
        "add-release-milestone"
    fi
  done <<EOF
$rows
EOF

  pdda_emit_summary "$CHECK_NAME" "$rc"
  return "$(pdda_gated_exit "$rc")"
}

usage() {
  printf 'Usage: utils/pdda-local-checks.sh [completed-status|release-milestone|run]\n' >&2
}

CMD="${1:-run}"
case "$CMD" in
  completed-status)    check_completed_status ;;
  release-milestone)   check_release_milestone ;;
  roadmap-issue-state) check_roadmap_issue_state ;;
  run)
    EXIT_CODE=0
    check_completed_status     || EXIT_CODE=$?
    check_roadmap_issue_state  || EXIT_CODE=$?
    check_release_milestone    || EXIT_CODE=$?
    exit "$EXIT_CODE"
    ;;
  -h|--help|help) usage; exit 0 ;;
  *) usage; printf 'pdda-local-checks: unknown command: %s\n' "$CMD" >&2; exit 2 ;;
esac
