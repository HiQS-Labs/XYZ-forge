#!/usr/bin/env bash
#
# scan-issues.sh — deterministic GH issue window pull for the /10days skill.
#
# Lists OPEN issues updated (created, commented, labeled — anything that bumps
# `updated`) within an age window, sorted by issue number, as one JSON object per
# line. This script makes zero judgment calls (validity, reproducibility, "already
# done" are for the skill's subagent fan-out, not this script) — it exists so the
# window pull is byte-identical every run instead of a hand-typed `gh` one-liner.
#
#   bash skills/3-weekly/10days/scan-issues.sh [MAX_DAYS] [MIN_DAYS]
#
#   MAX_DAYS   how far back the window opens (default 10). Issues updated more than
#              MAX_DAYS ago are excluded.
#   MIN_DAYS   how close to today the window closes (default 0 = today). Issues
#              updated more recently than MIN_DAYS ago are excluded. Use this to
#              carve out a slice that doesn't overlap a window another run already
#              covered — e.g. `scan-issues.sh 14 11` = issues 11-14 days old, skipping
#              the last 10 days if another sweep already owns that range.
#
# Requires: gh (authenticated), run with the Bash sandbox disabled (gh needs
# keychain/TLS access it does not have inside the sandbox).
set -uo pipefail
# strict-mode: -e exempt — adapter propagates the Python/gh exit status.
command -v python3 >/dev/null 2>&1 || { echo "10days: python3 not found on PATH" >&2; exit 2; }
SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 2
exec python3 "$SCRIPT_DIR/intake_adapter.py" scan "$@"
