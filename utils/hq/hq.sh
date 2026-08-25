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
#
# Phase 2 adds `park` — the first WRITE path — which PREVIEWS by default and only writes with
# --create (creating a real GitHub issue is outward-facing; preview-first is the safe default).
# `queue`/`fire` remain Phase 3 (gated notices).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
HQ_GH_BIN="${HQ_GH_BIN:-gh}"   # seam: tests point this at a stub
HQ_GIT_BIN="${HQ_GIT_BIN:-git}"   # seam: promote's git mv (tests can point at a stub)
# shellcheck source=utils/hq/hq-lib.sh
. "$HERE/hq-lib.sh"

usage(){
  cat >&2 <<'EOF'
HQ — multi-repo command-center (read-only prototype, GH-128)

usage:
  hq.sh resolve <project|repo>            machine-readable KEY=value resolution
  hq.sh status  <project|repo>            human-readable project card
  hq.sh registries                        what each registry knows (Phase-0 introspection)
  hq.sh next [--limit N]                   projects ranked by Rebalance priority + HQ capability tier
  hq.sh park [--create] [--title T] <project> <req…>
                                          issue-first intake in the target repo
                                          (PREVIEWS by default; --create writes;
                                           --title sets a clean title, request = body)
                                          Capture doc renders the full PDDA skeleton (TODO stubs by
                                          default); optional synthesis passthrough via env vars
                                          HQ_PARK_{WHY,KEY_CONCEPTS,NON_GOALS,RELATED,COMPLEXITY,
                                          RISK,EFFORT,PHASES} (GH-164 Phase 1).
  hq.sh queue [--create] [--gh-issue N] <project> <req…>
                                          append an HQ-queued lane to the target's Marathon Plan
                                          (PREVIEWS by default; --create appends, non-destructive)
  hq.sh promote [--create] --gh-issue N <project>
                                          PDDA 1-INBOX → 2-WORKING: git mv GH-N-*.md + scaffold the
                                          2-WORKING contract (PREVIEWS by default; --create moves)
  hq.sh fire --gh-issue N [--risk 1-5] <project>
                                          GATED prepare-and-hand-off: resolve + gate (Tier A,
                                          risk<3) + emit the swarm-preflight command. Never drives
                                          the harness itself (operator decides — §8).
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

  local via cands
  via="$(printf '%s\n' "$R" | val RESOLVED_VIA)"
  cands="$(printf '%s\n' "$R" | val CANDIDATES)"

  echo "HQ · project card"
  printf '  query:        %s\n' "$q"
  if [ "$rc" = 2 ]; then
    echo   '  path:         AMBIGUOUS — the name matches more than one repo'
    printf '  candidates:   %s\n' "${cands//,/, }"
    echo   '  Re-run with a more specific name (a candidate above).'
    return 2
  fi
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
  
  local lnext lroadmap_open ldash_stale
  lnext="$(printf '%s\n' "$I" | val LOCAL_NEXT_RELEASE)"
  lroadmap_open="$(printf '%s\n' "$I" | val LOCAL_ROADMAP_OPEN)"
  ldash_stale="$(printf '%s\n' "$I" | val LOCAL_DASHBOARD_STALE)"

  # capability tier: PDDA present (registry OR on-disk) AND XYZ install present
  local has_pdda=0 has_xyz=0 tier tierdesc
  { [ -n "$pmode" ] || [ -n "$lpddash" ] || [ -n "$lmode" ]; } && has_pdda=1
  local is_releases=0
  if grep -q "ROADMAP_SOURCE=releases" "$path/.pdda-mode" 2>/dev/null; then
    is_releases=1
  fi
  [ -n "$xyz_path" ] && has_xyz=1
  tier="$(hq_tier "$has_pdda" "$has_xyz")"
  case "$tier" in
    A) tierdesc="PDDA + XYZ (dispatch-eligible)";;
    B) tierdesc="PDDA only (intake only, no dispatch)";;
    C) tierdesc="bare repo (plain issue only)";;
  esac

  printf '  repo:         %s%s\n' "$repo" "$([ "$via" = fuzzy ] && echo '  (fuzzy match — confirm this is right)')"
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
  local rmap_label="ROADMAP"
  local rmap_check="$([ -n "$lroadmap" ] && echo ✓ || echo ✗)"
  if [ "$is_releases" = "1" ]; then
    rmap_label="RELEASES-DB"
    if [ "$lroadmap" = "broken" ]; then
      rmap_check="✗ (releases-mode declared, but releases.db or CLI missing)"
    elif [ -n "$lroadmap" ]; then
      rmap_check="✓"
      local dash_txt="dashboard ✓"
      [ "$ldash_stale" = "yes" ] && dash_txt="dashboard ✗ stale"
      rmap_check="$rmap_check ($dash_txt, $lroadmap_open open roadmap items)"
    fi
  fi
  
  printf '  startup docs: ROUTER %s  AGENTS %s  %s %s\n' \
    "$([ -n "$lrouter" ] && echo ✓ || echo ✗)" \
    "$([ -n "$lagents" ] && echo ✓ || echo ✗)" \
    "$rmap_label" "$rmap_check"
    
  if [ "$is_releases" = "1" ] && [ "$lroadmap" != "broken" ] && [ -n "$lnext" ]; then
    printf '  next release: %s\n' "$lnext"
  fi
  
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

# cmd_park <create 0|1> <project> <request...>
# Preview (default) or --create the issue-first intake in the RESOLVED TARGET repo:
# GH issue -> PROJECT/1-INBOX/GH-<n>-<SLUG>.md capture -> ROADMAP queue pointer -> target pdda check.
#
# GH-164 Phase 1: optional synthesis passthrough via env vars (unset -> hq_render_capture's own
# TODO-stub defaults; a bare zero-flag `hq park <project> <request>` is byte-identical to before).
# A front end (e.g. the /idea skill) exports these before calling `hq park --create` to fill in the
# judgment-heavy prose a deterministic bash template cannot synthesize itself:
#   HQ_PARK_COMPLEXITY / HQ_PARK_RISK / HQ_PARK_EFFORT / HQ_PARK_PHASES  — integers 1-5 / phase count
#   HQ_PARK_WHY                                                          — the ## Why paragraph
#   HQ_PARK_KEY_CONCEPTS / HQ_PARK_NON_GOALS / HQ_PARK_RELATED           — pipe ('|')-delimited lists
cmd_park(){
  local create="$1" ptitle="$2" project="$3"; shift 3; local request="$*"
  # GH-164 Phase 1: read the optional synthesis passthrough once; all unset -> hq_render_capture's
  # own TODO-stub defaults (empty strings here reproduce the pre-Phase-1 bare-call behavior exactly).
  local p_complexity="${HQ_PARK_COMPLEXITY:-}" p_risk="${HQ_PARK_RISK:-}" p_effort="${HQ_PARK_EFFORT:-}" p_phases="${HQ_PARK_PHASES:-}"
  local p_why="${HQ_PARK_WHY:-}" p_kc="${HQ_PARK_KEY_CONCEPTS:-}" p_ng="${HQ_PARK_NON_GOALS:-}" p_rel="${HQ_PARK_RELATED:-}"
  local R rc; R="$(hq_resolve "$project")"; rc=$?
  local repo path tier has_pdda=0 has_xyz=0
  repo="$(printf '%s\n' "$R" | val REPO)"
  path="$(printf '%s\n' "$R" | val REPO_PATH)"
  if [ "$rc" = 2 ]; then
    local cands; cands="$(printf '%s\n' "$R" | val CANDIDATES)"
    echo "hq park: '$project' is AMBIGUOUS — matches: ${cands//,/, }" >&2
    echo "  re-run with a specific repo name so intake lands in the right repo." >&2
    return 2
  fi
  if [ "$rc" != 0 ] || [ -z "$path" ]; then
    echo "hq park: '$project' is UNRESOLVED — cannot file intake without a target repo." >&2
    printf '  find ~ -type d -name "%s" -exec test -d "{}/.git" \\; -print\n' "$repo" >&2
    return 1
  fi
  { [ -n "$(printf '%s\n' "$R" | val PDDA_MODE)" ] || [ -f "$path/utils/pdda/pdda.sh" ] || [ -f "$path/.pdda-mode" ]; } && has_pdda=1
  [ -n "$(printf '%s\n' "$R" | val XYZ_PATH)" ] && has_xyz=1
  local is_releases=0
  if grep -q "ROADMAP_SOURCE=releases" "$path/.pdda-mode" 2>/dev/null; then
    is_releases=1
  fi
  tier="$(hq_tier "$has_pdda" "$has_xyz")"

  local title slug created oslug src
  # --title (if given) is used verbatim for the issue + capture-doc title; the request stays the body.
  title="${ptitle:-$(hq_issue_title "$project" "$request")}"
  slug="$(hq_slug "${ptitle:-$request}")"
  created="$(date +%F)"
  oslug="$(hq_target_slug "$path")"

  # ---- Tier C: bare repo -> plain issue only, no PDDA doc structure ----
  if [ "$tier" = C ]; then
    echo "HQ park · Tier C (bare repo) — plain GitHub issue only"
    printf '  target repo:  %s  (%s)\n' "$repo" "${oslug:-no origin}"
    printf '  issue title:  %s\n' "$title"
    echo   '  (no PDDA rails here — not writing a capture doc or ROADMAP pointer)'
    echo   "  suggestion:   install PDDA to unlock full intake — see install.sh / utils/pdda"
    if [ "$create" = 1 ]; then
      local out url
      out="$(cd "$path" && "$HQ_GH_BIN" issue create --title "$title" --body "$request" 2>&1)" || {
        echo "  gh issue create failed: $out" >&2; return 1; }
      url="$(printf '%s\n' "$out" | grep -oE 'https?://[^ ]+/issues/[0-9]+' | tail -1)"
      printf '  ✓ issue created: %s\n' "${url:-$out}"
    else
      echo; echo "  [preview only] re-run with --create to file the issue."
    fi
    return 0
  fi

  # ---- Tier A/B: full PDDA intake ----
  local num relpath docname roadmap="$path/ROADMAP.md"
  if [ "$create" != 1 ]; then
    num="<N>"; src="<assigned when the issue is created>"
    docname="GH-${num}-${slug}.md"; relpath="PROJECT/1-INBOX/$docname"
    echo "HQ park · Tier $tier — issue-first intake PREVIEW (writes nothing)"
    printf '  target repo:  %s  →  %s  (%s)\n' "$project" "$repo" "$path"
    printf '  GitHub issue: %s\n' "$title"
    printf '  capture doc:  %s\n' "$relpath"
    if [ "$is_releases" = "1" ]; then
      printf '  ROADMAP sink: releases roadmap add\n'
    else
      printf '  ROADMAP line: %s\n' "$(hq_roadmap_line "$num" "$title" "$created" "$relpath" "$docname" "#")"
    fi
    echo
    echo "  --- capture doc that would be written ---"
    hq_render_capture "$num" "$src" "$title" "$created" "feedback" "$project" "$repo" "$request" \
      "$p_complexity" "$p_risk" "$p_effort" "$p_phases" "$p_why" "$p_kc" "$p_ng" "$p_rel" \
      | sed 's/^/  | /'
    echo
    echo "  [preview only] re-run with --create to file the issue + write the two docs into the target."
    return 0
  fi

  # --create: real intake
  echo "HQ park · Tier $tier — creating intake in $repo …"
  # dup-guard (best-effort; never blocks on gh error)
  local dup
  dup="$(cd "$path" && "$HQ_GH_BIN" issue list --search "$title" --state open --json number,title 2>/dev/null)" || dup=""
  if printf '%s' "$dup" | grep -q '"number"'; then
    echo "  ! possible duplicate open issue matching this title — aborting to avoid double-filing:" >&2
    printf '    %s\n' "$dup" >&2
    echo "    (refine the request or file manually if this is genuinely new)" >&2
    return 1
  fi
  local out url
  out="$(cd "$path" && "$HQ_GH_BIN" issue create --title "$title" --body "$request" 2>&1)" || {
    echo "  gh issue create failed: $out" >&2; return 1; }
  url="$(printf '%s\n' "$out" | grep -oE 'https?://[^ ]+/issues/[0-9]+' | tail -1)"
  num="$(printf '%s' "$url" | grep -oE '[0-9]+$')"
  [ -n "$num" ] || { echo "  could not parse issue number from: $out" >&2; return 1; }
  src="$url"
  docname="GH-${num}-${slug}.md"; relpath="PROJECT/1-INBOX/$docname"

  mkdir -p "$path/PROJECT/1-INBOX"
  hq_render_capture "$num" "$src" "$title" "$created" "feedback" "$project" "$repo" "$request" \
    "$p_complexity" "$p_risk" "$p_effort" "$p_phases" "$p_why" "$p_kc" "$p_ng" "$p_rel" \
    > "$path/$relpath"
  printf '  ✓ issue:   %s\n' "$url"
  printf '  ✓ capture: %s\n' "$relpath"

  if [ "$is_releases" = "1" ]; then
    local out
    out="$(cd "$path" && python3 utils/py/releases_app.py roadmap add --issue-num "$num" --issue-url "$url" --title "$title" --created "$created" --doc-path "$relpath" 2>&1)"
    if [ $? -eq 0 ]; then
      printf '  ✓ DB: pointer added via releases CLI\n'
    else
      echo "  ! releases roadmap add failed: $out" >&2
      return 1
    fi
  else
    if [ -f "$roadmap" ]; then
      local where
      where="$(hq_roadmap_insert "$roadmap" "$(hq_roadmap_line "$num" "$title" "$created" "$relpath" "$docname" "$url")")"
      printf '  ✓ ROADMAP: pointer added (%s)\n' "$where"
    else
      echo '  ! no ROADMAP.md in target — skipped the queue pointer (add one to complete intake)'
    fi
  fi

  # GH-164 Phase 1 item 2: regenerate the dashboard right after the ROADMAP write, closing the gap
  # the manual GH-161-164 trace hit twice (forgetting this step is exactly why it is automated here).
  # "Only if present" mirrors the pdda.sh frontmatter check below — never required, never fatal.
  if [ "$is_releases" = "1" ]; then
    if ( cd "$path" && python3 utils/py/releases_app.py gen >/dev/null 2>&1 ); then
      echo '  ✓ dashboard: RELEASES.md regenerated'
    else
      echo '  ! dashboard: releases gen failed — regenerate manually' >&2
    fi
  elif [ -f "$path/utils/roadmap-dashboard.sh" ]; then
    if ( cd "$path" && bash utils/roadmap-dashboard.sh >/dev/null 2>&1 ); then
      echo '  ✓ dashboard: ROADMAP-DASHBOARD.md regenerated'
    else
      echo '  ! dashboard: utils/roadmap-dashboard.sh failed — regenerate manually' >&2
    fi
  fi

  local fm_ok=1
  if [ -f "$path/utils/pdda/pdda.sh" ]; then
    if ( cd "$path" && PDDA_ONLY_FILE="$relpath" utils/pdda/pdda.sh frontmatter >/dev/null 2>&1 ); then
      echo '  ✓ pdda:    capture doc passes the target frontmatter check'
    else
      fm_ok=0
      echo '  ✗ pdda:    target frontmatter check FAILED on the capture doc — intake is incomplete' >&2
    fi
  fi
  echo "  (files written but NOT committed — review, then commit in the target repo)"
  # GH-132: don't report success on an invalid capture doc — fail hard so the operator fixes it.
  [ "$fm_ok" = 1 ] || { echo "  hq park: capture doc is not PDDA-valid — fix the frontmatter before promoting." >&2; return 1; }
}

# cmd_queue <create 0|1> <issue|-> <project> <request...>
# Preview or --create: append an HQ-queued lane to the target's newest Marathon Plan (non-destructive).
cmd_queue(){
  local create="$1" issue="$2" project="$3"; shift 3; local request="$*"
  local R rc; R="$(hq_resolve "$project")"; rc=$?
  local repo path; repo="$(printf '%s\n' "$R" | val REPO)"; path="$(printf '%s\n' "$R" | val REPO_PATH)"
  if [ "$rc" = 2 ]; then
    echo "hq queue: '$project' is AMBIGUOUS — matches: $(printf '%s\n' "$R" | val CANDIDATES | tr ',' ' ')" >&2; return 2
  fi
  [ "$rc" = 0 ] && [ -n "$path" ] || { echo "hq queue: '$project' is UNRESOLVED — no target repo." >&2; return 1; }

  # need PDDA rails + an existing marathon plan to queue into
  local has_pdda=0; { [ -n "$(printf '%s\n' "$R" | val PDDA_MODE)" ] || [ -f "$path/utils/pdda/pdda.sh" ] || [ -f "$path/.pdda-mode" ]; } && has_pdda=1
  [ "$has_pdda" = 1 ] || { echo "hq queue: $repo is Tier C (no PDDA) — nothing to queue into; use 'park' for a plain issue." >&2; return 1; }
  local mara; mara="$(hq_inspect_repo "$path" | val LOCAL_MARATHON)"
  if [ -z "$mara" ]; then
    echo "hq queue: $repo has no open MARATHON-*.md in PROJECT/2-WORKING — create one first, or 'park' the request." >&2
    return 1
  fi
  local plan="$path/PROJECT/2-WORKING/$mara" title created tier
  title="$(hq_issue_title "$project" "$request")"
  created="$(date +%F)"
  tier="$(hq_tier "$has_pdda" "$([ -n "$(printf '%s\n' "$R" | val XYZ_PATH)" ] && echo 1 || echo 0)")"

  if [ "$create" != 1 ]; then
    echo "HQ queue · PREVIEW (writes nothing) — would append to $mara"
    printf '  target plan:  %s\n' "PROJECT/2-WORKING/$mara"
    echo "  --- lane block that would be appended ---"
    hq_queue_lane_block "$title" "$created" "$tier" "$issue" | sed 's/^/  | /'
    echo "  [preview only] re-run with --create to append the lane."
    return 0
  fi
  hq_queue_lane_block "$title" "$created" "$tier" "$issue" >> "$plan"
  echo "HQ queue · appended an HQ-queued lane to $repo"
  printf '  ✓ plan:    %s\n' "PROJECT/2-WORKING/$mara"
  echo "  (appended, NOT committed — review + rate + slot into a wave before firing)"
}

# cmd_promote <create> <issue> <project> — PDDA 1-INBOX → 2-WORKING transition (GH-138). Mirrors
# cmd_park/cmd_queue: PREVIEWS by default, --create moves + scaffolds. Mechanical + honest — it does
# the git mv + fills the derivable frontmatter/status-table so the result passes the enforced
# 2-WORKING contract, then tells the operator to rate + fill the real Status + QA gates.
cmd_promote(){
  local create="$1" issue="$2" project="$3"
  local R rc; R="$(hq_resolve "$project")"; rc=$?
  local repo path; repo="$(printf '%s\n' "$R" | val REPO)"; path="$(printf '%s\n' "$R" | val REPO_PATH)"
  if [ "$rc" = 2 ]; then
    echo "hq promote: '$project' is AMBIGUOUS — matches: $(printf '%s\n' "$R" | val CANDIDATES | tr ',' ' ')" >&2; return 2
  fi
  [ "$rc" = 0 ] && [ -n "$path" ] || { echo "hq promote: '$project' is UNRESOLVED — no target repo." >&2; return 1; }
  [ -n "$issue" ] && [ "$issue" != "-" ] || { echo "hq promote: --gh-issue N is required (which 1-INBOX capture to promote)." >&2; return 2; }
  local has_pdda=0; { [ -n "$(printf '%s\n' "$R" | val PDDA_MODE)" ] || [ -f "$path/utils/pdda/pdda.sh" ] || [ -f "$path/.pdda-mode" ]; } && has_pdda=1
  [ "$has_pdda" = 1 ] || { echo "hq promote: $repo is Tier C (no PDDA) — no 1-INBOX/2-WORKING lifecycle to promote within." >&2; return 1; }

  local src_doc base
  src_doc="$(find "$path/PROJECT/1-INBOX" -maxdepth 1 -name "GH-${issue}-*.md" 2>/dev/null | sort | head -1)"
  [ -n "$src_doc" ] || { echo "hq promote: no PROJECT/1-INBOX/GH-${issue}-*.md in $repo — nothing to promote." >&2; return 1; }
  base="$(basename "$src_doc")"
  local dest="$path/PROJECT/2-WORKING/$base"
  [ -e "$dest" ] && { echo "hq promote: PROJECT/2-WORKING/$base already exists — refusing to overwrite." >&2; return 1; }

  local updated; updated="$(date +%F)"
  if [ "$create" != 1 ]; then
    echo "HQ promote · PREVIEW (writes nothing)"
    printf '  target repo:  %s  →  %s\n' "$project" "$repo"
    printf '  git mv:       PROJECT/1-INBOX/%s  →  PROJECT/2-WORKING/%s\n' "$base" "$base"
    echo   "  upgrade:      status→active · ensure updated/owner/goal · add a '## Status' table (2-WORKING contract)"
    echo   "  [preview only] re-run with --create to move + scaffold the doc."
    return 0
  fi

  echo "HQ promote · moving $base into 2-WORKING in $repo …"
  if ! ( cd "$path" && "$HQ_GIT_BIN" mv "PROJECT/1-INBOX/$base" "PROJECT/2-WORKING/$base" 2>/dev/null ); then
    mv "$src_doc" "$dest" || { echo "  move failed" >&2; return 1; }   # fallback: not git-tracked
  fi
  hq_promote_upgrade_doc "$dest" "$updated" || { echo "  frontmatter upgrade failed" >&2; return 1; }
  printf '  ✓ promoted: PROJECT/2-WORKING/%s\n' "$base"
  echo   "  (moved + scaffolded, NOT committed — set cx/risk/eff ratings, write the real ## Status, add QA gates, then commit)"
}

# cmd_fire <project> <issue> <risk|-> — GATED prepare-and-handoff. NEVER drives the harness itself:
# it resolves, gates, and emits the swarm-preflight command; the operator runs it + drives via the
# relay-xyz skill (GUIDING-PRINCIPLES §8 "operator decides"; the relay-xyz guard owns harness driving).
cmd_fire(){
  local project="$1" issue="$2" risk="$3"
  local R rc; R="$(hq_resolve "$project")"; rc=$?
  local repo path; repo="$(printf '%s\n' "$R" | val REPO)"; path="$(printf '%s\n' "$R" | val REPO_PATH)"
  if [ "$rc" = 2 ]; then
    echo "hq fire: '$project' is AMBIGUOUS — matches: $(printf '%s\n' "$R" | val CANDIDATES | tr ',' ' ')" >&2; return 2
  fi
  [ "$rc" = 0 ] && [ -n "$path" ] || { echo "hq fire: '$project' is UNRESOLVED — no target repo." >&2; return 1; }
  [ -n "$issue" ] || { echo "hq fire: requires --gh-issue <n> (dispatch operates on captured intake, not a raw request)." >&2; return 2; }

  # gate 1: Tier A (dispatch-eligible)
  local has_pdda=0 has_xyz=0
  { [ -n "$(printf '%s\n' "$R" | val PDDA_MODE)" ] || [ -f "$path/utils/pdda/pdda.sh" ] || [ -f "$path/.pdda-mode" ]; } && has_pdda=1
  [ -n "$(printf '%s\n' "$R" | val XYZ_PATH)" ] && has_xyz=1
  local is_releases=0
  if grep -q "ROADMAP_SOURCE=releases" "$path/.pdda-mode" 2>/dev/null; then
    is_releases=1
  fi
  if [ "$(hq_tier "$has_pdda" "$has_xyz")" != A ]; then
    echo "hq fire: $repo is not Tier A (needs PDDA + a vendored XYZ install to run driven lanes) — refusing." >&2
    return 1
  fi
  # gate 2: risk (a hard gate, not an addend — risk>=3 routes to a human; unknown risk holds)
  case "$risk" in
    ''|-) echo "hq fire: risk unknown — pass --risk N (1-5). Refusing to arm without it." >&2; return 1;;
    [3-5]) echo "hq fire: risk $risk >= 3 — routes to a human, not an auto-fire. Refusing." >&2; return 1;;
    [12]) : ;;
    *) echo "hq fire: --risk must be 1-5." >&2; return 2;;
  esac

  echo "HQ fire · GATES PASS — prepared dispatch for $repo #$issue (Tier A, risk $risk)"
  echo "  HQ does not drive the harness itself (operator decides — GUIDING-PRINCIPLES §8)."
  echo "  1) produce the run packet:"
  printf '       utils/swarm-preflight.sh --gh-issue %s --target-root %q\n' "$issue" "$path"
  echo "  2) drive the emitted packet via the relay-xyz skill (it owns sandbox rules + containment)."
  echo "  (nothing was executed — this is the armed, gated hand-off)"
}

# cmd_next [limit] — Phase 4: a Rebalance-priority-ranked board of projects with their HQ capability
# tier, so "what should I pick up next across my repos?" has one read-only answer. Rebalance stays
# read-only (mirrors the #96 seam discipline).
cmd_next(){
  local limit="${1:-8}" rows
  rows="$(hq_projects_by_priority "$limit")"
  if [ -z "$rows" ]; then
    echo "hq next: no Rebalance project_registry available (need the rebalance.db + sqlite3)." >&2
    return 1
  fi
  echo "HQ · next — projects by Rebalance priority (tier 1 = highest .. 5 = lowest)"
  echo
  printf '  %-3s %-26s %-4s %-4s %s\n' "#" "project" "tier" "cap" "status"
  local i=0 tier value status name repo fields path has_xyz has_pdda cap sw
  while IFS='|' read -r tier value status name; do
    [ -n "$name" ] || continue
    i=$((i + 1))
    repo="$(hq_bare "$name")"
    fields="$(hq_repo_resolve "$repo" "$name")"   # GH-132: name is owner/repo -> disambiguates collisions
    path="$(printf '%s\n' "$fields" | val REPO_PATH)"
    has_xyz=0; has_pdda=0
    [ -n "$(printf '%s\n' "$fields" | val XYZ_PATH)" ] && has_xyz=1
    { [ -n "$(printf '%s\n' "$fields" | val PDDA_MODE)" ] \
        || { [ -n "$path" ] && { [ -f "$path/utils/pdda/pdda.sh" ] || [ -f "$path/.pdda-mode" ]; }; }; } && has_pdda=1
    if [ -n "$path" ]; then cap="$(hq_tier "$has_pdda" "$has_xyz")"; else cap="-"; fi
    case "$cap" in
      A) sw="dispatch-eligible";;
      B) sw="intake only";;
      C) sw="bare repo";;
      *) sw="unresolved on this device";;
    esac
    printf '  %-3s %-26s %-4s %-4s %s\n' "$i" "$repo" "$tier" "$cap" "$sw"
  done <<EOF
$rows
EOF
  echo
  echo "  Priority from Rebalance project_registry (read-only). 'cap' = HQ capability tier."
  echo "  Run 'hq status <project>' for the full card, or 'hq park <project> \"<request>\"' to file work."
}

case "${1:-}" in
  resolve)    shift; [ $# -ge 1 ] || { usage; exit 2; }; cmd_resolve "$@";;
  status)     shift; [ $# -ge 1 ] || { usage; exit 2; }; cmd_status "$@";;
  registries) cmd_registries;;
  next)
    shift
    nlimit=8
    while [ $# -gt 0 ]; do
      case "$1" in
        --limit) shift; nlimit="${1:-8}";;
        --limit=*) nlimit="${1#--limit=}";;
      esac
      shift
    done
    cmd_next "$nlimit";;
  park)
    shift
    create=0; ptitle=""; pargs=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --create|--yes) create=1;;
        --title) shift; ptitle="${1:-}";;
        --title=*) ptitle="${1#--title=}";;
        *) pargs+=("$1");;
      esac
      shift
    done
    [ "${#pargs[@]}" -ge 2 ] || { echo "usage: hq.sh park [--create] [--title T] <project> <request...>" >&2; exit 2; }
    cmd_park "$create" "$ptitle" "${pargs[@]}";;
  queue)
    shift
    create=0; issue="-"; qargs=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --create|--yes) create=1;;
        --gh-issue) shift; issue="${1:-}";;
        --gh-issue=*) issue="${1#--gh-issue=}";;
        *) qargs+=("$1");;
      esac
      shift
    done
    [ "${#qargs[@]}" -ge 2 ] || { echo "usage: hq.sh queue [--create] [--gh-issue N] <project> <request...>" >&2; exit 2; }
    cmd_queue "$create" "$issue" "${qargs[@]}";;
  promote)
    shift
    create=0; issue=""; prargs=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --create|--yes) create=1;;
        --gh-issue) shift; issue="${1:-}";;
        --gh-issue=*) issue="${1#--gh-issue=}";;
        *) prargs+=("$1");;
      esac
      shift
    done
    [ "${#prargs[@]}" -ge 1 ] || { echo "usage: hq.sh promote [--create] --gh-issue N <project>" >&2; exit 2; }
    cmd_promote "$create" "$issue" "${prargs[0]}";;
  fire)
    shift
    issue=""; risk="-"; fargs=()
    while [ $# -gt 0 ]; do
      case "$1" in
        --gh-issue) shift; issue="${1:-}";;
        --gh-issue=*) issue="${1#--gh-issue=}";;
        --risk) shift; risk="${1:-}";;
        --risk=*) risk="${1#--risk=}";;
        *) fargs+=("$1");;
      esac
      shift
    done
    [ "${#fargs[@]}" -ge 1 ] || { echo "usage: hq.sh fire --gh-issue N [--risk 1-5] <project>" >&2; exit 2; }
    cmd_fire "${fargs[0]}" "$issue" "$risk";;
  ''|-h|--help) usage;;
  *) echo "hq: unknown subcommand '$1'" >&2; usage; exit 2;;
esac
