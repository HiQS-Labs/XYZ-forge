#!/usr/bin/env bash
# resolve-profile.sh (GH-346 Phase 3a) — one name resolves to harness, gateway, and model.
#
# GH-148: Python is the only implementation for this entry point.
#
#   eval "$(relay-automation/resolve-profile.sh 'glm 5.3 max' --env)"
#   relay-automation/resolve-profile.sh --list
#   relay-automation/resolve-profile.sh 'qwen 3.8 max' --explain
#
# Profiles live in the `profiles` block of ~/.xyz/device_config.json -- the file that already
# holds default_harness / default_gateway / default_model, which were a one-profile version of
# this feature. A second file would have been the eleventh curated list GH-346 exists to stop.
#
# NOTE the name: this is NOT resolve-model-alias.sh, which maps a colloquial model name to a
# canonical slug and knows nothing about harnesses. This script resolves the whole path, and
# reuses that one for name matching. See utils/py/profile_resolve.py for the resolution order.
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1 \
   || ! python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
  echo "resolve-profile: python3 >= 3.8 is required" >&2
  exit 5
fi

xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export XYZ_ROOT="${XYZ_ROOT:-$xyz_root}"
export PYTHONPATH="$xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
exec python3 "$xyz_root/utils/py/profile_resolve.py" "$@"
