#!/usr/bin/env bash
set -euo pipefail
#
# write-xyz-heartbeat.sh — GH-96 Seam #1: overwrite the current in-flight heartbeat companion file
# (XYZ.heartbeat.json) at the harness repo root. Unlike append-xyz-completion.sh's array writer, this
# is a single-object overwrite, so there is no read-modify-write lost-update window to lock.
#
# Usage:
#   write-xyz-heartbeat.sh <harness> <sessionId>
#   XYZ_HEARTBEAT_CLEAR=1 write-xyz-heartbeat.sh <harness> <sessionId>
#
# The default mode atomically overwrites XYZ.heartbeat.json with:
#   { "harness": "...", "sessionId": "...", "updatedAt": "..." }
#
# Clear mode is best-effort and only removes the file when the CURRENT heartbeat names the same
# harness + sessionId. This lets a finishing run clear its own in-flight marker without deleting a
# newer session that already replaced it.

ROOT_DIR="${XYZ_ROOT:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"}"
XYZ_HEARTBEAT_JSON="${XYZ_HEARTBEAT_JSON_PATH:-"$ROOT_DIR/XYZ.heartbeat.json"}"

die() { printf 'write-xyz-heartbeat: %s\n' "$*" >&2; exit 2; }

(($# == 2)) || die "usage: write-xyz-heartbeat.sh <harness> <sessionId>"
harness="$1"; session_id="$2"

case "$harness" in relay|marathon|swarm) ;; *) die "harness must be relay|marathon|swarm, got: $harness" ;; esac
[[ -n "$session_id" ]] || die "sessionId cannot be empty"

mkdir -p "$(dirname "$XYZ_HEARTBEAT_JSON")" 2>/dev/null || true

if [[ "${XYZ_HEARTBEAT_CLEAR:-0}" == "1" ]]; then
  python3 - "$XYZ_HEARTBEAT_JSON" "$harness" "$session_id" <<'PYEOF'
import json
import os
import sys

heartbeat_path, harness, session_id = sys.argv[1:4]

try:
    with open(heartbeat_path) as f:
        data = json.load(f)
except (OSError, ValueError):
    sys.exit(0)

if isinstance(data, dict) and data.get("harness") == harness and data.get("sessionId") == session_id:
    try:
        os.unlink(heartbeat_path)
    except FileNotFoundError:
        pass
PYEOF
  exit 0
fi

updated_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

python3 - "$XYZ_HEARTBEAT_JSON" "$harness" "$session_id" "$updated_at" <<'PYEOF'
import json
import os
import sys
import tempfile

heartbeat_path, harness, session_id, updated_at = sys.argv[1:5]

record = {
    "harness": harness,
    "sessionId": session_id,
    "updatedAt": updated_at,
}

directory = os.path.dirname(heartbeat_path) or "."
fd, tmp = tempfile.mkstemp(dir=directory, prefix=".xyz-heartbeat.", suffix=".tmp")
try:
    with os.fdopen(fd, "w") as f:
        json.dump(record, f, indent="\t")
        f.write("\n")
    os.replace(tmp, heartbeat_path)
except Exception:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise
PYEOF
