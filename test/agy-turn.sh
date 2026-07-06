#!/usr/bin/env bash
# agy-turn.sh test: the Antigravity (`agy`) turn-taker drives a relay turn behind the SHARED safety
# core (relay-turn-lib.sh) — same containment as codex-turn.sh / gemini-turn.sh, via a STUB `agy`
# that performs the real turn-taker contract (tick + file edit). Also proves the agy-specific
# empty-output guard (silent-failure-under-sandbox → exit 5).
source "$(dirname "$0")/_setup.sh" agy-turn
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/agy-turn.sh"
tick_a init >/dev/null

# committed relay-file baseline; mirror the real repo's .tick/ gitignore (invisible to git status).
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

# Stub `agy`: answers the shim's auth/model pre-flights (`whoami`, `models`) and ignores the turn
# flags (--dangerously-skip-permissions --print-timeout <d> --model <m> -p <prompt>). For the real
# turn it performs the contract as $RELAY_AGENT and ALWAYS prints a response line to stdout (so the
# shim's non-empty-output guard sees content). STUB_MODE: authfail=whoami exits non-zero;
# bad=off-allowlist file; commitbypass=commits one; spacefile=off-lane path with a space; empty=NO
# output + NO edits (simulates the silent backend-blocked exit 0 that agy produces under a sandbox).
STUB="$WORK/agy"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
if [ "${1:-}" = whoami ]; then
  [ "${STUB_MODE:-good}" = authfail ] && { printf 'login required\n' >&2; exit 1; }
  printf 'agy@example.test\n'
  exit 0
fi
if [ "${1:-}" = models ]; then
  [ "${STUB_MODE:-good}" = modelsfail ] && { printf 'models unavailable\n' >&2; exit 1; }
  printf '%s\n' "${STUB_MODELS:-Gemini 3.5 Flash}"
  exit 0
fi
if [ -n "${STUB_ARGS_LOG:-}" ]; then
  : >"$STUB_ARGS_LOG"
  printf '%s\n' "$@" >"$STUB_ARGS_LOG"
fi
if [ "${STUB_MODE:-good}" = empty ]; then exit 0; fi   # silent sandbox failure: exit 0, no output
export TICK_REPO_ROOT="$A"
printf 'agy-stub: model response for %s\n' "$RELAY_AGENT"   # stdout -> non-empty transcript
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
printf '\n### Round 1 · Reviewer · %s (agy-stub)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
[ "${STUB_MODE:-good}" = bad ] && printf 'off-lane\n' >>"$A/offlane.md"
if [ "${STUB_MODE:-good}" = commitbypass ]; then
  printf 'sneaky\n' >>"$A/sneaky.md"
  git -C "$A" add sneaky.md >/dev/null 2>&1
  git -C "$A" commit -q -m "agy sneaked a commit" >/dev/null 2>&1
fi
[ "${STUB_MODE:-good}" = spacefile ] && printf 'off-lane\n' >>"$A/off lane.md"
# editartifact: reviewer overstep — edit an ALLOW_PATHS artifact (reviewer-scoping must revert it)
[ "${STUB_MODE:-good}" = editartifact ] && printf 'reviewer-edit\n' >>"$A/artifact.md"
exit 0
STUB_EOF
chmod +x "$STUB"

seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to agy >/dev/null; }

run_shim(){ # <relay-task> <agent> <stub-mode>
  # Use a REAL temp log (not /dev/null) so the empty-output guard's `-s` test is exercised.
  local log="$WORK/agy-turn-out.$$.log"; : >"$log"
  RELAY_AGENT="$2" RELAY_FILE="$A/relay.md" RELAY_TASK="$1" AGY_AGENT=agy \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$log" STUB_MODE="$3" \
  bash "$SHIM" >/dev/null 2>&1
}

# --- (1) defer: non-agy actor -> no-op, no commit -------------------------
seed_token RELAY-TURN-defer
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-defer claude-a good; rc=$?
[ "$rc" -eq 0 ] && [ "$(git -C "$A" rev-parse HEAD)" = "$before" ] \
  && pass "non-agy actor -> shim defers, no commit" || fail "should defer with no commit (rc=$rc)"

# --- (2) good turn: only relay file changes -> committed, no push --------
seed_token RELAY-TURN-good
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-good agy good; rc=$?
[ "$rc" -eq 0 ] && pass "agy turn (good) exits 0" || fail "good turn rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "agy turn committed (file-scoped)" || fail "expected a commit"
git -C "$A" show --stat HEAD | grep -q "relay.md" && pass "commit touched the relay file" || fail "commit should include relay.md"
git -C "$A" log -1 --format='%s' | grep -q "agy headless" && pass "commit message names the agy tool" || fail "commit msg should say agy"

# --- (3) off-lane edit -> reverted + fail (exit 6), shared guard ---------
seed_token RELAY-TURN-bad
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-bad agy bad; rc=$?
[ "$rc" -eq 6 ] && pass "off-allowlist edit -> shim fails (exit 6)" || fail "expected exit 6, got $rc"
[ ! -f "$A/offlane.md" ] && pass "off-lane file was reverted/removed" || fail "off-lane file should be gone"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a violating turn" || fail "should not commit on violation"

# --- (4) commit-bypass: agy commits off-lane -> reset + fail -------------
seed_token RELAY-TURN-bypass
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-bypass agy commitbypass; rc=$?
[ "$rc" -eq 6 ] && pass "agy commit during turn -> shim fails (exit 6)" || fail "commit-bypass should exit 6, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "sneaked commit reset to BEFORE_HEAD" || fail "HEAD should reset"
[ ! -f "$A/sneaky.md" ] && pass "off-lane committed file removed by reset" || fail "sneaky.md should be gone"

# --- (5) quoted path: off-lane file with a space -> reverted + fail ------
seed_token RELAY-TURN-space
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-space agy spacefile; rc=$?
[ "$rc" -eq 6 ] && pass "off-lane path with space -> shim fails (exit 6)" || fail "spacefile should exit 6, got $rc"
[ ! -f "$A/off lane.md" ] && pass "spaced off-lane file reverted (-z parsing)" || fail "'off lane.md' should be removed"

# --- (6) AGY-SPECIFIC: silent backend-blocked exit 0 + empty output -> fail (exit 5) ---
seed_token RELAY-TURN-empty
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-empty agy empty; rc=$?
[ "$rc" -eq 5 ] && pass "empty-output-on-exit-0 (sandbox-blocked) -> shim fails (exit 5)" || fail "empty output should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a phantom/empty turn" || fail "empty turn must not commit"

# --- (7) S9: unavailable AGY_MODEL -> exit 5 before the turn/commit -------------------------------
seed_token RELAY-TURN-model-bad
before="$(git -C "$A" rev-parse HEAD)"
before_relay="$(cksum "$A/relay.md")"
badmodellog="$WORK/agy-model-bad.$$.log"; : >"$badmodellog"
RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-model-bad AGY_AGENT=agy \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$badmodellog" STUB_MODE=good \
  STUB_MODELS=$'Gemini 3.5 Flash\nGPT-OSS 120B' AGY_MODEL='Totally Bogus Model' \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] && pass "S9: unavailable AGY_MODEL -> shim fails loudly (exit 5)" || fail "unavailable AGY_MODEL should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "S9: unavailable AGY_MODEL -> no commit" || fail "unavailable AGY_MODEL must not commit"
[ "$(cksum "$A/relay.md")" = "$before_relay" ] && pass "S9: unavailable AGY_MODEL -> no relay edit" || fail "unavailable AGY_MODEL should fail before the turn writes"

# --- (8) S9: listed AGY_MODEL -> turn proceeds and passes through --model -------------------------
seed_token RELAY-TURN-model-good
before="$(git -C "$A" rev-parse HEAD)"
goodmodellog="$WORK/agy-model-good.$$.log"; : >"$goodmodellog"
argslog="$WORK/agy-model-good.$$.args"; rm -f "$argslog"
RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-model-good AGY_AGENT=agy \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$goodmodellog" STUB_MODE=good \
  STUB_MODELS=$'Gemini 3.5 Flash\nGPT-OSS 120B' STUB_ARGS_LOG="$argslog" AGY_MODEL='Gemini 3.5 Flash' \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "S9: listed AGY_MODEL -> shim proceeds" || fail "listed AGY_MODEL should succeed, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "S9: listed AGY_MODEL -> committed normal turn" || fail "listed AGY_MODEL should still commit"
grep -Fxq -- "--model" "$argslog" && grep -Fxq "Gemini 3.5 Flash" "$argslog" \
  && pass "S9: listed AGY_MODEL passed through to agy" || fail "listed AGY_MODEL should be forwarded to agy"

# --- (9) auth pre-flight fail -> exit 5 before the turn mutates anything --------------------------
seed_token RELAY-TURN-authfail
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-authfail agy authfail; rc=$?
[ "$rc" -eq 5 ] && pass "auth pre-flight fail -> shim exits 5 with no turn" || fail "authfail should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on auth pre-flight failure" || fail "authfail must not commit"

# --- (8) pre-existing dirty file is NOT reverted; turn still succeeds (MBP16 [1], shared core) ---
seed_token RELAY-TURN-ambient
printf 'unrelated WIP\n' > "$A/ambient.md"
run_shim RELAY-TURN-ambient agy good; rc=$?
[ "$rc" -eq 0 ] && pass "pre-existing dirty file -> turn still succeeds" || fail "ambient WIP must not fail the turn (rc=$rc)"
[ -f "$A/ambient.md" ] && pass "pre-existing ambient WIP left untouched (not reverted)" || fail "ambient.md was destroyed (regression!)"
rm -f "$A/ambient.md"

# --- (10) REVIEWER-turn scoping: artifact on ALLOW_PATHS is dropped -> edit reverted (exit 6) ---
printf 'NEXT: Reviewer\nSTATUS: Open\n# relay body\n' >"$A/relay-rev.md"
printf 'orig\n' >"$A/artifact.md"
git -C "$A" add relay-rev.md artifact.md >/dev/null 2>&1; git -C "$A" commit -q -m "seed reviewer fixture" >/dev/null 2>&1
seed_token RELAY-TURN-rev
before="$(git -C "$A" rev-parse HEAD)"
revlog="$WORK/agy-rev.$$.log"; : >"$revlog"
RELAY_AGENT=agy RELAY_FILE="$A/relay-rev.md" RELAY_TASK=RELAY-TURN-rev AGY_AGENT=agy \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$revlog" STUB_MODE=editartifact ALLOW_PATHS="artifact.md" \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 6 ] && pass "reviewer turn: artifact on ALLOW_PATHS dropped -> edit reverted (exit 6)" || fail "reviewer-scoping should revert the artifact edit (exit 6), got $rc"
[ "$(cat "$A/artifact.md" 2>/dev/null)" = "orig" ] && pass "reviewer's artifact edit reverted to original" || fail "artifact.md should be reverted to 'orig'"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a reviewer-scoping violation" || fail "should not commit"
git -C "$A" reset --hard HEAD >/dev/null 2>&1   # clean the uncommitted reviewer block before the next case

# --- (11) GH-22: worktree isolation must NOT lose an absolute-ROOT write -------------------
# Real agy edits the relay file via its ABSOLUTE ROOT path even when CWD=worktree (it treats ROOT as
# its workspace). The stub models this faithfully: it appends to $RELAY_FILE (= $A/relay.md, an
# absolute ROOT path). Under RELAY_WORKTREE_ISOLATION=1 the buggy rtl_worktree_end copied the stale
# (unmodified) worktree seed back over ROOT, silently discarding agy's output (exit 0, no commit, blank
# relay file). The fix copies back ONLY files the turn actually modified IN THE WORKTREE.
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reseed relay for wt-iso test" >/dev/null 2>&1
seed_token RELAY-TURN-wt
before="$(git -C "$A" rev-parse HEAD)"
wtlog="$WORK/agy-wt.$$.log"; : >"$wtlog"
RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-wt AGY_AGENT=agy \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$wtlog" STUB_MODE=good RELAY_WORKTREE_ISOLATION=1 \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "wt-iso: absolute-ROOT write turn exits 0" || fail "wt-iso good turn rc=$rc"
grep -q "agy-stub" "$A/relay.md" && pass "wt-iso: agy's relay block PRESERVED (GH-22)" || fail "GH-22: agy's relay output LOST (stale worktree copy-back overwrote ROOT)"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "wt-iso: turn committed (output not silently dropped)" || fail "GH-22: no commit — output discarded"

# --- (9) .tick exemption independent of host .gitignore (MBP16 [2]) — LAST: mutates fixture .gitignore ---
printf '# host repo does NOT gitignore .tick\n' > "$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "drop .tick gitignore" >/dev/null 2>&1
seed_token RELAY-TURN-tickexempt
run_shim RELAY-TURN-tickexempt agy good; rc=$?
[ "$rc" -eq 0 ] && pass ".tick writes exempted when host doesn't gitignore .tick (turn succeeds)" || fail "unignored .tick must not fail the turn (rc=$rc)"
[ -d "$A/.tick" ] && pass ".tick state dir preserved (not rm-rf'd)" || fail ".tick was destroyed"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
