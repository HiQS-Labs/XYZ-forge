#!/usr/bin/env bash
# test/marathon-monitor.sh — dependency-free tests for marathon-ls.sh.
#
# Covers:
#   (a) Both lock-path cases:
#       - Normal clone: .git/relay-driver.lock/pid
#       - Vendored install: .relay-driver.lock/pid  (no .git/)
#   (b) All four states:
#       - LIVE  (pid = live process — $$)
#       - STALE (pid = dead pid, 999999)
#       - IDLE  (no lock + marathon.complete event)
#       - GONE  (registry row pointing to a deleted path)
#
# Uses a fake registry.tsv via $XYZ_REGISTRY.
# Final line: "marathon-monitor: N pass, M fail"
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
LS="$HERE/../relay-automation/marathon-ls.sh"

PASS=0; FAIL=0
pass() { printf '  PASS: %s\n' "$*"; PASS=$((PASS+1)); }
fail() { printf '  FAIL: %s\n' "$*" >&2; FAIL=$((FAIL+1)); }

echo "== test: marathon-monitor =="

# ---------------------------------------------------------------------------
# Temp fixture dir
# ---------------------------------------------------------------------------
_tmp="${TMPDIR:-/tmp}"; D="${_tmp%/}/marathon-monitor-test.$$"   # strip trailing slash so paths never contain '//'
rm -rf "$D"
mkdir -p "$D"
trap 'rm -rf "$D"' EXIT

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

make_clone_repo() {
  # make_clone_repo <path> — create a fake "normal clone" (has .git/)
  # GH-484: the phase dir is marathon-system/, what a current driver actually writes.
  local repo="$1"
  mkdir -p "$repo/.git" "$repo/.tick/events" "$repo/marathon-system/p1"
}

make_vendored_repo() {
  # make_vendored_repo <path> — create a fake "vendored" repo (no .git/)
  local repo="$1"
  mkdir -p "$repo/.tick/events" "$repo/marathon-system/p1"
}

write_marathon_event() {
  # write_marathon_event <repo> <type> [<ts>]
  local repo="$1" type="$2" ts="${3:-2026-07-02T00:00:00.000Z}"
  local events_dir="$repo/.tick/events"
  mkdir -p "$events_dir"
  # Use a fixed filename that matches *marathon*.jsonl.
  local f="$events_dir/marathon-DRIVE.jsonl"
  printf '{"type":"%s","ts":"%s"}\n' "$type" "$ts" >> "$f"
}

# ---------------------------------------------------------------------------
# Build fake registry.tsv
# ---------------------------------------------------------------------------
REGISTRY="$D/registry.tsv"
# Columns: install_dir  last_install_utc  tick_version  source_commit  coordinated_repo
# Header line.
printf 'install_dir\tlast_install_utc\ttick_version\tsource_commit\tcoordinated_repo\n' > "$REGISTRY"

# We will add rows after creating fixtures below.

# ---------------------------------------------------------------------------
# Fixture 1: LIVE — normal clone (.git/) + live PID
# ---------------------------------------------------------------------------
REPO_LIVE="$D/repo-live"
make_clone_repo "$REPO_LIVE"
write_marathon_event "$REPO_LIVE" "marathon.start"
# Create .git/relay-driver.lock/pid with our own PID (definitely alive).
mkdir -p "$REPO_LIVE/.git/relay-driver.lock"
printf '%s\n' "$$" > "$REPO_LIVE/.git/relay-driver.lock/pid"
printf '%s\t2026-07-02\tv1\tabc\t%s\n' "$REPO_LIVE/.xyz" "$REPO_LIVE" >> "$REGISTRY"

# ---------------------------------------------------------------------------
# Fixture 2: STALE — vendored (.relay-driver.lock/) + dead PID
# ---------------------------------------------------------------------------
REPO_STALE="$D/repo-stale"
make_vendored_repo "$REPO_STALE"
write_marathon_event "$REPO_STALE" "marathon.start"
# Create .relay-driver.lock/pid with a dead PID.
mkdir -p "$REPO_STALE/.relay-driver.lock"
printf '%s\n' "999999" > "$REPO_STALE/.relay-driver.lock/pid"
printf '%s\t2026-07-02\tv1\tabc\t%s\n' "$REPO_STALE/.xyz" "$REPO_STALE" >> "$REGISTRY"

# ---------------------------------------------------------------------------
# Fixture 3: IDLE — clone, no lock, marathon.complete event
# ---------------------------------------------------------------------------
REPO_IDLE="$D/repo-idle"
make_clone_repo "$REPO_IDLE"
write_marathon_event "$REPO_IDLE" "marathon.complete" "2026-07-02T12:00:00.000Z"
# No lock directory.
printf '%s\t2026-07-02\tv1\tabc\t%s\n' "$REPO_IDLE/.xyz" "$REPO_IDLE" >> "$REGISTRY"

# ---------------------------------------------------------------------------
# Fixture 4: GONE — path that we will delete before running the check
# ---------------------------------------------------------------------------
REPO_GONE="$D/repo-gone"
make_clone_repo "$REPO_GONE"
printf '%s\t2026-07-02\tv1\tabc\t%s\n' "$REPO_GONE/.xyz" "$REPO_GONE" >> "$REGISTRY"
# Delete the path now so marathon-ls.sh sees it as GONE.
rm -rf "$REPO_GONE"

# ---------------------------------------------------------------------------
# Fixture 5 (GH-484): NEW-DEFAULT only — a run written by a current driver
# ---------------------------------------------------------------------------
REPO_NEW="$D/repo-new-default"
make_clone_repo "$REPO_NEW"
write_marathon_event "$REPO_NEW" "marathon.complete" "2026-08-09T12:00:00.000Z"
printf 'STATUS: Open\n' > "$REPO_NEW/marathon-system/p1/RELAY.md"
printf '%s\t2026-08-09\tv1\tabc\t%s\n' "$REPO_NEW/.xyz" "$REPO_NEW" >> "$REGISTRY"

# ---------------------------------------------------------------------------
# Fixture 6 (GH-484): LEGACY only — a pre-flip run, or a fleet repo whose
# vendored .xyz/ has not re-synced and is therefore still writing to phases/.
# ---------------------------------------------------------------------------
REPO_LEGACY="$D/repo-legacy"
make_clone_repo "$REPO_LEGACY"
rm -rf "$REPO_LEGACY/marathon-system"
mkdir -p "$REPO_LEGACY/phases/p1"
write_marathon_event "$REPO_LEGACY" "marathon.complete" "2026-08-09T12:00:00.000Z"
printf 'STATUS: Open\n' > "$REPO_LEGACY/phases/p1/RELAY.md"
printf '%s\t2026-08-09\tv1\tabc\t%s\n' "$REPO_LEGACY/.xyz" "$REPO_LEGACY" >> "$REGISTRY"

# ---------------------------------------------------------------------------
# Fixture 7 (GH-484): BOTH populations present, and the LEGACY file is NEWER.
# This is the falsifiable case: a naive "look in marathon-system/, return if
# found" implementation passes fixtures 5 and 6 and fails only this one.
# ---------------------------------------------------------------------------
REPO_MIXED="$D/repo-mixed"
make_clone_repo "$REPO_MIXED"
mkdir -p "$REPO_MIXED/phases/p1"
write_marathon_event "$REPO_MIXED" "marathon.complete" "2026-08-09T12:00:00.000Z"
printf 'STATUS: Approved\n' > "$REPO_MIXED/marathon-system/p1/RELAY.md"
sleep 1   # mtime granularity: `test -nt` is second-resolution on some filesystems
printf 'STATUS: Open\n' > "$REPO_MIXED/phases/p1/RELAY.md"
printf '%s\t2026-08-09\tv1\tabc\t%s\n' "$REPO_MIXED/.xyz" "$REPO_MIXED" >> "$REGISTRY"

# ---------------------------------------------------------------------------
# Run marathon-ls.sh with our fake registry
# ---------------------------------------------------------------------------
OUTPUT="$(XYZ_REGISTRY="$REGISTRY" bash "$LS" 2>/dev/null || true)"

# Helper: get the STATE column (col 2) for a given repo path.
state_for() {
  local repo="$1"
  printf '%s' "$OUTPUT" | awk -F'\t' -v r="$repo" '$1 == r { print $2 }'
}

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

# (a) BOTH lock-path cases (LIVE uses .git/ clone; STALE uses vendored no-.git/)
LIVE_STATE="$(state_for "$REPO_LIVE")"
[ "$LIVE_STATE" = "LIVE" ] \
  && pass "LIVE: clone with .git/relay-driver.lock + live pid -> LIVE" \
  || fail "LIVE: expected LIVE, got '${LIVE_STATE}' (repo=$REPO_LIVE)"

STALE_STATE="$(state_for "$REPO_STALE")"
[ "$STALE_STATE" = "STALE" ] \
  && pass "STALE: vendored .relay-driver.lock + dead pid (999999) -> STALE" \
  || fail "STALE: expected STALE, got '${STALE_STATE}' (repo=$REPO_STALE)"

# (b) ALL FOUR states
IDLE_STATE="$(state_for "$REPO_IDLE")"
[ "$IDLE_STATE" = "IDLE" ] \
  && pass "IDLE: no lock + marathon.complete event -> IDLE" \
  || fail "IDLE: expected IDLE, got '${IDLE_STATE}' (repo=$REPO_IDLE)"

GONE_STATE="$(state_for "$REPO_GONE")"
[ "$GONE_STATE" = "GONE" ] \
  && pass "GONE: deleted path -> GONE" \
  || fail "GONE: expected GONE, got '${GONE_STATE}' (repo=$REPO_GONE)"

# Sanity: header row is present.
HEADER="$(printf '%s' "$OUTPUT" | head -1)"
case "$HEADER" in
  REPO*)
    pass "header row starts with REPO" ;;
  *)
    fail "header row missing or malformed: '$HEADER'" ;;
esac

# Sanity: PID column for LIVE row = our own PID.
LIVE_PID="$(printf '%s' "$OUTPUT" | awk -F'\t' -v r="$REPO_LIVE" '$1 == r { print $5 }')"
[ "$LIVE_PID" = "$$" ] \
  && pass "LIVE pid column matches our PID ($$)" \
  || fail "LIVE pid column: expected $$, got '$LIVE_PID'"

# Sanity: lock-path distinction — STALE uses vendored lock, LIVE uses .git/ lock.
# Confirm the lock files exist (or don't) as expected.
[ -d "$REPO_LIVE/.git/relay-driver.lock" ] \
  && pass "LIVE fixture has .git/relay-driver.lock (clone path)" \
  || fail "LIVE fixture missing .git/relay-driver.lock"

[ ! -d "$REPO_STALE/.git" ] \
  && pass "STALE fixture has no .git/ (vendored path)" \
  || fail "STALE fixture unexpectedly has .git/"

[ -d "$REPO_STALE/.relay-driver.lock" ] \
  && pass "STALE fixture has .relay-driver.lock (vendored path)" \
  || fail "STALE fixture missing .relay-driver.lock"

# ---------------------------------------------------------------------------
# (c) GH-484: dual-path RELAY-FILE lookup (col 6)
# ---------------------------------------------------------------------------
relay_for() {
  local repo="$1"
  printf '%s' "$OUTPUT" | awk -F'\t' -v r="$repo" '$1 == r { print $6 }'
}

[ "$(relay_for "$REPO_NEW")" = "$REPO_NEW/marathon-system/p1/RELAY.md" ] \
  && pass "GH-484: new default — RELAY-FILE resolves under marathon-system/" \
  || fail "GH-484: new default: expected $REPO_NEW/marathon-system/p1/RELAY.md, got '$(relay_for "$REPO_NEW")'"

[ "$(relay_for "$REPO_LEGACY")" = "$REPO_LEGACY/phases/p1/RELAY.md" ] \
  && pass "GH-484: legacy fallback — a pre-flip / not-yet-re-synced repo stays visible" \
  || fail "GH-484: legacy fallback: expected $REPO_LEGACY/phases/p1/RELAY.md, got '$(relay_for "$REPO_LEGACY")'"

# The falsifiable one: both dirs populated, legacy written LAST. "check new, return
# if found" would report the marathon-system file here and be wrong.
[ "$(relay_for "$REPO_MIXED")" = "$REPO_MIXED/phases/p1/RELAY.md" ] \
  && pass "GH-484: both populations present — the NEWER file wins regardless of which dir it is in" \
  || fail "GH-484: mixed: expected the newer $REPO_MIXED/phases/p1/RELAY.md, got '$(relay_for "$REPO_MIXED")'"

# marathon-detail.sh reads the same two locations; assert it agrees rather than
# trusting that the duplicated loop stayed in sync.
DETAIL="$HERE/../relay-automation/marathon-detail.sh"
detail_out="$(bash "$DETAIL" "$REPO_LEGACY" 2>/dev/null || true)"
grep -q 'RELAY.md: p1/RELAY.md' <<<"$(printf '%s' "$detail_out")" \
  && pass "GH-484: marathon-detail.sh finds the legacy relay file too" \
  || fail "GH-484: marathon-detail.sh missed the legacy relay file: [$detail_out]"

# ---------------------------------------------------------------------------
# bash -n syntax check on all 4 scripts
# ---------------------------------------------------------------------------
SCRIPTS=(
  "$HERE/../relay-automation/marathon-ls.sh"
  "$HERE/../relay-automation/marathon-detail.sh"
  "$HERE/../relay-automation/marathon-tui.sh"
  "$HERE/marathon-monitor.sh"
)
for s in "${SCRIPTS[@]}"; do
  if bash -n "$s" 2>/dev/null; then
    pass "syntax OK: $(basename "$s")"
  else
    fail "syntax error in: $s"
  fi
done

# ---------------------------------------------------------------------------
printf '\nmarathon-monitor: %d pass, %d fail\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
