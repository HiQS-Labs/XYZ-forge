#!/usr/bin/env bash
# HQ — multi-repo command-center (GH-128). Phase 0/1: READ-ONLY resolver + project card.
#
# The front door for "For project X, do Y": this layer resolves the project name to a real repo on
# this device and reports its governance state. Writing intake (issue -> 1-INBOX capture -> ROADMAP
# parking) and dispatch (queue/fire) are Phase 2/3 — deliberately NOT implemented here; `park`/`queue`
# /`fire` print a not-yet-built notice so the surface is discoverable without pretending to act.
#
# Subcommands:
#   hq.sh resolve <project|repo>    machine-readable KEY=value resolution (for scripts)
#   hq.sh status  <project|repo>    human-readable project card (the Phase 1 first use case)
#   hq.sh registries                Phase-0 introspection: what each registry knows + coverage
#
# See utils/hq/hq-lib.sh for the resolution ladder and the HQ_* env seams.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=utils/hq/hq-lib.sh
. "$HERE/hq-lib.sh"

usage(){
  cat >&2 <<'EOF'
HQ — multi-repo command-center (read-only prototype, GH-128)

usage:
  hq.sh resolve <project|repo>   machine-readable KEY=value resolution
  hq.sh status  <project|repo>   human-readable project card
  hq.sh registries               what each registry knows (Phase-0 introspection)

not yet built (Phase 2/3): park | queue | fire
EOF
}

# val <field> <<< "$RESOLVE_OUTPUT" — pull one KEY=value line
val(){ sed -n "s/^$1=//p" | head -1; }

cmd_resolve(){ hq_resolve "$*"; }

cmd_status(){
  local q="$*" R rc
  R="$(hq_resolve "$q")"; rc=$?
  local repo path psrc rebal_name rebal_tier rebal_value pmode pstartup pdev
  local xyz_path xyz_tick xyz_commit lmode lrouter lagents lroadmap lpddash ldocs lmara
  repo="$(printf '%s\n' "$R"      | val REPO)"
  path="$(printf '%s\n' "$R"      | val REPO_PATH)"
  psrc="$(printf '%s\n' "$R"      | val REPO_PATH_SOURCE)"
  rebal_name="$(printf '%s\n' "$R"  | val REBAL_NAME)"
  rebal_tier="$(printf '%s\n' "$R"  | val REBAL_TIER)"
  rebal_value="$(printf '%s\n' "$R" | val REBAL_VALUE)"
  pmode="$(printf '%s\n' "$R"     | val PDDA_MODE)"
  pstartup="$(printf '%s\n' "$R"  | val PDDA_STARTUP)"
  pdev="$(printf '%s\n' "$R"      | val PDDA_DEVICE)"
  xyz_path="$(printf '%s\n' "$R"  | val XYZ_PATH)"
  xyz_tick="$(printf '%s\n' "$R"  | val XYZ_TICK)"
  xyz_commit="$(printf '%s\n' "$R" | val XYZ_COMMIT)"

  echo "HQ · project card"
  printf '  query:        %s\n' "$q"
  if [ "$rc" != 0 ] || [ -z "$path" ]; then
    printf '  repo:         %s (candidate)\n' "$repo"
    echo   '  path:         UNRESOLVED — no registry or filesystem match'
    echo
    echo   '  Try a bare repo name, or confirm the repo is cloned under one of:'
    printf '    %s\n' "${HQ_SEARCH_ROOTS//:/$'\n    '}"
    echo   '  Fallback find recipe:'
    printf '    find ~ -type d -name "%s" -exec test -d "{}/.git" \\; -print\n' "$repo"
    return 1
  fi

  # repo-local governance facts (authoritative over the registries)
  local I
  I="$(hq_inspect_repo "$path")"
  lmode="$(printf '%s\n' "$I"    | val LOCAL_PDDA_MODE)"
  lrouter="$(printf '%s\n' "$I"  | val LOCAL_ROUTER)"
  lagents="$(printf '%s\n' "$I"  | val LOCAL_AGENTS)"
  lroadmap="$(printf '%s\n' "$I" | val LOCAL_ROADMAP)"
  lpddash="$(printf '%s\n' "$I"  | val LOCAL_PDDA_SH)"
  ldocs="$(printf '%s\n' "$I"    | val LOCAL_ACTIVE_DOCS)"
  lmara="$(printf '%s\n' "$I"    | val LOCAL_MARATHON)"

  # capability tier: PDDA present (registry OR on-disk) AND XYZ install present
  local has_pdda=0 has_xyz=0 tier tierdesc
  { [ -n "$pmode" ] || [ -n "$lpddash" ] || [ -n "$lmode" ]; } && has_pdda=1
  [ -n "$xyz_path" ] && has_xyz=1
  tier="$(hq_tier "$has_pdda" "$has_xyz")"
  case "$tier" in
    A) tierdesc="PDDA + XYZ (dispatch-eligible)";;
    B) tierdesc="PDDA only (intake only, no dispatch)";;
    C) tierdesc="bare repo (plain issue only)";;
  esac

  printf '  repo:         %s\n' "$repo"
  printf '  path:         %s  (via %s)\n' "$path" "$psrc"
  printf '  capability:   Tier %s — %s\n' "$tier" "$tierdesc"
  echo
  if [ -n "$rebal_name" ]; then
    printf '  Rebalance:    %s · priority tier %s · value %s\n' \
      "$rebal_name" "${rebal_tier:-–}" "${rebal_value:-–}"
  else
    echo   '  Rebalance:    (no project_registry match)'
  fi
  if [ -n "$pmode" ]; then
    printf '  PDDA rails:   mode %s · startup_docs %s · (git-pulse: %s)\n' "$pmode" "${pstartup:-?}" "${pdev:-?}"
  else
    echo   '  PDDA rails:   (not in any git-pulse registry)'
  fi
  printf '  local mode:   %s\n' "${lmode:-– (no .pdda-mode)}"
  printf '  startup docs: ROUTER %s  AGENTS %s  ROADMAP %s\n' \
    "$([ -n "$lrouter" ] && echo ✓ || echo ✗)" \
    "$([ -n "$lagents" ] && echo ✓ || echo ✗)" \
    "$([ -n "$lroadmap" ] && echo ✓ || echo ✗)"
  printf '  active docs:  %s in PROJECT/2-WORKING\n' "${ldocs:-0}"
  printf '  marathon:     %s\n' "${lmara:-(none open)}"
  if [ -n "$xyz_path" ]; then
    printf '  XYZ install:  yes · tick %s · harness commit %s\n' "${xyz_tick:-?}" "${xyz_commit:-?}"
    echo   '                (run `relay-automation/xyz-sync.sh check` for the authoritative drift verdict)'
  else
    echo   '  XYZ install:  no (cannot run driven lanes)'
  fi
  return 0
}

cmd_registries(){
  echo "HQ · registry introspection (Phase 0)"
  echo
  echo "1. Rebalance project_registry — semantic project names + priority (no local path)"
  printf '   db: %s\n' "$HQ_REBALANCE_DB"
  if [ -f "$HQ_REBALANCE_DB" ] && command -v sqlite3 >/dev/null 2>&1; then
    printf '   projects: %s\n' "$(sqlite3 "$HQ_REBALANCE_DB" 'SELECT count(*) FROM project_registry;' 2>/dev/null)"
  else
    echo '   (unavailable — db missing or sqlite3 absent)'
  fi
  echo
  echo "2. XYZ install registry — repo -> ABSOLUTE PATH + runnable/drift stamps"
  printf '   tsv: %s\n' "$HQ_XYZ_REGISTRY"
  if [ -f "$HQ_XYZ_REGISTRY" ]; then
    printf '   installs: %s\n' "$(grep -vcE '^\s*(#|$)' "$HQ_XYZ_REGISTRY" 2>/dev/null)"
  else
    echo '   (unavailable)'
  fi
  echo
  echo "3. Git Pulse PDDA registry — repo -> PDDA mode + startup_docs (device-partitioned, no path)"
  printf '   dir: %s\n' "$HQ_PDDA_REGISTRY_DIR"
  if [ -d "$HQ_PDDA_REGISTRY_DIR" ]; then
    local f
    for f in "$HQ_PDDA_REGISTRY_DIR"/registry-*.tsv; do
      [ -f "$f" ] || continue
      printf '   %s: %s repos\n' \
        "$(basename "$f" | sed 's/^registry-//; s/\.tsv$//')" \
        "$(grep -vcE '^\s*(#|$)' "$f" 2>/dev/null)"
    done
  else
    echo '   (unavailable)'
  fi
  echo
  echo "Resolution order: rebalance NAME -> repo -> XYZ path (else filesystem find) -> PDDA governance."
}

case "${1:-}" in
  resolve)    shift; [ $# -ge 1 ] || { usage; exit 2; }; cmd_resolve "$@";;
  status)     shift; [ $# -ge 1 ] || { usage; exit 2; }; cmd_status "$@";;
  registries) cmd_registries;;
  park|queue|fire)
    echo "hq: '$1' is a Phase 2/3 verb — not built yet (this prototype is read-only)." >&2
    echo "    Phase 1 provides: resolve, status, registries." >&2
    exit 3;;
  ''|-h|--help) usage;;
  *) echo "hq: unknown subcommand '$1'" >&2; usage; exit 2;;
esac
