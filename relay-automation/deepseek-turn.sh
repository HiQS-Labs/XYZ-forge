#!/usr/bin/env bash
# GH-148: Python is the only implementation for this entry point.
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1 \
   || ! python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
  echo "deepseek-turn: python3 >= 3.8 is required" >&2
  exit 5
fi

xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export XYZ_ROOT="$xyz_root"
export PYTHONPATH="$xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
exec python3 "$xyz_root/utils/py/deepseek-turn.py" "$@"
