#!/usr/bin/env bash
set -uo pipefail

FIXTURE_DIR=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --fixture) FIXTURE_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg $1" >&2; exit 1 ;;
  esac
done

if [[ -n "$FIXTURE_DIR" && -f "$FIXTURE_DIR/branch.txt" ]]; then
  branch=$(cat "$FIXTURE_DIR/branch.txt")
else
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
fi

run_mock() {
  local id="$1"
  shift
  if [[ -n "$FIXTURE_DIR" ]]; then
    if [[ -f "$FIXTURE_DIR/$id.rc" ]]; then
      local rc=$(cat "$FIXTURE_DIR/$id.rc")
      [[ -f "$FIXTURE_DIR/$id.txt" ]] && cat "$FIXTURE_DIR/$id.txt"
      return $rc
    fi
    if [[ -f "$FIXTURE_DIR/$id.txt" ]]; then
      cat "$FIXTURE_DIR/$id.txt"
      return 0
    fi
    # Assume ok but empty output for unspecified mocks to avoid crashing other lenses
    return 0
  fi
  "$@"
}

lens2_status="ok"
lens2_deg="null"
lens2_cands="[]"

if out=$(run_mock "lens2" git status --porcelain); then
  cands="[]"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    st="${line:0:2}"
    path="${line:3}"
    # exclude untracked paths under PARKED/
    if [[ "$st" == "??" && "$path" == PARKED/* ]]; then
      continue
    fi
    cand=$(jq -n \
      --arg key "file:$path" \
      --arg what "commit or discard $path" \
      --arg evtype "status" \
      --arg evpay "$path" \
      --arg close "git add \"$path\" && git commit -m \"updated $path\"" \
      --arg lstate "$line" \
      '{
        key: $key,
        what: $what,
        evidence_type: $evtype,
        evidence_payload: $evpay,
        staleness: null,
        close: $close,
        close_kind: "command",
        live_state: $lstate
      }')
    cands=$(echo "$cands" | jq --argjson c "$cand" '. + [$c]')
  done <<< "$out"
  lens2_cands="$cands"
else
  lens2_status="degraded"
  lens2_deg="\"D5\""
fi

lens3_status="ok"
lens3_deg="null"
lens3_cands="[]"

if out=$(run_mock "lens3" git rev-list --left-right --count "@{upstream}...HEAD" 2>/dev/null); then
  behind=$(echo "$out" | awk '{print $1}')
  ahead=$(echo "$out" | awk '{print $2}')
  up_state="tracked"
else
  if out=$(run_mock "lens3_fallback" git rev-list --left-right --count "main...HEAD" 2>/dev/null); then
    behind=$(echo "$out" | awk '{print $1}')
    ahead=$(echo "$out" | awk '{print $2}')
    up_state="no-upstream"
  else
    lens3_status="degraded"
    lens3_deg="\"D5\""
  fi
fi

if [[ "$lens3_status" == "ok" ]]; then
  if [[ -n "${ahead:-}" && -n "${behind:-}" ]] && [[ "$ahead" -gt 0 || "$behind" -gt 0 ]]; then
    if [[ "$up_state" == "no-upstream" ]]; then
      close="inspect: git push?"
    else
      close="git push"
    fi
    clean_tree=true
    if [[ -n "$(run_mock "lens3_status" git status --porcelain 2>/dev/null)" ]]; then
      clean_tree=false
    fi
    cand=$(jq -n \
      --arg key "branch:$branch" \
      --arg what "sync branch" \
      --arg evtype "branch" \
      --arg evpay "${behind} behind, ${ahead} ahead" \
      --arg close "$close" \
      --arg lstate "${behind}_${ahead}_${up_state}" \
      --arg ahead "$ahead" \
      --arg behind "$behind" \
      --arg upstate "$up_state" \
      --argjson clt "$clean_tree" \
      '{
        key: $key,
        what: $what,
        evidence_type: $evtype,
        evidence_payload: $evpay,
        staleness: null,
        close: $close,
        close_kind: "command",
        live_state: $lstate,
        ahead: ($ahead | tonumber),
        behind: ($behind | tonumber),
        upstream_state: $upstate,
        clean_tree: $clt
      }')
    lens3_cands="[$cand]"
  fi
fi

lens7_status="ok"
lens7_deg="null"
lens7_cands="[]"

if out=$(run_mock "lens7" python3 utils/py/releases_app.py roadmap sync --dry-run 2>/dev/null); then
  if ! echo "$out" | grep -q "already in sync" && [[ -n "$out" ]]; then
    cand=$(jq -n \
      --arg key "ledger:roadmap" \
      --arg what "sync ROADMAP ledger" \
      --arg evtype "ledger" \
      --arg evpay "roadmap_diverged" \
      --arg close "python3 utils/py/releases_app.py roadmap sync" \
      --arg lstate "$out" \
      '{
        key: $key,
        what: $what,
        evidence_type: $evtype,
        evidence_payload: $evpay,
        staleness: null,
        close: $close,
        close_kind: "command",
        live_state: $lstate
      }')
    lens7_cands="[$cand]"
  fi
else
  lens7_status="degraded"
  lens7_deg="\"D4\""
fi

cat <<EOF
{"repo": {"branch": "$branch"},
 "lenses": {
   "2": {"status": "$lens2_status", "degraded_id": $lens2_deg, "candidates": $lens2_cands},
   "3": {"status": "$lens3_status", "degraded_id": $lens3_deg, "candidates": $lens3_cands},
   "7": {"status": "$lens7_status", "degraded_id": $lens7_deg, "candidates": $lens7_cands}
 }
}
EOF
