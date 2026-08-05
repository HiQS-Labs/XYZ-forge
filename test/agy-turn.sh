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
# S10 (GH-242): off-prompt-nonempty controlled trigger. GH-142's characterization matrix observed agy
# answer ABOUT the `--print-timeout` flag instead of the actual prompt on 2 early calls — exit 0,
# nonempty output, zero real work. Deterministically reproduce that shape: print an off-topic line and
# perform NO tool calls at all (no tick claim/ping, no relay edit, no release) before exiting 0.
if [ "${STUB_MODE:-good}" = offprompt ]; then
  printf 'The --print-timeout flag controls how long agy waits before giving up before returning.\n'
  exit 0
fi
export TICK_REPO_ROOT="$A"
printf 'agy-stub: model response for %s\n' "$RELAY_AGENT"   # stdout -> non-empty transcript
# GH-183/187 regression shapes: print lines containing $A (=ROOT) to stdout (-> AGY_LOG)
[ "${STUB_MODE:-good}" = ticknarration ] && printf 'I ran: TICK_REPO_ROOT="%s" tick claim %s --agent %s --paths "z/**"\n' "$A" "$RELAY_TASK" "$RELAY_AGENT"
[ "${STUB_MODE:-good}" = markdowncite ] && printf 'Edited [relay.md](file://%s/relay.md)\n' "$A"
[ "${STUB_MODE:-good}" = breach ] && printf 'I found the issue at %s/secret.txt\n' "$A"
"$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
"$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
# S2 role/model adherence (GH-155/F4): rolegood/roledrift read the relay file's assigned role off its
# NEXT: header (same field rtl_is_reviewer_turn reads) instead of hardcoding "Reviewer" like every other
# mode here. rolegood writes the ASSIGNED role's block and flips NEXT to the other role (compliant);
# roledrift writes the WRONG role's block and leaves NEXT unflipped (the observed F4 failure shape).
if [ "${STUB_MODE:-good}" = rolegood ] || [ "${STUB_MODE:-good}" = roledrift ]; then
  assigned="$(sed -n 's/^NEXT:[[:space:]]*//p' "$RELAY_FILE" | head -1)"
  [ -n "$assigned" ] || assigned="Producer"
  other="Reviewer"; [ "$assigned" = "Reviewer" ] && other="Producer"
  if [ "${STUB_MODE}" = rolegood ]; then
    printf '\n### Round 1 · %s · %s (agy-stub)\n**Verdict:** Changes requested\n' "$assigned" "$RELAY_AGENT" >>"$RELAY_FILE"
    sed -i.bak -E "s/^(NEXT:[[:space:]]*).*/\\1${other}/" "$RELAY_FILE" 2>/dev/null && rm -f "$RELAY_FILE.bak"
  else
    printf '\n### Round 1 · %s · %s (agy-stub)\n**Verdict:** Changes requested\n' "$other" "$RELAY_AGENT" >>"$RELAY_FILE"
  fi
else
  printf '\n### Round 1 · Reviewer · %s (agy-stub)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
fi
"$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
[ "${STUB_MODE:-good}" = bad ] && printf 'off-lane\n' >>"$A/offlane.md"
# S5 distraction (GH-155/F3): models the 2026-06-17 dogfood shape — an agy turn distracted by stray
# tree files makes an off-lane edit. agy-turn.sh has no PATH-shadow of its own (unlike claude-turn.sh's
# CLAUDE_BLOCK_CMDS), so the off-lane edit is what the shared allowlist guard (rtl_enforce) must catch.
[ "${STUB_MODE:-good}" = distract ] && printf 'off-lane\n' >>"$A/distracted-offlane.md"
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

# --- (13) GH-183: tick-command narration in transcript must NOT false-positive isolation check ---
seed_token RELAY-TURN-ticknarr
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reseed relay for tick-narration test" >/dev/null 2>&1
ticklog="$WORK/agy-ticknarr.$$.log"; : >"$ticklog"
RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-ticknarr AGY_AGENT=agy \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$ticklog" STUB_MODE=ticknarration RELAY_WORKTREE_ISOLATION=1 \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "GH-183: tick-command narration -> turn succeeds (not a breach)" || fail "tick-narration should exit 0, got $rc"
grep -q "agy-stub" "$A/relay.md" && pass "GH-183: tick-narration turn committed relay block" || fail "tick-narration: relay output lost"

# --- (14) GH-187: markdown file:// citation in transcript must NOT false-positive isolation check ---
seed_token RELAY-TURN-markdowncite
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reseed relay for markdown-cite test" >/dev/null 2>&1
mdlog="$WORK/agy-markdowncite.$$.log"; : >"$mdlog"
RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-markdowncite AGY_AGENT=agy \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$mdlog" STUB_MODE=markdowncite RELAY_WORKTREE_ISOLATION=1 \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "GH-187: markdown file:// citation -> turn succeeds (not a breach)" || fail "markdown-cite should exit 0, got $rc"
grep -q "agy-stub" "$A/relay.md" && pass "GH-187: markdown-cite turn committed relay block" || fail "markdown-cite: relay output lost"

# --- (15) GH-410: a plain $ROOT citation is ADVISORY, not a breach — the turn survives ------------
# This case asserted exit 5 until GH-410. Naming a path is not accessing one: the same scan passed a
# phase with TEN repo-root mentions and failed one with NINE in the same run, and the harness's own
# retry preamble renders absolute paths into the relay file, so a compliant agent seeds its own
# transcript. Out-of-worktree WRITES are still enforced by rtl.worktree_end() — see
# test/gh410-containment-advisory.sh, which pins that direction so this relaxation cannot be
# mistaken for containment having been deleted.
seed_token RELAY-TURN-breach
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reseed relay for citation test" >/dev/null 2>&1
breachlog="$WORK/agy-breach.$$.log"; : >"$breachlog"
RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-breach AGY_AGENT=agy \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$breachlog" STUB_MODE=breach RELAY_WORKTREE_ISOLATION=1 \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "GH-410: plain \$ROOT citation -> turn survives (exit 0), not exit 5" || fail "GH-410: citation should exit 0, got $rc"
grep -q "agy-stub" "$A/relay.md" && pass "GH-410: the completed review is NOT discarded" || fail "GH-410: review lost on a mere citation"
grep -q "ADVISORY" "$breachlog" && pass "GH-410: the advisory is still recorded on the transcript" || fail "GH-410: advisory not recorded — traded a false positive for a blind spot"
git -C "$A" reset --hard HEAD >/dev/null 2>&1   # clean uncommitted stub block before the next case

# --- (12) GH-172 / GH-174: Python port refuses an unowned relay token before any edit ----------
tick_a log task.created RELAY-TURN-py-unowned --agent dispatcher >/dev/null
tick_a claim RELAY-TURN-py-unowned --agent intruder --paths "z/**" >/dev/null
before="$(git -C "$A" rev-parse HEAD)"
before_relay="$(cksum "$A/relay.md")"
pylog="$WORK/agy-py-unowned.$$.log"; : >"$pylog"
RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-py-unowned AGY_AGENT=agy \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$pylog" STUB_MODE=good XYZ_PYTHON=1 \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] && pass "GH-172/GH-174: XYZ_PYTHON=1 agy turn refuses an unowned token (exit 5)" || fail "python agy unowned-token guard should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "GH-172/GH-174: python agy guard blocks commits before mutation" || fail "python agy guard must not commit"
[ "$(cksum "$A/relay.md")" = "$before_relay" ] && pass "GH-172/GH-174: python agy guard leaves relay file untouched" || fail "python agy guard should not edit the relay file"

# --- (13) GH-296 follow-up: with AGY_TURN_ROOT unset, agy-turn.py's own pre-launch `tick claim
# --paths` call (claim_paths_for_turn, native Python — NOT bridged through relay-turn-lib.sh's
# already-toplevel-correcting rtl_init/GH-160) computes the claim path via os.path.relpath(relay_file,
# root). Before this fix `root` fell back to XYZ_ROOT (this repo's own top level, __file__-derived)
# instead of the CWD's git toplevel, so a relay file living in a DIFFERENT repo produced an
# escaping "../../.../relay.md" claim path instead of a clean repo-relative one. Driven with CWD=$A
# (no AGY_TURN_ROOT override) and forced Python runtime; asserts on `tick info`'s recorded paths, the
# direct observable of this native computation (a full end-to-end run isn't discriminating here,
# since relay-turn-lib.sh's own worktree/containment logic already self-corrects a wrong root via the
# unrelated GH-160 fix).
seed_token RELAY-TURN-gh296agy
pygh296log="$WORK/agy-gh296.$$.log"; : >"$pygh296log"
( cd "$A" && env RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-gh296agy AGY_AGENT=agy \
    AGY_BIN="$STUB" AGY_LOG="$pygh296log" STUB_MODE=good XYZ_PYTHON=1 \
    bash "$SHIM" ) >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "GH-296: Python agy turn (AGY_TURN_ROOT unset) exits 0" || fail "GH-296: agy turn should exit 0, got $rc"
# The shim's own PRE-LAUNCH claim (claim_paths_for_turn's real computed value) is the EARLIEST
# agy-claimed event for this task — chronologically before the stub's own hardcoded "z/**" re-claim
# (same agent, same task) — find it by filename (ISO-timestamp-prefixed, sorts correctly) rather
# than `tick info`'s current/post-release state. Excludes seed_token's own claude-a claim event
# (different agent segment in the filename).
first_claim_file="$(find "$A/.tick/events" -maxdepth 1 -name '*-agy-claimed-RELAY-TURN-gh296agy.jsonl' 2>/dev/null | sort | head -1)"
claimed_paths="$(cat "$first_claim_file" 2>/dev/null | sed -n 's/.*"paths":\[\([^]]*\)\].*/\1/p')"
case "$claimed_paths" in
  *..*) fail "GH-296: agy-turn.py's claim --paths escaped root (got: $claimed_paths) — root did not resolve to the CWD's git toplevel" ;;
  *) pass "GH-296: agy-turn.py's claim --paths stayed repo-relative, no root-escaping '..' (got: $claimed_paths)" ;;
esac

# --- (S2) AGY-SPECIFIC: role/model adherence — the acting model must write ITS ASSIGNED role's block
# and flip NEXT to the other role. F4 (sibling run feedback #4a; GH-142 Phase-1 S2): agy took a
# NEXT:-assigned Producer turn but wrote a Reviewer block and never flipped NEXT, rotating the
# model<->role binding with nothing catching it (rtl_enforce only guards the allowlist/commit boundary,
# not block-content correctness — an honor-system gap). This closes the missing regression coverage for
# the compliant round-trip (assigned role written + NEXT flipped) and locks in today's honest behavior
# for the drift shape (mismatched role + stale NEXT is NOT caught — still a live gap, not fixed here).
printf 'NEXT: Producer\nSTATUS: Open\n# relay body\n' >"$A/relay-role.md"
git -C "$A" add relay-role.md >/dev/null 2>&1; git -C "$A" commit -q -m "seed role-adherence fixture" >/dev/null 2>&1
seed_token RELAY-TURN-role-good
rolelog="$WORK/agy-role-good.$$.log"; : >"$rolelog"
RELAY_AGENT=agy RELAY_FILE="$A/relay-role.md" RELAY_TASK=RELAY-TURN-role-good AGY_AGENT=agy \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$rolelog" STUB_MODE=rolegood \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "S2: assigned-role-compliant agy turn exits 0" || fail "S2: compliant role turn rc=$rc"
grep -q '### Round 1 · Producer · agy' "$A/relay-role.md" && pass "S2: agy wrote its ASSIGNED role's block (Producer)" || fail "S2: agy should have written a Producer block"
grep -E '^NEXT:[[:space:]]*Reviewer' "$A/relay-role.md" >/dev/null && pass "S2: agy flipped NEXT to the other role (Reviewer)" || fail "S2: NEXT should be flipped to Reviewer"

printf 'NEXT: Producer\nSTATUS: Open\n# relay body\n' >"$A/relay-role.md"
git -C "$A" add relay-role.md >/dev/null 2>&1; git -C "$A" commit -q -m "reseed role-adherence fixture (drift)" >/dev/null 2>&1
seed_token RELAY-TURN-role-drift
driftlog="$WORK/agy-role-drift.$$.log"; : >"$driftlog"
RELAY_AGENT=agy RELAY_FILE="$A/relay-role.md" RELAY_TASK=RELAY-TURN-role-drift AGY_AGENT=agy \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$driftlog" STUB_MODE=roledrift \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "S2: role-drift turn still exits 0 today (honor-system gap, not enforced)" || fail "S2: role-drift turn unexpectedly failed, rc=$rc"
grep -q '### Round 1 · Reviewer · agy' "$A/relay-role.md" && pass "S2: KNOWN GAP reproduced — agy wrote the WRONG role's block (Reviewer, was assigned Producer)" || fail "S2: drift repro should show the mismatched Reviewer block"
grep -E '^NEXT:[[:space:]]*Producer' "$A/relay-role.md" >/dev/null && pass "S2: KNOWN GAP reproduced — NEXT was NOT flipped (still Producer) and nothing caught it" || fail "S2: drift repro should show NEXT left unflipped"

# --- (S5) AGY-SPECIFIC: distraction — stray tree files (unclean workspace) must not let a distracted
# agy escape containment. F3 (2026-06-17 dogfood; GH-142 Phase-1 S5): the agy builder, distracted by
# stray briefs already in the tree, ran `consult` (real external calls) + edited an off-lane file.
# agy-turn.sh has no CLAUDE_BLOCK_CMDS-style PATH-shadow of its own (that external-model-spawn block is
# claude-turn.sh/builder-only) and the clean-workspace precondition itself lives one layer up, in
# marathon-drive.sh's Step 0, outside this shim — so the containment agy-turn.sh DOES own is the shared
# allowlist guard (rtl_enforce). Confirm it still catches a distraction-driven off-lane edit even with
# stray "brief" files already sitting in the tree, and that those pre-existing stray files are left
# untouched (not swept as if they were the agent's own edit — the MBP16 [1] ambient-WIP behavior).
printf '# stray audit brief\nDo something else entirely.\n' >"$A/AUDIT-STRAY.md"
printf 'unrelated note\n' >"$A/NOTES-STRAY.md"
seed_token RELAY-TURN-distract
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-distract agy distract; rc=$?
[ "$rc" -eq 6 ] && pass "S5: distracted-by-stray-files off-lane edit -> shim fails (exit 6)" || fail "S5: distraction off-lane edit should exit 6, got $rc"
[ ! -f "$A/distracted-offlane.md" ] && pass "S5: distraction-driven off-lane edit reverted" || fail "S5: distraction off-lane file should be gone"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "S5: no commit on a distraction-driven violation" || fail "S5: distraction turn must not commit"
[ -f "$A/AUDIT-STRAY.md" ] && [ -f "$A/NOTES-STRAY.md" ] \
  && pass "S5: pre-existing stray brief files left untouched (not reverted as if agent-owned)" \
  || fail "S5: stray brief files should survive the turn untouched"
rm -f "$A/AUDIT-STRAY.md" "$A/NOTES-STRAY.md"

# --- (S8) AGY-SPECIFIC: cost-blindness — no misleading exact-0 cost.tokens event ever lands for an agy
# turn; the harness's shared cost-signal path explicitly flags agy token spend as a FLOOR (uncounted),
# never "exact". F5 (GH-142 Phase-1 S8): agy print mode emits no JSON/usage block (see this shim's
# header note (b)) — agy-turn.sh has NO cost.tokens capture at all. Confirm that holds (no fabricated 0
# in the coordination log) and confirm relay-automation/loop-cost.sh's documented agy contract (a cost
# floor; budget agy in --currency seconds instead) still reports floor/0, not exact/0 (src/cost.js's own
# convention: return null/"not captured" rather than a fake zero — loop-cost.sh mirrors that honesty).
seed_token RELAY-TURN-cost
run_shim RELAY-TURN-cost agy good; rc=$?
[ "$rc" -eq 0 ] && pass "S8: normal agy turn exits 0 (baseline for cost-blindness check)" || fail "S8: cost-blindness baseline turn rc=$rc"
if grep -rl '"type":"cost.tokens".*"task":"RELAY-TURN-cost"' "$A/.tick/events" >/dev/null 2>&1; then
  fail "S8: agy turn should NOT emit a cost.tokens event (agy has no token capture -- a captured 0 would be misleading)"
else
  pass "S8: agy turn emits no cost.tokens event (no misleading exact-0 lands in the coordination log)"
fi
LOOP_COST="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/loop-cost.sh"
lc_err="$WORK/loop-cost-agy.$$.err"; : >"$lc_err"
lc_out="$(bash "$LOOP_COST" --agent agy --currency tokens --tokens 9999 2>"$lc_err")"
lc_honesty="$(tail -1 "$lc_err")"; rm -f "$lc_err"
[ "$lc_out" = "0" ] && [ "$lc_honesty" = "floor" ] \
  && pass "S8: loop-cost.sh flags agy token spend as a FLOOR (cost-blind), never a misleading exact 0" \
  || fail "S8: loop-cost.sh should report agy as floor 0, got out=$lc_out honesty=$lc_honesty"

# --- (S10) AGY-SPECIFIC: off-prompt-nonempty — GH-242 controlled repro for GH-142's deferred S10 gap.
# agy print mode can exit 0 with NONEMPTY output that is entirely off-topic (GH-142's observed shape:
# two early calls answered ABOUT the `--print-timeout` flag instead of the actual prompt) while doing
# ZERO real turn work (no tick claim/ping by the stub, no relay edit, no release). The real shim's only
# output guard (agy-turn.sh's `! -s "$AGY_LOG"` byte-emptiness check, i.e. F1) cannot see this: the
# transcript IS nonempty, so it sails through undetected. This is a deterministic, on-demand trigger
# (unlike the original "could not re-trigger on demand" #142 observation) — the offprompt stub mode
# always emits the same off-topic line and always skips every tool call. Documents TODAY'S honest,
# uncaught behavior (no content-relevance guard exists in agy-turn.sh to assert against without landing
# a real fix there, which is out of this test file's allowlist) — same "KNOWN GAP reproduced" pattern
# as the S2 role-drift case above.
seed_token RELAY-TURN-offprompt
before="$(git -C "$A" rev-parse HEAD)"
before_relay="$(cksum "$A/relay.md")"
offlog="$WORK/agy-offprompt.$$.log"; : >"$offlog"
RELAY_AGENT=agy RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-offprompt AGY_AGENT=agy \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$A" AGY_LOG="$offlog" STUB_MODE=offprompt \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "S10: KNOWN GAP reproduced — off-prompt-nonempty turn still exits 0 (F1's empty-output guard can't see it)" || fail "S10: offprompt stub turn rc=$rc"
{ [ -s "$offlog" ] && grep -q -- "--print-timeout" "$offlog"; } \
  && pass "S10: transcript is nonempty but entirely off-topic (defeats the byte-emptiness guard)" || fail "S10: offprompt transcript should be nonempty and off-topic"
[ "$(cksum "$A/relay.md")" = "$before_relay" ] && pass "S10: KNOWN GAP reproduced — off-prompt turn performed ZERO real work (relay file untouched, uncaught)" || fail "S10: relay.md should be untouched by an off-prompt turn"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "S10: no commit on an off-prompt no-op turn" || fail "S10: off-prompt turn should not commit"
# Test hygiene: the offprompt stub deliberately performs NO tick calls (that's the repro), so
# rtl_enforce's token-handoff step falls into its "not terminal, no RELAY_PEER" warn-stuck branch and
# leaves RELAY-TURN-offprompt claimed by agy forever — itself a live instance of the same off-prompt
# "no cleanup" hazard this case documents. Force-release it here (test-suite bookkeeping, not part of
# the assertions above) so it doesn't permanently occupy one of agy's MAX_ACTIVE_CLAIMS_PER_AGENT (2)
# slots and starve a later case's claim (same latent leak already exists in the pre-existing "empty"
# stub-mode case above; this just avoids stacking a second one).
tick_a done RELAY-TURN-offprompt --agent agy >/dev/null 2>&1

# --- (9) .tick exemption independent of host .gitignore (MBP16 [2]) — LAST: mutates fixture .gitignore ---
printf '# host repo does NOT gitignore .tick\n' > "$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "drop .tick gitignore" >/dev/null 2>&1
seed_token RELAY-TURN-tickexempt
run_shim RELAY-TURN-tickexempt agy good; rc=$?
[ "$rc" -eq 0 ] && pass ".tick writes exempted when host doesn't gitignore .tick (turn succeeds)" || fail "unignored .tick must not fail the turn (rc=$rc)"
[ -d "$A/.tick" ] && pass ".tick state dir preserved (not rm-rf'd)" || fail ".tick was destroyed"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
