#!/usr/bin/env bash
# jog-queue.sh — GH-259 Phase 1: Jog serial execution queue and engine.
#
# Asserts:
#   - jog_queue schema creation and migration in releases_app.py
#   - queue CRUD operations: add, list, bump, drop, retry, skip, clear, to-marathon
#   - duplicate enqueue rejection (jog-duplicate)
#   - canonical dump and check --rebuild roundtrip preserving jog_queue
#   - outer driver lock mutual exclusion (relay-driver.lock)
#   - startup orphan lease reconciliation (dead PID reset to pending/parked)
#   - jog run dry-run supervisor execution loop
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
APP="$ROOT/utils/py/releases_app.py"

pass=0
fail=0
ok() {
  local label="$1" rc="$2"
  if [ "$rc" -eq 0 ]; then
    printf '  PASS: %s\n' "$label"
    pass=$((pass + 1))
  else
    printf '  FAIL: %s\n' "$label" >&2
    fail=$((fail + 1))
  fi
}
has() { printf '%s' "$1" | grep -Fq -- "$2"; }
same() { [ "$1" = "$2" ]; }

printf '== test: jog-queue ==\n'
command -v python3 >/dev/null 2>&1 || { echo 'python3 required' >&2; exit 1; }
command -v sqlite3 >/dev/null 2>&1 || { echo 'sqlite3 required' >&2; exit 1; }
[ -f "$APP" ] || { echo "missing app: $APP" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/jog-test.XXXXXX")"
. "$HERE/lib/fixture-guard.sh"
fixture_guard_init "$WORK"
cleanup() {
  case "${WORK:-}" in
    "${TMPDIR:-/tmp}"/jog-test.*) [ -d "$WORK" ] && rm -rf "$WORK" ;;
    *) echo "jog: REFUSING cleanup outside workspace: ${WORK:-<empty>}" >&2 ;;
  esac
}
trap cleanup EXIT

repo() {
  local r="$WORK/$1"
  mkdir -p "$r"
  require_fixture "$r" "fixture repo"
  git -C "$r" init -q
  git -C "$r" config user.email jog@test.invalid
  git -C "$r" config user.name jog
  printf '%s\n' "$r"
}
ra() {
  local r="$1"
  shift
  require_fixture "$r" "releases fixture"
  python3 "$APP" --root "$r" "$@"
}

R="$(repo r1)"

# 1. DB Init & Schema Migration
out="$(ra "$R" init 2>&1)"
ok "releases init creates DB and dump" $?
out="$(ra "$R" check 2>&1)"
ok "releases check reports clean on fresh DB" $?

# 2. Add queue items
ra "$R" jog add 101 >/dev/null 2>&1
ok "jog add 101 succeeds" $?
ra "$R" jog add 102 >/dev/null 2>&1
ok "jog add 102 succeeds" $?
ra "$R" jog add 103 >/dev/null 2>&1
ok "jog add 103 succeeds" $?

# 3. List active queue
out="$(ra "$R" jog list)"
has "$out" "GH-101" && has "$out" "GH-102" && has "$out" "GH-103"
ok "jog list includes all enqueued items" $?

out_json="$(ra "$R" jog list --json)"
has "$out_json" '"gh_number": 101' && has "$out_json" '"gh_number": 102'
ok "jog list --json outputs structured JSON" $?

# 4. Duplicate rejection
out_dup="$(ra "$R" jog add 101 2>&1 || true)"
has "$out_dup" "jog-duplicate"
ok "jog add rejects duplicate active issue" $?

# 5. Bump item to head
ra "$R" jog bump 103 >/dev/null 2>&1
ok "jog bump 103 succeeds" $?
out_bump="$(ra "$R" jog list)"
first_item="$(printf '%s\n' "$out_bump" | grep -E '^[0-9]' | head -1)"
has "$first_item" "GH-103"
ok "jog bump moves GH-103 to position 1" $?

# 6. Drop item with reason
ra "$R" jog drop 101 --reason "superceded" >/dev/null 2>&1
ok "jog drop 101 succeeds" $?
out_drop="$(ra "$R" jog list)"
! has "$out_drop" "GH-101"
ok "dropped item GH-101 is excluded from active list" $?

out_all="$(ra "$R" jog list --all)"
has "$out_all" "GH-101" && has "$out_all" "dropped"
ok "jog list --all includes dropped item" $?

# 7. Skip / Park item
ra "$R" jog skip 103 --reason "blocked on PR" >/dev/null 2>&1
ok "jog skip 103 succeeds" $?
out_skip="$(ra "$R" jog list)"
! has "$out_skip" "GH-103"
ok "skipped item GH-103 is parked" $?

# 8. Retry item
ra "$R" jog retry 103 >/dev/null 2>&1
ok "jog retry 103 succeeds" $?
out_retry="$(ra "$R" jog list)"
has "$out_retry" "GH-103"
ok "retried item GH-103 is active pending" $?

# 9. Clear terminal items
ra "$R" jog clear >/dev/null 2>&1
ok "jog clear succeeds" $?
out_clear="$(ra "$R" jog list --all)"
has "$out_clear" "archived"
ok "jog clear archives dropped rows" $?

# 10. To-marathon export
out_mar="$(ra "$R" jog to-marathon)"
has "$out_mar" "GH-102"
ok "jog to-marathon emits active issues" $?

# 11. Dump and rebuild integrity
out_check="$(ra "$R" check 2>&1)"
ok "releases check clean after jog operations" $?

out_rebuild="$(ra "$R" check --rebuild 2>&1)"
ok "releases check --rebuild succeeds with jog_queue" $?

out_post_rebuild="$(ra "$R" jog list)"
has "$out_post_rebuild" "GH-102"
ok "jog queue items survive dump rebuild" $?

# 12. Driver lock mutual exclusion
mkdir -p "$R/.git/relay-driver.lock"
printf '%s\n' "$$" > "$R/.git/relay-driver.lock/pid"
out_lock="$(ra "$R" jog run --dry-run 2>&1 || true)"
has "$out_lock" "another driver is active"
ok "jog run refuses when relay-driver.lock is held by live PID" $?
rm -rf "$R/.git/relay-driver.lock"

# 13. Startup orphan lease reconciliation
# Inject dead PID into a running row
sqlite3 "$R/releases.db" "UPDATE jog_queue SET status = 'running', lease_pid = 999999 WHERE gh_number = 102;"
out_recon="$(ra "$R" jog run --dry-run --max-tasks 0 2>&1)"
has "$out_recon" "orphan lease"
ok "jog run reconciles dead orphan lease on startup" $?

status_after="$(sqlite3 "$R/releases.db" "SELECT status FROM jog_queue WHERE gh_number = 102;")"
same "$status_after" "pending"
ok "orphan row reset to pending" $?

# 14. Jog run execution loop (dry-run)
out_run="$(ra "$R" jog run --dry-run --max-tasks 2 2>&1)"
has "$out_run" "simulated single-phase drive on GH-102"
ok "jog run processes queue items in dry-run mode" $?

status_done="$(sqlite3 "$R/releases.db" "SELECT status FROM jog_queue WHERE gh_number = 102;")"
same "$status_done" "completed"
ok "processed item is marked completed" $?

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
