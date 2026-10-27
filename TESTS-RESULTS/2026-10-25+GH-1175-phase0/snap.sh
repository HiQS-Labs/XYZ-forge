#!/bin/bash
# snap.sh <label> — capture jog/execution/heartbeat state into scratchpad ev/
P="/Users/noelsaw/Documents/GitHub Repos/XYZ-forge"; T="/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh416-phase0"
OUT="/private/tmp/claude-501/-Users-noelsaw-Documents-GitHub-Repos-XYZ-forge/e8e389e9-bb48-4607-aec6-69dd40a616ca/scratchpad/ev/snap-$1.log"
{
echo "## snap $1 at $(date -u +%FT%TZ)"
echo "### jog list --all (head)"; (cd "$P" && python3 utils/py/releases_app.py jog list --json 2>&1 | python3 -c 'import json,sys
d=json.load(sys.stdin)
for r in d:
  if r.get("gh_number")==416: print(json.dumps(r,indent=1))' 2>&1)
for R in "$P" "$T"; do
  echo "### root: $R"
  echo "#### .tick/jog state files"; for f in "$R"/.tick/jog/*/state.json; do [ -f "$f" ] && { echo "-- $f"; cat "$f"; echo; }; done
  echo "#### driver-heartbeat.json"; cat "$R/.tick/driver-heartbeat.json" 2>&1; echo
  echo "#### rtl_driver_heartbeat_status"; (source "$P/relay-automation/relay-turn-lib.sh" >/dev/null 2>&1; rtl_driver_heartbeat_status "$R"; echo " (rc=$?)")
  echo "#### driver lock"; ls -la "$R/.git/relay-driver.lock" 2>&1; cat "$R/.git/relay-driver.lock" 2>/dev/null; echo
done
echo "### processes"; ps -axo pid,ppid,etime,command | grep -E 'releases_app|jog|marathon|relay-drive|agy|codex-turn|agy-turn|codex exec' | grep -v -E 'grep|snap.sh' | cut -c1-250
} > "$OUT" 2>&1
echo "$OUT"
