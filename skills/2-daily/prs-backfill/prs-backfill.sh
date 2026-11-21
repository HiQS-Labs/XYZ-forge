#!/usr/bin/env bash
#
# prs-backfill.sh — thin locator for prs_backfill.py (GH-1175), which lives beside this script.
#
# The implementation is skill-local (the GH-777 inventory ratchet freezes utils/py); it resolves
# the harness itself three levels up for releases_app.py. Symlink-safe, so a ~/.claude/skills
# install, a harness clone, or a vendored .xyz/ copy all work.
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
IMPL="$SELF_DIR/prs_backfill.py"

[ -f "$IMPL" ] || { echo "prs-backfill: implementation not found at $IMPL" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "prs-backfill: python3 not found" >&2; exit 2; }
exec python3 "$IMPL" "$@"
