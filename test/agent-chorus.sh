#!/usr/bin/env bash
# GH-497/GH-510/GH-144 — compact multi-party discussions with explicit watch/drive levels.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
CLI="$REPO/skills/agent-chorus/scripts/agent_chorus.py"
SKILL="$REPO/skills/agent-chorus/SKILL.md"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/agent-chorus-test.XXXXXX")" || {
  echo "FAIL: mktemp -d failed" >&2
  exit 1
}
[ -n "$WORK" ] && [ -d "$WORK" ] || {
  echo "FAIL: mktemp -d returned an invalid directory" >&2
  exit 1
}
case "$WORK" in
  "${TMPDIR:-/tmp}"/agent-chorus-test.*) ;;
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

echo "agent-chorus (GH-497/GH-510/GH-144):"
ROOT="$WORK/root with spaces"
mkdir -p "$ROOT"
STORE="$WORK/Agent2Agent-Transcripts"
export AGENT2AGENT_HOME="$STORE"
PACKET="$WORK/context-packet.md"
cat >"$PACKET" <<'PACKET'
## Goal
Exercise the canonical Agent2Agent protocol.
## Scope
The local test fixture is in scope; external systems are out of scope.
## Context and current state
The test creates a fresh discussion and advances serialized turns.
## Evidence and artifacts
The generated conversation and runtime files are the evidence.
## Constraints and safety boundaries
Only paths below the temporary test root may be changed.
## Questions for participants
Does each protocol operation preserve its stated invariants?
## Requested outcome / done condition
All assertions pass and the discussion closes cleanly.
PACKET

python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(), feature_version=(3, 8))' "$CLI" \
  && pass "helper parses with the repository's Python 3.8 floor" \
  || fail "helper uses syntax newer than Python 3.8"

grep -Fq -- '<this-skill>' "$SKILL" \
  && fail "skill retains a shell-significant path placeholder" \
  || pass "skill contains no shell-significant path placeholder"
# GH-231: commands resolve the helper from the skill's own directory via a quoted $AGENT_CHORUS,
# not from `git rev-parse --show-toplevel` (which fails outside an XYZ-forge clone). The Phase 2
# `start --supersedes`, `invite`, and `verify-citations` examples now follow the same rule.
helper_examples="$(grep -c '^"\$AGENT_CHORUS" ' "$SKILL")"
[ "$helper_examples" -eq 17 ] \
  && pass "all skill commands use the quoted skill-relative helper variable" \
  || fail "expected 17 \$AGENT_CHORUS helper commands, found $helper_examples"
grep -Fq -- '$(git rev-parse --show-toplevel)/skills/agent-chorus/scripts/agent_chorus.py' "$SKILL" \
  && pass "skill still documents the in-repo helper path for XYZ-forge clones" \
  || fail "skill lost the in-repo helper path note"
(cd "$REPO" && "$(git rev-parse --show-toplevel)/skills/agent-chorus/scripts/agent_chorus.py" --help >/dev/null) \
  && pass "documented root-resolved helper path executes" \
  || fail "documented root-resolved helper path does not execute"
expect_file_contains "skill documents stdin message streaming" "$SKILL" \
  "--message-file - < /safe/path/to/message.md"
expect_file_contains "skill documents safe lock-contention recovery" "$SKILL" \
  "discussion is locked by another writer"

# The start output is the copy/paste API. Turn 1 is durable before agent2 is invited.
start_out="$(AGENT2AGENT_ID_SEQUENCE=123456 python3 "$CLI" --root "$ROOT" start \
  --subject "subject line here" --packet-file "$PACKET" --agents 4 2>&1)"
start_rc=$?
[ "$start_rc" -eq 0 ] && pass "starts a four-agent discussion" || fail "start exits $start_rc: $start_out"
expected_invitation='Join XYZ AgentChorus #123456 as agent number two to discuss: "subject line here"'
expect_contains "preserves the exact agent2 compact invitation" "$start_out" "$expected_invitation"
expect_contains "prints an upfront agent3 invitation" "$start_out" \
  'Join XYZ AgentChorus #123456 as agent number three to discuss: "subject line here"'
expect_contains "prints an upfront agent4 invitation" "$start_out" \
  'Join XYZ AgentChorus #123456 as agent number four to discuss: "subject line here"'
[ "$(printf '%s\n' "$start_out" | grep -c '^Join XYZ AgentChorus')" -eq 3 ] \
  && pass "four-agent start prints exactly three non-initiator invitations" \
  || fail "four-agent start did not print exactly three invitations: $start_out"

relay_file="$(find "$STORE/repositories" -path '*/????-??-??/123456--*/conversation.md' -print)"
[ -f "$relay_file" ] && pass "creates an external canonical conversation for a spaced root" || fail "conversation missing"
case "$relay_file" in "$STORE"/repositories/*/????-??-??/123456--*/conversation.md) pass "uses the external session store" ;; *) fail "unexpected conversation path: $relay_file" ;; esac
expect_file_contains "records stable 4-agent roster" "$relay_file" "AGENTS: agent1 agent2 agent3 agent4"
expect_file_contains "routes the opening turn to agent2" "$relay_file" "NEXT: agent2"
expect_file_contains "defaults timed watch to disabled" "$relay_file" "TIMED-WATCH: disabled"

# GH-144: every non-initiator can onboard immediately. Off-turn joins and the operator status view
# are strictly read-only; neither is allowed to create a watch sidecar or mutate the conversation.
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
if grep -q . <<<"$(find "$status_dir/runtime" -maxdepth 1 -name '*.watch' -print 2>/dev/null)"; then
  fail "status created a doorbell sidecar"
else
  pass "status creates no doorbell sidecar"
fi

timed_start="$(python3 "$CLI" --root "$ROOT" start --id 654321 --subject "timed watch" \
  --packet-file "$PACKET" --timed-watch 2>&1)"
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
agent2_sidecar="$(dirname "$relay_file")/runtime/agent2.watch"
before_status_sidecar="$(fingerprint "$agent2_sidecar")"
before_status_sidecar_mtime="$(mtime_ns "$agent2_sidecar")"
observed_status="$(python3 "$CLI" --root "$ROOT" status --id 123456 2>&1)"
expect_contains "status reports the active owner's observed heartbeat" "$observed_status" \
  "DOORBELL agent2: ACTIVE — owns NEXT"
[ "$before_status_sidecar" = "$(fingerprint "$agent2_sidecar")" ] \
  && pass "status leaves an observed sidecar byte-identical" || fail "status mutated a sidecar"
[ "$before_status_sidecar_mtime" = "$(mtime_ns "$agent2_sidecar")" ] \
  && pass "status does not refresh an observed sidecar's liveness timestamp" \
  || fail "status refreshed an observed sidecar"
python3 -c 'import os, sys; os.utime(sys.argv[1], (0, 0))' "$agent2_sidecar"
stale_status="$(python3 "$CLI" --root "$ROOT" status --id 123456 2>&1)"
expect_contains "status still reports an aged active heartbeat" "$stale_status" \
  "DOORBELL agent2: ACTIVE — owns NEXT"
expect_contains "active owner is not falsely stale" "$stale_status" "ACTIVE — owns NEXT"
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
lock_dir="$(dirname "$relay_file")/runtime"; lock_file="$lock_dir/discussion.lock"
python3 - "$lock_file" <<'PYEOF' &
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
  grep -q "held-since" "$lock_file" 2>/dev/null && break
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
  'Join XYZ AgentChorus #123456 as agent number three to discuss: "subject line here"'
join3="$(python3 "$CLI" --root "$ROOT" join --id 123456 --agent 3 2>&1)"
expect_contains "agent3 can take its routed turn" "$join3" "DECISION: take-turn"
send3_out="$(printf '%s\n' 'Multiline agent three response.' 'Second line.' | \
  python3 "$CLI" --root "$ROOT" send --id 123456 --agent 3 --next-agent 4 --message-file - 2>&1)"
send3_rc=$?
[ "$send3_rc" -eq 0 ] && pass "agent3 routes stdin content to agent4" || fail "agent3 send exits $send3_rc: $send3_out"
expect_contains "prints an agent4 handoff invitation" "$send3_out" \
  'Join XYZ AgentChorus #123456 as agent number four to discuss: "subject line here"'
expect_file_contains "preserves multiline turn content" "$relay_file" "Second line."

# Close is terminal and every later write is refused without a byte change.
close_out="$(python3 "$CLI" --root "$ROOT" close --id 123456 --agent 4 \
  --trivial --message "Agent four closes with consensus." 2>&1)"
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
python3 "$CLI" --root "$COLLISION_ROOT" start --id 223344 --subject "first" \
  --packet-file "$PACKET" >/dev/null 2>&1
collision_out="$(AGENT2AGENT_ID_SEQUENCE=223344,334455 python3 "$CLI" --root "$COLLISION_ROOT" \
  start --subject "second" --packet-file "$PACKET" 2>&1)"
collision_rc=$?
[ "$collision_rc" -eq 0 ] && pass "retries after a six-digit ID collision" || fail "collision retry exits $collision_rc: $collision_out"
expect_contains "selects the next unused deterministic ID" "$collision_out" "#334455"
python3 "$CLI" --root "$COLLISION_ROOT" start --id 223344 --subject "duplicate" \
  --packet-file "$PACKET" >/dev/null 2>&1 \
  && fail "explicit duplicate ID fails loudly" || pass "explicit duplicate ID fails loudly"

# Discovery distinguishes missing from ambiguous IDs.
python3 "$CLI" --root "$ROOT" join --id 999999 --agent 1 >/dev/null 2>&1 \
  && fail "missing discussion ID fails" || pass "missing discussion ID fails"
AMBIG="$WORK/ambiguous"
mkdir -p "$AMBIG/relay-system/2026-08-10" "$AMBIG/relay-system/2026-08-11"
python3 "$CLI" --root "$AMBIG" start --id 445566 --subject "ambiguous" \
  --packet-file "$PACKET" >/dev/null 2>&1
ambig_source="$(find "$STORE/repositories" -path '*/????-??-??/445566--*/conversation.md' -print)"
cp "$ambig_source" "$AMBIG/relay-system/2026-08-10/445566-agent2agent-duplicate.md"
ambig_out="$(python3 "$CLI" --root "$AMBIG" join --id 445566 --agent 2 2>&1)"
ambig_rc=$?
[ "$ambig_rc" -ne 0 ] && pass "ambiguous discussion ID fails" || fail "ambiguous ID unexpectedly joined"
expect_contains "ambiguous failure is explicit" "$ambig_out" "is ambiguous"

# Watch never dispatches commands. Drive is explicit, bounded, and delegates the guarded write to
# the turn command, which must advance through the same send/close helper.
DRIVE_ROOT="$WORK/drive"
mkdir -p "$DRIVE_ROOT"
python3 "$CLI" --root "$DRIVE_ROOT" start --id 556677 --subject "hands free" \
  --packet-file "$PACKET" --agents 4 >/dev/null 2>&1
drive_file="$(find "$STORE/repositories" -path '*/????-??-??/556677--*/conversation.md' -print)"
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
  'Join XYZ AgentChorus #556677 as agent number two to discuss: "hands free"'
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
  --trivial --message "Close before another driver can dispatch." >/dev/null 2>&1
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
expect_contains "interrupt is reported visibly" "$interrupt_out" "agent-chorus: interrupted"

# ── GH-38: doorbell hardening — re-arm reliability and crash durability ─────────────────────────
# Each item below has its own negative control: the defect is REPRODUCED (a killed sender, a
# stripped exec bit, an expiring window) and the guard asserted against that reproduction, not
# against a happy path that was already green.
echo "  -- GH-38 doorbell hardening"
G38="$WORK/gh38 root"
mkdir -p "$G38"
a2a_start() { python3 "$CLI" --root "$G38" start --packet-file "$PACKET" "$@"; }
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
G38_FILE="$(find "$STORE/repositories" -path "*/????-??-??/$G38_ID--*/conversation.md" | head -1)"
[ -n "$G38_ID" ] && [ -f "$G38_FILE" ] && pass "GH-38 fixture discussion created" \
  || fail "GH-38 fixture: id='$G38_ID' file='$G38_FILE'"

# ── item 1: a crashed sender must not brick the discussion forever ──────────────────────────────
# The lock is held by flock (agy QA r1 rejected the original pid-liveness/steal design: os.kill sees
# only the local process table, and steal-then-claim raced — two contenders could both unlink and
# both create, the second unlink deleting the first's fresh lock). So the reproduction is the real
# crash state: a lock FILE left behind by a process that no longer exists, with no flock held.
G38_LOCK="$(dirname "$G38_FILE")/runtime/discussion.lock"
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
# GH-231 finding 6: the marker exists only while the watch process lives — it is removed on any
# exit so a dead doorbell can never read as armed. Observe it mid-watch, then confirm removal.
# agent2 does not own NEXT here, so its watch genuinely waits until the 1 s timeout.
a2a watch --agent 2 --interval 0.05 --timeout 1 >/dev/null 2>&1 &
G38_WATCH_PID=$!
# GH-345: this was a bare `sleep 0.3`, and mutation testing showed the assertion below was red at
# 0.2s and green at 0.3s on an IDLE 10-core box — under 1.5x headroom for a backgrounded python3 to
# start and stamp the marker. That is not a margin on a shared Linux runner under load, and it is
# the exact failure shape #123 exists to close. Poll for the marker instead, the same way the flock
# wait at :236 and the lock wait at :497 already do. Faster when the box is fast, patient when it
# is not.
G38_WATCH_SIDECAR="$(dirname "$G38_FILE")/runtime/agent2.watch"
for _ in $(seq 1 100); do [ -f "$G38_WATCH_SIDECAR" ] && break; sleep 0.02; done
[ -f "$G38_WATCH_SIDECAR" ] && pass "watch records its liveness in a per-agent sidecar while running" \
  || fail "no watch sidecar written"
wait "$G38_WATCH_PID" 2>/dev/null
[ ! -e "$(dirname "$G38_FILE")/runtime/agent2.watch" ] && pass "watch removes its liveness sidecar on exit" \
  || fail "watch left its sidecar behind after exiting"
[ "$before_sidecar" = "$(fingerprint "$G38_FILE")" ] \
  && pass "the sidecar leaves the relay file byte-identical (the watch contract is intact)" \
  || fail "the liveness marker mutated the discussion"
peer_out="$(a2a join --agent 2 2>&1)"
expect_contains "the other seat sees the active peer's heartbeat" "$peer_out" \
  "peer doorbell (agent1): ACTIVE — owns NEXT"

# agy QA r1 [Blocker]: stamping the sidecar ONCE before the poll loop made any seat waiting longer
# than 2x its interval read as STALE while it was polling perfectly normally — worst for exactly the
# long patient waits the doorbell exists to support. The marker must refresh on EVERY poll.
# Reproduction: a watch that waits well past 2x its interval, then check the marker is fresh.
route_to 2   # agent1 must NOT own the turn, or its watch returns take-turn instead of waiting
# The wait must be long enough that a once-only stamp is UNAMBIGUOUSLY stale: with a 3s wait, a
# non-refreshing marker ages ~3s while a refreshing one ages ~0s. A shorter window made this
# assertion vacuous (1.2s truncates to 1, passing a `<= 1` check either way) — caught by reverting
# the heartbeat and seeing the suite stay green.
a2a watch --agent 1 --interval 0.1 --timeout 3 >/dev/null 2>&1 &     # waits ~30 intervals
G38_LONG_WATCH_PID=$!
# GH-345: this one MUST stay a fixed sleep — it is a measurement window, not a wait-for-an-event.
# The assertion is that the marker stays FRESH across a long wait, and there is no condition to poll
# for ("still fresh" is the thing being measured). Mutation confirms it is not fragile: it survives
# being cut to 0.5. Do not "fix" it into a readiness poll the way :611 was fixed.
sleep 2.5   # measure while the watch is still polling (the marker is removed on exit, GH-231)
SIDECAR_AGE="$(python3 -c "import os,sys,time; print(int(time.time()-os.stat(sys.argv[1]).st_mtime))" "$(dirname "$G38_FILE")/runtime/agent1.watch" 2>/dev/null)"
wait "$G38_LONG_WATCH_PID" 2>/dev/null
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
  bash "$REPO/skills/agent-chorus/install.sh" 2>&1)"
install_rc=$?
[ "$install_rc" -eq 0 ] && pass "installer completes for Claude and Codex" || fail "installer exits $install_rc: $install_out"
[ -L "$CLAUDE_DIR/agent-chorus" ] && [ -L "$CODEX_DIR/agent-chorus" ] \
  && pass "installer exposes the same skill to both agents" || fail "installer symlinks missing"

# Legacy symlink migration (#193 Phase 0): a machine that installed the old agent2agent skill
# holds a symlink whose target dies with this rename. The installer must repoint it (old-name
# target), leave real directories alone, and drop links that dangle at something unrelated.
MIG_DIR="$WORK/legacy-skills"
mkdir -p "$MIG_DIR"
ln -s "$REPO/skills/agent2agent" "$MIG_DIR/agent2agent"   # the pre-rename install shape (now dangling)
mig_out="$(CLAUDE_SKILLS_DIR="$MIG_DIR" CODEX_SKILLS_DIR="$WORK/mig-codex" \
  bash "$REPO/skills/agent-chorus/install.sh" 2>&1)"
mig_target="$(readlink "$MIG_DIR/agent2agent" 2>/dev/null || true)"
[ "$mig_target" = "$REPO/skills/agent-chorus" ] \
  && pass "installer repoints the legacy agent2agent symlink at the renamed skill" \
  || fail "legacy symlink not repointed (now -> '$mig_target'): $mig_out"

MIG_DIR2="$WORK/legacy-realdir"
mkdir -p "$MIG_DIR2/agent2agent"
CLAUDE_SKILLS_DIR="$MIG_DIR2" CODEX_SKILLS_DIR="$WORK/mig2-codex" \
  bash "$REPO/skills/agent-chorus/install.sh" >/dev/null 2>&1
[ -d "$MIG_DIR2/agent2agent" ] && [ ! -L "$MIG_DIR2/agent2agent" ] \
  && pass "installer leaves a real agent2agent directory untouched" \
  || fail "installer touched a real (non-symlink) agent2agent directory"

# Deprecated agent2agent.py shim: warns and delegates to agent_chorus.py (Gen 2 Phase 0, #193)
shim_out="$(python3 "$(dirname "$CLI")/agent2agent.py" --help 2>&1)"; shim_rc=$?
case "$shim_out" in
  *"deprecated — use agent_chorus.py"*)
    [ "$shim_rc" -eq 0 ] && pass "deprecated agent2agent.py shim warns and delegates" || fail "shim exit $shim_rc" ;;
  *) fail "deprecated shim did not warn+delegate: $shim_out" ;;
esac

# ── Gen 2 Phase 1: telemetry sidecar + index + outcome + audit (#193) ──────────────
TS_STORE="$WORK/telemetry-store"; mkdir -p "$TS_STORE"
ts_cli() { python3 "$CLI" --store "$TS_STORE" "$@"; }
printf '## Goal\nT\n## Scope\nT\n## Context and current state\nT\n## Evidence and artifacts\nT\n## Constraints and safety boundaries\nT\n## Questions for participants\nT\n## Requested outcome / done condition\nT\n' > "$WORK/pkt.md"
ts_cli start --subject "telemetry suite probe" --packet-file "$WORK/pkt.md" --id 777001 >/dev/null 2>&1
TS_SIDECAR="$(find "$TS_STORE" -path "*777001*" -name telemetry.jsonl | head -1)"
[ -n "$TS_SIDECAR" ] && [ -s "$TS_SIDECAR" ] \
  && pass "telemetry sidecar written on start (pilot window default-ON)" || fail "no telemetry sidecar after start"
grep -q '"event": "discussion_started"' "$TS_SIDECAR" 2>/dev/null \
  && pass "discussion_started event present with schema version" || fail "discussion_started event missing"
# hard override: a fresh discussion with AGENT2AGENT_TELEMETRY=0 writes nothing
TS_STORE2="$WORK/telemetry-store-off"; mkdir -p "$TS_STORE2"
AGENT2AGENT_TELEMETRY=0 python3 "$CLI" --store "$TS_STORE2" start --subject "off probe" --packet-file "$WORK/pkt.md" --id 777002 >/dev/null 2>&1
[ -z "$(find "$TS_STORE2" -name telemetry.jsonl)" ] \
  && pass "AGENT2AGENT_TELEMETRY=0 hard override suppresses all telemetry" || fail "override failed: sidecar written while disabled"
# close with a falsifier + action; outcome with model attribution; aggregate; audit
ts_cli close --id 777001 --agent 2 --message "## Final Consensus & Recommendation
### Decision
Suite close.
### Key Invariants & Rationale
Allowlist.
### Recorded Dissent / Falsifiers
- one falsifier
### Recommended Next Actions
1. first action" >/dev/null 2>&1
grep -q '"event": "close_written"' "$TS_SIDECAR" && grep -q '"falsifier_count": 1' "$TS_SIDECAR" \
  && pass "close_written event carries counts (falsifier_count=1), never prose" || fail "close_written missing or wrong counts"
TS_REPORT="$(find "$TS_STORE" -path "*777001*" -name close_report.json | head -1)"
[ -n "$TS_REPORT" ] && grep -q '"recommended_actions_count": 1' "$TS_REPORT" \
  && pass "close_report.json emitted on substantive close" || fail "close_report.json missing/wrong"
ts_cli outcome --id 777001 --result implemented --note "suite" --agent 1=tester-a --agent 2=tester-b >/dev/null 2>&1
grep -q '"event": "outcome_recorded"' "$TS_SIDECAR" && grep -q 'tester-a' "$TS_STORE/telemetry_index.db" 2>/dev/null \
  && pass "outcome_recorded event + per-seat model attribution in index" || fail "outcome event/attribution missing"
AGG_OUT="$(ts_cli telemetry aggregate 2>&1)"
case "$AGG_OUT" in *"777001"*"outcome=implemented"*) pass "telemetry aggregate queries the index across discussions" ;; *) fail "aggregate missing discussion: $AGG_OUT" ;; esac
ts_cli telemetry audit --id 777001 >/dev/null 2>&1 \
  && pass "comparator audit: zero transcript content in telemetry (negative control)" || fail "audit failed: content leak suspected"
ts_cli telemetry status >/dev/null 2>&1 \
  && pass "telemetry status reports mode/window/override" || fail "telemetry status failed"
PURGE_OUT="$(ts_cli telemetry purge 2>&1)"; case "$PURGE_OUT" in *"purged"*[1-9]*) pass "telemetry purge revokes all artifacts" ;; *) fail "purge removed nothing: $PURGE_OUT" ;; esac

# ── Gen 2 Phase 2: Roster Widening, Supersession & Citations (#233) ──────────────
P2_STORE="$WORK/p2-store"; mkdir -p "$P2_STORE"
p2_cli() { python3 "$CLI" --store "$P2_STORE" "$@"; }

# 1. Supersession
p2_cli start --subject "supersession base" --packet-file "$WORK/pkt.md" --id 888001 >/dev/null 2>&1
p2_start_out="$(p2_cli start --subject "supersession replacement" --packet-file "$WORK/pkt.md" --id 888002 --supersedes 888001 2>&1)"
p2_start_rc=$?
[ "$p2_start_rc" -eq 0 ] && pass "start --supersedes 888001 creates new discussion" || fail "start --supersedes failed: $p2_start_out"

# Check old discussion is closed with pointer
p2_old_status="$(p2_cli status --id 888001 2>&1)"
expect_contains "old discussion status is Closed" "$p2_old_status" "STATUS: Closed"
expect_contains "old discussion points to new discussion" "$p2_old_status" "SUPERSEDED-BY: 888002"

# Check join on old discussion reports closed and pointer
p2_old_join="$(p2_cli join --id 888001 --agent 2 2>&1)"
expect_contains "join on superseded discussion reports pointer" "$p2_old_join" "SUPERSEDED-BY: 888002"
expect_contains "join on superseded discussion decides closed" "$p2_old_join" "DECISION: closed"

# Check turns on superseded discussion are refused
p2_old_send="$(p2_cli send --id 888001 --agent 2 --next-agent 1 --message "turn" 2>&1)"
expect_contains "send on superseded discussion is refused" "$p2_old_send" "closed (superseded by #888002)"

# Check superseding an already-superseded discussion is refused
p2_re_sup="$(p2_cli start --subject "attempt 3" --packet-file "$WORK/pkt.md" --supersedes 888001 2>&1)"
p2_re_rc=$?
[ "$p2_re_rc" -ne 0 ] && pass "re-superseding already superseded discussion is refused" || fail "re-superseding succeeded unexpectedly: $p2_re_sup"

# 2. Operator-mediated roster widening (invite)
p2_cli start --subject "invite test" --packet-file "$WORK/pkt.md" --id 888003 --agents 2 >/dev/null 2>&1
p2_invite_out="$(p2_cli invite --id 888003 --agent 3 --reason "Add third reviewer seat" 2>&1)"
p2_invite_rc=$?
[ "$p2_invite_rc" -eq 0 ] && pass "invite adds agent3 to 2-agent discussion" || fail "invite failed: $p2_invite_out"
expect_contains "invite outputs formatted invitation" "$p2_invite_out" 'Join XYZ AgentChorus #888003 as agent number three'

p2_inv_status="$(p2_cli status --id 888003 2>&1)"
expect_contains "status reflects widened roster" "$p2_inv_status" "AGENTS: agent1 agent2 agent3"

# Check duplicate seat invite is refused
p2_dup_invite="$(p2_cli invite --id 888003 --agent 3 2>&1)"
[ $? -ne 0 ] && pass "inviting existing seat is refused" || fail "duplicate invite succeeded unexpectedly"

# Check non-sequential seat invite is refused
p2_gap_invite="$(p2_cli invite --id 888003 --agent 5 2>&1)"
[ $? -ne 0 ] && pass "inviting non-sequential seat is refused" || fail "gap invite succeeded unexpectedly"

# Check invite on closed discussion is refused
p2_cli close --id 888003 --agent 2 --trivial --message "closing" >/dev/null 2>&1
p2_closed_invite="$(p2_cli invite --id 888003 --agent 4 2>&1)"
[ $? -ne 0 ] && pass "inviting on closed discussion is refused" || fail "invite on closed discussion succeeded unexpectedly"

# 3. Citation verification (verify-citations)
p2_cli start --subject "citations test" --packet-file "$WORK/pkt.md" --id 888004 --agents 2 >/dev/null 2>&1
HEAD_SHA="$(git rev-parse HEAD)"
p2_cli send --id 888004 --agent 2 --next-agent 1 --message "Referencing skills/agent-chorus/SKILL.md:10 and commit $HEAD_SHA" >/dev/null 2>&1

p2_cit_pass="$(p2_cli verify-citations --id 888004 --format json 2>&1)"
p2_cit_rc=$?
[ "$p2_cit_rc" -eq 0 ] && pass "verify-citations passes on valid file and commit references" || fail "verify-citations failed on valid refs: $p2_cit_pass"
expect_contains "verify-citations reports PASS status" "$p2_cit_pass" '"status": "PASS"'

# Append bad citation
p2_cli send --id 888004 --agent 1 --next-agent 2 --message "Referencing bogus/path/to/missing_file.ext:99" >/dev/null 2>&1
p2_cit_fail="$(p2_cli verify-citations --id 888004 2>&1)"
p2_cit_fail_rc=$?
[ "$p2_cit_fail_rc" -ne 0 ] && pass "verify-citations fails on unresolvable file citation" || fail "verify-citations passed on invalid refs: $p2_cit_fail"
expect_contains "verify-citations text output lists unresolvable count" "$p2_cit_fail" "STATUS: FAIL"

# --- GH-329: a missing store must degrade telemetry, never fail a turn that was already written ---
# The trigger is a LEGACY relay-system discussion (resolvable with no store at all) on a machine that
# has never run `start` or `configure-store`. Before the fix, `close` wrote the turn at append_turn
# and then died in index_connect with sqlite3.OperationalError — turn committed, exit 1, and the
# operator's retry refused as out of turn. Telemetry is forced ON explicitly rather than relying on
# the pilot window, so this test keeps testing the same thing after the window closes.
G329="$WORK/gh329-legacy"
G329_STORE="$WORK/gh329-store-that-never-existed"
mkdir -p "$G329/relay-system/2026-08-30"
G329_SEED_STORE="$WORK/gh329-seed-store"
AGENT2AGENT_ID_SEQUENCE=779779 python3 "$CLI" --root "$G329" --store "$G329_SEED_STORE" \
  start --subject "gh329 legacy discussion" --agents 2 --packet-file "$PACKET" >/dev/null 2>&1
g329_seed="$(find "$G329_SEED_STORE" -name conversation.md | head -1)"
if [ -n "$g329_seed" ] && [ -f "$g329_seed" ]; then
  cp "$g329_seed" "$G329/relay-system/2026-08-30/779779-gh329-legacy-discussion.md"
  rm -rf "$G329_SEED_STORE"
  g329_file="$G329/relay-system/2026-08-30/779779-gh329-legacy-discussion.md"
  [ -e "$G329_STORE" ] \
    && fail "gh329 fixture is invalid: the store must not exist" \
    || pass "gh329 fixture: legacy discussion resolves with no store on disk"
  g329_out="$(AGENT2AGENT_TELEMETRY=1 python3 "$CLI" --root "$G329" --store "$G329_STORE" \
    close --id 779779 --agent 2 --trivial --message "Administrative close under a missing store." 2>&1)"
  g329_rc=$?
  [ "$g329_rc" -eq 0 ] \
    && pass "close SUCCEEDS when the telemetry store does not exist" \
    || fail "a missing store still fails a written turn: rc=$g329_rc $g329_out"
  case "$g329_out" in
    *Traceback*) fail "close still crashes with a traceback under a missing store" ;;
    *) pass "close reports no traceback under a missing store" ;;
  esac
  expect_contains "the telemetry degrade is announced, not silent" "$g329_out" "telemetry index unavailable"
  expect_file_contains "the turn is written despite the unavailable index" \
    "$g329_file" "Administrative close under a missing store."
  expect_file_contains "the discussion actually reaches Closed" "$g329_file" "STATUS: Closed"
else
  fail "gh329 fixture could not be seeded (no conversation.md produced)"
fi

# --- GH-328: a crash mid-supersede must not leave a pointer to an unwritable discussion ---
# The old order closed the original, stamped SUPERSEDED-BY on it, and only then wrote the new
# conversation.md. A failure in that gap left the original Closed pointing at a directory with no
# readable content, the ID permanently reserved, and a retry refused as "already superseded" — no
# way back through the CLI. Fault injection is the only honest way to test this: the window is an
# I/O failure, so a copy of the helper is patched to raise at exactly the boundary that used to be
# unsafe. If the anchor ever moves, the patch step exits 3 and this FAILS rather than passing silently.
G328="$WORK/gh328-supersede"
G328_STORE="$WORK/gh328-store"
G328_CLI="$WORK/agent_chorus_gh328_fault.py"
mkdir -p "$G328"
python3 - "$CLI" "$G328_CLI" <<'GH328_PATCH'
import pathlib, sys
src, dst = sys.argv[1], sys.argv[2]
text = pathlib.Path(src).read_text(encoding="utf-8")
anchor = '            private_mkdir(session_dir / "runtime")'
if anchor not in text:
    sys.exit(3)
injected = '            raise OSError(28, "GH328 injected fault")\n' + anchor
pathlib.Path(dst).write_text(text.replace(anchor, injected, 1), encoding="utf-8")
GH328_PATCH
g328_patch_rc=$?
if [ "$g328_patch_rc" -ne 0 ]; then
  fail "gh328 fault injection could not find its anchor in the helper (rc=$g328_patch_rc)"
else
  pass "gh328 fault injection anchors on the new-discussion write"
  # Seed with the CLEAN helper — the patched copy raises on every creation, including this one.
  AGENT2AGENT_ID_SEQUENCE=886001 python3 "$CLI" --root "$G328" --store "$G328_STORE" \
    start --subject "gh328 original" --agents 2 --packet-file "$PACKET" >/dev/null 2>&1
  g328_old="$(find "$G328_STORE" -name conversation.md 2>/dev/null | head -1)"
  if [ -n "$g328_old" ] && [ -f "$g328_old" ]; then
    AGENT2AGENT_ID_SEQUENCE=886002 python3 "$G328_CLI" --root "$G328" --store "$G328_STORE" \
      start --subject "gh328 replacement" --agents 2 --packet-file "$PACKET" \
      --supersedes 886001 >/dev/null 2>&1
    g328_crash_rc=$?
    [ "$g328_crash_rc" -ne 0 ] \
      && pass "the injected fault does abort the supersede" \
      || fail "the injected fault did not abort the supersede (rc=$g328_crash_rc)"
    grep -q '^STATUS: Open' "$g328_old" \
      && pass "a crash mid-supersede leaves the ORIGINAL discussion open" \
      || fail "a crash mid-supersede closed the original: $(grep -m1 '^STATUS' "$g328_old")"
    grep -q 'SUPERSEDED-BY' "$g328_old" \
      && fail "a crash mid-supersede left a SUPERSEDED-BY pointer to nothing" \
      || pass "a crash mid-supersede writes no dangling SUPERSEDED-BY pointer"
    # Recovery is the property that actually matters: before the fix the retry was refused,
    # so the operator's only route was hand-editing a header.
    g328_retry="$(AGENT2AGENT_ID_SEQUENCE=886003 python3 "$CLI" --root "$G328" --store "$G328_STORE" \
      start --subject "gh328 retry" --agents 2 --packet-file "$PACKET" --supersedes 886001 2>&1)"
    g328_retry_rc=$?
    [ "$g328_retry_rc" -eq 0 ] \
      && pass "the supersede can be retried after a crash" \
      || fail "the supersede is still unrecoverable after a crash: $g328_retry"
    expect_file_contains "the retry closes the original for real" "$g328_old" "STATUS: Closed"
    expect_file_contains "the original now points at the discussion that replaced it" \
      "$g328_old" "SUPERSEDED-BY: 886003"
  else
    fail "gh328 fixture could not be seeded (no original discussion produced)"
  fi
fi

# --- GH-327: telemetry must never be written inside the coordinated repository ---
# The sidecar used to root at `path.parent/runtime` unconditionally, so a LEGACY
# relay-system/<date>/<id>-slug.md discussion — which lives in the git worktree — got
# runtime/telemetry.jsonl and runtime/close_report.json written into the repo. That broke
# TELEMETRY.md's "nothing is copied into any repository" and put the files beyond `telemetry purge`,
# which only walks the store. Telemetry is forced ON so this tests the policy, not the pilot window.
G327="$WORK/gh327-legacy/repo"
G327_STORE="$WORK/gh327-store"
mkdir -p "$G327/relay-system/2026-08-30"
AGENT2AGENT_ID_SEQUENCE=771201 python3 "$CLI" --root "$G327" --store "$G327_STORE" \
  start --subject "gh327 legacy" --agents 2 --packet-file "$PACKET" >/dev/null 2>&1
g327_seed="$(find "$G327_STORE" -path "*771201*" -name conversation.md 2>/dev/null | head -1)"
if [ -n "$g327_seed" ] && [ -f "$g327_seed" ]; then
  # A store-resident discussion DOES get a sidecar. Negative control: without this the whole block
  # would still pass if telemetry were simply broken everywhere.
  g327_store_sidecar="$(dirname "$g327_seed")/runtime/telemetry.jsonl"
  [ -f "$g327_store_sidecar" ] \
    && pass "a store-resident discussion still gets its telemetry sidecar" \
    || fail "telemetry is broken for store discussions, not just excluded for legacy ones"
  cp "$g327_seed" "$G327/relay-system/2026-08-30/771201-gh327-legacy.md"
  rm -rf "$(dirname "$g327_seed")"
  AGENT2AGENT_TELEMETRY=1 python3 "$CLI" --root "$G327" --store "$G327_STORE" \
    join --id 771201 --agent 1 >/dev/null 2>&1
  g327_close="$(AGENT2AGENT_TELEMETRY=1 python3 "$CLI" --root "$G327" --store "$G327_STORE" \
    close --id 771201 --agent 2 --trivial --message "Administrative close for gh327." 2>&1)"
  g327_close_rc=$?
  [ "$g327_close_rc" -eq 0 ] \
    && pass "a legacy discussion still closes normally" \
    || fail "excluding telemetry broke the legacy close: $g327_close"
  g327_leaked="$(find "$G327" \( -name runtime -o -name telemetry.jsonl -o -name close_report.json \) 2>/dev/null | head -1)"
  [ -z "$g327_leaked" ] \
    && pass "no telemetry file is written inside the repository for a legacy discussion" \
    || fail "telemetry still leaks into the repository: $g327_leaked"
  expect_contains "the exclusion is announced when telemetry was explicitly enabled" \
    "$g327_close" "telemetry is skipped"
  # audit must report the policy, not die on a None sidecar
  g327_audit="$(AGENT2AGENT_TELEMETRY=1 AGENT2AGENT_ROOT="$G327" python3 "$CLI" \
    --root "$G327" --store "$G327_STORE" telemetry audit --id 771201 2>&1)"
  case "$g327_audit" in
    *Traceback*) fail "telemetry audit crashes on a non-eligible discussion" ;;
    *) pass "telemetry audit does not crash on a non-eligible discussion" ;;
  esac
  expect_contains "telemetry audit names the exclusion rather than 'off or no events'" \
    "$g327_audit" "not telemetry-eligible"
else
  fail "gh327 fixture could not be seeded"
fi

# The geometry a containment check would have failed on: normalize_store refuses a store INSIDE the
# repo but not a repo INSIDE the store, so `_is_within(path, store)` returns true for a legacy
# discussion here and would have written telemetry straight back into the worktree. The name check
# has no geometry to defeat.
G327B_STORE="$WORK/gh327-inverted"
G327B="$G327B_STORE/repo"
mkdir -p "$G327B/relay-system/2026-08-30"
AGENT2AGENT_ID_SEQUENCE=772202 python3 "$CLI" --root "$G327B" --store "$G327B_STORE" \
  start --subject "gh327 inverted" --agents 2 --packet-file "$PACKET" >/dev/null 2>&1
g327b_seed="$(find "$G327B_STORE/repositories" -path "*772202*" -name conversation.md 2>/dev/null | head -1)"
if [ -n "$g327b_seed" ] && [ -f "$g327b_seed" ]; then
  pass "a repo inside its own store is accepted (the geometry that defeats a containment guard)"
  cp "$g327b_seed" "$G327B/relay-system/2026-08-30/772202-gh327-inverted.md"
  rm -rf "$(dirname "$g327b_seed")"
  AGENT2AGENT_TELEMETRY=1 python3 "$CLI" --root "$G327B" --store "$G327B_STORE" \
    close --id 772202 --agent 2 --trivial --message "Administrative close for gh327 inverted." >/dev/null 2>&1
  g327b_leaked="$(find "$G327B" \( -name runtime -o -name telemetry.jsonl -o -name close_report.json \) 2>/dev/null | head -1)"
  [ -z "$g327b_leaked" ] \
    && pass "no telemetry lands in the repo even when the repo sits inside the store" \
    || fail "the repo-inside-store geometry still leaks telemetry: $g327b_leaked"
else
  fail "gh327 inverted-geometry fixture could not be seeded"
fi

printf '  agent-chorus: %s pass, %s fail\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
