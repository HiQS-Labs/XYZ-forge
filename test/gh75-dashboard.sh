#!/usr/bin/env bash
# GH-75 - releases dashboard test
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
APP="$ROOT_DIR/utils/py/releases_app.py"

pass=0; fail=0
ok()   { if eval "$2"; then echo "  PASS: $1"; pass=$((pass+1)); else echo "  FAIL: $1" >&2; fail=$((fail+1)); fi }
has()  { printf '%s' "$1" | grep -Fq -- "$2"; }

echo "== test: gh75-dashboard =="
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo "sqlite3 required" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh75-dashboard.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup() {
  case "${WORK:-}" in
    "${TMPDIR:-/tmp}"/gh75-dashboard.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
    *) echo "gh75: REFUSING cleanup outside the workspace: ${WORK:-<empty>}" >&2 ;;
  esac
}
trap cleanup EXIT

R="$WORK/r"
mkdir -p "$R"; require_fixture "$R" "dashboard fixture"
git -C "$R" init -q -b main

echo "1. Empty states and read-only invariants"
python3 "$APP" --root "$R" init >/dev/null

out=$(python3 "$APP" --root "$R" dashboard 2>&1)
ok "dashboard runs on empty db" 'has "$out" "Releases Dashboard"'
ok "dashboard outputs HTML" 'has "$out" "<!DOCTYPE html>"'
ok "dashboard trust header" 'has "$out" "Generation: 1 | Receipts: 0"'

# Add some data
sqlite3 "$R/releases.db" "INSERT INTO issue_refs (id, global_id, url, temp_id, created_at) VALUES (1, 'ref-01234567890123456789012345', NULL, 'TMP-111111', '2026-08-27T00:00:00Z');"
sqlite3 "$R/releases.db" "INSERT INTO releases (global_id, repo_id, version, codename, status, description, tracking_ref_id) VALUES ('rel-01234567890123456789012345', 1, '1.0', 'Alpha', 'active', 'Initial release', 1);"
sqlite3 "$R/releases.db" "INSERT INTO roadmap_items (global_id, repo_id, section, position, title, status_marker, raw_text, first_seen, updated_at) VALUES ('rmi-01234567890123456789012345', 1, 'Queue', 1, 'Task 1', '✅', '- [x] Task 1', '2026-08-27T00:00:00Z', '2026-08-27T00:00:00Z');"

out=$(python3 "$APP" --root "$R" dashboard 2>&1)
ok "dashboard displays release version" 'has "$out" "1.0 Alpha"'
ok "dashboard displays release status" 'has "$out" "Status: active"'
ok "dashboard displays roadmap section" 'has "$out" "<h3>Queue</h3>"'
ok "dashboard displays roadmap item" 'has "$out" "Task 1"'

# Invariants check
python3 "$APP" --root "$R" check >/dev/null
gen=$(sqlite3 "$R/releases.db" "SELECT value FROM settings WHERE key='generation'")
out=$(python3 "$APP" --root "$R" dashboard 2>&1)
gen2=$(sqlite3 "$R/releases.db" "SELECT value FROM settings WHERE key='generation'")
ok "dashboard does not bump generation" '[ "$gen" = "$gen2" ]'

if [ $fail -ne 0 ]; then
  echo "gh75-dashboard.sh: $fail failed" >&2
  exit 1
fi
echo "gh75-dashboard.sh: all pass"
exit 0
