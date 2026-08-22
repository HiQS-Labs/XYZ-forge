#!/usr/bin/env bash
# test/gh131-marathon-target-root.sh — #131: cross-repo marathon commits route to the repo
# containing phase_dir (commit_root); in-repo runs byte-identical.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "$HERE/test/synthetic/gh131-marathon-target-root.sh"
