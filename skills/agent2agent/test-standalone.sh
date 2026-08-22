#!/usr/bin/env bash
# test-standalone.sh — minimal, dependency-free regression suite for agent2agent.py.
#
# TEMP HOME: this file lives beside the skill (skills/agent2agent/) rather than under this
# repo's test/ tree on purpose — it is a portability proof, not a replacement for the full
# suite. It exercises ONLY agent2agent.py + bash/python3/coreutils: no bin/tick, no
# relay-automation/, no test/_setup.sh or lib/fixture-guard.sh. If a real standalone
# extraction of this skill ever happens, this file (or its direct descendant) is the one
# that should move with it; test/agent2agent.sh should stay behind since it also covers
# this repo's poll.sh interop point.
#
# For full coverage (129 assertions incl. doorbell staleness, 3+ roster onboarding, the
# poll.sh compatibility check, and more) run test/agent2agent.sh from the repo root instead.
#
# Deliberately NOT covered: `drive` (opt-in bounded polling + an operator-supplied turn
# command) — it spawns an arbitrary process, which is out of scope for a smoke suite this
# small; the full suite doesn't exercise it either.
#
# Two implicit contracts a standalone porter should know about, both used below:
#   AGENT2AGENT_ID_SEQUENCE — env var; a comma-free six-digit override for `start`'s
#     otherwise-random discussion ID, so tests get a deterministic ID to address.
#   --expect-subject — `join`'s optional guard against a stale/altered invitation subject.
#
# Usage: bash skills/agent2agent/test-standalone.sh
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI="$HERE/scripts/agent2agent.py"

command -v python3 >/dev/null 2>&1 || { echo "FAIL: python3 not found" >&2; exit 1; }
[ -f "$CLI" ] || { echo "FAIL: $CLI not found" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/agent2agent-standalone-test.XXXXXX")" || {
  echo "FAIL: mktemp -d failed" >&2; exit 1
}
case "$WORK" in
  "${TMPDIR:-/tmp}"/agent2agent-standalone-test.*) ;;
  *) echo "FAIL: refusing unsafe cleanup target: $WORK" >&2; exit 1 ;;
esac
trap 'rm -rf "$WORK"' EXIT
ROOT="$WORK/root"
mkdir -p "$ROOT"

PASS=0
FAIL=0
pass() { printf '  PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }
expect_contains() {
  _label="$1"; _text="$2"; _needle="$3"
  case "$_text" in *"$_needle"*) pass "$_label" ;; *) fail "$_label (missing: $_needle)" ;; esac
}
fingerprint() { cksum "$1" | awk '{print $1 ":" $2}'; }
# F1: a relay-file-only fingerprint misses sibling artifacts (lock files, watch sidecars)
# agent2agent.py may create or rewrite around a call that claims to "mutate nothing" —
# notably, even a REJECTED out-of-turn send opens (and so creates, if absent) the lock
# dotfile before it checks turn ownership. Fingerprint the whole tree, not just one file.
tree_fp() { find "$ROOT" -type f -exec cksum {} + 2>/dev/null | sort | cksum; }
run() { python3 "$CLI" --root "$ROOT" "$@"; }

echo "agent2agent standalone smoke suite (no tick, no relay-automation, no repo test harness):"

# --- 1. The script runs on its own, no repo context required ---
run --help >/dev/null 2>&1
[ $? -eq 0 ] && pass "--help executes standalone" || fail "--help failed to execute"

# --- 2. start: a 3-agent discussion, deterministic ID via env override ---
start_out="$(AGENT2AGENT_ID_SEQUENCE=222222 run start --subject "standalone smoke" --agents 3 2>&1)"
start_rc=$?
[ "$start_rc" -eq 0 ] && pass "start creates a discussion" || fail "start exits $start_rc: $start_out"
expect_contains "start prints the agent2 invitation" "$start_out" \
  'Join XYZ agent2agent #222222 as agent number two to discuss: "standalone smoke"'
expect_contains "start prints the agent3 invitation" "$start_out" \
  'Join XYZ agent2agent #222222 as agent number three to discuss: "standalone smoke"'

# F6: an unguarded `find` assigns a multi-line match list to $relay_file if two files
# ever collide, and every downstream -f/fingerprint use then degrades silently. Count first.
relay_matches="$(find "$ROOT/relay-system" -type f -name '222222-*.md' -print)"
relay_count="$(printf '%s\n' "$relay_matches" | grep -c .)"
[ "$relay_count" -eq 1 ] && pass "exactly one relay file exists for #222222" \
  || fail "expected exactly 1 relay file, found $relay_count: $relay_matches"
relay_file="$relay_matches"
[ -f "$relay_file" ] && pass "relay file exists under root/relay-system/<date>/" \
  || fail "relay file missing under $ROOT/relay-system"

# --- 3. status: read-only, mutates nothing anywhere under root (not just the relay file) ---
before_status="$(tree_fp)"
status_out="$(run status --id 222222 2>&1)"
[ $? -eq 0 ] && pass "status inspects without a participant seat" || fail "status failed: $status_out"
expect_contains "status reports the subject" "$status_out" "Subject: standalone smoke"
expect_contains "status reports NEXT" "$status_out" "NEXT: agent2"
[ "$before_status" = "$(tree_fp)" ] \
  && pass "status leaves the whole tree byte-identical" || fail "status mutated something under root"

# --- 4. join: take-turn for the owner, wait for a non-owner, rejection for a bad seat ---
join2_out="$(run join --id 222222 --agent 2 --expect-subject "standalone smoke" 2>&1)"
[ $? -eq 0 ] && pass "join succeeds for the current owner" || fail "join failed: $join2_out"
expect_contains "join reports take-turn for the owner" "$join2_out" "DECISION: take-turn"

join3_out="$(run join --id 222222 --agent 3 2>&1)"
expect_contains "join reports wait for a non-owner" "$join3_out" "DECISION: wait"

run join --id 222222 --agent 9 >/dev/null 2>&1
[ $? -ne 0 ] && pass "join rejects an agent outside the roster" \
  || fail "join accepted an out-of-roster agent"

# --- 5. send: out-of-turn refusal (checked by cause, not just exit code), then a real
#         handoff agent2 -> agent3 ---
before_send_relay="$(fingerprint "$relay_file")"
before_send_tree="$(tree_fp)"
# F4: asserting only the exit code lets a refusal for the WRONG reason (bad seat, a parse
# error, a held lock) pass as if it were the turn-order check. Assert the message too.
early_out="$(run send --id 222222 --agent 3 --next-agent 2 --message "out of turn" 2>&1)"
early_rc=$?
[ "$early_rc" -ne 0 ] && pass "send rejects an out-of-turn writer" \
  || fail "out-of-turn send unexpectedly succeeded"
expect_contains "out-of-turn refusal names the turn-order cause" "$early_out" "out of turn"
[ "$before_send_relay" = "$(fingerprint "$relay_file")" ] \
  && pass "rejected send leaves the discussion content untouched" || fail "rejected send mutated the discussion"
# F1 (verified against source): append_turn() acquires the discussion lock BEFORE checking
# turn ownership, so even a REJECTED out-of-turn send creates/rewrites the lock dotfile —
# a real, benign side effect a relay-file-only fingerprint can't see. Assert it explicitly
# instead of asserting the false "nothing changed" claim the old relay-file-only check made.
[ "$before_send_tree" != "$(tree_fp)" ] \
  && pass "rejected send's lock-file side effect is visible to a tree-wide fingerprint" \
  || fail "expected the known lock-dotfile side effect but the tree was unchanged (implementation may have changed)"
[ -e "$(dirname "$relay_file")/.$(basename "$relay_file").lock" ] \
  && pass "the specific side effect is the documented lock dotfile" \
  || fail "tree changed but not via the expected .<relay>.lock dotfile"

send_out="$(run send --id 222222 --agent 2 --next-agent 3 --message "handing to agent3" 2>&1)"
[ $? -eq 0 ] && pass "send records a turn and hands off" || fail "send failed: $send_out"
expect_contains "send prints the next invitation" "$send_out" \
  'Join XYZ agent2agent #222222 as agent number three to discuss: "standalone smoke"'

# --- 6. watch: the fast path (caller already owns NEXT), the wake-on-handoff path, and
#         the timeout-expiry path — the polling logic is the part actually worth testing ---
watch_out="$(run watch --id 222222 --agent 3 --interval 0.05 --timeout 1 2>&1)"
[ $? -eq 0 ] && pass "watch returns when the participant owns NEXT" || fail "watch failed: $watch_out"
expect_contains "watch reports take-turn" "$watch_out" "DECISION: take-turn"
expect_contains "watch prints a REARM line" "$watch_out" "REARM: "

# F2: wake-on-handoff — agent2 watches while NOT yet owning NEXT; a background send from
# agent3 hands the turn over mid-poll, and the watch must return take-turn before its
# timeout, not merely time out.
( sleep 0.3; run send --id 222222 --agent 3 --next-agent 2 --message "wake agent2" >/dev/null 2>&1 ) &
WAKER=$!
wake_watch_out="$(run watch --id 222222 --agent 2 --interval 0.05 --timeout 2 2>&1)"
wake_watch_rc=$?
wait "$WAKER" 2>/dev/null
[ "$wake_watch_rc" -eq 0 ] && pass "watch wakes on a mid-poll handoff" \
  || fail "watch did not wake on handoff: rc=$wake_watch_rc out=$wake_watch_out"
expect_contains "wake-on-handoff watch reports take-turn" "$wake_watch_out" "DECISION: take-turn"

# F2 (timeout path): agent3 watches for a turn nobody hands it — must time out, not hang
# or falsely report take-turn.
timeout_watch_out="$(run watch --id 222222 --agent 3 --interval 0.05 --timeout 1 2>&1)"
timeout_watch_rc=$?
[ "$timeout_watch_rc" -ne 0 ] && pass "watch reports a real timeout when no handoff arrives" \
  || fail "watch with no handoff unexpectedly reported success: $timeout_watch_out"
expect_contains "timed-out watch reports the timeout decision" "$timeout_watch_out" "DECISION: timeout"

# The wake-on-handoff test above moved NEXT to agent2; hand it back to agent3 so the turn
# owner sections 7-8 assume (agent3) is actually correct, rather than silently relying on
# state a prior test happened to leave behind.
restore_out="$(run send --id 222222 --agent 2 --next-agent 3 --message "restore to agent3" 2>&1)"
[ $? -eq 0 ] && pass "turn restored to agent3 before the lock/close sections" \
  || fail "could not restore turn to agent3: $restore_out"

# --- 7. a real writer lock fails a concurrent write closed. The fixture holds the flock
#         WITHOUT touching the lock file's payload (F3): content is irrelevant to flock
#         contention, and overwriting it risks colliding with agent2agent.py's own
#         "pid=<n> held-since=<ts>" convention if that payload ever becomes structured.
#         Readiness is signaled via a separate sentinel file instead. ---
before_lock="$(tree_fp)"
lock_dir="$(dirname "$relay_file")"; lock_base="$(basename "$relay_file")"
sentinel="$WORK/lock-held.sentinel"
rm -f "$sentinel"
python3 - "$lock_dir/.$lock_base.lock" "$sentinel" <<'PYEOF' >/dev/null 2>&1 &
import fcntl, sys, time
lock_path, sentinel_path = sys.argv[1], sys.argv[2]
fh = open(lock_path, "a+")
fcntl.flock(fh.fileno(), fcntl.LOCK_EX)
open(sentinel_path, "w").close()
time.sleep(10)
PYEOF
LOCK_HOLDER=$!
# F8: `seq` is the least-portable thing in a "portability proof" suite (absent on some
# minimal/BSD images) — a plain counting loop needs no external command.
i=0
while [ "$i" -lt 100 ]; do
  [ -e "$sentinel" ] && break
  sleep 0.1
  i=$((i + 1))
done
lock_out="$(run send --id 222222 --agent 3 --next-agent 2 --message "contended" 2>&1)"
lock_rc=$?
kill "$LOCK_HOLDER" 2>/dev/null; wait "$LOCK_HOLDER" 2>/dev/null
[ "$lock_rc" -ne 0 ] && pass "send rejects a write while the lock is held" \
  || fail "lock-held send unexpectedly succeeded"
expect_contains "lock refusal names the cause" "$lock_out" "discussion is locked by another writer"
[ "$before_lock" = "$(tree_fp)" ] \
  && pass "lock refusal leaves the whole tree untouched" || fail "lock refusal mutated something under root"

# --- 8. close: terminal, and a subsequent join reports it ---
close_out="$(run close --id 222222 --agent 3 --message "smoke test done" 2>&1)"
[ $? -eq 0 ] && pass "close terminates the discussion" || fail "close failed: $close_out"

closed_join="$(run join --id 222222 --agent 2 2>&1)"
expect_contains "join reports closed after close" "$closed_join" "DECISION: closed"

closed_status="$(run status --id 222222 2>&1)"
expect_contains "status reports Closed" "$closed_status" "STATUS: Closed"

# F10: a cheap negative-path check — an unknown discussion ID must fail closed, not
# silently succeed or crash uncaught.
run status --id 999999 >/dev/null 2>&1
[ $? -ne 0 ] && pass "status on an unknown discussion ID fails closed" \
  || fail "status on an unknown discussion ID unexpectedly succeeded"

echo "agent2agent-standalone: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
