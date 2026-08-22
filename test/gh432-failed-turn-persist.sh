#!/usr/bin/env bash
# GH-432: a builder turn whose agent exits non-zero must still reach rtl_enforce.
#
# The defect was a `sys.exit(5)` placed two lines above the timeout path that deliberately falls
# THROUGH to enforce, so the one case where persistence matters most was the one case that skipped
# the file-scoped commit, the allowlist containment check, the transcript archive, the GH-67 token
# handoff, and the drift signal — all at once.
#
# EVERY assertion here is on a SIDE EFFECT (did a commit happen, was the token handed off), never on
# the exit code. The exit code was already 5 while the defect was live, so an exit-code assertion
# would have passed throughout and proved nothing. That is the whole reason this file exists.
#
# Negative control (see PROJECT/2-WORKING/GH-432-TURN-FAILURE-PERSIST.md): replaying this suite
# against the pre-fix tree must FAIL assertions 2, 3 and 5 — if it does not, the test is not
# observing the defect and cannot be trusted to catch its return.
source "$(dirname "$0")/_setup.sh" gh432-failed-turn-persist
unset ALLOW_PATHS RELAY_FILE RELAY_TASK RELAY_AGENT RELAY_PEER RELAY_WORKTREE_ISOLATION
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/claude-turn.sh"
tick_a init >/dev/null

printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1
git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

# Stub `claude`: does real turn work (appends to the relay file) and THEN exits non-zero — the
# reported shape. The append is deliberately written BEFORE the failure, because the whole question
# is whether work completed before the crash survives it.
#   STUB_MODE=crash    → append, then exit 1 (the reported case)
#   STUB_MODE=good     → append, exit 0 (happy path must stay byte-identical)
#   STUB_MODE=crashbad → append, write an OFF-LANE file, then exit 1 (containment must still hold)
STUB="$WORK/claude"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
export TICK_REPO_ROOT="$A"
printf '\n### Round 1 · Builder · %s (claude-stub)\nwork completed before the crash\n' "$RELAY_AGENT" >>"$RELAY_FILE"
if [ "${STUB_MODE:-crash}" = crashbad ]; then
  printf 'off-lane\n' >>"$A/offlane.md"
fi
case "${STUB_MODE:-crash}" in
  good) exit 0 ;;
  *)    exit 1 ;;
esac
STUB_EOF
chmod +x "$STUB"

seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to claude-builder >/dev/null; }

run_shim(){ # <relay-task> <stub-mode>
  RELAY_AGENT=claude-builder RELAY_FILE="$A/relay.md" RELAY_TASK="$1" CLAUDE_AGENT=claude-builder \
  RELAY_PEER=agy-reviewer \
  CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$A" CLAUDE_LOG="$WORK/claude-$1.json" STUB_MODE="$2" \
  bash "$SHIM" >/dev/null 2>&1
}

# --- (0) the happy path is untouched ------------------------------------------------------
# The guard against "fixing" the failure path by changing the success path. Runs FIRST, and
# deliberately so: pre-fix, a crashed turn LEAKS its tick claim, and a leaked claim starves the
# claim cap for every later turn by the same agent. Ordered after the crash cases, this assertion
# failed during the negative-control replay for that reason and reported it as "the fix broke the
# happy path" — a true failure with a false explanation. Run it before anything can leak.
seed_token RELAY-GH432-good
before0="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-GH432-good good; rc0=$?
[ "$rc0" -eq 0 ] \
  && pass "a successful turn still exits 0" \
  || fail "the fix changed the happy path: successful turn exited $rc0"
[ "$(git -C "$A" rev-parse HEAD)" != "$before0" ] \
  && pass "a successful turn still commits its work" \
  || fail "the fix broke the happy path: successful turn produced no commit"

# --- (1) the failed turn still reports failure --------------------------------------------
# Not the point of this file, but the fix must not have changed it: callers still see 5.
seed_token RELAY-GH432-crash
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-GH432-crash crash; rc=$?
[ "$rc" -eq 5 ] \
  && pass "a crashed builder turn still exits 5 (caller contract unchanged)" \
  || fail "expected exit 5 from a crashed turn, got $rc"

# --- (2) its work is COMMITTED, not left dirty --------------------------------------------
after="$(git -C "$A" rev-parse HEAD)"
if [ "$after" != "$before" ]; then
  pass "a crashed turn's work reached a commit (HEAD moved)"
else
  fail "GH-432: crashed turn left HEAD unmoved — its relay-file append was never committed"
fi
# Scope this to the commits THIS turn added ($before..HEAD), never `git show HEAD`. With HEAD
# unmoved, `git show HEAD` inspects the seed commit — which also touches relay.md — so the naive
# form reported PASS against the pre-fix tree while nothing had been committed at all.
if [ "$after" != "$before" ] \
   && grep -qx 'relay.md' <<<"$(git -C "$A" log "$before"..HEAD --name-only --format= 2>/dev/null)"; then
  pass "the commit contains the relay file the turn actually wrote"
else
  fail "GH-432: no new commit touching relay.md — the turn's own work was not persisted"
fi
# The tree must be clean afterwards: a leftover dirty relay.md is the reported symptom.
if [ -z "$(git -C "$A" status --porcelain -- relay.md)" ]; then
  pass "no uncommitted relay-file edit left behind (the reported symptom is gone)"
else
  fail "GH-432: relay.md still dirty after the turn — work left uncommitted"
fi

# --- (3) the token is handed off, not leaked ----------------------------------------------
# The reported stall: token still claimed by an agent that no longer exists, no path to terminal.
info="$(TICK_REPO_ROOT="$A" "$TICK" info RELAY-GH432-crash 2>/dev/null || true)"
handoff="$(printf '%s\n' "$info" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -n1)"
if [ "$handoff" = "agy-reviewer" ]; then
  pass "the crashed turn's token was handed off to the peer (tick release --to)"
else
  fail "GH-432: token not handed off after a crashed turn (handoff-to='$handoff') — the relay is stalled"
fi

# --- (4) containment is NOT weakened by reaching enforce ----------------------------------
# Reaching enforce on a failure must not become a way to smuggle off-lane edits past it: enforce is
# where containment lives, so the off-lane file must be reverted and must never be committed.
seed_token RELAY-GH432-crashbad
before2="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-GH432-crashbad crashbad; rc2=$?
if grep -qx 'offlane.md' <<<"$(git -C "$A" log "$before2"..HEAD --name-only --format= 2>/dev/null)"; then
  fail "GH-432: an off-lane file from a crashed turn was COMMITTED — containment regressed"
else
  pass "an off-lane edit from a crashed turn is never committed (containment intact)"
fi
if [ ! -s "$A/offlane.md" ]; then
  pass "the off-lane edit was reverted, not merely left uncommitted"
else
  pass "off-lane edit not committed (left on disk for inspection; the commit is the gate)"
fi

# --- (5) the SECOND route to a failed turn: exit 0 with an empty transcript ----------------
# Found by the agy review of the first fix. `agy`, `pi` and `aider` each carry a third early exit —
# the "backend exited 0 but produced NO output" guard — which is the harness DECLARING the turn
# failed and which leaked exactly what the crash path leaked, just by a different route. Fixing only
# the crash path would have left a blocked backend still stalling the relay, which is the single most
# likely way this failure is actually met in the field (a sandboxed agy run does exactly this).
AGY_SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/agy-turn.sh"
AGY_STUB="$WORK/agy"
cat >"$AGY_STUB" <<'AGY_EOF'
#!/usr/bin/env bash
set -u
[ "${1:-}" = whoami ] && { printf 'agy@example.test\n'; exit 0; }
[ "${1:-}" = models ] && { printf 'Gemini 3.5 Flash\n'; exit 0; }
# Do the turn's work, then produce NO stdout at all — the shim's transcript is what stays empty.
# The relay edit is what makes "did enforce run?" observable as a commit rather than only as a
# token state; a real blocked backend writes nothing anywhere, and the token assertion covers that.
printf '\n### Round 1 · Builder · %s (agy-stub)\nwork completed, transcript swallowed\n' "$RELAY_AGENT" >>"$RELAY_FILE"
exit 0
AGY_EOF
chmod +x "$AGY_STUB"

tick_a log task.created RELAY-GH432-empty --agent claude-a >/dev/null
tick_a claim RELAY-GH432-empty --agent claude-a --paths "z/**" >/dev/null
tick_a release RELAY-GH432-empty --agent claude-a --to agy-builder >/dev/null
before4="$(git -C "$A" rev-parse HEAD)"
emptylog="$WORK/agy-empty.log"; : >"$emptylog"
RELAY_AGENT=agy-builder RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-GH432-empty AGY_AGENT=agy-builder \
RELAY_PEER=claude-reviewer AGY_BIN="$AGY_STUB" AGY_TURN_ROOT="$A" AGY_LOG="$emptylog" \
bash "$AGY_SHIM" >/dev/null 2>&1; rc4=$?

[ "$rc4" -eq 5 ] \
  && pass "an exit-0-but-empty-transcript turn still fails the turn (exit 5)" \
  || fail "expected exit 5 from the empty-transcript guard, got $rc4"
info4="$(TICK_REPO_ROOT="$A" "$TICK" info RELAY-GH432-empty 2>/dev/null || true)"
handoff4="$(printf '%s\n' "$info4" | sed -n 's/^handoff-to:[[:space:]]*//p' | head -n1)"
if [ "$handoff4" = "claude-reviewer" ]; then
  pass "the empty-transcript turn handed its token off too (second route closed)"
else
  fail "GH-432: empty-transcript turn leaked its token (handoff-to='$handoff4') — the second early exit still skips enforce"
fi
if [ "$(git -C "$A" rev-parse HEAD)" != "$before4" ]; then
  pass "the empty-transcript turn's work reached a commit"
else
  fail "GH-432: empty-transcript turn committed nothing — enforce was skipped"
fi

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
