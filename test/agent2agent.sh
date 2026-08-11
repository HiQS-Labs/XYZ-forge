#!/usr/bin/env bash
# GH-497 — compact-ID, serialized, multi-party agent2agent discussions.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
CLI="$REPO/skills/agent2agent/scripts/agent2agent.py"
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

echo "agent2agent (GH-497):"
ROOT="$WORK/root with spaces"
mkdir -p "$ROOT"

python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(), feature_version=(3, 8))' "$CLI" \
  && pass "helper parses with the repository's Python 3.8 floor" \
  || fail "helper uses syntax newer than Python 3.8"

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

# Any current participant may route to any other roster member, including agent3 and agent4.
send2_out="$(python3 "$CLI" --root "$ROOT" send --id 123456 --agent 2 --next-agent 3 \
  --message "Agent two response." 2>&1)"
send2_rc=$?
[ "$send2_rc" -eq 0 ] && pass "agent2 routes turn 2 to agent3" || fail "agent2 send exits $send2_rc: $send2_out"
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
