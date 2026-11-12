#!/bin/bash
# GH-1430 live smoke (#87 step 7). Read-only: policy from XYZ_GITHUB_BOARD_POLICY_* env, plus
# repos_source from a scratch XYZ_DEVICE_CONFIG_PATH file (the env tier cannot carry an object).
# Usage: bash smoke.sh <clone> <scratch-dir> <on|off> [preview]
set -u
CLONE=$1 S=$2 KEY=$3
[ "$KEY" = on ] && V=true || V=false
mkdir -p "$S"
printf '{"github_board_selection_policy":{"repos_source":{"type":"rebalance_active","top_n":3,"since_days":7,"include_agent_sessions":%s}}}\n' "$V" > "$S/device_config.$KEY.json"
export XYZ_DEVICE_CONFIG_PATH="$S/device_config.$KEY.json" XYZ_BOARD_SYNC_STATE_PATH="$S/state.json" \
  XYZ_GITHUB_BOARD_POLICY_PROJECT_OWNER=noelsaw1 XYZ_GITHUB_BOARD_POLICY_PROJECT_NUMBER=9 \
  XYZ_GITHUB_BOARD_POLICY_REPOS=HiQS-Labs/XYZ-forge PYTHONDONTWRITEBYTECODE=1
cd "$CLONE"
echo "## config (key $KEY)"
/usr/bin/python3 utils/py/board_sync.py config | /usr/bin/python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin).get("selection_policy_repos"), indent=1))'
if [ "${4:-}" = preview ]; then
  echo "## policy-preview (key $KEY)"
  /usr/bin/python3 utils/py/board_sync.py policy-preview --root "$CLONE" --out "$S/preview.$KEY.json"; echo "exit=$?"
  /usr/bin/python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); print("preview policy.repos:", p["policy"]["repos"])' "$S/preview.$KEY.json"
fi
