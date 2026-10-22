#!/usr/bin/env bash
#
# prs-backfill.sh — thin locator for utils/py/prs_backfill.py (GH-1175).
#
# Resolves the implementation three levels up from this script's real directory (the skills/
# contract), so it works from a harness clone, a vendored .xyz/ copy, or a symlinked install.
# The repo being RATED is resolved by the Python side (--root > $PRS_BACKFILL_ROOT > git
# toplevel > CWD), never from this script's location (GH-344).
#
#   bash skills/2-daily/prs-backfill/prs-backfill.sh status
#   bash skills/2-daily/prs-backfill/prs-backfill.sh scan --mode backfill --limit 20
set -euo pipefail

_src="${BASH_SOURCE[0]}"
while [ -h "$_src" ]; do
  _dir="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"
  _src="$(readlink "$_src")"
  case "$_src" in /*) ;; *) _src="$_dir/$_src" ;; esac
done
SELF_DIR="$(cd -P "$(dirname "$_src")" >/dev/null 2>&1 && pwd)"   # …/skills/2-daily/prs-backfill
HARNESS="$(cd -P "$SELF_DIR/../../.." >/dev/null 2>&1 && pwd)"
IMPL="$HARNESS/utils/py/prs_backfill.py"

[ -f "$IMPL" ] || { echo "prs-backfill: implementation not found at $IMPL" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "prs-backfill: python3 not found" >&2; exit 2; }
exec python3 "$IMPL" "$@"
