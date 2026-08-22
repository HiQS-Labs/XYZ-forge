#!/usr/bin/env bash
# GH-497/GH-510/GH-144 — compact multi-party discussions with explicit watch/drive levels.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
CLI="$REPO/skills/agent2agent/scripts/agent2agent.py"
SKILL="$REPO/skills/agent2agent/SKILL.md"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/agent2agent-test.XXXXXX")" || {
  echo "FAIL: mktemp -d failed" >&2
  exit 1
}
[ -n "$WORK" ] && [ -d "$WORK" ] || {
  echo "FAIL: mktemp -d returned an invalid directory" >&2
  exit 1
}
case "$WORK" in
  "${TMPDIR:-/tmp}"/agent2agent-test.*) ;;
  *) echo "FAIL: refusing unsafe cleanup target: $WORK" >&2; exit 1 ;;
esac
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
pass() { printf '  PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }
expect_contains() {
  _label="$1"; _text="$2"; _needle="$3"
  case "$_text" in *"$_needle"*) pass "$_label" ;; *) fail "$_label (missing: $_needle)" ;; esac
}
expect_file_contains() {
  _label="$1"; _file="$2"; _needle="$3"
  grep -Fq -- "$_needle" "$_file" && pass "$_label" || fail "$_label (missing: $_needle)"
}
fingerprint() { cksum "$1" | awk '{print $1 ":" $2}'; }
mtime_ns() { python3 -c 'import os, sys; print(os.stat(sys.argv[1]).st_mtime_ns)' "$1"; }

echo "agent2agent (GH-497/GH-510/GH-144):"
ROOT="$WORK/root with spaces"
mkdir -p "$ROOT"

python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(), feature_version=(3, 8))' "$CLI" \
  && pass "helper parses with the repository's Python 3.8 floor" \
  || fail "helper uses syntax newer than Python 3.8"

grep -Fq -- '<this-skill>' "$SKILL" \
  && fail "skill retains a shell-significant path placeholder" \
  || pass "skill contains no shell-significant path placeholder"
helper_examples="$(grep -Fc -- '"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py"' "$SKILL")"
[ "$helper_examples" -eq 9 ] \
  && pass "all skill commands resolve and quote the repository helper" \
  || fail "expected 9 root-resolved helper commands, found $helper_examples"
(cd "$REPO" && "$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py" --help >/dev/null) \
  && pass "documented root-resolved helper path executes" \
  || fail "documented root-resolved helper path does not execute"
expect_file_contains "skill documents stdin message streaming" "$SKILL" \
  "--message-file - < /safe/path/to/message.md"
expect_file_contains "skill documents safe lock-contention recovery" "$SKILL" \
  "discussion is locked by another writer"

# The start output is the copy/paste API. Turn 1 is durable before agent2 is invited.
start_out="$(AGENT2AGENT_ID_SEQUENCE=123456 python3 "$CLI" --root "$ROOT" start \
  --subject "subject line here" --agents 4 2>&1)"
start_rc=$?
[ "$start_rc" -eq 0 ] && pass "starts a four-agent discussion" || fail "start exits $start_rc: $start_out"
expected_invitation='Join XYZ agent2agent #123456 as agent number two to discuss: "subject line here"'
expect_contains "preserves the exact agent2 compact invitation" "$start_out" "$expected_invitation"
expect_contains "prints an upfront agent3 invitation" "$start_out" \
  'Join XYZ agent2agent #123456 as agent number three to discuss: "subject line here"'
expect_contains "prints an upfront agent4 invitation" "$start_out" \
  'Join XYZ agent2agent #123456 as agent number four to discuss: "subject line here"'
[ "$(printf '%s\n' "$start_out" | grep -c '^Join XYZ agent2agent')" -eq 3 ] \
  && pass "four-agent start prints exactly three non-initiator invitations" \
  || fail "four-agent start did not print exactly three invitations: $start_out"

relay_file="$(find "$ROOT/relay-system" -type f -name '123456-*.md' -print)"
[ -f "$relay_file" ] && pass "creates a dated relay file under a spaced root" || fail "relay file missing"
case "$relay_file" in "$ROOT"/relay-system/????-??-??/123456-agent2agent-*.md) pass "uses dated relay storage" ;; *) fail "unexpected relay path: $relay_file" ;; esac
expect_file_contains "records stable 4-agent roster" "$relay_file" "AGENTS: agent1 agent2 agent3 agent4"
expect_file_contains "routes the opening turn to agent2" "$relay_file" "NEXT: agent2"
expect_file_contains "defaults timed watch to disabled" "$relay_file" "TIMED-WATCH: disabled"

# GH-144: every non-initiator can onboard immediately. Off-turn joins and the operator status view
# are strictly read-only; neither is allowed to create a watch sidecar or writer lock.
before_early_join="$(fingerprint "$relay_file")"
early_join3="$(python3 "$CLI" --root "$ROOT" join --id 123456 --agent 3 2>&1)"
early_join4="$(python3 "$CLI" --root "$ROOT" join --id 123456 --agent 4 2>&1)"
expect_contains "agent3 can join upfront and wait" "$early_join3" "DECISION: wait"
expect_contains "agent4 can join upfront and wait" "$early_join4" "DECISION: wait"
[ "$before_early_join" = "$(fingerprint "$relay_file")" ] \
  && pass "upfront off-turn joins leave the discussion byte-identical" \
  || fail "an upfront off-turn join mutated the discussion"

before_status="$(fingerprint "$relay_file")"
status_out="$(python3 "$CLI" --root "$ROOT" status --id 123456 2>&1)"
status_rc=$?
[ "$status_rc" -eq 0 ] && pass "status inspects a discussion without a participant seat" \
  || fail "status exits $status_rc: $status_out"
expect_contains "status reports the subject" "$status_out" "Subject: subject line here"
expect_contains "status reports open state" "$status_out" "STATUS: Open"
expect_contains "status reports the current turn" "$status_out" "TURN: 1"
expect_contains "status reports the single next writer" "$status_out" "NEXT: agent2"
expect_contains "status reports the full roster" "$status_out" "AGENTS: agent1 agent2 agent3 agent4"
expect_contains "status reports the timed-watch setting" "$status_out" "TIMED-WATCH: disabled"
expect_contains "status distinguishes an unobserved/manual seat" "$status_out" \
  "DOORBELL agent4: not observed/manual"
[ "$before_status" = "$(fingerprint "$relay_file")" ] \
  && pass "status leaves the discussion byte-identical" || fail "status mutated the discussion"
status_dir="$(dirname "$relay_file")"; status_base="$(basename "$relay_file")"
if find "$status_dir" -maxdepth 1 -name "$status_base.watch.*" -print | grep -q . \
  || [ -e "$status_dir/.$status_base.lock" ]; then
  fail "status created a doorbell sidecar or writer lock"
else
  pass "status creates no doorbell sidecar or writer lock"
fi

timed_start="$(python3 "$CLI" --root "$ROOT" start --id 654321 --subject "timed watch" --timed-watch 2>&1)"
[ "$?" -eq 0 ] && pass "starts a timed-watch discussion" || fail "timed start failed: $timed_start"
expect_contains "timed invitation tells the target to start its watch" "$timed_start" \
  "Timed two-minute doorbell requested: when waiting, start a background watch that checks every 120 seconds for 1,800 seconds."
timed_join="$(python3 "$CLI" --root "$ROOT" join --id 654321 --agent 1 2>&1)"
expect_contains "timed join reports the persisted watch request" "$timed_join" \
  "TIMED-WATCH: check every 120 seconds for 1,800 seconds while waiting"
expect_file_contains "seeds turn 1 as agent1" "$relay_file" "### Turn 1 — agent1 —"
expect_file_contains "seeds the requested subject" "$relay_file" "subject line here"

poll_out="$("$REPO/relay-automation/poll.sh" --mode relay --agent agent2 \
  --relay-file "$relay_file" --turn-source file --dry-run 2>&1)"
expect_contains "existing file-driven poller accepts agent IDs" "$poll_out" "DECISION: run-runner"

# Join is read-only and validates both membership and the subject embedded in the invitation.
before_join="$(fingerprint "$relay_file")"
join_out="$(python3 "$CLI" --root "$ROOT" join --id 123456 --agent 2 \
  --expect-subject "subject line here" 2>&1)"
join_rc=$?
after_join="$(fingerprint "$relay_file")"
[ "$join_rc" -eq 0 ] && pass "joins an existing discussion by ID" || fail "join exits $join_rc: $join_out"
expect_contains "join reports turn ownership" "$join_out" "DECISION: take-turn"
[ "$before_join" = "$after_join" ] && pass "join leaves the discussion byte-identical" || fail "join mutated the discussion"
before_watch="$(fingerprint "$relay_file")"
watch_now="$(python3 "$CLI" --root "$ROOT" watch --id 123456 --agent 2 \
  --interval 0.05 --timeout 1 2>&1)"
watch_now_rc=$?
[ "$watch_now_rc" -eq 0 ] && pass "watch returns when the participant owns NEXT" \
  || fail "watch exits $watch_now_rc: $watch_now"
expect_contains "watch reports turn ownership" "$watch_now" "DECISION: take-turn"
# GH-510 doorbell: take-turn must hand the waking session its exact relaunch command.
# `--root` is a global argparse option, so it must precede `watch`; execute the rendered command
# verbatim to prove both its ordering and the shell quoting for a root containing spaces.
expect_contains "take-turn watch prints a REARM line" "$watch_now" "REARM: "
rearm_line="$(printf '%s\n' "$watch_now" | grep '^REARM: ' | head -1)"
case "$rearm_line" in
  *" --root "*" watch --id 123456 --agent 2 "*) pass "REARM argv is self-contained" ;;
  *) fail "REARM argv incomplete: $rearm_line" ;;
esac
rearm_out="$(sh -c "${rearm_line#REARM: }" 2>&1)"
rearm_rc=$?
[ "$rearm_rc" -eq 0 ] && expect_contains "REARM command runs verbatim" "$rearm_out" "DECISION: take-turn" \
  || fail "REARM command exits $rearm_rc: $rearm_out"
[ "$before_watch" = "$(fingerprint "$relay_file")" ] \
  && pass "watch leaves the discussion byte-identical" || fail "watch mutated the discussion"
agent2_sidecar="$relay_file.watch.agent2"
before_status_sidecar="$(fingerprint "$agent2_sidecar")"
before_status_sidecar_mtime="$(mtime_ns "$agent2_sidecar")"
observed_status="$(python3 "$CLI" --root "$ROOT" status --id 123456 2>&1)"
expect_contains "status reports an observed armed doorbell" "$observed_status" "DOORBELL agent2: armed"
[ "$before_status_sidecar" = "$(fingerprint "$agent2_sidecar")" ] \
  && pass "status leaves an observed sidecar byte-identical" || fail "status mutated a sidecar"
[ "$before_status_sidecar_mtime" = "$(mtime_ns "$agent2_sidecar")" ] \
  && pass "status does not refresh an observed sidecar's liveness timestamp" \
  || fail "status refreshed an observed sidecar"
python3 -c 'import os, sys; os.utime(sys.argv[1], (0, 0))' "$agent2_sidecar"
stale_status="$(python3 "$CLI" --root "$ROOT" status --id 123456 2>&1)"
expect_contains "status reports a stale doorbell explicitly" "$stale_status" \
  "DOORBELL agent2: armed"
expect_contains "stale status remains advisory" "$stale_status" "STALE, that seat may no longer be listening"
python3 "$CLI" --root "$ROOT" join --id 123456 --agent 5 >/dev/null 2>&1 \
  && fail "rejects an agent outside the roster" || pass "rejects an agent outside the roster"
python3 "$CLI" --root "$ROOT" join --id 123456 --agent 2 --expect-subject "wrong subject" >/dev/null 2>&1 \
  && fail "rejects a mismatched invitation subject" || pass "rejects a mismatched invitation subject"

# Out-of-turn and invalid routing attempts must fail before the atomic write.
before_refusal="$(fingerprint "$relay_file")"
python3 "$CLI" --root "$ROOT" send --id 123456 --agent 3 --next-agent 4 \
  --message "early write" >/dev/null 2>&1 \
  && fail "rejects an out-of-turn writer" || pass "rejects an out-of-turn writer"
[ "$before_refusal" = "$(fingerprint "$relay_file")" ] \
  && pass "out-of-turn refusal is byte-preserving" || fail "out-of-turn refusal mutated the file"
python3 "$CLI" --root "$ROOT" send --id 123456 --agent 2 --next-agent 5 \
  --message "bad route" >/dev/null 2>&1 \
  && fail "rejects routing outside the roster" || pass "rejects routing outside the roster"
[ "$before_refusal" = "$(fingerprint "$relay_file")" ] \
  && pass "invalid route refusal is byte-preserving" || fail "invalid route mutated the file"

# A live writer lock fails closed. Callers must re-read ownership before retrying.
# GH-38: the lock is held by flock, so a merely-EXISTING lock file is not a lock — this holds a real
# one from a background process, which is the only thing that can now refuse a writer.
before_lock="$(fingerprint "$relay_file")"
lock_dir="$(dirname "$relay_file")"; lock_base="$(basename "$relay_file")"
python3 - "$lock_dir/.$lock_base.lock" <<'PYEOF' &
import fcntl, sys, time
fh = open(sys.argv[1], "a+")
fcntl.flock(fh.fileno(), fcntl.LOCK_EX)
fh.seek(0); fh.truncate(); fh.write("pid=%d held-since=test\n" % __import__("os").getpid()); fh.flush()
print("HELD", flush=True)
time.sleep(30)
PYEOF
LOCK_HOLDER=$!
# Wait for the holder to actually own the flock before contending (no fixed sleep).
for _ in $(seq 1 100); do
  grep -q "held-since" "$lock_dir/.$lock_base.lock" 2>/dev/null && break
  sleep 0.1
done
lock_out="$(python3 "$CLI" --root "$ROOT" send --id 123456 --agent 2 --next-agent 3 \
  --message "contended write" 2>&1)"
lock_rc=$?
kill "$LOCK_HOLDER" 2>/dev/null; wait "$LOCK_HOLDER" 2>/dev/null
[ "$lock_rc" -ne 0 ] && pass "rejects a write while the discussion lock is held" \
  || fail "lock-held write unexpectedly succeeded"
expect_contains "lock refusal is explicit" "$lock_out" "discussion is locked by another writer"
[ "$before_lock" = "$(fingerprint "$relay_file")" ] \
  && pass "lock refusal is byte-preserving" || fail "lock refusal mutated the discussion"

# Any current participant may route to any other roster member, including agent3 and agent4.
watch_later_file="$WORK/watch-later.out"
python3 "$CLI" --root "$ROOT" watch --id 123456 --agent 3 \
  --interval 0.05 --timeout 2 >"$watch_later_file" 2>&1 &
watch_later_pid=$!
sleep 0.1
send2_out="$(python3 "$CLI" --root "$ROOT" send --id 123456 --agent 2 --next-agent 3 \
  --message "Agent two response." 2>&1)"
send2_rc=$?
[ "$send2_rc" -eq 0 ] && pass "agent2 routes turn 2 to agent3" || fail "agent2 send exits $send2_rc: $send2_out"
wait "$watch_later_pid"
watch_later_rc=$?
[ "$watch_later_rc" -eq 0 ] && grep -Fq "DECISION: take-turn" "$watch_later_file" \
  && pass "watch detects a delayed turn arrival" || fail "delayed watch did not wake for agent3"
expect_contains "prints an agent3 handoff invitation" "$send2_out" \
  'Join XYZ agent2agent #123456 as agent number three to discuss: "subject line here"'
join3="$(python3 "$CLI" --root "$ROOT" join --id 123456 --agent 3 2>&1)"
expect_contains "agent3 can take its routed turn" "$join3" "DECISION: take-turn"
send3_out="$(printf '%s\n' 'Multiline agent three response.' 'Second line.' | \
  python3 "$CLI" --root "$ROOT" send --id 123456 --agent 3 --next-agent 4 --message-file - 2>&1)"
send3_rc=$?
[ "$send3_rc" -eq 0 ] && pass "agent3 routes stdin content to agent4" || fail "agent3 send exits $send3_rc: $send3_out"
expect_contains "prints an agent4 handoff invitation" "$send3_out" \
  'Join XYZ agent2agent #123456 as agent number four to discuss: "subject line here"'
expect_file_contains "preserves multiline turn content" "$relay_file" "Second line."

# Close is terminal and every later write is refused without a byte change.
close_out="$(python3 "$CLI" --root "$ROOT" close --id 123456 --agent 4 \
  --message "Agent four closes with consensus." 2>&1)"
close_rc=$?
[ "$close_rc" -eq 0 ] && pass "current participant closes the discussion" || fail "close exits $close_rc: $close_out"
expect_file_contains "marks terminal status" "$relay_file" "STATUS: Closed"
expect_file_contains "clears the next writer" "$relay_file" "NEXT: none"
closed_join="$(python3 "$CLI" --root "$ROOT" join --id 123456 --agent 1 2>&1)"
expect_contains "join reports terminal state" "$closed_join" "DECISION: closed"
before_closed_watch="$(fingerprint "$relay_file")"
closed_watch="$(python3 "$CLI" --root "$ROOT" watch --id 123456 --agent 1 \
  --interval 0.05 --timeout 1 2>&1)"
closed_watch_rc=$?
[ "$closed_watch_rc" -eq 0 ] && pass "watch exits cleanly on a closed discussion" \
  || fail "closed watch exits $closed_watch_rc: $closed_watch"
expect_contains "closed watch reports terminal state" "$closed_watch" "DECISION: closed"
# A closed discussion must never invite a re-arm — a REARM line here is the reflex-re-arm bug.
case "$closed_watch" in
  *"REARM: "*) fail "closed watch printed a REARM line: $closed_watch" ;;
  *) pass "closed watch prints no REARM line" ;;
esac
[ "$before_closed_watch" = "$(fingerprint "$relay_file")" ] \
  && pass "closed watch remains byte-preserving" || fail "closed watch mutated the discussion"
before_closed_send="$(fingerprint "$relay_file")"
python3 "$CLI" --root "$ROOT" send --id 123456 --agent 1 --next-agent 2 \
  --message "too late" >/dev/null 2>&1 \
  && fail "rejects post-close writes" || pass "rejects post-close writes"
[ "$before_closed_send" = "$(fingerprint "$relay_file")" ] \
  && pass "post-close refusal is byte-preserving" || fail "post-close refusal mutated the file"

# Deterministic candidate injection proves collision retry without weakening production randomness.
COLLISION_ROOT="$WORK/collision"
mkdir -p "$COLLISION_ROOT"
python3 "$CLI" --root "$COLLISION_ROOT" start --id 223344 --subject "first" >/dev/null 2>&1
collision_out="$(AGENT2AGENT_ID_SEQUENCE=223344,334455 python3 "$CLI" --root "$COLLISION_ROOT" \
  start --subject "second" 2>&1)"
collision_rc=$?
[ "$collision_rc" -eq 0 ] && pass "retries after a six-digit ID collision" || fail "collision retry exits $collision_rc: $collision_out"
expect_contains "selects the next unused deterministic ID" "$collision_out" "#334455"
python3 "$CLI" --root "$COLLISION_ROOT" start --id 223344 --subject "duplicate" >/dev/null 2>&1 \
  && fail "explicit duplicate ID fails loudly" || pass "explicit duplicate ID fails loudly"

# Discovery distinguishes missing from ambiguous IDs.
python3 "$CLI" --root "$ROOT" join --id 999999 --agent 1 >/dev/null 2>&1 \
  && fail "missing discussion ID fails" || pass "missing discussion ID fails"
AMBIG="$WORK/ambiguous"
mkdir -p "$AMBIG/relay-system/2026-08-10" "$AMBIG/relay-system/2026-08-11"
python3 "$CLI" --root "$AMBIG" start --id 445566 --subject "ambiguous" >/dev/null 2>&1
ambig_source="$(find "$AMBIG/relay-system" -type f -name '445566-*.md' -print)"
cp "$ambig_source" "$AMBIG/relay-system/2026-08-10/445566-agent2agent-duplicate.md"
ambig_out="$(python3 "$CLI" --root "$AMBIG" join --id 445566 --agent 2 2>&1)"
ambig_rc=$?
[ "$ambig_rc" -ne 0 ] && pass "ambiguous discussion ID fails" || fail "ambiguous ID unexpectedly joined"
expect_contains "ambiguous failure is explicit" "$ambig_out" "is ambiguous"

# Watch never dispatches commands. Drive is explicit, bounded, and delegates the guarded write to
# the turn command, which must advance through the same send/close helper.
DRIVE_ROOT="$WORK/drive"
mkdir -p "$DRIVE_ROOT"
python3 "$CLI" --root "$DRIVE_ROOT" start --id 556677 --subject "hands free" --agents 4 >/dev/null 2>&1
drive_file="$(find "$DRIVE_ROOT/relay-system" -type f -name '556677-*.md' -print)"
before_drive_wait="$(fingerprint "$drive_file")"
drive_wait="$(python3 "$CLI" --root "$DRIVE_ROOT" drive --id 556677 --agent 3 \
  --interval 0.05 --timeout 0.15 --max-turns 1 -- /usr/bin/true 2>&1)"
drive_wait_rc=$?
[ "$drive_wait_rc" -eq 3 ] && pass "drive times out without dispatching out of turn" \
  || fail "out-of-turn drive exits $drive_wait_rc: $drive_wait"
[ "$before_drive_wait" = "$(fingerprint "$drive_file")" ] \
  && pass "out-of-turn drive is byte-preserving" || fail "out-of-turn drive mutated the discussion"

before_drive_failure="$(fingerprint "$drive_file")"
drive_failure="$(python3 "$CLI" --root "$DRIVE_ROOT" drive --id 556677 --agent 2 \
  --interval 0.05 --timeout 1 --max-turns 1 -- /usr/bin/false 2>&1)"
drive_failure_rc=$?
[ "$drive_failure_rc" -eq 2 ] && pass "drive reports a failing turn command" \
  || fail "failing command exits $drive_failure_rc: $drive_failure"
expect_contains "drive failure names the command exit" "$drive_failure" "turn command failed with exit 1"
[ "$before_drive_failure" = "$(fingerprint "$drive_file")" ] \
  && pass "failed turn command leaves the discussion byte-identical" || fail "failed command mutated the discussion"

before_drive_timeout="$(fingerprint "$drive_file")"
drive_timeout="$(python3 "$CLI" --root "$DRIVE_ROOT" drive --id 556677 --agent 2 \
  --interval 0.05 --timeout 0.15 --max-turns 1 -- /bin/sleep 5 2>&1)"
drive_timeout_rc=$?
[ "$drive_timeout_rc" -eq 2 ] && pass "drive bounds a turn command by its total deadline" \
  || fail "timed-out command exits $drive_timeout_rc: $drive_timeout"
expect_contains "command timeout is explicit" "$drive_timeout" "turn command timed out after"
[ "$before_drive_timeout" = "$(fingerprint "$drive_file")" ] \
  && pass "timed-out command leaves the discussion byte-identical" || fail "timed-out command mutated the discussion"

first_drive_out="$WORK/first-drive.out"
python3 "$CLI" --root "$DRIVE_ROOT" drive --id 556677 --agent 1 \
  --interval 0.05 --timeout 2 --max-turns 1 -- /usr/bin/true >"$first_drive_out" 2>&1 &
first_drive_pid=$!
sleep 0.1
contended="$(python3 "$CLI" --root "$DRIVE_ROOT" drive --id 556677 --agent 1 \
  --interval 0.05 --timeout 1 --max-turns 1 -- /usr/bin/true 2>&1)"
contended_rc=$?
kill "$first_drive_pid" 2>/dev/null || true
wait "$first_drive_pid" 2>/dev/null || true
[ "$contended_rc" -eq 2 ] && pass "second drive for the same participant is refused" \
  || fail "contended drive exits $contended_rc: $contended"
expect_contains "drive contention is explicit" "$contended" "drive is already active for this participant"

TURN_COMMAND="$WORK/agent-turn.sh"
cat >"$TURN_COMMAND" <<'TURN'
#!/usr/bin/env bash
set -eu
prompt="$(cat)"
printf '%s\n' "$prompt" >"$AGENT2AGENT_PROMPT_CAPTURE"
python3 "$AGENT2AGENT_CLI" --root "$AGENT2AGENT_ROOT" send \
  --id "$AGENT2AGENT_ID" --agent "$AGENT2AGENT_AGENT" --next-agent 3 \
  --message "Driven response from $AGENT2AGENT_MEMBER."
TURN
chmod +x "$TURN_COMMAND"
PROMPT_CAPTURE="$WORK/drive-prompt.txt"
drive_success="$(AGENT2AGENT_CLI="$CLI" AGENT2AGENT_PROMPT_CAPTURE="$PROMPT_CAPTURE" \
  python3 "$CLI" --root "$DRIVE_ROOT" drive --id 556677 --agent 2 \
  --interval 0.05 --timeout 2 --max-turns 1 -- "$TURN_COMMAND" 2>&1)"
drive_success_rc=$?
[ "$drive_success_rc" -eq 0 ] && pass "drive dispatches the owned turn command" \
  || fail "successful drive exits $drive_success_rc: $drive_success"
expect_contains "drive stops at its explicit turn bound" "$drive_success" "DECISION: max-turns"
expect_file_contains "drive supplies the compact invitation prompt" "$PROMPT_CAPTURE" \
  'Join XYZ agent2agent #556677 as agent number two to discuss: "hands free"'
expect_file_contains "drive command advances through guarded send" "$drive_file" "NEXT: agent3"
expect_file_contains "drive preserves 3+ participant routing" "$drive_file" "Driven response from agent2."

before_no_advance="$(fingerprint "$drive_file")"
no_advance="$(python3 "$CLI" --root "$DRIVE_ROOT" drive --id 556677 --agent 3 \
  --interval 0.05 --timeout 1 --max-turns 1 -- /usr/bin/true 2>&1)"
no_advance_rc=$?
[ "$no_advance_rc" -eq 2 ] && pass "drive rejects a command that does not hand off" \
  || fail "non-advancing command exits $no_advance_rc: $no_advance"
expect_contains "non-advance failure is explicit" "$no_advance" "without advancing and handing off"
[ "$before_no_advance" = "$(fingerprint "$drive_file")" ] \
  && pass "drive itself never bypasses send enforcement" || fail "drive wrote around send enforcement"

python3 "$CLI" --root "$DRIVE_ROOT" close --id 556677 --agent 3 \
  --message "Close before another driver can dispatch." >/dev/null 2>&1
closed_drive="$(python3 "$CLI" --root "$DRIVE_ROOT" drive --id 556677 --agent 1 \
  --interval 0.05 --timeout 1 --max-turns 1 -- /usr/bin/false 2>&1)"
closed_drive_rc=$?
[ "$closed_drive_rc" -eq 0 ] && pass "drive exits cleanly when the discussion is closed" \
  || fail "closed drive exits $closed_drive_rc: $closed_drive"
expect_contains "closed drive does not dispatch its failing command" "$closed_drive" "DECISION: closed"

interrupt_out="$(python3 - "$CLI" "$DRIVE_ROOT" <<'PY' 2>&1
import importlib.util
import sys

spec = importlib.util.spec_from_file_location("agent2agent_under_test", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
module.watch_discussion = lambda *args, **kwargs: (_ for _ in ()).throw(KeyboardInterrupt())
raise SystemExit(module.main(["--root", sys.argv[2], "watch", "--id", "556677", "--agent", "1"]))
PY
)"
interrupt_rc=$?
[ "$interrupt_rc" -eq 130 ] && pass "interrupt exits with the conventional 130 status" \
  || fail "interrupt exits $interrupt_rc: $interrupt_out"
expect_contains "interrupt is reported visibly" "$interrupt_out" "agent2agent: interrupted"

# ── GH-38: doorbell hardening — re-arm reliability and crash durability ─────────────────────────
# Each item below has its own negative control: the defect is REPRODUCED (a killed sender, a
# stripped exec bit, an expiring window) and the guard asserted against that reproduction, not
# against a happy path that was already green.
echo "  -- GH-38 doorbell hardening"
G38="$WORK/gh38 root"
mkdir -p "$G38"
a2a_start() { python3 "$CLI" --root "$G38" start "$@"; }
# Every post-start verb needs --id; fold it in so no call site can forget it.
a2a() { _v="$1"; shift; python3 "$CLI" --root "$G38" "$_v" --id "$G38_ID" "$@"; }
# Park NEXT on a named seat regardless of where the previous probe left it. Without this the
# probes below are order-dependent: the concurrency test hands the turn to whichever seat won,
# so a later `watch` expecting take-turn intermittently timed out instead (observed flaky, 2/3
# runs). Each probe declares the turn state it needs rather than inheriting one.
route_to() {
  _want="$1"
  _owner="$(sed -n 's/^NEXT: agent//p' "$G38_FILE" | head -1)"
  [ "$_owner" = "$_want" ] && return 0
  a2a send --agent "$_owner" --next-agent "$_want" --message "route turn to agent$_want" >/dev/null 2>&1
}
start_out="$(a2a_start --subject "gh38 hardening" --agents 2 2>&1)"
G38_ID="$(printf '%s\n' "$start_out" | grep -oE '#[0-9]{6}' | head -1 | tr -d '#')"
G38_FILE="$(find "$G38/relay-system" -name "$G38_ID-agent2agent-*.md" | head -1)"
[ -n "$G38_ID" ] && [ -f "$G38_FILE" ] && pass "GH-38 fixture discussion created" \
  || fail "GH-38 fixture: id='$G38_ID' file='$G38_FILE'"

# ── item 1: a crashed sender must not brick the discussion forever ──────────────────────────────
# The lock is held by flock (agy QA r1 rejected the original pid-liveness/steal design: os.kill sees
# only the local process table, and steal-then-claim raced — two contenders could both unlink and
# both create, the second unlink deleting the first's fresh lock). So the reproduction is the real
# crash state: a lock FILE left behind by a process that no longer exists, with no flock held.
G38_LOCK="$(dirname "$G38_FILE")/.$(basename "$G38_FILE").lock"
DEAD_PID=999999
while kill -0 "$DEAD_PID" 2>/dev/null; do DEAD_PID=$((DEAD_PID - 1)); done
printf 'pid=%s held-since=2020-01-01T00:00:00+00:00\n' "$DEAD_PID" > "$G38_LOCK"
steal_out="$(a2a send --agent 2 --next-agent 1 --message "after a crashed sender" 2>&1)"
steal_rc=$?
[ "$steal_rc" -eq 0 ] && pass "a send after a crashed sender SUCCEEDS (the OS released the flock)" \
  || fail "a crashed sender still bricks the discussion: rc=$steal_rc $steal_out"
# No steal announcement should exist: with flock there is nothing to steal, which is the point.
case "$steal_out" in
  *STALE-LOCK*) fail "a steal was announced — the pid-liveness design should be gone" ;;
  *) pass "no lock is stolen or guessed at (flock made liveness the kernel's problem)" ;;
esac

# The other half: a genuinely HELD flock refuses, and the refusal names the holder.
python3 - "$G38_LOCK" <<'PYEOF' &
import fcntl, os, sys, time
fh = open(sys.argv[1], "a+")
fcntl.flock(fh.fileno(), fcntl.LOCK_EX)
fh.seek(0); fh.truncate(); fh.write("pid=%d held-since=live\n" % os.getpid()); fh.flush()
time.sleep(30)
PYEOF
LIVE_PID=$!
for _ in $(seq 1 100); do grep -q "held-since=live" "$G38_LOCK" 2>/dev/null && break; sleep 0.1; done
HELD_PID="$(sed -n 's/^pid=\([0-9]*\).*/\1/p' "$G38_LOCK" | head -1)"
live_out="$(a2a send --agent 1 --next-agent 2 --message "should refuse" 2>&1)"
live_rc=$?
[ "$live_rc" -ne 0 ] && pass "a genuinely held flock refuses the writer" \
  || fail "a held lock was bypassed: $live_out"
expect_contains "the refusal names the holding pid" "$live_out" "held by pid $HELD_PID"
kill "$LIVE_PID" 2>/dev/null; wait "$LIVE_PID" 2>/dev/null
# After the holder dies the lock needs NO cleanup — that is the whole benefit over the pid design.
recover_out="$(a2a send --agent 1 --next-agent 2 --message "after the holder died" 2>&1)"
[ $? -eq 0 ] && pass "the next writer proceeds with no cleanup once the holder exits" \
  || fail "lock needed manual cleanup: $recover_out"
# Route the turn to agent2 so the watch probes below exercise take-turn rather than a wait.
a2a send --agent 1 --next-agent 2 --message "route to agent2 for the watch probes" >/dev/null 2>&1

# The r1 race directly: many contenders start at once against a LEFTOVER lock file from a crashed
# sender. Under the rejected steal design two could both unlink and both create — the second unlink
# deleting the first's fresh lock — so both would proceed and tear the write. Under flock the kernel
# admits exactly one at a time, so the file stays structurally intact and the turn counter agrees
# with the number of turns actually recorded.
printf 'pid=%s held-since=2020-01-01T00:00:00+00:00\n' "$DEAD_PID" > "$G38_LOCK"
race_before="$(grep -c '^### Turn ' "$G38_FILE")"
# Every racer sends as the seat that ACTUALLY owns NEXT, or they are all refused on turn ownership
# and the lock is never contended at all — which is how the first draft of this test passed while
# proving nothing.
race_owner="$(sed -n 's/^NEXT: agent//p' "$G38_FILE" | head -1)"
race_peer=$([ "$race_owner" = "1" ] && echo 2 || echo 1)
RACE_RC="$WORK/race-rcs"; rm -rf "$RACE_RC"; mkdir -p "$RACE_RC"
for i in 1 2 3 4 5 6; do
  ( a2a send --agent "$race_owner" --next-agent "$race_peer" --message "racer $i" >/dev/null 2>&1
    echo $? > "$RACE_RC/$i" ) &
done
wait
RACE_WINNERS="$(cat "$RACE_RC"/* 2>/dev/null | grep -c '^0$')"
race_after="$(grep -c '^### Turn ' "$G38_FILE")"
race_hdr="$(grep -c '^TURN: ' "$G38_FILE")"
race_next="$(grep -c '^NEXT: ' "$G38_FILE")"
race_turn_field="$(sed -n 's/^TURN: //p' "$G38_FILE" | head -1)"
if [ "$race_hdr" -eq 1 ] && [ "$race_next" -eq 1 ] && [ "$race_turn_field" = "$race_after" ]; then
  pass "6 concurrent writers over a crashed sender's lock leave the file structurally intact (TURN=$race_turn_field matches $race_after recorded turns)"
else
  fail "concurrent writers corrupted the discussion: TURN:x$race_hdr NEXT:x$race_next field=$race_turn_field blocks=$race_after"
fi
# THE discriminating assertion (agy QA r2 [Blocker]): structural intactness alone is VACUOUS — it
# passes with the lock removed entirely. `atomic_write` uses os.replace, so six unserialized racers
# each read the same state, each build the same valid next state, and each cleanly overwrite the
# file; the result is a structurally perfect ledger with one turn recorded, and every earlier
# assertion here passes. agy proved this by disabling the lock and watching the test stay green.
# Exit codes are what distinguishes serialized from merely atomic: under flock exactly ONE racer
# can hold the turn, so one exits 0 and the rest are refused out-of-turn. Unserialized, all six
# validate NEXT against the same pre-write state and all exit 0.
[ "$RACE_WINNERS" = "1" ] \
  && pass "exactly ONE of 6 concurrent racers committed (flock serialized them; the rest were refused out-of-turn)" \
  || fail "$RACE_WINNERS of 6 racers exited 0 — expected exactly 1; the lock did not serialize them"
[ "$race_after" -gt "$race_before" ] && pass "the winning racer's turn was actually committed" \
  || fail "no racer committed a turn (before=$race_before after=$race_after)"

# ── item 2: REARM names the interpreter, so a mode-stripped copy still re-arms ───────────────────
route_to 2
rearm_now="$(a2a watch --agent 2 --interval 0.05 --timeout 1 2>&1)"
rearm_cmd="$(printf '%s\n' "$rearm_now" | grep '^REARM: ' | head -1 | sed 's/^REARM: //')"
case "$rearm_cmd" in
  *python*) pass "REARM names the interpreter explicitly (not a bare script path)" ;;
  *) fail "REARM does not name an interpreter: $rearm_cmd" ;;
esac
case "$rearm_cmd" in
  *"/-c"*) fail "REARM rendered a bogus argv[0] path: $rearm_cmd" ;;
  *) pass "REARM renders the real script path, not the invoking argv[0]" ;;
esac
# The negative control for the exec bit: strip it from a COPY and prove the rendered command still
# runs. Pre-fix this produced a 127/permission error.
G38_COPY="$WORK/copy-no-exec-bit.py"
cp "$CLI" "$G38_COPY"; chmod -x "$G38_COPY"
copy_rearm="$(python3 "$G38_COPY" --root "$G38" watch --id "$G38_ID" --agent 2 --interval 0.05 --timeout 1 2>&1 \
  | grep '^REARM: ' | head -1 | sed 's/^REARM: //')"
copy_out="$(sh -c "$copy_rearm" 2>&1)"; copy_rc=$?
[ "$copy_rc" -eq 0 ] && expect_contains "a mode-stripped copy still re-arms verbatim" "$copy_out" "DECISION: take-turn" \
  || fail "mode-stripped copy re-arm exits $copy_rc: $copy_out"

# ── item 4: the rendered interval/timeout must ROUND-TRIP, not merely be present ─────────────────
route_to 2
rt="$(a2a watch --agent 2 --interval 7 --timeout 991 2>&1 | grep '^REARM: ' | head -1)"
expect_contains "REARM round-trips the interval value" "$rt" "--interval 7"
expect_contains "REARM round-trips the timeout value" "$rt" "--timeout 991"
rt_cmd="$(printf '%s\n' "$rt" | sed 's/^REARM: //')"
case "$rt_cmd" in
  *"--interval 0.05"*|*"--timeout 1"*) fail "REARM leaked values from an earlier watch: $rt_cmd" ;;
  *) pass "REARM carries THIS watch's values, not a default or a stale one" ;;
esac

# ── item 3: an expiring window offers a deliberate re-arm instead of dying silently ──────────────
route_to 1   # the turn must be held ELSEWHERE for agent2's watch to genuinely time out
to_out="$(a2a watch --agent 2 --interval 0.05 --timeout 0.2 2>&1)"; to_rc=$?
[ "$to_rc" -eq 3 ] && pass "a timed-out watch still exits 3 (the documented status is unchanged)" \
  || fail "timeout exit changed: rc=$to_rc"
expect_contains "a timed-out watch names the wait explicitly" "$to_out" "STILL-WAITING:"
case "$to_out" in
  *"REARM: "*) fail "timeout printed REARM — re-arm by reflex is exactly what must not happen" ;;
  *) pass "timeout does NOT print REARM (the non-reflex contract holds)" ;;
esac
to_cmd="$(printf '%s\n' "$to_out" | grep -A1 'STILL-WAITING:' | tail -1 | sed 's/^ *//')"
to_run="$(sh -c "$to_cmd" 2>&1)"; to_run_rc=$?
[ "$to_run_rc" -eq 3 ] || [ "$to_run_rc" -eq 0 ] \
  && pass "the offered still-waiting command is executable verbatim" \
  || fail "still-waiting command exits $to_run_rc: $to_run"

# ── item 6: doorbell liveness is visible to the other seat, WITHOUT touching the relay file ──────
route_to 1
before_sidecar="$(fingerprint "$G38_FILE")"
a2a watch --agent 1 --interval 0.05 --timeout 0.2 >/dev/null 2>&1
[ -f "$G38_FILE.watch.agent1" ] && pass "watch records its liveness in a per-agent sidecar" \
  || fail "no watch sidecar written"
[ "$before_sidecar" = "$(fingerprint "$G38_FILE")" ] \
  && pass "the sidecar leaves the relay file byte-identical (the watch contract is intact)" \
  || fail "the liveness marker mutated the discussion"
peer_out="$(a2a join --agent 2 2>&1)"
expect_contains "the other seat sees the peer's doorbell age" "$peer_out" "peer doorbell (agent1): armed"

# agy QA r1 [Blocker]: stamping the sidecar ONCE before the poll loop made any seat waiting longer
# than 2x its interval read as STALE while it was polling perfectly normally — worst for exactly the
# long patient waits the doorbell exists to support. The marker must refresh on EVERY poll.
# Reproduction: a watch that waits well past 2x its interval, then check the marker is fresh.
route_to 2   # agent1 must NOT own the turn, or its watch returns take-turn instead of waiting
# The wait must be long enough that a once-only stamp is UNAMBIGUOUSLY stale: with a 3s wait, a
# non-refreshing marker ages ~3s while a refreshing one ages ~0s. A shorter window made this
# assertion vacuous (1.2s truncates to 1, passing a `<= 1` check either way) — caught by reverting
# the heartbeat and seeing the suite stay green.
a2a watch --agent 1 --interval 0.1 --timeout 3 >/dev/null 2>&1      # waits ~30 intervals
SIDECAR_AGE="$(python3 -c "import os,sys,time; print(int(time.time()-os.stat(sys.argv[1]).st_mtime))" "$G38_FILE.watch.agent1" 2>/dev/null)"
[ -n "$SIDECAR_AGE" ] && [ "$SIDECAR_AGE" -le 1 ] 2>/dev/null \
  && pass "the doorbell marker refreshes on every poll (a long wait is not reported STALE)" \
  || fail "sidecar went stale during an active wait (age=${SIDECAR_AGE}s) — the r1 false positive"

# ── item 5: atomic_write persists the RENAME, not just the bytes ─────────────────────────────────
fsync_probe="$(python3 - "$CLI" "$G38_FILE" <<'PYEOF'
import importlib.util, sys, os
spec = importlib.util.spec_from_file_location("a2a", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
from pathlib import Path
calls = []
real = os.fsync
os.fsync = lambda fd: (calls.append(fd), real(fd))[1]
try:
    m.atomic_write(Path(sys.argv[2]), Path(sys.argv[2]).read_text(encoding="utf-8"))
finally:
    os.fsync = real
print("fsync_calls=%d" % len(calls))
PYEOF
)"
case "$fsync_probe" in
  fsync_calls=0|fsync_calls=1) fail "atomic_write fsyncs the file but not the directory: $fsync_probe" ;;
  *) pass "atomic_write fsyncs both the file and its parent directory (the rename survives power loss)" ;;
esac

# The installer is cross-agent and never writes to real user skill directories in this test.
CLAUDE_DIR="$WORK/claude-skills"
CODEX_DIR="$WORK/codex-skills"
install_out="$(CLAUDE_SKILLS_DIR="$CLAUDE_DIR" CODEX_SKILLS_DIR="$CODEX_DIR" \
  bash "$REPO/skills/agent2agent/install.sh" 2>&1)"
install_rc=$?
[ "$install_rc" -eq 0 ] && pass "installer completes for Claude and Codex" || fail "installer exits $install_rc: $install_out"
[ -L "$CLAUDE_DIR/agent2agent" ] && [ -L "$CODEX_DIR/agent2agent" ] \
  && pass "installer exposes the same skill to both agents" || fail "installer symlinks missing"

printf '  agent2agent: %s pass, %s fail\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
