#!/usr/bin/env bash
# GH-497/GH-510 — compact multi-party discussions with explicit watch/drive levels.
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

echo "agent2agent (GH-497/GH-510):"
ROOT="$WORK/root with spaces"
mkdir -p "$ROOT"

python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(), feature_version=(3, 8))' "$CLI" \
  && pass "helper parses with the repository's Python 3.8 floor" \
  || fail "helper uses syntax newer than Python 3.8"

grep -Fq -- '<this-skill>' "$SKILL" \
  && fail "skill retains a shell-significant path placeholder" \
  || pass "skill contains no shell-significant path placeholder"
helper_examples="$(grep -Fc -- '"$(git rev-parse --show-toplevel)/skills/agent2agent/scripts/agent2agent.py"' "$SKILL")"
[ "$helper_examples" -eq 7 ] \
  && pass "all skill commands resolve and quote the repository helper" \
  || fail "expected 7 root-resolved helper commands, found $helper_examples"
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
[ "$(printf '%s\n' "$start_out" | tail -1)" = "$expected_invitation" ] \
  && pass "prints the exact compact invitation" || fail "exact invitation changed: $start_out"

relay_file="$(find "$ROOT/relay-system" -type f -name '123456-*.md' -print)"
[ -f "$relay_file" ] && pass "creates a dated relay file under a spaced root" || fail "relay file missing"
case "$relay_file" in "$ROOT"/relay-system/????-??-??/123456-agent2agent-*.md) pass "uses dated relay storage" ;; *) fail "unexpected relay path: $relay_file" ;; esac
expect_file_contains "records stable 4-agent roster" "$relay_file" "AGENTS: agent1 agent2 agent3 agent4"
expect_file_contains "routes the opening turn to agent2" "$relay_file" "NEXT: agent2"
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
# GH-510 doorbell: take-turn must hand the waking session its exact relaunch command,
# and the printed argv must be self-contained (watch verb, id, agent, --root).
expect_contains "take-turn watch prints a REARM line" "$watch_now" "REARM: "
rearm_line="$(printf '%s\n' "$watch_now" | grep '^REARM: ' | head -1)"
case "$rearm_line" in
  *" watch --id 123456 --agent 2 "*--root*) pass "REARM argv is self-contained" ;;
  *) fail "REARM argv incomplete: $rearm_line" ;;
esac
[ "$before_watch" = "$(fingerprint "$relay_file")" ] \
  && pass "watch leaves the discussion byte-identical" || fail "watch mutated the discussion"
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
before_lock="$(fingerprint "$relay_file")"
printf '%s\n' 'pid=test' > "$relay_file.lock"
lock_out="$(python3 "$CLI" --root "$ROOT" send --id 123456 --agent 2 --next-agent 3 \
  --message "contended write" 2>&1)"
lock_rc=$?
rm -f "$relay_file.lock"
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
