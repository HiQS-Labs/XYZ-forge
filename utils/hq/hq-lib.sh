#!/usr/bin/env bash
# HQ resolver library (GH-128, Phase 0/1). READ-ONLY. Sourced by utils/hq/hq.sh and test/hq.sh.
#
# Resolution ladder (name -> repo -> path -> governance), each rung degrading gracefully to empty
# when its source is missing/offline, so a partial registry set never hard-fails:
#   1. Rebalance project_registry (rebalance.db) -> semantic project NAME -> repo list + priority
#   2. XYZ install registry (registry.tsv)       -> repo -> ABSOLUTE PATH + runnable/drift stamps
#   3. Git Pulse PDDA registry (registry-*.tsv)  -> repo -> PDDA mode + startup_docs (NO path)
#   4. Filesystem `find` fallback                -> repo -> path when no registry knows it
#
# Output contract: functions emit `KEY=value` lines (never uses the reserved name PATH — see
# REPO_PATH). Callers grep the keys; nothing is meant to be `eval`ed.
#
# Env seams (override for tests / non-default installs):
#   HQ_PDDA_REGISTRY_DIR  default $HOME/git-pulse-sync/pdda        (globs registry-*.tsv)
#   HQ_XYZ_REGISTRY       default ${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv
#   HQ_REBALANCE_DB       default $HOME/Documents/rebalance-OS/rebalance.db
#   HQ_SEARCH_ROOTS       default "$HOME/Documents/GH Repos:$HOME/Documents:$HOME" (colon-separated)

: "${HQ_PDDA_REGISTRY_DIR:=$HOME/git-pulse-sync/pdda}"
: "${HQ_XYZ_REGISTRY:=${XDG_CONFIG_HOME:-$HOME/.config}/xyz/registry.tsv}"
: "${HQ_REBALANCE_DB:=$HOME/Documents/rebalance-OS/rebalance.db}"
: "${HQ_SEARCH_ROOTS:=$HOME/Documents/GH Repos:$HOME/Documents:$HOME}"

hq_lc(){ printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
hq_bare(){ printf '%s' "${1##*/}"; }                       # strip any owner/ prefix
hq_sanitize(){ printf '%s' "$1" | tr -cd '[:alnum:]/_.- '; } # defang before SQL interpolation
# hq_yaml_dq <string> -> escape for a YAML double-quoted scalar (backslash + double-quote). Without
# this, a title containing " (or \) produces invalid frontmatter — GH-132.
hq_yaml_dq(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# hq_rebalance_lookup <query> -> REBAL_NAME / REBAL_TIER / REBAL_VALUE / REBAL_STATUS / REBAL_REPOS
# Matches the human project NAME (owner/repo) exactly, or on its repo-part, case-insensitively.
hq_rebalance_lookup(){
  [ -f "$HQ_REBALANCE_DB" ] || return 0
  command -v sqlite3 >/dev/null 2>&1 || return 0
  local q qbare
  q="$(hq_lc "$(hq_sanitize "$1")")"
  qbare="$(hq_lc "$(hq_sanitize "$(hq_bare "$1")")")"
  local row
  row="$(sqlite3 -separator '|' "$HQ_REBALANCE_DB" \
    "SELECT name, priority_tier, value_level, status, repos_json FROM project_registry
       WHERE lower(name)='$q' OR lower(name)='$qbare' OR lower(name) LIKE '%/'||'$qbare'
       LIMIT 1;" 2>/dev/null)" || return 0
  [ -n "$row" ] || return 0
  local name tier value status repos_json repos
  IFS='|' read -r name tier value status repos_json <<<"$row"
  repos="$(printf '%s' "$repos_json" | grep -oE '"[^"]+"' | tr -d '"' | sed 's#.*/##' | paste -sd, -)"
  printf 'REBAL_NAME=%s\n'   "$name"
  printf 'REBAL_TIER=%s\n'   "$tier"
  printf 'REBAL_VALUE=%s\n'  "$value"
  printf 'REBAL_STATUS=%s\n' "$status"
  printf 'REBAL_REPOS=%s\n'  "$repos"
}

# hq_xyz_lookup <repo> [<slug_hint>] -> XYZ_PATH / XYZ_INSTALL / XYZ_TICK / XYZ_COMMIT for the LIVE
# install whose coord basename matches <repo>. GH-132 hardening:
#   * Blocker 2 — a registry row whose coord no longer exists on disk is NOT a usable install; skip it
#     (so a stale row can't arm Tier A / `fire` at a dead path).
#   * Blocker 1 — on a basename COLLISION among live installs, disambiguate by full `owner/repo` slug
#     (authoritative: each candidate's git origin remote) when <slug_hint> carries an owner. If it still
#     can't uniquely resolve, emit `XYZ_AMBIGUOUS=<paths>` and return 2 rather than guessing a path.
hq_xyz_lookup(){
  [ -f "$HQ_XYZ_REGISTRY" ] || return 0
  local repo slug install _f tick commit coord
  repo="$(hq_lc "$(hq_bare "$1")")"
  slug="$(hq_lc "${2:-}")"
  local matches=()
  while IFS=$'\t' read -r install _f tick commit coord; do
    case "$install" in ''|'#'*) continue;; esac
    [ -n "$coord" ] || continue
    [ -d "$coord" ] || continue                          # stale row -> not a usable install (Blocker 2)
    [ "$(hq_lc "$(hq_bare "$coord")")" = "$repo" ] || continue
    matches+=("$install"$'\t'"$coord"$'\t'"$tick"$'\t'"$commit")
  done < "$HQ_XYZ_REGISTRY"

  local n="${#matches[@]}"
  [ "$n" -gt 0 ] || return 0

  local chosen=""
  if [ "$n" = 1 ]; then
    chosen="${matches[0]}"
  elif [ -n "$slug" ] && printf '%s' "$slug" | grep -q '/'; then
    # basename collision + an owner-carrying hint: keep only candidates whose real git slug matches
    local m mslug hits=()
    for m in "${matches[@]}"; do
      mslug="$(hq_lc "$(hq_target_slug "$(printf '%s' "$m" | cut -f2)")")"
      [ -n "$mslug" ] && [ "$mslug" = "$slug" ] && hits+=("$m")
    done
    [ "${#hits[@]}" = 1 ] && chosen="${hits[0]}"
  fi

  if [ -n "$chosen" ]; then
    printf 'XYZ_PATH=%s\n'    "$(printf '%s' "$chosen" | cut -f2)"
    printf 'XYZ_INSTALL=%s\n' "$(printf '%s' "$chosen" | cut -f1)"
    printf 'XYZ_TICK=%s\n'    "$(printf '%s' "$chosen" | cut -f3)"
    printf 'XYZ_COMMIT=%s\n'  "$(printf '%s' "$chosen" | cut -f4)"
    return 0
  fi

  # collision we won't resolve -> refuse to guess (Blocker 1)
  local paths=() m sIFS
  for m in "${matches[@]}"; do paths+=("$(printf '%s' "$m" | cut -f2)"); done
  sIFS="$IFS"; IFS=,; printf 'XYZ_AMBIGUOUS=%s\n' "${paths[*]}"; IFS="$sIFS"
  return 2
}

# hq_pdda_lookup <repo> -> PDDA_MODE / PDDA_STARTUP / PDDA_DEVICE  (scans every device registry)
hq_pdda_lookup(){
  [ -d "$HQ_PDDA_REGISTRY_DIR" ] || return 0
  local repo; repo="$(hq_lc "$(hq_bare "$1")")"
  local f rrepo mode startup
  for f in "$HQ_PDDA_REGISTRY_DIR"/registry-*.tsv; do
    [ -f "$f" ] || continue
    while IFS=$'\t' read -r rrepo _ mode _ startup; do
      case "$rrepo" in ''|'#'*) continue;; esac
      if [ "$(hq_lc "$rrepo")" = "$repo" ]; then
        printf 'PDDA_MODE=%s\n'    "$mode"
        printf 'PDDA_STARTUP=%s\n' "$startup"
        printf 'PDDA_DEVICE=%s\n'  "$(basename "$f" | sed 's/^registry-//; s/\.tsv$//')"
        return 0
      fi
    done < "$f"
  done
}

# hq_fs_find <repo> -> first git working tree named <repo> under the search roots (depth-capped)
hq_fs_find(){
  local repo; repo="$(hq_bare "$1")"
  # GH-132: a glob-metachar token would be a `find -name` PATTERN, not a literal name — e.g. `resolve
  # '*'` would match the first repo under the roots. A real repo name has no glob chars, so refuse to
  # fall through to a filesystem match on one (return empty -> UNRESOLVED, not a wrong guess).
  case "$repo" in *[\*\?\[]*) return 0;; esac
  local saved="$IFS" root hit
  IFS=':'
  for root in $HQ_SEARCH_ROOTS; do
    IFS="$saved"
    [ -d "$root" ] || continue
    hit="$(find "$root" -maxdepth 3 -type d -name "$repo" -exec test -d '{}/.git' \; -print 2>/dev/null | head -1)"
    [ -n "$hit" ] && { printf '%s\n' "$hit"; return 0; }
  done
  IFS="$saved"
  return 0
}

# ---- Fuzzy resolution (Phase 1.x) --------------------------------------------------------------
# Loose names ("rebalanceOS", "rebalance os", "REBALANCE-OS") should resolve to the canonical repo,
# but a genuinely ambiguous name must return candidates rather than guess.

hq_norm(){ printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]'; }  # lower + alnum-only
hq_contains(){ case "$1" in *"$2"*) return 0;; *) return 1;; esac; }

# hq_known_repos -> every distinct repo name any registry knows (one per line). Filesystem is NOT
# enumerated here (too broad); the exact path-resolve already covers on-disk repos.
hq_known_repos(){
  {
    if [ -f "$HQ_REBALANCE_DB" ] && command -v sqlite3 >/dev/null 2>&1; then
      sqlite3 "$HQ_REBALANCE_DB" 'SELECT name FROM project_registry;' 2>/dev/null | sed 's#.*/##'
    fi
    if [ -f "$HQ_XYZ_REGISTRY" ]; then
      local install coord
      while IFS=$'\t' read -r install _ _ _ coord; do
        case "$install" in ''|'#'*) continue;; esac
        [ -n "$coord" ] && basename "$coord"
      done < "$HQ_XYZ_REGISTRY"
    fi
    if [ -d "$HQ_PDDA_REGISTRY_DIR" ]; then
      local f rrepo
      for f in "$HQ_PDDA_REGISTRY_DIR"/registry-*.tsv; do
        [ -f "$f" ] || continue
        while IFS=$'\t' read -r rrepo _; do
          case "$rrepo" in ''|'#'*) continue;; esac
          printf '%s\n' "$rrepo"
        done < "$f"
      done
    fi
  } | awk 'NF' | sort -u
}

# hq_candidates <query> -> matching repo names. Normalized-EQUAL matches win outright; only if there
# are none does it fall back to substring matches (either direction). Deduped, one per line.
hq_candidates(){
  local q; q="$(hq_norm "$1")"
  [ -n "$q" ] || return 0
  local name n equal=() sub=()
  while IFS= read -r name; do
    n="$(hq_norm "$name")"
    if [ "$n" = "$q" ]; then equal+=("$name")
    elif hq_contains "$n" "$q" || hq_contains "$q" "$n"; then sub+=("$name")
    fi
  done < <(hq_known_repos)
  if   [ "${#equal[@]}" -gt 0 ]; then printf '%s\n' "${equal[@]}" | sort -u
  elif [ "${#sub[@]}"   -gt 0 ]; then printf '%s\n' "${sub[@]}"   | sort -u
  fi
}

# hq_repo_resolve <repo> [<slug_hint>] -> XYZ_*/PDDA_* + REPO_PATH= + REPO_PATH_SOURCE=
# (xyz-registry|filesystem|ambiguous|''). <slug_hint> (an owner/repo) is only used to break an XYZ
# basename collision (GH-132). On an unresolved collision it emits XYZ_AMBIGUOUS + empty REPO_PATH.
hq_repo_resolve(){
  local repo="$1" slug="${2:-}" xyz xrc amb path src="" pdda xyz_path
  xyz="$(hq_xyz_lookup "$repo" "$slug")"; xrc=$?
  if [ "$xrc" = 2 ]; then
    amb="$(printf '%s\n' "$xyz" | sed -n 's/^XYZ_AMBIGUOUS=//p')"
    printf 'XYZ_AMBIGUOUS=%s\n' "$amb"
    printf 'REPO_PATH=\n'
    printf 'REPO_PATH_SOURCE=ambiguous\n'
    return 0
  fi
  xyz_path="$(printf '%s\n' "$xyz" | sed -n 's/^XYZ_PATH=//p')"   # already existence-filtered
  if [ -n "$xyz_path" ]; then src="xyz-registry"; path="$xyz_path"
  else path="$(hq_fs_find "$repo")"; [ -n "$path" ] && src="filesystem"; fi
  pdda="$(hq_pdda_lookup "$repo")"
  [ -n "$xyz" ]  && printf '%s\n' "$xyz"
  [ -n "$pdda" ] && printf '%s\n' "$pdda"
  printf 'REPO_PATH=%s\n' "$path"
  printf 'REPO_PATH_SOURCE=%s\n' "$src"
}

# hq_resolve <query> -> QUERY / REPO / RESOLVED_VIA / REPO_PATH / REPO_PATH_SOURCE + REBAL_/XYZ_/PDDA_.
# Exit 0 if a REPO_PATH was resolved (exact or fuzzy), 2 if the name is ambiguous (CANDIDATES listed),
# 1 if unresolved.
hq_resolve(){
  local query="$1" rebal repo fields path via="exact" slug_hint amb
  rebal="$(hq_rebalance_lookup "$query")"
  repo="$(printf '%s\n' "$rebal" | sed -n 's/^REBAL_REPOS=//p' | cut -d, -f1)"
  [ -n "$repo" ] || repo="$(hq_bare "$query")"
  # GH-132: slug hint for an XYZ basename collision — prefer an owner-carrying query, else the
  # Rebalance project NAME (owner/repo). Bare names give no owner, so a collision stays ambiguous.
  case "$query" in */*) slug_hint="$query";; *) slug_hint="";; esac
  [ -n "$slug_hint" ] || slug_hint="$(printf '%s\n' "$rebal" | sed -n 's/^REBAL_NAME=//p')"
  fields="$(hq_repo_resolve "$repo" "$slug_hint")"
  amb="$(printf '%s\n' "$fields" | sed -n 's/^XYZ_AMBIGUOUS=//p')"
  if [ -n "$amb" ]; then
    printf 'QUERY=%s\nREPO=%s\nRESOLVED_VIA=ambiguous\nCANDIDATES=%s\nREPO_PATH=\nREPO_PATH_SOURCE=ambiguous\n' \
      "$query" "$repo" "$amb"
    return 2
  fi
  path="$(printf '%s\n' "$fields" | sed -n 's/^REPO_PATH=//p' | head -1)"

  if [ -z "$path" ]; then
    local cands count
    cands="$(hq_candidates "$query")"
    count="$(printf '%s' "$cands" | grep -c .)"
    if [ "$count" = 1 ]; then
      repo="$cands"; via="fuzzy"
      rebal="$(hq_rebalance_lookup "$repo")"
      fields="$(hq_repo_resolve "$repo" "$(printf '%s\n' "$rebal" | sed -n 's/^REBAL_NAME=//p')")"
      amb="$(printf '%s\n' "$fields" | sed -n 's/^XYZ_AMBIGUOUS=//p')"
      if [ -n "$amb" ]; then
        printf 'QUERY=%s\nREPO=%s\nRESOLVED_VIA=ambiguous\nCANDIDATES=%s\nREPO_PATH=\nREPO_PATH_SOURCE=ambiguous\n' \
          "$query" "$repo" "$amb"
        return 2
      fi
      path="$(printf '%s\n' "$fields" | sed -n 's/^REPO_PATH=//p' | head -1)"
    elif [ "$count" -gt 1 ]; then
      printf 'QUERY=%s\nREPO=\nRESOLVED_VIA=ambiguous\nCANDIDATES=%s\nREPO_PATH=\nREPO_PATH_SOURCE=ambiguous\n' \
        "$query" "$(printf '%s' "$cands" | paste -sd, -)"
      return 2
    fi
  fi

  printf 'QUERY=%s\nREPO=%s\nRESOLVED_VIA=%s\n' "$query" "$repo" "$via"
  [ -n "$rebal" ] && printf '%s\n' "$rebal"
  if [ -n "$path" ]; then
    printf '%s\n' "$fields"
    return 0
  fi
  printf '%s\n' "$fields" | sed 's/^REPO_PATH_SOURCE=$/REPO_PATH_SOURCE=unresolved/'
  return 1
}

# hq_inspect_repo <path> -> repo-local governance facts (authoritative over the registries)
hq_inspect_repo(){
  local p="$1"
  [ -d "$p" ] || return 0
  [ -f "$p/.pdda-mode" ]        && printf 'LOCAL_PDDA_MODE=%s\n' "$(head -1 "$p/.pdda-mode" | tr -d '[:space:]')"
  [ -f "$p/ROUTER.md" ]         && printf 'LOCAL_ROUTER=yes\n'
  [ -f "$p/AGENTS.md" ]         && printf 'LOCAL_AGENTS=yes\n'
  [ -f "$p/ROADMAP.md" ]        && printf 'LOCAL_ROADMAP=yes\n'
  [ -f "$p/utils/pdda/pdda.sh" ] && printf 'LOCAL_PDDA_SH=yes\n'
  if [ -d "$p/PROJECT/2-WORKING" ]; then
    local n mp
    n="$(find "$p/PROJECT/2-WORKING" -maxdepth 1 -name '*.md' ! -name 'blank.md' 2>/dev/null | wc -l | tr -d ' ')"
    printf 'LOCAL_ACTIVE_DOCS=%s\n' "$n"
    # Broadened from 'MARATHON-PLAN-*.md' to 'MARATHON-*.md' (GH-138): a target repo may name its
    # plan MARATHON-<date>.md (e.g. rebalance-OS) rather than this repo's MARATHON-PLAN-<date>.md.
    mp="$(find "$p/PROJECT/2-WORKING" -maxdepth 1 -name 'MARATHON-*.md' 2>/dev/null | sort | tail -1)"
    [ -n "$mp" ] && printf 'LOCAL_MARATHON=%s\n' "$(basename "$mp")"
  fi
}

# hq_tier <has_pdda 0|1> <has_xyz 0|1> -> A (PDDA+XYZ) / B (PDDA only) / C (bare)
hq_tier(){
  if [ "$1" = 1 ] && [ "$2" = 1 ]; then echo A
  elif [ "$1" = 1 ]; then echo B
  else echo C; fi
}

# ---- Phase 2 (intake writer) helpers ------------------------------------------------------------

# hq_slug <request text> -> SCREAMING-KEBAB of up to 4 meaningful words (stopwords dropped).
# Falls back to REQUEST when nothing survives. Used for the GH-<n>-<SLUG>.md capture filename.
hq_slug(){
  local s
  s="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '\n' \
        | grep -vxE '(the|a|an|to|for|of|and|do|this|that|please|add|make|it)' \
        | head -4 | tr '[:lower:]' '[:upper:]' | paste -sd- -)"
  [ -n "$s" ] && printf '%s' "$s" || printf 'REQUEST'
}

# hq_issue_title <project> <request> -> a concise (<=72 char) issue title.
hq_issue_title(){
  local t="$2"
  [ "${#t}" -le 72 ] || t="${t:0:69}..."
  printf '%s' "$t"
}

# hq_render_capture <issue_num> <source_url> <title> <created> <doc_type> <project> <repo> <request>
# Emits a PDDA-compliant 1-INBOX capture doc (frontmatter matches PROJECT/PDDA.md GitHub-issue intake).
hq_render_capture(){
  local num="$1" src="$2" title="$3" created="$4" dtype="$5" project="$6" repo="$7" request="$8"
  local title_dq; title_dq="$(hq_yaml_dq "$title")"   # GH-132: keep the YAML scalar valid
  cat <<EOF
---
gh_issue: $num
source: $src
title: "$title_dq"
status: Proposed (1-INBOX — not yet active)
created: $created
doc_type: $dtype
---

# $title

Captured via HQ (\`/hq park\`) for project **$project** → repo \`$repo\`.
The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference.

## Request

$request

## Notes

- Filed under the PDDA issue-first SOP. Promote to \`PROJECT/2-WORKING/\` when execution starts,
  carrying \`gh_issue\` forward, and satisfy the full active-doc contract (status table, QA gates).
EOF
}

# GH-138: upgrade a just-moved 1-INBOX capture doc in place so it satisfies the MINIMUM enforced
# 2-WORKING contract (check_frontmatter: title status created updated owner goal; check_status_table:
# a '## Status' table with the exact header + non-blank cells). Mechanical + honest — it fills the
# derivable fields and leaves cx/risk/eff + the real Status + QA gates as loud operator TODOs.
# hq_promote_upgrade_doc <file> <updated_date> [owner]
hq_promote_upgrade_doc(){
  local file="$1" updated="$2" owner="${3:-unassigned}" tmp="$1.hqtmp"
  local goaltxt="Promoted from 1-INBOX by hq promote — replace with the real goal (see the Request section)."
  awk -v updated="$updated" -v owner="$owner" -v goaltxt="$goaltxt" '
    BEGIN{ infm=0; seen_updated=0; seen_owner=0; seen_goal=0 }
    NR==1 && $0=="---"{ infm=1; print; next }
    infm && $0=="---"{
      if(!seen_updated) print "updated: " updated
      if(!seen_owner)   print "owner: " owner
      if(!seen_goal)    print "goal: \"" goaltxt "\""
      print "---"; infm=0; next
    }
    infm && /^status:[[:space:]]*/{
      if($0 ~ /Proposed|1-INBOX|not yet active/)
        print "status: Promoted from 1-INBOX via HQ on " updated " — awaiting operator rating + scoping"
      else print
      next
    }
    infm && /^updated:[[:space:]]*/{ seen_updated=1; print "updated: " updated; next }
    infm && /^owner:[[:space:]]*/{ seen_owner=1; print; next }
    infm && /^goal:[[:space:]]*/{ seen_goal=1; print; next }
    { print }
  ' "$file" > "$tmp" || return 1
  mv "$tmp" "$file"
  # append a checker-valid Status table only if the body has none
  if ! grep -qE '^##[[:space:]]+Status[[:space:]]*$' "$file"; then
    cat >> "$file" <<EOF

## Status

| What was just completed | What's next |
|---|---|
| Promoted from PROJECT/1-INBOX to PROJECT/2-WORKING via \`hq promote\` on $updated. | Operator: set complexity/risk/effort ratings, replace this row with the real state, and add phase QA gates before execution. |
EOF
  fi
}

# hq_roadmap_line <issue_num> <title> <created> <doc_relpath> <doc_basename> <issue_url>
hq_roadmap_line(){
  printf -- '- **GH-%s · %s** 🆕 **captured %s via HQ** — [%s](%s) · [#%s](%s)\n' \
    "$1" "$2" "$3" "$5" "$4" "$1" "$6"
}

# hq_roadmap_insert <roadmap_file> <line> -> inserts <line> after the first "### Queue" heading,
# else after the first "## " heading, else appends. Writes atomically via a temp file. Returns where.
hq_roadmap_insert(){
  local file="$1" line="$2" tmp where
  tmp="$(mktemp "${TMPDIR:-/tmp}/hq-roadmap.XXXXXX")" || return 1
  if grep -qiE '^### .*queue' "$file" 2>/dev/null; then
    where="after '### … queue' heading"
    awk -v ins="$line" 'BEGIN{done=0}
      { print }
      (!done && tolower($0) ~ /^### .*queue/){ print ins; done=1 }' "$file" > "$tmp"
  elif grep -qE '^## ' "$file" 2>/dev/null; then
    where="after first '## ' heading"
    awk -v ins="$line" 'BEGIN{done=0}
      { print }
      (!done && $0 ~ /^## /){ print ins; done=1 }' "$file" > "$tmp"
  else
    where="appended (no heading found)"
    cat "$file" > "$tmp"; printf '%s\n' "$line" >> "$tmp"
  fi
  mv "$tmp" "$file" && printf '%s' "$where"
}

# hq_target_slug <path> -> owner/repo from the target's origin remote (for the source: URL / gh -R).
hq_target_slug(){
  local url
  url="$(git -C "$1" config --get remote.origin.url 2>/dev/null)" || return 0
  [ -n "$url" ] || return 0
  printf '%s' "$url" | sed -E 's#^git@[^:]+:##; s#^https?://[^/]+/##; s#\.git$##'
}

# ---- Phase 3 (dispatch) helpers -----------------------------------------------------------------

# hq_queue_lane_block <title> <created> <tier> <issue|-> -> a non-destructive lane block appended to
# the target's Marathon Plan. Deliberately an explicit "HQ-queued" appendix, NOT an in-schema lane —
# a human/planner rates it and slots it into the wave/collision map before it is ever fired.
hq_queue_lane_block(){
  local title="$1" created="$2" tier="$3" issue="$4" ref=""
  [ "$issue" != "-" ] && ref=" → #$issue"
  cat <<EOF

<!-- HQ-queued lane — appended $created; reconcile into a wave + collision map before firing. -->
- **HQ-queued: $title** (Tier $tier, queued $created$ref)
  - [ ] rate effort/complexity/risk, then slot into a wave (respect the plan's collision map, GH-45).
EOF
}

# ---- Phase 4 (Rebalance-priority board) helpers -------------------------------------------------

# hq_projects_by_priority [limit] -> `tier|value|status|name` rows from Rebalance project_registry,
# ranked by priority_tier ASC (1 = highest .. 5 = lowest, per rebalance next_actions.py), then name.
# Read-only; degrades to empty when the DB / sqlite3 is unavailable.
hq_projects_by_priority(){
  local limit="${1:-8}"
  case "$limit" in ''|*[!0-9]*) limit=8;; esac
  [ -f "$HQ_REBALANCE_DB" ] || return 0
  command -v sqlite3 >/dev/null 2>&1 || return 0
  sqlite3 -separator '|' "$HQ_REBALANCE_DB" \
    "SELECT priority_tier, COALESCE(value_level,''), COALESCE(status,''), name
       FROM project_registry
       ORDER BY priority_tier ASC, name
       LIMIT $limit;" 2>/dev/null
}
