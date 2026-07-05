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

# hq_xyz_lookup <repo> -> XYZ_PATH / XYZ_INSTALL / XYZ_TICK / XYZ_COMMIT  (first basename match wins)
hq_xyz_lookup(){
  [ -f "$HQ_XYZ_REGISTRY" ] || return 0
  local repo; repo="$(hq_lc "$(hq_bare "$1")")"
  local install tick commit coord
  while IFS=$'\t' read -r install _ tick commit coord; do
    case "$install" in ''|'#'*) continue;; esac
    [ -n "$coord" ] || continue
    if [ "$(hq_lc "$(hq_bare "$coord")")" = "$repo" ]; then
      printf 'XYZ_PATH=%s\n'    "$coord"
      printf 'XYZ_INSTALL=%s\n' "$install"
      printf 'XYZ_TICK=%s\n'    "$tick"
      printf 'XYZ_COMMIT=%s\n'  "$commit"
      return 0
    fi
  done < "$HQ_XYZ_REGISTRY"
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

# hq_resolve <query> -> QUERY / REPO / REPO_PATH / REPO_PATH_SOURCE + any REBAL_/XYZ_/PDDA_ fields.
# Exit 0 if a REPO_PATH was resolved, 1 if unresolved.
hq_resolve(){
  local query="$1" rebal repo xyz path src pdda
  rebal="$(hq_rebalance_lookup "$query")"
  repo="$(printf '%s' "$rebal" | sed -n 's/^REBAL_REPOS=//p' | cut -d, -f1)"
  [ -n "$repo" ] || repo="$(hq_bare "$query")"

  xyz="$(hq_xyz_lookup "$repo")"
  path="$(printf '%s' "$xyz" | sed -n 's/^XYZ_PATH=//p')"
  if [ -n "$path" ]; then
    src="xyz-registry"
  else
    path="$(hq_fs_find "$repo")"
    [ -n "$path" ] && src="filesystem"
  fi
  pdda="$(hq_pdda_lookup "$repo")"

  printf 'QUERY=%s\n' "$query"
  printf 'REPO=%s\n'  "$repo"
  [ -n "$rebal" ] && printf '%s\n' "$rebal"
  [ -n "$xyz" ]   && printf '%s\n' "$xyz"
  [ -n "$pdda" ]  && printf '%s\n' "$pdda"
  if [ -n "$path" ]; then
    printf 'REPO_PATH=%s\n'        "$path"
    printf 'REPO_PATH_SOURCE=%s\n' "$src"
    return 0
  fi
  printf 'REPO_PATH=\n'
  printf 'REPO_PATH_SOURCE=unresolved\n'
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
    mp="$(find "$p/PROJECT/2-WORKING" -maxdepth 1 -name 'MARATHON-PLAN-*.md' 2>/dev/null | sort | tail -1)"
    [ -n "$mp" ] && printf 'LOCAL_MARATHON=%s\n' "$(basename "$mp")"
  fi
}

# hq_tier <has_pdda 0|1> <has_xyz 0|1> -> A (PDDA+XYZ) / B (PDDA only) / C (bare)
hq_tier(){
  if [ "$1" = 1 ] && [ "$2" = 1 ]; then echo A
  elif [ "$1" = 1 ]; then echo B
  else echo C; fi
}
