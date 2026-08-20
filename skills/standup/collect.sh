#!/usr/bin/env bash
set -uo pipefail

FIXTURE_DIR=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --fixture) FIXTURE_DIR="$2"; shift 2 ;;
    *) echo "Unknown arg $1" >&2; exit 1 ;;
  esac
done

# `jq` is this collector's only external dependency beyond git and coreutils, and it is load-bearing:
# every candidate and the branch name are JSON-encoded through it, precisely so a path or ref
# containing a quote cannot produce invalid JSON at exit 0. Nothing else under skills/, utils/ or
# relay-automation/ uses jq, and the repo's own quickstart asks only for Node and git — so on a clone
# where it is absent the collector would die at the first `jq -n` with exit 127 and print NOTHING.
#
# That is the failure this whole design exists to prevent, one level up: the consumer reads stdin, and
# an empty stdin is indistinguishable from "the session is clean". Degrade LOUDLY instead — emit a
# well-formed document that triage.py can still consume, with every lens carrying D5 ("a lens cannot
# supply all six fields", the spec's degradation table), and exit non-zero so a caller that checks
# knows. Hand-written rather than built with jq for the obvious reason.
if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' '{"repo": {"branch": "unknown"},' \
    ' "lenses": {' \
    '   "2": {"status": "degraded", "degraded_id": "D5", "candidates": []},' \
    '   "3": {"status": "degraded", "degraded_id": "D5", "candidates": []},' \
    '   "7": {"status": "degraded", "degraded_id": "D5", "candidates": []}' \
    ' }' \
    '}'
  echo "collect.sh: jq is required and was not found on PATH — every lens degraded (D5)." >&2
  exit 3
fi

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
    echo "Missing fixture: $id" >&2
    return 1
  fi
  "$@"
}

lens2_status="ok"
lens2_deg="null"
lens2_cands="[]"

set +e
out=$(run_mock "lens2" git status --porcelain)
rc2=$?
set -e
if [[ $rc2 -eq 0 ]]; then
  cands="[]"
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    st="${line:0:2}"
    path="${line:3}"
    # exclude untracked paths under PARKED/
    if [[ "$st" == "??" && "$path" == PARKED/* ]]; then
      continue
    fi
    if [[ -n "$FIXTURE_DIR" && -f "$FIXTURE_DIR/stat_${path//\//_}.txt" ]]; then
      mtime=$(cat "$FIXTURE_DIR/stat_${path//\//_}.txt")
    else
      mtime=$(python3 -c "import os, sys; print(int(os.path.getmtime(sys.argv[1])))" "$path" 2>/dev/null || echo null)
    fi
    cand=$(jq -n \
      --arg key "path:$path" \
      --arg what "commit or discard $path" \
      --arg evtype "path" \
      --arg evpay "$path" \
      --arg close "git add \"$path\" && git commit -m \"updated $path\"" \
      --arg lstate "$st" \
      --arg mtime "$mtime" \
      '{
        key: $key,
        what: $what,
        evidence_type: $evtype,
        evidence_payload: $evpay,
        staleness: ($mtime | if . == "null" then null else tonumber end),
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

set +e
out=$(run_mock "lens3" git rev-list --left-right --count "@{upstream}...HEAD" 2>/dev/null)
rc3=$?
set -e
if [[ $rc3 -eq 0 ]]; then
  behind=$(echo "$out" | awk '{print $1}')
  ahead=$(echo "$out" | awk '{print $2}')
  if [[ -n "${ahead:-}" && -n "${behind:-}" && "$behind" =~ ^[0-9]+$ && "$ahead" =~ ^[0-9]+$ ]]; then
    up_state="tracked"
  else
    lens3_status="degraded"
    lens3_deg="\"D5\""
  fi
elif [[ $rc3 -eq 128 ]]; then
  set +e
  out=$(run_mock "lens3_fallback" git rev-list --left-right --count "development...HEAD" 2>/dev/null)
  rc_fall=$?
  set -e
  if [[ $rc_fall -eq 0 ]]; then
    behind=$(echo "$out" | awk '{print $1}')
    ahead=$(echo "$out" | awk '{print $2}')
    if [[ -n "${ahead:-}" && -n "${behind:-}" && "$behind" =~ ^[0-9]+$ && "$ahead" =~ ^[0-9]+$ ]]; then
      up_state="no-upstream"
    else
      lens3_status="degraded"
      lens3_deg="\"D5\""
    fi
  else
    lens3_status="degraded"
    lens3_deg="\"D5\""
  fi
else
  lens3_status="degraded"
  lens3_deg="\"D5\""
fi

if [[ "$lens3_status" == "ok" ]]; then
  if [[ -n "${ahead:-}" && -n "${behind:-}" ]] && [[ "$ahead" -gt 0 || "$behind" -gt 0 ]]; then
    if [[ "$up_state" == "no-upstream" ]]; then
      close="inspect: branch $branch (push state unknown, no upstream)"
      close_kind="inspect"
    else
      close="git push"
      close_kind="command"
    fi
    clean_tree=true
    set +e
    out_status=$(run_mock "lens3_status" git status --porcelain 2>/dev/null)
    rc_status=$?
    set -e
    if [[ $rc_status -ne 0 ]]; then
      lens3_status="degraded"
      lens3_deg="\"D5\""
      lens3_cands="[]"
    else
      if [[ -n "$out_status" ]]; then
        clean_tree=false
      fi
      cand=$(jq -n \
        --arg key "branch:$branch" \
        --arg what "sync branch" \
        --arg evtype "counts" \
        --arg evpay "${ahead}/${behind}@${up_state}" \
        --arg close "$close" \
        --arg lstate "${ahead}/${behind}/${up_state}" \
        --arg ahead "$ahead" \
        --arg behind "$behind" \
        --arg upstate "$up_state" \
        --arg close_kind "$close_kind" \
        --argjson clt "$clean_tree" \
        '{
          key: $key,
          what: $what,
          evidence_type: $evtype,
          evidence_payload: $evpay,
          staleness: null,
          close: $close,
          close_kind: $close_kind,
          live_state: $lstate,
          ahead: ($ahead | tonumber),
          behind: ($behind | tonumber),
          upstream_state: $upstate,
          clean_tree: $clt
        }')
      lens3_cands="[$cand]"
    fi
  fi
fi

lens7_status="ok"
lens7_deg="null"
lens7_cands="[]"

set +e
out=$(run_mock "lens7" python3 utils/py/releases_app.py roadmap sync --dry-run 2>/dev/null)
rc7=$?
set -e
if [[ $rc7 -eq 0 ]]; then
  if ! echo "$out" | grep -q "already in sync" && [[ -n "$out" ]]; then
    a=$(echo "$out" | grep -E -o '\+[0-9]+ added' | grep -E -o '[0-9]+' || echo "0")
    u=$(echo "$out" | grep -E -o '~[0-9]+ updated' | grep -E -o '[0-9]+' || echo "0")
    r=$(echo "$out" | grep -E -o -- '-[0-9]+ removed' | grep -E -o '[0-9]+' || echo "0")
    evpay="+${a}~${u}-${r}"
    cand=$(jq -n \
      --arg key "ledger:roadmap" \
      --arg what "sync ROADMAP ledger" \
      --arg evtype "counts" \
      --arg evpay "$evpay" \
      --arg close "python3 utils/py/releases_app.py roadmap sync" \
      --arg lstate "$evpay" \
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

branch_json=$(jq -Rn --arg b "$branch" '$b')

cat <<EOF
{"repo": {"branch": $branch_json},
 "lenses": {
   "2": {"status": "$lens2_status", "degraded_id": $lens2_deg, "candidates": $lens2_cands},
   "3": {"status": "$lens3_status", "degraded_id": $lens3_deg, "candidates": $lens3_cands},
   "7": {"status": "$lens7_status", "degraded_id": $lens7_deg, "candidates": $lens7_cands}
 }
}
EOF
