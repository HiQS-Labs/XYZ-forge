#!/usr/bin/env bash
# GH-384 — Test suite for cross-device AgentChorus bridge over Cloudflare Tunnel / HTTP.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
CLI="$REPO/skills/agent-chorus/scripts/agent_chorus.py"
BRIDGE="$REPO/skills/agent-chorus/scripts/agent_chorus_bridge.py"
CLIENT="$REPO/skills/agent-chorus/scripts/agent_chorus_client.py"
SKILL="$REPO/skills/agent-chorus/SKILL.md"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/agent-chorus-bridge-test.XXXXXX")" || {
  echo "FAIL: mktemp -d failed" >&2
  exit 1
}
[ -n "$WORK" ] && [ -d "$WORK" ] || {
  echo "FAIL: mktemp -d returned an invalid directory" >&2
  exit 1
}
case "$WORK" in
  "${TMPDIR:-/tmp}"/agent-chorus-bridge-test.*) ;;
  *) echo "FAIL: refusing unsafe cleanup target: $WORK" >&2; exit 1 ;;
esac

BRIDGE_PID=""
cleanup() {
  if [ -n "$BRIDGE_PID" ] && kill -0 "$BRIDGE_PID" 2>/dev/null; then
    kill -TERM "$BRIDGE_PID" 2>/dev/null || true
    wait "$BRIDGE_PID" 2>/dev/null || true
  fi
  rm -rf "$WORK"
}
trap cleanup EXIT

PASS=0
FAIL=0
pass() { printf '  PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }

expect_contains() {
  _label="$1"; _text="$2"; _needle="$3"
  case "$_text" in *"$_needle"*) pass "$_label" ;; *) fail "$_label (missing: $_needle)" ;; esac
}

expect_not_contains() {
  _label="$1"; _text="$2"; _needle="$3"
  case "$_text" in *"$_needle"*) fail "$_label (unexpected: $_needle)" ;; *) pass "$_label" ;; esac
}

echo "agent-chorus-bridge (GH-384):"
ROOT="$WORK/repo_root"
mkdir -p "$ROOT"
STORE="$WORK/Agent2Agent-Transcripts"
mkdir -p "$STORE"
export AGENT2AGENT_HOME="$STORE"

PACKET="$WORK/packet.md"
cat >"$PACKET" <<'PACKET'
## Goal
Validate the AgentChorus cross-device bridge.
## Scope
Localhost HTTP bridge and remote client interaction.
## Context and current state
Testing dual auth, capability tokens, and 10-minute idle leases.
## Evidence and artifacts
HTTP responses and transcript files.
## Constraints and safety boundaries
Must preserve flock and single-writer invariants.
## Questions for participants
Does the bridge enforce all AgentChorus invariants?
## Requested outcome / done condition
All tests pass and discussion closes cleanly.
PACKET

# 1. Syntax and AST check
python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(), feature_version=(3, 8))' "$BRIDGE" \
  && pass "bridge parses with Python 3.8 floor" \
  || fail "bridge uses syntax newer than Python 3.8"

python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(), feature_version=(3, 8))' "$CLIENT" \
  && pass "client parses with Python 3.8 floor" \
  || fail "client uses syntax newer than Python 3.8"

# 2. Start bridge server on random free port
PORT_FILE="$WORK/port.txt"
LOG_FILE="$WORK/bridge.log"

python3 -c '
import socket, sys
s = socket.socket()
s.bind(("127.0.0.1", 0))
port = s.getsockname()[1]
s.close()
sys.stdout.write(str(port))
' > "$PORT_FILE"
PORT="$(cat "$PORT_FILE")"

python3 "$BRIDGE" --host 127.0.0.1 --port "$PORT" --root "$ROOT" --store "$STORE" >"$LOG_FILE" 2>&1 &
BRIDGE_PID=$!
sleep 1.0

if ! kill -0 "$BRIDGE_PID" 2>/dev/null; then
  fail "bridge failed to start: $(cat "$LOG_FILE")"
  exit 1
fi
pass "bridge server started on 127.0.0.1:$PORT"

BASE_URL="http://127.0.0.1:$PORT"

# 3. GET / health check
health_res="$(curl -s -w "\n%{http_code}" "$BASE_URL/")"
health_code="$(echo "$health_res" | tail -n 1)"
health_body="$(echo "$health_res" | sed '$d')"

[ "$health_code" -eq 200 ] && pass "GET / returns HTTP 200" || fail "GET / returned HTTP $health_code: $health_body"
expect_contains "health body reports service name" "$health_body" "agent-chorus-bridge"

# 4. POST /sessions — create new discussion
create_payload="$(python3 -c '
import json, sys
packet = open(sys.argv[1]).read()
print(json.dumps({
  "subject": "Bridge Architecture Verification",
  "packet": packet,
  "agents": 2,
  "explicit_id": "777001"
}))
' "$PACKET")"

create_res="$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/sessions" \
  -H "Content-Type: application/json" -d "$create_payload")"
create_code="$(echo "$create_res" | tail -n 1)"
create_body="$(echo "$create_res" | sed '$d')"

[ "$create_code" -eq 201 ] && pass "POST /sessions creates discussion 777001 (HTTP 201)" || fail "POST /sessions returned HTTP $create_code: $create_body"
expect_contains "response contains discussion id" "$create_body" '"id": "777001"'
expect_contains "response reports NEXT is agent2" "$create_body" '"next": "agent2"'

# Verify transcript exists on disk
TRANSCRIPT=( "$STORE/repositories"/*--*/*/"777001--bridge-architecture-verification/conversation.md" )
[ -f "${TRANSCRIPT[0]}" ] && pass "canonical conversation.md created on local filesystem" || fail "conversation.md missing"

# 5. POST /sessions/777001/join — seat capability token issuance
join2_res="$(python3 "$CLIENT" --url "$BASE_URL" join --id 777001 --agent 2 --model "gemini-flash" 2>&1)"
expect_contains "agent2 join receives take-turn decision" "$join2_res" '"decision": "take-turn"'
expect_contains "agent2 join receives capability token" "$join2_res" '"capability_token":'

TOKEN_AGENT2="$(python3 -c 'import json, sys; print(json.loads(sys.stdin.read())["capability_token"])' <<<"$join2_res")"
[ -n "$TOKEN_AGENT2" ] && pass "agent2 capability token extracted" || fail "agent2 capability token missing"

join1_res="$(python3 "$CLIENT" --url "$BASE_URL" join --id 777001 --agent 1 2>&1)"
expect_contains "agent1 join receives wait decision" "$join1_res" '"decision": "wait"'
TOKEN_AGENT1="$(python3 -c 'import json, sys; print(json.loads(sys.stdin.read())["capability_token"])' <<<"$join1_res")"

# 6. Four-turn alternating conversation
# Turn 2: Remote Agent 2 sends via HTTP client
CANARY_BODY_TEXT="ConfidentialMessageCanary123"
send2_res="$(python3 "$CLIENT" --url "$BASE_URL" send \
  --id 777001 --agent 2 --next-agent 1 --token "$TOKEN_AGENT2" \
  --expected-turn 1 --message "Turn 2 from remote agent: $CANARY_BODY_TEXT" 2>&1)"
expect_contains "remote agent2 send succeeds" "$send2_res" '"turn": 2'
expect_contains "turn 2 routes to agent1" "$send2_res" '"next": "agent1"'

# Turn 3: Local Agent 1 takes turn via local CLI
turn3_out="$(python3 "$CLI" --root "$ROOT" send --id 777001 --agent 1 --next-agent 2 --message "Turn 3 from local agent" 2>&1)"
expect_contains "local agent1 advances to turn 3" "$turn3_out" "Recorded turn 3"

# Remote Agent 2 fetches turns
turns_res="$(python3 "$CLIENT" --url "$BASE_URL" turns --id 777001 --after 1 2>&1)"
expect_contains "turns endpoint returns turn 2" "$turns_res" '"turn": 2'
expect_contains "turns endpoint returns turn 3" "$turns_res" '"turn": 3'

# Turn 4: Remote Agent 2 sends via HTTP client
send4_res="$(python3 "$CLIENT" --url "$BASE_URL" send \
  --id 777001 --agent 2 --next-agent 1 --token "$TOKEN_AGENT2" \
  --expected-turn 3 --message "Turn 4 from remote agent: ready to close" 2>&1)"
expect_contains "remote agent2 advances to turn 4" "$send4_res" '"turn": 4'

# Turn 5: Local Agent 1 closes discussion
CLOSE_MSG="$WORK/close.md"
cat >"$CLOSE_MSG" <<'CLOSE'
## Final Consensus & Recommendation

### Decision
Bridge architecture verified and accepted.

### Key Invariants & Rationale
Flock, single-writer routing, capability tokens, and 10-minute idle leases are fully proven.

### Recorded Dissent / Falsifiers
- None raised during testing.
- Verified in-process flock serialization.

### Recommended Next Actions
1. Deploy bridge across Cloudflare Tunnel in production.
CLOSE

close_out="$(python3 "$CLI" --root "$ROOT" close --id 777001 --agent 1 --message-file "$CLOSE_MSG" 2>&1)"
expect_contains "local agent1 closes discussion" "$close_out" "Closed XYZ AgentChorus #777001"

# Remote agent checks status -> Closed
status_res="$(python3 "$CLIENT" --url "$BASE_URL" status --id 777001 2>&1)"
expect_contains "remote client observes Closed status" "$status_res" '"status": "Closed"'

# 7. Authentication & Capability Token Failure Modes
echo "Testing authentication failure modes:"

# Create second discussion for failure tests
create_fail_res="$(python3 -c '
import json, sys
packet = open(sys.argv[1]).read()
print(json.dumps({
  "subject": "Failure Mode Suite",
  "packet": packet,
  "agents": 2,
  "explicit_id": "777002"
}))
' "$PACKET" | curl -s -X POST "$BASE_URL/sessions" -H "Content-Type: application/json" -d @-)"

join_fail_res="$(python3 "$CLIENT" --url "$BASE_URL" join --id 777002 --agent 2 2>&1)"
TOKEN_F2="$(python3 -c 'import json, sys; print(json.loads(sys.stdin.read())["capability_token"])' <<<"$join_fail_res")"
join_fail1_res="$(python3 "$CLIENT" --url "$BASE_URL" join --id 777002 --agent 1 2>&1)"
TOKEN_F1="$(python3 -c 'import json, sys; print(json.loads(sys.stdin.read())["capability_token"])' <<<"$join_fail1_res")"

# 7a. Missing capability token -> HTTP 401
no_token_res="$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/sessions/777002/send" \
  -H "Content-Type: application/json" \
  -d '{"agent": 2, "next_agent": 1, "message": "hello"}')"
no_token_code="$(echo "$no_token_res" | tail -n 1)"
[ "$no_token_code" -eq 401 ] && pass "missing token rejected with HTTP 401" || fail "missing token returned HTTP $no_token_code"

# 7b. Wrong seat capability token (Agent 1 token used for Agent 2 seat) -> HTTP 403
wrong_token_res="$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/sessions/777002/send" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_F1" \
  -d '{"agent": 2, "next_agent": 1, "message": "hello"}')"
wrong_token_code="$(echo "$wrong_token_res" | tail -n 1)"
[ "$wrong_token_code" -eq 403 ] && pass "wrong seat capability token rejected with HTTP 403" || fail "wrong token returned HTTP $wrong_token_code"

# 7c. Out of turn write (Agent 1 attempts write while NEXT is Agent 2) -> HTTP 409
out_of_turn_res="$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/sessions/777002/send" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_F1" \
  -d '{"agent": 1, "next_agent": 2, "message": "hello out of turn"}')"
out_of_turn_code="$(echo "$out_of_turn_res" | tail -n 1)"
[ "$out_of_turn_code" -eq 409 ] && pass "out of turn write rejected with HTTP 409" || fail "out of turn returned HTTP $out_of_turn_code"

# 7d. Stale version write -> HTTP 409
stale_ver_res="$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/sessions/777002/send" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_F2" \
  -d '{"agent": 2, "next_agent": 1, "expected_turn": 999, "message": "hello stale version"}')"
stale_ver_code="$(echo "$stale_ver_res" | tail -n 1)"
[ "$stale_ver_code" -eq 409 ] && pass "stale version rejected with HTTP 409" || fail "stale version returned HTTP $stale_ver_code"

# 7e. Idempotency test: duplicate send with idempotency_key
idem_res1="$(curl -s -X POST "$BASE_URL/sessions/777002/send" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_F2" \
  -d '{"agent": 2, "next_agent": 1, "expected_turn": 1, "idempotency_key": "req-xyz-123", "message": "Valid Turn 2"}')"
expect_contains "first send with idempotency key commits turn 2" "$idem_res1" '"turn": 2'

idem_res2="$(curl -s -X POST "$BASE_URL/sessions/777002/send" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_F2" \
  -d '{"agent": 2, "next_agent": 1, "expected_turn": 1, "idempotency_key": "req-xyz-123", "message": "Valid Turn 2"}')"
expect_contains "duplicate send with idempotency key returns identical turn 2" "$idem_res2" '"turn": 2'

# Verify transcript has exactly 2 turns (not 3)
content_777002_arr=( "$STORE/repositories"/*--*/*/"777002--failure-mode-suite/conversation.md" )
content_777002="$(cat "${content_777002_arr[0]}")"
turn_count_777002="$(grep -c '^### Turn ' <<<"$content_777002")"
[ "$turn_count_777002" -eq 2 ] && pass "idempotent retry produced exactly one committed turn on disk" || fail "expected 2 turns, found $turn_count_777002"

# 8. Cloudflare Access Service Token Verification
echo "Testing Cloudflare Access Service Token validation:"
kill -TERM "$BRIDGE_PID" 2>/dev/null || true
wait "$BRIDGE_PID" 2>/dev/null || true

CF_PORT="$((PORT + 1))"
CF_ID="test-cf-client-id"
CF_TOKEN="test-cf-client-secret-999"

python3 "$BRIDGE" --host 127.0.0.1 --port "$CF_PORT" --root "$ROOT" --store "$STORE" \
  --cf-client-id "$CF_ID" --cf-client-secret "$CF_TOKEN" >"$LOG_FILE.cf" 2>&1 &
BRIDGE_PID=$!
sleep 1.0

CF_BASE_URL="http://127.0.0.1:$CF_PORT"

# Request without CF headers -> HTTP 401
cf_no_headers="$(curl -s -w "\n%{http_code}" "$CF_BASE_URL/sessions/777001/status")"
cf_no_code="$(echo "$cf_no_headers" | tail -n 1)"
[ "$cf_no_code" -eq 401 ] && pass "missing CF Access headers rejected with HTTP 401" || fail "missing CF headers returned HTTP $cf_no_code"

# Request with wrong CF headers -> HTTP 401
cf_bad_headers="$(curl -s -w "\n%{http_code}" "$CF_BASE_URL/sessions/777001/status" \
  -H "CF-Access-Client-Id: $CF_ID" -H "CF-Access-Client-Secret: wrong-secret")"
cf_bad_code="$(echo "$cf_bad_headers" | tail -n 1)"
[ "$cf_bad_code" -eq 401 ] && pass "invalid CF Access secret rejected with HTTP 401" || fail "invalid CF secret returned HTTP $cf_bad_code"

# Request with valid CF headers -> HTTP 200
cf_ok_headers="$(curl -s -w "\n%{http_code}" "$CF_BASE_URL/sessions/777001/status" \
  -H "CF-Access-Client-Id: $CF_ID" -H "CF-Access-Client-Secret: $CF_TOKEN")"
cf_ok_code="$(echo "$cf_ok_headers" | tail -n 1)"
[ "$cf_ok_code" -eq 200 ] && pass "valid CF Access headers accepted with HTTP 200" || fail "valid CF headers returned HTTP $cf_ok_code"

# 9. 10-Minute Idle Lease Expiration Test (configured to 2s for test)
echo "Testing idle lease expiration:"
kill -TERM "$BRIDGE_PID" 2>/dev/null || true
wait "$BRIDGE_PID" 2>/dev/null || true

IDLE_PORT="$((PORT + 2))"
python3 "$BRIDGE" --host 127.0.0.1 --port "$IDLE_PORT" --root "$ROOT" --store "$STORE" \
  --idle-timeout 2.0 >"$LOG_FILE.idle" 2>&1 &
BRIDGE_PID=$!
sleep 1.0

IDLE_BASE="http://127.0.0.1:$IDLE_PORT"

# Create discussion on short-idle bridge
python3 -c '
import json, sys
packet = open(sys.argv[1]).read()
print(json.dumps({
  "subject": "Idle Lease Expiration Check",
  "packet": packet,
  "agents": 2,
  "explicit_id": "777003"
}))
' "$PACKET" | curl -s -X POST "$IDLE_BASE/sessions" -H "Content-Type: application/json" -d @- >/dev/null

join_idle="$(python3 "$CLIENT" --url "$IDLE_BASE" join --id 777003 --agent 2 2>&1)"
TOKEN_IDLE="$(python3 -c 'import json, sys; print(json.loads(sys.stdin.read())["capability_token"])' <<<"$join_idle")"

# Wait 3 seconds to exceed 2-second idle timeout
sleep 3.0

idle_expired_res="$(curl -s -w "\n%{http_code}" -X POST "$IDLE_BASE/sessions/777003/send" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_IDLE" \
  -d '{"agent": 2, "next_agent": 1, "message": "Send after idle expiry"}')"
idle_expired_code="$(echo "$idle_expired_res" | tail -n 1)"
[ "$idle_expired_code" -eq 410 ] && pass "write on expired session rejected with HTTP 410 Gone" || fail "expired session returned HTTP $idle_expired_code"

# Verify canonical conversation.md still exists and is not corrupted
IDLE_TRANSCRIPT=( "$STORE/repositories"/*--*/*/"777003--idle-lease-expiration-check/conversation.md" )
[ -f "${IDLE_TRANSCRIPT[0]}" ] && pass "canonical transcript preserved after session expiry" || fail "transcript corrupted or deleted"

# 10. Zero-Leak Access Log Verification
echo "Auditing bridge access logs for zero secret / message content leakage:"
ALL_LOGS="$(cat "$LOG_FILE" "$LOG_FILE.cf" "$LOG_FILE.idle" 2>/dev/null || true)"

expect_not_contains "access log contains no capability tokens" "$ALL_LOGS" "$TOKEN_AGENT2"
expect_not_contains "access log contains no CF Access secret" "$ALL_LOGS" "$CF_TOKEN"
expect_not_contains "access log contains no message content" "$ALL_LOGS" "$CANARY_BODY_TEXT"

# 11. Crash & Restart Recovery
echo "Testing crash and restart recovery:"
kill -9 "$BRIDGE_PID" 2>/dev/null || true
wait "$BRIDGE_PID" 2>/dev/null || true

RESTART_PORT="$((PORT + 3))"
python3 "$BRIDGE" --host 127.0.0.1 --port "$RESTART_PORT" --root "$ROOT" --store "$STORE" >"$LOG_FILE.restart" 2>&1 &
BRIDGE_PID=$!
sleep 1.0

restart_status="$(curl -s "http://127.0.0.1:$RESTART_PORT/sessions/777001/status")"
expect_contains "restarted bridge recovers status of closed discussion 777001" "$restart_status" '"status": "Closed"'
expect_contains "restarted bridge recovers turn count 5" "$restart_status" '"current_turn": 5'


# ── GH-384 review: the UNCONFIGURED-CF path ──────────────────────────────────────────────────────
#
# Every CF assertion above starts the bridge WITH credentials, so all three pass while saying
# nothing about the default configuration — which is the one that ships. That is the shape
# AGENTS.md §6 calls a check that cannot fail: green, and blind to the hazard.
#
# The hazard, verified by hand during review: with no credentials, zero-header requests minted a
# capability token from /join, read full turn bodies from /turns, and wrote to conversation.md on
# disk. Over --tunnel that is reachable from anywhere, and conversation.md is fed back to a local
# agent as turn context, so it doubles as a remote prompt-injection channel.
#
# These assertions pin the guard that closes it. NEGATIVE CONTROL: delete the
# `args.tunnel and not auth_enabled` branch in agent_chorus_bridge.py's main() and A1 must go red.

echo
echo "── unauthenticated-by-default guard (GH-384 review) ──"

# A1: --tunnel must REFUSE when no Cloudflare credentials are configured.
# BOUNDED, and that is load-bearing. The first draft invoked the bridge in the foreground: with
# the guard PRESENT it exits 2 immediately and passes, but with the guard REMOVED it falls through
# to launch_quick_tunnel + serve_forever and the assertion HANGS instead of failing. A hanging
# assertion stalls the whole pool and never reports — strictly worse than a red. Found by running
# the mutation this block exists to catch. Run it detached, poll for a verdict, reap either way.
_noauth_log="$WORK/noauth-tunnel.log"
: > "$_noauth_log"
( env -u CF_ACCESS_CLIENT_ID -u CF_ACCESS_CLIENT_SECRET \
    PYTHONUNBUFFERED=1 python3 "$BRIDGE" --port 0 --tunnel --root "$REPO" \
    > "$_noauth_log" 2>&1; echo "rc=$?" >> "$_noauth_log" ) &
_noauth_pid=$!
for _i in $(seq 1 100); do
  grep -q '^rc=' "$_noauth_log" 2>/dev/null && break
  sleep 0.1
done
kill "$_noauth_pid" 2>/dev/null || true
wait "$_noauth_pid" 2>/dev/null || true
noauth_out="$(cat "$_noauth_log")"

case "$noauth_out" in
  *"REFUSING --tunnel without Cloudflare Access credentials"*)
    pass "A1: --tunnel refuses without CF Access credentials" ;;
  *)
    fail "A1: --tunnel did NOT refuse unauthenticated (got: $(printf '%s' "$noauth_out" | head -1))" ;;
esac

# A1b: the refusal must be an error EXIT, not a warning it continues past. If the guard is gone
# the process never exits, no rc= line is ever written, and this fails on the missing verdict —
# which is the correct outcome for a hang.
case "$noauth_out" in
  *"rc=2"*) pass "A1b: the refusal exits 2 rather than continuing" ;;
  *)        fail "A1b: expected exit 2 from the tunnel refusal (no rc=2 in output — guard missing or process hung)" ;;
esac

# A2: the escape hatch still exists, so the guard is a decision and not a wall. Asserted on the
# flag surface rather than by opening a real tunnel in a test.
# capture-then-match, never a pipe into a quiet grep (GH-139): `grep -q` exits at its first match
# and the writer dies of SIGPIPE, which is nondeterministically red under `set -o pipefail`.
_help_out="$(python3 "$BRIDGE" --help 2>&1)"
grep -q -- '--insecure-allow-unauthenticated' <<<"$_help_out" \
  && pass "A2: --insecure-allow-unauthenticated is available as an explicit opt-out" \
  || fail "A2: no documented way to intentionally run an open bridge"

# A3: the banner must state the auth posture in BOTH directions. Silence used to mean "disabled",
# which is the state an operator most needs told, and the old check read argparse instead of the
# manager so an env-configured bridge also printed nothing.
# NB: no `timeout(1)` here — it is GNU coreutils and is NOT present on macOS, where this gate's
# promotion boundary runs. The first draft used it; the command simply did not exist, `|| true`
# swallowed the failure, and the assertion compared against an empty string. Start the server in
# the background, read its banner from a log, then kill it. PYTHONUNBUFFERED is required: stdout
# is block-buffered when redirected, so the banner never reaches the file otherwise.
_banner() {  # <log> <env-assignments...> — capture the startup banner of a short-lived bridge
  local log="$1"; shift
  : > "$log"
  ( env "$@" PYTHONUNBUFFERED=1 python3 "$BRIDGE" --port 0 --root "$REPO" > "$log" 2>&1 ) &
  local pid=$!
  local i
  for i in $(seq 1 100); do
    grep -q 'Cloudflare Access authentication' "$log" 2>/dev/null && break
    sleep 0.05
  done
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  cat "$log"
}

banner_off="$(_banner "$WORK/banner-off.log" CF_ACCESS_CLIENT_ID= CF_ACCESS_CLIENT_SECRET=)"
expect_contains "A3: banner names DISABLED auth on an unauthenticated bridge" "$banner_off" "DISABLED"

# The fixture values go through variables, not inline literals. security-scan.sh's
# PATTERN_CRED_ASSIGN flags a secret-named variable assigned an inline literal wherever it appears
# (including inside a comment — it is a static text scan, so this note must not spell the shape
# out) — correctly, since it cannot
# know a probe value from a real one — and PATTERN_CRED_EXCLUDE deliberately permits a `$`-prefixed
# value. Indirection is the sanctioned shape here, not a baseline entry: baselining a fixture
# teaches the scanner to ignore the pattern that matters.
_probe_id="probe-id"
_probe_sec="probe-not-a-real-credential"
banner_on="$(_banner "$WORK/banner-on.log" CF_ACCESS_CLIENT_ID="$_probe_id" CF_ACCESS_CLIENT_SECRET="$_probe_sec")"
expect_contains "A3b: banner names ENABLED when creds come from the ENVIRONMENT (not argv)" "$banner_on" "ENABLED"

echo
echo "=========================================="
echo "AgentChorus Bridge Test Summary: $PASS passed, $FAIL failed"
echo "=========================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
