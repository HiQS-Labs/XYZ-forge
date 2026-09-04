#!/usr/bin/env bash
# test/relay-xyz-skill-guard.sh
# The PreToolUse guard (relay-automation/hooks/relay-xyz-guard.sh) must block a session from
# driving a harness driver before the relay-xyz skill has been loaded, and must stay silent
# once it has. It must never block reads, test/ paths, or unrelated commands (no false positives).
source "$(dirname "$0")/_setup.sh" relay-xyz-skill-guard

GUARD="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/hooks/relay-xyz-guard.sh"
[ -x "$GUARD" ] || { echo "  FAIL: guard hook not executable: $GUARD" >&2; exit 1; }

# Isolate guard state per test so markers from a real session never leak in.
export TMPDIR="$WORK/tmp"; mkdir -p "$TMPDIR"

# Emit a PreToolUse event JSON: ev <session> <tool> <field>
#   tool=Skill → field is the skill name; tool=Bash → field is the command.
ev() {
  python3 - "$1" "$2" "$3" <<'PY'
import sys, json
sess, tool, field = sys.argv[1], sys.argv[2], sys.argv[3]
ti = {"skill": field} if tool == "Skill" else {"command": field}
print(json.dumps({"session_id": sess, "tool_name": tool, "tool_input": ti}))
PY
}

# Run the guard with an event; sets global RC to its exit code.
run() { RC=0; printf '%s' "$(ev "$1" "$2" "$3")" | bash "$GUARD" >/dev/null 2>&1 || RC=$?; }

DRIVE="bash relay-automation/relay-drive.sh --relay-file relay-system/2026-06-24/t.md --round-cap 4"

# 1. Cold driver, skill never loaded → BLOCKED (exit 2).
run "sess-cold" Bash "$DRIVE"
[ "$RC" = 2 ] && pass "cold relay-drive.sh is blocked (exit 2)" \
              || fail "cold relay-drive.sh should block with exit 2, got $RC"

# 2. After the Skill tool loads relay-xyz, the SAME session may drive → allowed.
run "sess-skill" Skill "relay-xyz"
[ "$RC" = 0 ] && pass "Skill(relay-xyz) event is allowed and records the session" \
              || fail "Skill(relay-xyz) should exit 0, got $RC"
run "sess-skill" Bash "$DRIVE"
[ "$RC" = 0 ] && pass "post-skill relay-drive.sh is allowed (marker honored)" \
              || fail "post-skill relay-drive.sh should exit 0, got $RC"

# 3. Running the skill's locator also counts as proof-of-load.
run "sess-loc" Bash 'eval "$(bash skills/relay-xyz/find-harness.sh --env)"'
[ "$RC" = 0 ] && pass "find-harness.sh event is allowed and records the session" \
              || fail "find-harness.sh should exit 0, got $RC"
run "sess-loc" Bash "bash relay-automation/poll.sh --mode relay --agent claude-a"
[ "$RC" = 0 ] && pass "post-locator poll.sh is allowed" \
              || fail "post-locator poll.sh should exit 0, got $RC"

# 4. Marker is session-scoped: a DIFFERENT cold session is still blocked.
run "sess-other" Bash "$DRIVE"
[ "$RC" = 2 ] && pass "marker is session-scoped (a different cold session still blocks)" \
              || fail "different cold session should block with exit 2, got $RC"

# 5. No false positives: running the test copy (test/…), reading, and unrelated commands.
run "sess-fp" Bash "bash test/marathon-drive.sh"
[ "$RC" = 0 ] && pass "test/marathon-drive.sh is not treated as driving" \
              || fail "test/ path should not block, got $RC"
run "sess-fp" Bash "cat relay-automation/poll.sh"
[ "$RC" = 0 ] && pass "reading a harness file (cat) is not blocked" \
              || fail "cat of harness file should not block, got $RC"
run "sess-fp" Bash "bash -n relay-automation/codex-turn.sh"
[ "$RC" = 0 ] && pass "syntax-check (bash -n) of a shim is not blocked" \
              || fail "bash -n should not block, got $RC"
run "sess-fp" Bash "git status"
[ "$RC" = 0 ] && pass "unrelated command (git status) is allowed" \
              || fail "unrelated command should exit 0, got $RC"
run "sess-fp" Bash 'printf "%s\\n" relay-automation/relay-drive.sh'
[ "$RC" = 0 ] && pass "driver path used only as an argument is allowed" \
              || fail "argument-only driver path should not block, got $RC"

# 6. Malformed event → fail open (allow), never a hard error.
RC=0; printf 'not json' | bash "$GUARD" >/dev/null 2>&1 || RC=$?
[ "$RC" = 0 ] && pass "malformed event fails open (exit 0)" \
              || fail "malformed event should fail open, got $RC"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
