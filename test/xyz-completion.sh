#!/usr/bin/env bash
# test/xyz-completion.sh — GH-75: the shared writer (append-xyz-completion.sh) + health lib.
#
# Covers Phase 1 (locked atomic prepend) and Phase 3 (concurrent-write safety) QA gates:
#   - newest-first prepend; N sequential appends stay valid JSON, none lost
#   - absent/corrupt/partial XYZ.json self-heals to a fresh array (never aborts the session)
#   - N concurrent writers → exactly N records, no lost update (the lock), no corruption (atomic swap)
#   - no leftover temp file / lock dir after a write
#   - arg validation (harness/health) rejects garbage
#   - health-lib mapping matches GH-24's table
#
# Standalone: the writer needs no tick/relay harness.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
WRITER="$ROOT/utils/telemetry/append-xyz-completion.sh"
HEARTBEAT="$ROOT/utils/telemetry/write-xyz-heartbeat.sh"

# The concurrent assertion has an outer test wait and a separate writer lock budget.  Keep both
# visible: a record lost after a successful writer is a lock defect, while an exhausted writer budget
# is starvation.  The two test-only overrides power GH-358's negative controls.
CONCURRENT_TEST_WAIT_S="${XYZ_COMPLETION_TEST_WAIT_S:-60}"
CONCURRENT_WRITER_LOCK_WAIT_S="${XYZ_COMPLETION_WRITER_LOCK_WAIT_S:-30}"
WRITER_LOCK_WAIT_DEFAULT_S=30

WORK="$(mktemp -d "${TMPDIR:-/tmp}/xyz-completion.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

PASS=0; FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); }

echo "== test: xyz-completion =="
echo "  workdir: $WORK"

valid_json()  { python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$1" >/dev/null 2>&1; }
valid_obj()   { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if isinstance(d, dict) else 1)" "$1" >/dev/null 2>&1; }
count()       { python3 -c "import json,sys; print(len(json.load(open(sys.argv[1]))))" "$1" 2>/dev/null; }
field()       { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d[int(sys.argv[2])][sys.argv[3]])" "$1" "$2" "$3" 2>/dev/null; }
obj_field()   { python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d[sys.argv[2]])" "$1" "$2" 2>/dev/null; }
has_session_id() {
  python3 - "$1" "$2" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    records = json.load(f)
sys.exit(0 if any(r.get("sessionId") == sys.argv[2] for r in records) else 1)
PYEOF
}

wait_for_appender() {
  local pid="$1" deadline
  deadline=$(( $(date +%s) + CONCURRENT_TEST_WAIT_S ))
  while kill -0 "$pid" 2>/dev/null; do
    if [[ "$(date +%s)" -ge "$deadline" ]]; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 124
    fi
    sleep 0.1
  done
  wait "$pid" 2>/dev/null
}

appender_status() {
  local wanted="$1" entry
  for entry in $2; do
    if [[ "${entry%%:*}" == "$wanted" ]]; then
      printf '%s\n' "${entry#*:}"
      return 0
    fi
  done
  return 1
}

concurrent_bounds() {
  printf 'test wait=%ss; writer XYZ_LOCK_WAIT_S=%ss (default=%ss)\n' \
    "$CONCURRENT_TEST_WAIT_S" "$CONCURRENT_WRITER_LOCK_WAIT_S" "$WRITER_LOCK_WAIT_DEFAULT_S"
}

report_missing_session() {
  local session_id="$1" rc="$2"
  case "$rc" in
    0) fail "concurrent mismatch: missing sessionId=$session_id; terminal state=lock acquired, record lost. $(concurrent_bounds)" ;;
    75) fail "concurrent mismatch: missing sessionId=$session_id; terminal state=lock never acquired; writer XYZ_LOCK_WAIT_S=${CONCURRENT_WRITER_LOCK_WAIT_S}s exhausted. $(concurrent_bounds)" ;;
    124) fail "concurrent mismatch: missing sessionId=$session_id; terminal state=process failed; test wait=${CONCURRENT_TEST_WAIT_S}s exhausted. $(concurrent_bounds)" ;;
    *) fail "concurrent mismatch: missing sessionId=$session_id; terminal state=process failed (exit $rc). $(concurrent_bounds)" ;;
  esac
}

# ── (1) basic prepend + schema ──────────────────────────────────────────────
X="$WORK/x1.json"
XYZ_JSON_PATH="$X" bash "$WRITER" relay slug-a green "Title A" "did A"
XYZ_JSON_PATH="$X" bash "$WRITER" marathon plan-b red "Title B" "halted at phase p2"
valid_json "$X" && pass "XYZ.json is valid JSON after two appends" || fail "invalid JSON: $(cat "$X")"
[ "$(count "$X")" = "2" ] && pass "two records present" || fail "expected 2 records, got $(count "$X")"
[ "$(field "$X" 0 sessionId)" = "plan-b" ] && pass "newest record is prepended (index 0)" || fail "prepend order wrong: $(field "$X" 0 sessionId)"
[ "$(field "$X" 0 harness)" = "marathon" ] && pass "harness field carried" || fail "harness wrong"
[ "$(field "$X" 0 health)" = "red" ] && pass "health field carried" || fail "health wrong"
[ "$(field "$X" 1 sessionId)" = "slug-a" ] && pass "older record slides to index 1" || fail "older record misplaced"
[ -n "$(field "$X" 0 updatedAt)" ] && pass "updatedAt stamped" || fail "updatedAt missing"

# ── (2) N sequential appends stay valid & complete ──────────────────────────
X2="$WORK/x2.json"
N=25
for i in $(seq 1 "$N"); do XYZ_JSON_PATH="$X2" bash "$WRITER" relay "seq-$i" green "T$i" "d$i"; done
valid_json "$X2" && pass "valid JSON after $N sequential appends" || fail "invalid JSON after $N appends"
[ "$(count "$X2")" = "$N" ] && pass "$N sequential records all present" || fail "expected $N, got $(count "$X2")"

# ── (3) corrupt / partial existing file self-heals (never aborts) ───────────
X3="$WORK/x3.json"
printf '{ this is not valid json' > "$X3"   # a truncated/partial write from a hypothetical crash
XYZ_JSON_PATH="$X3" bash "$WRITER" swarm slug-c orange "Title C" "d C"; rc=$?
[ "$rc" -eq 0 ] && pass "corrupt existing file does not fail the writer (exit 0)" || fail "corrupt file → exit $rc"
valid_json "$X3" && pass "corrupt file is replaced with a valid fresh array" || fail "still invalid after recovery"
[ "$(count "$X3")" = "1" ] && pass "recovered array holds the new record" || fail "recovered count=$(count "$X3")"

# a non-array JSON value (e.g. an object) is also treated as fresh
printf '{"not":"an array"}' > "$X3"
XYZ_JSON_PATH="$X3" bash "$WRITER" relay slug-d green "Title D" "d D" >/dev/null 2>&1
[ "$(count "$X3")" = "1" ] && pass "non-array JSON self-heals to a fresh 1-record array" || fail "non-array not healed: $(cat "$X3")"

# ── (4) concurrent writers: no lost update, no corruption (Phase 3 QA gate) ──
X4="$WORK/x4.json"
M=16
pids=""
session_ids=""
for i in $(seq 1 "$M"); do
  ( XYZ_JSON_PATH="$X4" XYZ_LOCK_WAIT_S="$CONCURRENT_WRITER_LOCK_WAIT_S" bash "$WRITER" relay "conc-$i" green "C$i" "d$i" ) &
  pids="$pids conc-$i:$!"
  session_ids="$session_ids conc-$i"
done
appender_statuses=""
for entry in $pids; do
  session_id="${entry%%:*}"
  pid="${entry#*:}"
  wait_for_appender "$pid"; rc=$?
  appender_statuses="$appender_statuses $session_id:$rc"
  case "$rc" in
    0) ;;
    75) fail "appender sessionId=$session_id; terminal state=lock never acquired; writer XYZ_LOCK_WAIT_S=${CONCURRENT_WRITER_LOCK_WAIT_S}s exhausted. $(concurrent_bounds)" ;;
    124) fail "appender sessionId=$session_id; terminal state=process failed; test wait=${CONCURRENT_TEST_WAIT_S}s exhausted. $(concurrent_bounds)" ;;
    *) fail "appender sessionId=$session_id; terminal state=process failed (exit $rc). $(concurrent_bounds)" ;;
  esac
done

# GH-358 negative control: only the focused instrumentation test sets this test-only switch.  It
# simulates a successful writer whose record disappeared after the appenders finished.
if [[ -n "${XYZ_COMPLETION_TEST_CLOBBER_SESSION_ID:-}" ]]; then
  python3 - "$X4" "$XYZ_COMPLETION_TEST_CLOBBER_SESSION_ID" <<'PYEOF'
import json, sys
path, session_id = sys.argv[1:]
with open(path) as f:
    records = json.load(f)
with open(path, "w") as f:
    json.dump([r for r in records if r.get("sessionId") != session_id], f)
    f.write("\n")
PYEOF
  echo "  TEST CONTROL: clobbered sessionId=$XYZ_COMPLETION_TEST_CLOBBER_SESSION_ID after successful append"
fi

valid_json "$X4" && pass "valid JSON after $M concurrent appends" || fail "corrupt after concurrent writes: $(cat "$X4")"
concurrent_count="$(count "$X4")"
[ "$concurrent_count" = "$M" ] && pass "all $M concurrent records survive (lock prevents lost update)" || fail "expected $M, got $concurrent_count — a record was clobbered"
distinct="$(python3 -c "import json;print(len({r['sessionId'] for r in json.load(open('$X4'))}))" 2>/dev/null)"
[ "$distinct" = "$M" ] && pass "all $M sessionIds distinct (no duplicate/overwrite)" || fail "distinct=$distinct"
if ! valid_json "$X4" || [ "$concurrent_count" != "$M" ] || [ "$distinct" != "$M" ]; then
  echo "  concurrent diagnostic: $(concurrent_bounds)"
  for session_id in $session_ids; do
    if ! has_session_id "$X4" "$session_id"; then
      rc="$(appender_status "$session_id" "$appender_statuses")"
      report_missing_session "$session_id" "$rc"
    fi
  done
fi

# ── (5) no leftover temp file or lock dir after a write ─────────────────────
[ -z "$(find "$WORK" -name '.xyz.*.tmp' 2>/dev/null)" ] && pass "no leftover temp files" || fail "temp file leaked: $(find "$WORK" -name '.xyz.*.tmp')"
[ ! -e "$X4.lock" ] && pass "lock dir released after concurrent round" || fail "lock dir leaked: $X4.lock"

# ── (6) arg validation ──────────────────────────────────────────────────────
XYZ_JSON_PATH="$WORK/bad.json" bash "$WRITER" bogus slug green T d >/dev/null 2>&1; rc=$?
[ "$rc" -ne 0 ] && pass "unknown harness rejected (exit $rc)" || fail "bogus harness accepted"
XYZ_JSON_PATH="$WORK/bad.json" bash "$WRITER" relay slug purple T d >/dev/null 2>&1; rc=$?
[ "$rc" -ne 0 ] && pass "unknown health rejected (exit $rc)" || fail "bogus health accepted"
XYZ_JSON_PATH="$WORK/bad.json" bash "$WRITER" relay slug green T >/dev/null 2>&1; rc=$?
[ "$rc" -ne 0 ] && pass "missing arg rejected (exit $rc)" || fail "too-few-args accepted"

# ── (7) heartbeat companion file: overwrite, stale-while-running, clear, concurrency ───────────
HB="$WORK/heartbeat.json"
XYZ_HEARTBEAT_JSON_PATH="$HB" bash "$HEARTBEAT" marathon hb-1
valid_obj "$HB" && pass "heartbeat file is a single valid JSON object" || fail "invalid heartbeat JSON: $(cat "$HB")"
[ "$(obj_field "$HB" harness)" = "marathon" ] && pass "heartbeat harness field carried" || fail "heartbeat harness wrong"
[ "$(obj_field "$HB" sessionId)" = "hb-1" ] && pass "heartbeat sessionId field carried" || fail "heartbeat sessionId wrong"
[ -n "$(obj_field "$HB" updatedAt)" ] && pass "heartbeat updatedAt stamped" || fail "heartbeat updatedAt missing"

XYZ_HEARTBEAT_JSON_PATH="$HB" bash "$HEARTBEAT" marathon hb-2
valid_obj "$HB" && pass "heartbeat overwrite stays valid JSON" || fail "heartbeat overwrite invalid: $(cat "$HB")"
[ "$(obj_field "$HB" sessionId)" = "hb-2" ] && pass "heartbeat overwrites instead of appending" || fail "heartbeat did not overwrite: $(cat "$HB")"

XH="$WORK/x-heartbeat.json"
XYZ_JSON_PATH="$XH" bash "$WRITER" marathon done-1 green "Done 1" "completed 1"
XYZ_HEARTBEAT_JSON_PATH="$HB" bash "$HEARTBEAT" marathon run-inflight
[ "$(count "$XH")" = "1" ] && [ "$(field "$XH" 0 sessionId)" = "done-1" ] && pass "mid-run heartbeat does not change prior completed XYZ.json" || fail "completion log changed during heartbeat write"
[ "$(obj_field "$HB" sessionId)" = "run-inflight" ] && pass "mid-run heartbeat marks the current in-flight session" || fail "heartbeat missing current session"

XYZ_HEARTBEAT_JSON_PATH="$HB" XYZ_HEARTBEAT_CLEAR=1 bash "$HEARTBEAT" marathon run-inflight
XYZ_JSON_PATH="$XH" bash "$WRITER" marathon run-inflight green "Run inflight" "completed inflight"
[ ! -e "$HB" ] && pass "matching completion clears heartbeat before final append" || fail "heartbeat still present after matching clear"
[ "$(field "$XH" 0 sessionId)" = "run-inflight" ] && pass "matching completion still appends the final XYZ.json record" || fail "final completion record missing"

XYZ_HEARTBEAT_JSON_PATH="$HB" bash "$HEARTBEAT" relay crash-1
XYZ_HEARTBEAT_JSON_PATH="$HB" XYZ_HEARTBEAT_CLEAR=1 bash "$HEARTBEAT" relay other-session
[ -e "$HB" ] && [ "$(obj_field "$HB" sessionId)" = "crash-1" ] && pass "non-matching clear leaves a stale/crashed heartbeat in place" || fail "non-matching clear removed the wrong heartbeat"

HB2="$WORK/heartbeat-concurrent.json"
M2=16
pids=""
for i in $(seq 1 "$M2"); do
  ( XYZ_HEARTBEAT_JSON_PATH="$HB2" bash "$HEARTBEAT" relay "hb-$i" ) &
  pids="$pids $!"
done
for p in $pids; do
  wait "$p" 2>/dev/null; rc=$?
  [ "$rc" -eq 0 ] || fail "heartbeat appender pid=$p failed (exit $rc)"
done
valid_obj "$HB2" && pass "heartbeat stays valid JSON under concurrent overwrites" || fail "concurrent heartbeat corrupt: $(cat "$HB2")"
case "$(obj_field "$HB2" sessionId)" in hb-*) pass "concurrent heartbeat ends with one complete winning sessionId";; *) fail "unexpected concurrent sessionId=$(obj_field "$HB2" sessionId)";; esac
[ -z "$(find "$WORK" -name '.xyz-heartbeat.*.tmp' 2>/dev/null)" ] && pass "heartbeat writer leaves no temp files behind" || fail "heartbeat temp file leaked: $(find "$WORK" -name '.xyz-heartbeat.*.tmp')"

# ── (8) health-lib mapping matches GH-24's table ───────────────────────────
. "$ROOT/utils/telemetry/health-lib.sh"
h() { xyz_health_from_status "$1" "$2" "$3"; }
[ "$(h Approved 1 PASS)" = "green" ]        && pass "STATUS Approved → green" || fail "Approved not green"
[ "$(h Closed 1 '')" = "green" ]            && pass "STATUS Closed → green" || fail "Closed not green"
[ "$(h Escalated 1 PASS)" = "orange" ]      && pass "STATUS Escalated → orange" || fail "Escalated not orange"
[ "$(h 'Changes requested' 1 PASS)" = "orange" ] && pass "Changes requested → orange" || fail "Changes requested not orange"
[ "$(h 'In Progress' 1 PASS)" = "orange" ]  && pass "In Progress + verdict → orange" || fail "In Progress not orange"
[ "$(h 'In Progress' 0 '')" = "red" ]       && pass "In Progress + no log → red" || fail "empty-log not red"
[ "$(h '' 1 '')" = "red" ]                  && pass "no STATUS + no verdict → red" || fail "no-verdict not red"
[ "$(h 'In Progress' 1 FAIL)" = "red" ]     && pass "VERDICT FAIL under non-terminal → red" || fail "FAIL override missing"
[ "$(h Approved 1 FAIL)" = "green" ]        && pass "VERDICT FAIL under Approved stays green" || fail "green wrongly overridden"

echo "  xyz-completion: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
