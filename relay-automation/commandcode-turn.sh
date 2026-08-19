#!/usr/bin/env bash
# GH-42: Python is the only implementation for this new entry point.  Unlike the
# pre-existing frozen shims, there is no historical Bash behavior to preserve.
set -euo pipefail

if ! command -v python3 >/dev/null 2>&1 \
   || ! python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,8) else 1)' 2>/dev/null; then
  echo "commandcode-turn: python3 >= 3.8 is required" >&2
  exit 5
fi

xyz_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export XYZ_ROOT="$xyz_root"
export PYTHONPATH="$xyz_root/utils/py${PYTHONPATH:+:$PYTHONPATH}"
exec python3 "$xyz_root/utils/py/commandcode-turn.py" "$@"
