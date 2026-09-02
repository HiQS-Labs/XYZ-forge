#!/usr/bin/env bash
set -euo pipefail
#
# gh374-drift-path-filter.sh — stale cross-repo dependency.drift events must not enter a turn brief.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS="$(cd "$HERE/.." && pwd)"
LIB="$HARNESS/relay-automation/relay-turn-lib.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh374-drift-filter.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
D="$WORK/driven-repo"
R="$WORK/shared-registry"

git init -q "$D"
git -C "$D" config user.email test@example.com
git -C "$D" config user.name test
mkdir -p "$D/src" "$R/.tick/events"
printf 'module.exports = {};\n' > "$D/src/present.js"
git -C "$D" add src/present.js
git -C "$D" commit -qm seed

# The registry is separate from the driven repo: present.js belongs to this driven repo, while
# stale.js is a valid event from another repo.  Both must be marked scanned; only the former is shown.
printf '%s\n' '{"agent":"peer","surface":"src/present.js","diff_lines":4}' \
  > "$R/.tick/events/2026-09-01T00-00-00-000Z-dependency.drift-present.jsonl"
printf '%s\n' '{"agent":"peer","surface":"src/stale.js","diff_lines":9}' \
  > "$R/.tick/events/2026-09-01T00-00-01-000Z-dependency.drift-stale.jsonl"

source "$LIB"
rtl_init "$D" "" ""
bash_brief="$(rtl_drift_brief bash-agent "$R")"
[[ "$bash_brief" == *"src/present.js"* ]]
[[ "$bash_brief" != *"src/stale.js"* ]]
[[ -z "$(rtl_drift_brief bash-agent "$R")" ]]

# Exercise the Python entry point too: it must pass the driven root through to the shared core.
PYTHONPATH="$HARNESS/utils/py" GH374_ROOT="$D" GH374_REGISTRY="$R" GH374_HARNESS="$HARNESS" python3 - <<'PY'
import os
from rtl import RelayTurnLib

rtl = RelayTurnLib(os.environ["GH374_ROOT"], os.environ["GH374_HARNESS"], "", "")
brief = rtl.drift_brief("python-agent", os.environ["GH374_REGISTRY"])
assert "src/present.js" in brief, brief
assert "src/stale.js" not in brief, brief
assert not rtl.drift_brief("python-agent", os.environ["GH374_REGISTRY"])
PY

echo "gh374-drift-path-filter: PASS"
