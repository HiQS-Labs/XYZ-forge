#!/usr/bin/env bash
# GH-358: prove the concurrent append diagnostic distinguishes a lost record from lock starvation.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
XYZ_TEST="$HERE/xyz-completion.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gh358-lock-instrumentation.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }
require_log() {
  local log="$1" text="$2" description="$3"
  grep -Fq "$text" "$log" && pass "$description" || fail "$description (missing: $text)"
}

echo "== test: gh358-lock-instrumentation =="

# Control 1: all appenders exit 0, then one record is deliberately removed.  This must identify a
# successful writer whose record vanished, not report starvation or a generic count mismatch.
clobber_dir="$WORK/clobber"
mkdir -p "$clobber_dir"
clobber_log="$WORK/clobber.log"
if TMPDIR="$clobber_dir" XYZ_COMPLETION_TEST_CLOBBER_SESSION_ID=conc-1 bash "$XYZ_TEST" >"$clobber_log" 2>&1; then
  fail "clobbered-record control unexpectedly passed"
else
  pass "clobbered-record control fails as intended"
fi
require_log "$clobber_log" "missing sessionId=conc-1; terminal state=lock acquired, record lost" "clobber names the missing successful session"
require_log "$clobber_log" "test wait=60s; writer XYZ_LOCK_WAIT_S=30s (default=30s)" "clobber reports both normal lock bounds"
if grep -Fq "terminal state=lock never acquired" "$clobber_log"; then
  fail "clobber is not mislabeled as lock starvation"
else
  pass "clobber remains distinct from starvation"
fi
echo "  clobber diagnostic (observed failure):"
grep -F "terminal state=" "$clobber_log" | head -n 1 | sed 's/^/    /'

# Control 2: hold x4's lock while the writer has a one-second bound.  The outer test wait stays at
# 60 seconds, so the output must attribute the failure to the writer bound rather than the test wait.
starve_dir="$WORK/starve"
mkdir -p "$starve_dir"
starve_log="$WORK/starve.log"
TMPDIR="$starve_dir" XYZ_COMPLETION_WRITER_LOCK_WAIT_S=1 bash "$XYZ_TEST" >"$starve_log" 2>&1 &
test_pid=$!
workdir=""
for _ in $(seq 1 100); do
  workdir="$(sed -n 's/^  workdir: //p' "$starve_log" | head -n 1)"
  [ -n "$workdir" ] && break
  sleep 0.05
done

if [ -z "$workdir" ]; then
  fail "starvation control did not expose its temporary work directory"
  wait "$test_pid" 2>/dev/null || true
else
  sleep 20 &
  holder_pid=$!
  mkdir "$workdir/x4.json.lock"
  printf '%s\n' "$holder_pid" > "$workdir/x4.json.lock/pid"
  wait "$test_pid"; starve_rc=$?
  kill "$holder_pid" 2>/dev/null || true
  wait "$holder_pid" 2>/dev/null || true
  [ "$starve_rc" -ne 0 ] && pass "starved-appender control fails as intended" || fail "starved-appender control unexpectedly passed"
fi

require_log "$starve_log" "terminal state=lock never acquired" "starvation identifies the terminal lock state"
require_log "$starve_log" "writer XYZ_LOCK_WAIT_S=1s exhausted" "starvation identifies the exhausted writer bound"
require_log "$starve_log" "test wait=60s; writer XYZ_LOCK_WAIT_S=1s (default=30s)" "starvation reports both effective lock bounds"
if grep -Fq "terminal state=lock acquired, record lost" "$starve_log"; then
  fail "starvation is not mislabeled as a lost record"
else
  pass "starvation remains distinct from a lost record"
fi
echo "  starvation diagnostic (observed failure):"
grep -F "terminal state=" "$starve_log" | head -n 1 | sed 's/^/    /'

echo "  gh358-lock-instrumentation: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
