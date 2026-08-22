#!/usr/bin/env bash
# pi-turn.sh test (GH-295): the Pi (pi.dev) turn-taker drives a relay turn behind the SHARED safety
# core (relay-turn-lib.sh) — same containment as codex-turn.sh / agy-turn.sh, via a STUB `pi` that
# performs the real turn-taker contract (tick + file edit) and emits Pi's real JSONL --mode json shape
# (captured from a live Phase 0 smoke test). Also proves the Pi-specific bits: no silent PI_MODEL
# default, the OPENROUTER_API_KEY pre-flight, the empty-output guard (mirrors agy), and cost.tokens
# capture (the genuine improvement over agy's cost-blind lane).
source "$(dirname "$0")/_setup.sh" pi-turn
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/pi-turn.sh"
tick_a init >/dev/null

# committed relay-file baseline; mirror the real repo's .tick/ gitignore (invisible to git status).
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

# Stub `pi`: ignores its flags (--provider/--model/--no-session/--mode json/-p <prompt>), performs a
# real turn as $RELAY_AGENT — claim/ping the token, append a block to $RELAY_FILE, release to claude-a —
# and prints Pi's REAL --mode json JSONL shape (one JSON object per line) to stdout, with a genuine
# `message.usage` block on the final event, so the shim's cost-capture parser has real content to
# chew on. STUB_MODE: bad=off-allowlist file; commitbypass=commits one; spacefile=off-lane path with a
# space; empty=NO output + NO edits (mirrors agy's silent-backend-blocked exit-0 shape); notick=skips
# the token ops entirely (shim must establish ownership+handoff itself, GH-165 parity); editartifact=
# reviewer overstep.
STUB="$WORK/pi"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
printf '%s\n' "$*" > "$WORK/pi-args" 2>/dev/null || true
if [ "${STUB_MODE:-good}" = empty ]; then exit 0; fi   # silent backend-blocked: exit 0, no output
export TICK_REPO_ROOT="$A"
printf '{"type":"session","version":3,"id":"stub-session"}\n'
printf '{"type":"agent_start"}\n'
printf '{"type":"turn_start"}\n'
if [ "${STUB_MODE:-good}" != notick ]; then
  "$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
  "$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
fi
printf '\n### Round 1 · Reviewer · %s (pi-stub)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
if [ "${STUB_MODE:-good}" != notick ]; then
  "$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
fi
[ "${STUB_MODE:-good}" = slowafterrelease ] && sleep "${STUB_SLEEP_S:-2}"
[ "${STUB_MODE:-good}" = bad ] && printf 'off-lane\n' >>"$A/offlane.md"
[ "${STUB_MODE:-good}" = spacefile ] && printf 'off-lane\n' >>"$A/off lane.md"
[ "${STUB_MODE:-good}" = editartifact ] && printf 'reviewer-edit\n' >>"$A/artifact.md"
if [ "${STUB_MODE:-good}" = commitbypass ]; then
  printf 'sneaky\n' >>"$A/sneaky.md"
  git -C "$A" add sneaky.md >/dev/null 2>&1
  git -C "$A" commit -q -m "pi sneaked a commit" >/dev/null 2>&1
fi
# Real Phase-0-captured JSONL shape: final turn_end/agent_end carries the cumulative message.usage.
printf '{"type":"message_end","message":{"role":"assistant","content":[{"type":"text","text":"ok"}],"usage":{"input":1098,"output":18,"cacheRead":0,"cacheWrite":0,"totalTokens":1116,"cost":{"input":0.0008235,"output":0.000081,"total":0.0009045}}}}\n'
printf '{"type":"turn_end","message":{"role":"assistant","content":[{"type":"text","text":"ok"}],"usage":{"input":1098,"output":18,"cacheRead":0,"cacheWrite":0,"totalTokens":1116,"cost":{"input":0.0008235,"output":0.000081,"total":0.0009045}}},"toolResults":[]}\n'
printf '{"type":"agent_end","messages":[],"willRetry":false}\n'
printf '{"type":"agent_settled"}\n'
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to pi >/dev/null; }
tok_field(){ tick_a info "$1" 2>/dev/null | sed -n "s/^$2:[[:space:]]*//p" | head -1; }

run_shim(){ # <relay-task> <agent> <stub-mode> [extra env assignments...]
  local task="$1" agent="$2" mode="$3"; shift 3
  local log="$WORK/pi-turn-out.$$.log"; : >"$log"
  env RELAY_AGENT="$agent" RELAY_FILE="$A/relay.md" RELAY_TASK="$task" PI_AGENT=pi \
    PI_BIN="$STUB" PI_TURN_ROOT="$A" PI_LOG="$log" PI_MODEL="openai/gpt-mini-latest" \
    OPENROUTER_API_KEY="test-key-not-real" STUB_MODE="$mode" "$@" \
    bash "$SHIM" >/dev/null 2>&1
}

# --- (1) defer: non-Pi actor -> no-op, no commit --------------------------
seed_token RELAY-TURN-defer
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-defer claude-a good; rc=$?
[ "$rc" -eq 0 ] && [ "$(git -C "$A" rev-parse HEAD)" = "$before" ] \
  && pass "non-Pi actor -> shim defers, no commit" || fail "should defer with no commit (rc=$rc)"

# --- (2) good turn: only relay file changes -> committed, no push, cost captured ---
seed_token RELAY-TURN-good
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-good pi good; rc=$?
[ "$rc" -eq 0 ] && pass "Pi turn (good) exits 0" || fail "good turn rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "Pi turn committed (file-scoped)" || fail "expected a commit"
grep -q "relay.md" <<<"$(git -C "$A" show --stat HEAD)" && pass "commit touched the relay file" || fail "commit should include relay.md"
grep -q "pi headless" <<<"$(git -C "$A" log -1 --format='%s')" && pass "commit message names the pi tool" || fail "commit msg should say pi"
if grep -rl '"type":"cost.tokens".*"task":"RELAY-TURN-good"' "$A/.tick/events" >/dev/null 2>&1; then
  pass "GH-295: Pi turn emits a real cost.tokens event (unlike agy's cost-blind lane)"
else
  fail "GH-295: expected a cost.tokens event for RELAY-TURN-good"
fi

# --- (2a) GH-165 parity: stub skips tick entirely -> shim establishes ownership + handoff ---
seed_token RELAY-TURN-gh165
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-gh165 pi notick RELAY_PEER=claude-a; rc=$?
[ "$rc" -eq 0 ] && pass "GH-165 parity: no-tick Pi turn still exits 0" || fail "no-tick turn rc=$rc"
[ "$(tok_field RELAY-TURN-gh165 status)" = "open" ] && [ "$(tok_field RELAY-TURN-gh165 handoff-to)" = "claude-a" ] \
  && pass "GH-165 parity: shim handed the token to the peer after a no-tick Pi turn" \
  || fail "token not handed off: status=$(tok_field RELAY-TURN-gh165 status) handoff=$(tok_field RELAY-TURN-gh165 handoff-to)"

# --- (2b) token NOT owned by pi -> shim refuses before any mutation -------
tick_a log task.created RELAY-TURN-noown --agent boss >/dev/null
tick_a claim RELAY-TURN-noown --agent boss --paths "z/**" >/dev/null
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-noown pi good RELAY_PEER=claude-a; rc=$?
[ "$rc" -eq 5 ] && pass "unowned token -> shim refuses before the turn (exit 5)" || fail "unowned token should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "unowned token -> no commit made" || fail "should not commit without token ownership"

# --- (3) GH-295 SAFETY: PI_MODEL unset -> shim refuses (exit 5), no silent default, no turn ---
seed_token RELAY-TURN-nomodel
before="$(git -C "$A" rev-parse HEAD)"
before_relay="$(cksum "$A/relay.md")"
rm -f "$WORK/pi-args"   # earlier good-turn cases already created this; clear it so absence is meaningful
log="$WORK/pi-nomodel.$$.log"; : >"$log"
RELAY_AGENT=pi RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-nomodel PI_AGENT=pi \
  PI_BIN="$STUB" PI_TURN_ROOT="$A" PI_LOG="$log" OPENROUTER_API_KEY="test-key" STUB_MODE=good \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] && pass "GH-295: PI_MODEL unset -> shim refuses to guess (exit 5)" || fail "PI_MODEL unset should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "GH-295: PI_MODEL unset -> no commit" || fail "PI_MODEL unset must not commit"
[ "$(cksum "$A/relay.md")" = "$before_relay" ] && pass "GH-295: PI_MODEL unset -> no relay edit (fails BEFORE any turn work)" || fail "PI_MODEL unset should fail before the turn writes"
[ ! -f "$WORK/pi-args" ] && pass "GH-295: PI_MODEL unset -> pi binary never even invoked" || { fail "GH-295: pi binary should not run without PI_MODEL"; rm -f "$WORK/pi-args"; }

# --- (4) OPENROUTER_API_KEY missing (default provider) -> shim refuses (exit 5) --------------------
seed_token RELAY-TURN-nokey
before="$(git -C "$A" rev-parse HEAD)"
log="$WORK/pi-nokey.$$.log"; : >"$log"
RELAY_AGENT=pi RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-nokey PI_AGENT=pi \
  PI_BIN="$STUB" PI_TURN_ROOT="$A" PI_LOG="$log" PI_MODEL="openai/gpt-mini-latest" STUB_MODE=good \
  env -u OPENROUTER_API_KEY bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] && pass "OPENROUTER_API_KEY unset (default provider) -> shim refuses (exit 5)" || fail "missing key should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "missing key -> no commit" || fail "missing key must not commit"

# --- (5) off-allowlist edit -> reverted + fail (exit 6), shared guard -----------------------------
seed_token RELAY-TURN-bad
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-bad pi bad; rc=$?
[ "$rc" -eq 6 ] && pass "off-allowlist edit -> shim fails (exit 6)" || fail "expected exit 6, got $rc"
[ ! -f "$A/offlane.md" ] && pass "off-lane file was reverted/removed" || fail "off-lane file should be gone"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a violating turn" || fail "should not commit on violation"

# --- (6) commit-bypass: pi commits off-lane -> reset + fail -----------------------------------------
seed_token RELAY-TURN-bypass
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-bypass pi commitbypass; rc=$?
[ "$rc" -eq 6 ] && pass "pi commit during turn -> shim fails (exit 6)" || fail "commit-bypass should exit 6, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "sneaked commit reset to BEFORE_HEAD" || fail "HEAD should reset"
[ ! -f "$A/sneaky.md" ] && pass "off-lane committed file removed by reset" || fail "sneaky.md should be gone"

# --- (7) quoted path: off-lane file with a space -> reverted + fail ---------------------------------
seed_token RELAY-TURN-space
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-space pi spacefile; rc=$?
[ "$rc" -eq 6 ] && pass "off-lane path with space -> shim fails (exit 6)" || fail "spacefile should exit 6, got $rc"
[ ! -f "$A/off lane.md" ] && pass "spaced off-lane file reverted (-z parsing)" || fail "'off lane.md' should be removed"

# --- (8) empty-output guard (mirrors agy): silent exit-0 + no output -> fail (exit 5) ---------------
seed_token RELAY-TURN-empty
# GH-432: flush ambient dirty state before measuring this case. An earlier case in this file exits 6
# on a containment violation, which deliberately does NOT commit — so it leaves the allowlisted relay
# file dirty. Since GH-432 a failed turn reaches rtl_enforce, and enforce commits whatever allowlisted
# content is dirty at that moment (long-standing behavior for every turn, not new). The assertion
# below wants to know whether the EMPTY turn commits anything of its own; inherited dirt makes it
# measure the previous case instead. Verified in isolation: on a clean tree the empty turn moves HEAD
# not at all.
git -C "$A" add -A >/dev/null 2>&1; git -C "$A" commit -q -m "test fixture: flush ambient dirty state" >/dev/null 2>&1
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-empty pi empty; rc=$?
[ "$rc" -eq 5 ] && pass "empty-output-on-exit-0 -> shim fails (exit 5)" || fail "empty output should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a phantom/empty turn" || fail "empty turn must not commit"

# --- (9) pre-existing dirty file is NOT reverted; turn still succeeds (shared core) -----------------
seed_token RELAY-TURN-ambient
printf 'unrelated WIP\n' > "$A/ambient.md"
run_shim RELAY-TURN-ambient pi good; rc=$?
[ "$rc" -eq 0 ] && pass "pre-existing dirty file -> turn still succeeds" || fail "ambient WIP must not fail the turn (rc=$rc)"
[ -f "$A/ambient.md" ] && pass "pre-existing ambient WIP left untouched (not reverted)" || fail "ambient.md was destroyed (regression!)"
rm -f "$A/ambient.md"

# --- (10) REVIEWER-turn scoping: artifact on ALLOW_PATHS is dropped -> edit reverted (exit 6) -------
printf 'NEXT: Reviewer\nSTATUS: Open\n# relay body\n' >"$A/relay-rev.md"
printf 'orig\n' >"$A/artifact.md"
git -C "$A" add relay-rev.md artifact.md >/dev/null 2>&1; git -C "$A" commit -q -m "seed reviewer fixture" >/dev/null 2>&1
seed_token RELAY-TURN-rev
before="$(git -C "$A" rev-parse HEAD)"
revlog="$WORK/pi-rev.$$.log"; : >"$revlog"
RELAY_AGENT=pi RELAY_FILE="$A/relay-rev.md" RELAY_TASK=RELAY-TURN-rev PI_AGENT=pi \
  PI_BIN="$STUB" PI_TURN_ROOT="$A" PI_LOG="$revlog" PI_MODEL="openai/gpt-mini-latest" \
  OPENROUTER_API_KEY="test-key" STUB_MODE=editartifact ALLOW_PATHS="artifact.md" \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 6 ] && pass "reviewer turn: artifact on ALLOW_PATHS dropped -> edit reverted (exit 6)" || fail "reviewer-scoping should revert the artifact edit (exit 6), got $rc"
[ "$(cat "$A/artifact.md" 2>/dev/null)" = "orig" ] && pass "reviewer's artifact edit reverted to original" || fail "artifact.md should be reverted to 'orig'"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a reviewer-scoping violation" || fail "should not commit"
git -C "$A" reset --hard HEAD >/dev/null 2>&1   # clean the uncommitted reviewer block before the next case

# --- (11) timeout after a successful handoff still exits 7 (mirrors codex/agy GH-205 fixture) -------
seed_token RELAY-TURN-timeout
before="$(git -C "$A" rev-parse HEAD)"
RELAY_TURN_TIMEOUT_S=1 run_shim RELAY-TURN-timeout pi slowafterrelease RELAY_PEER=claude-a; rc=$?
[ "$rc" -eq 7 ] && pass "turn killed at RELAY_TURN_TIMEOUT_S exits 7" || fail "timeout fixture should exit 7, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "timeout fixture can still commit before the shim reports exit 7" || fail "timeout fixture should still commit the relay change"

# --- (12) default RELAY_TURN_TIMEOUT_S is 900s (GH-295 design doc) ----------------------------------
grep -q 'RELAY_TURN_TIMEOUT_S:-900' "$SHIM" && pass "default RELAY_TURN_TIMEOUT_S is 900s" || fail "expected 900s default turn timeout"

# --- (13) worktree isolation: pi's absolute-ROOT write still lands (GH-22 class, shared core) --------
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reseed relay for wt-iso test" >/dev/null 2>&1
seed_token RELAY-TURN-wt
before="$(git -C "$A" rev-parse HEAD)"
wtlog="$WORK/pi-wt.$$.log"; : >"$wtlog"
RELAY_AGENT=pi RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-wt PI_AGENT=pi \
  PI_BIN="$STUB" PI_TURN_ROOT="$A" PI_LOG="$wtlog" PI_MODEL="openai/gpt-mini-latest" \
  OPENROUTER_API_KEY="test-key" STUB_MODE=good RELAY_WORKTREE_ISOLATION=1 \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "wt-iso: absolute-ROOT write turn exits 0" || fail "wt-iso good turn rc=$rc"
grep -q "pi-stub" "$A/relay.md" && pass "wt-iso: pi's relay block PRESERVED" || fail "pi's relay output LOST under worktree isolation"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "wt-iso: turn committed (output not silently dropped)" || fail "no commit — output discarded"

# --- (14) dispatcher: a Python-default marathon's --agent-cmd reaches pi-turn.py ------------------
DISPATCH="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/marathon-agent.sh"
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reseed relay for Pi dispatch" >/dev/null 2>&1
seed_token RELAY-TURN-dispatch
before="$(git -C "$A" rev-parse HEAD)"
env RELAY_AGENT=pi RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-dispatch PI_AGENT=pi RELAY_PEER=claude-a \
  MARATHON_BUILDER=pi MARATHON_REVIEWER=claude-a PI_BIN="$STUB" PI_TURN_ROOT="$A" \
  PI_LOG="$WORK/pi-dispatch.$$.log" PI_MODEL="openai/gpt-mini-latest" OPENROUTER_API_KEY="test-key" \
  STUB_MODE=good TICK_REPO_ROOT="$A" bash "$DISPATCH" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "marathon-agent.sh dispatches RELAY_AGENT=pi -> pi-turn.py (exit 0)" || fail "Pi dispatch exit=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "dispatched Pi relay turn committed" || fail "dispatched Pi turn did not commit"

# --- (15) .tick exemption independent of host .gitignore (MBP16 [2]) — LAST: mutates fixture .gitignore ---
printf '# host repo does NOT gitignore .tick\n' > "$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "drop .tick gitignore" >/dev/null 2>&1
seed_token RELAY-TURN-tickexempt
run_shim RELAY-TURN-tickexempt pi good; rc=$?
[ "$rc" -eq 0 ] && pass ".tick writes exempted when host doesn't gitignore .tick (turn succeeds)" || fail "unignored .tick must not fail the turn (rc=$rc)"
[ -d "$A/.tick" ] && pass ".tick state dir preserved (not rm-rf'd)" || fail ".tick was destroyed"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
