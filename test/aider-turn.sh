#!/usr/bin/env bash
# aider-turn.sh test: the Aider↔OpenRouter turn-taker drives a relay turn behind the SHARED safety
# core (relay-turn-lib.sh) — same containment as codex-turn.sh / agy-turn.sh, via a STUB `aider` that
# models Aider's behaviour (edits the files added to the chat; does NOT run tick; does NOT commit).
# Proves the two Aider-specific things: (a) the SHIM performs the token ops (take + rtl_enforce
# handoff) since Aider can't, and (b) the OPENROUTER_API_KEY pre-flight fails fast when the key is
# absent. Also proves the model-agnostic containment (off-lane revert, commit-bypass reset, isolation).
source "$(dirname "$0")/_setup.sh" aider-turn
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/aider-turn.sh"
tick_a init >/dev/null

# The shim + rtl_enforce resolve tick as "$TICK_REPO_ROOT/bin/tick" (CWD-independent, exactly as a real
# harness clone ships it). Provide it in the fixture root so the shim's `tick take` and rtl_enforce's
# authoritative handoff actually run; gitignore bin/ so the symlink never trips containment.
mkdir -p "$A/bin"; ln -sf "$TICK" "$A/bin/tick"
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\nbin/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

# Stub `aider`: parses --file targets + --message (ignores every other flag), then models Aider —
# edits the FIRST --file (the relay file, CWD-relative) and prints a transcript line. It NEVER runs
# tick and NEVER commits (that's the whole point: the shim owns the token, --no-auto-commits owns git).
# STUB_MODE: approve=set STATUS Approved; bad=off-allowlist file; commitbypass=git-commit off-lane;
# spacefile=off-lane path with a space; empty=exit 0 with NO output + NO edit (blocked-backend phantom).
# A throwaway non-secret value for the OPENROUTER_API_KEY pre-flight (assigned via a var, not a literal,
# so the security-scan credential-literal rule's variable-value exclusion applies).
FAKE_ORKEY="not-a-real-key"

STUB="$WORK/aider"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
files=(); while (($#)); do
  case "$1" in
    --file)    files+=("$2"); shift 2 ;;
    --message) shift 2 ;;
    *)         shift ;;
  esac
done
[ "${STUB_MODE:-good}" = empty ] && exit 0           # blocked backend: exit 0, no output, no edit
printf 'aider-stub: edited for %s\n' "${RELAY_AGENT:-?}"   # stdout -> non-empty transcript
relay="${files[0]:-relay.md}"
if [ "${STUB_MODE:-good}" = approve ]; then
  tmp="$(mktemp)"; sed 's/^STATUS:.*/STATUS: Approved/' "$relay" > "$tmp" && mv "$tmp" "$relay"
  printf '\n### Round 1 · Builder · aider-stub\n**Verdict:** Approved\n' >>"$relay"
else
  printf '\n### Round 1 · Builder · aider-stub\nDid the work.\n' >>"$relay"
fi
[ "${STUB_MODE:-good}" = bad ] && printf 'off\n' >>offlane.md
[ "${STUB_MODE:-good}" = spacefile ] && printf 'off\n' >>"off lane.md"
if [ "${STUB_MODE:-good}" = commitbypass ]; then
  printf 'sneaky\n' >>sneaky.md; git add sneaky.md >/dev/null 2>&1; git commit -q -m "aider sneaked" >/dev/null 2>&1
fi
exit 0
STUB_EOF
chmod +x "$STUB"

# seed the token open→aider (as relay-drive would after handing off to the builder)
seed_token(){ tick_a log task.created "$1" --agent boss >/dev/null; tick_a claim "$1" --agent boss --paths "z/**" >/dev/null; tick_a release "$1" --agent boss --to aider >/dev/null; }

tok_field(){ tick_a info "$1" 2>/dev/null | sed -n "s/^$2:[[:space:]]*//p" | head -1; }

run_shim(){ # <relay-task> <agent> <stub-mode> [extra env assignments...]
  local task="$1" agent="$2" mode="$3"; shift 3
  local log="$WORK/aider-out.$$.log"; : >"$log"
  env RELAY_AGENT="$agent" RELAY_FILE="$A/relay.md" RELAY_TASK="$task" AIDER_AGENT=aider RELAY_PEER=claude-a \
    AIDER_BIN="$STUB" AIDER_TURN_ROOT="$A" AIDER_LOG="$log" STUB_MODE="$mode" \
    OPENROUTER_API_KEY="$FAKE_ORKEY" TICK_REPO_ROOT="$A" "$@" \
    bash "$SHIM" >/dev/null 2>&1
}

# --- (1) defer: non-aider actor -> no-op, no commit -----------------------
seed_token RELAY-TURN-defer
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-defer claude-a good; rc=$?
[ "$rc" -eq 0 ] && [ "$(git -C "$A" rev-parse HEAD)" = "$before" ] \
  && pass "non-aider actor -> shim defers, no commit" || fail "should defer with no commit (rc=$rc)"

# --- (2) good turn: shim takes the token, aider edits, rtl_enforce commits + hands off to peer ---
seed_token RELAY-TURN-good
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-good aider good; rc=$?
[ "$rc" -eq 0 ] && pass "aider turn (good) exits 0" || fail "good turn rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "aider turn committed (file-scoped)" || fail "expected a commit"
git -C "$A" show --stat HEAD | grep -q "relay.md" && pass "commit touched the relay file" || fail "commit should include relay.md"
git -C "$A" log -1 --format='%s' | grep -q "aider headless" && pass "commit message names the aider tool" || fail "commit msg should say aider"
[ "$(tok_field RELAY-TURN-good status)" = "open" ] && [ "$(tok_field RELAY-TURN-good handoff-to)" = "claude-a" ] \
  && pass "shim handed the token to the peer (rtl_enforce GH-67, non-terminal STATUS)" \
  || fail "token not handed to peer: status=$(tok_field RELAY-TURN-good status) handoff=$(tok_field RELAY-TURN-good handoff-to)"

# --- (2b) GH-77 [Blocker]: token NOT owned by aider -> shim refuses (exit 5) before any mutation ---
# Seed a token claimed by boss and NOT handed to aider. aider's best-effort claim must miss, so the
# shim must PROVE ownership via `tick info` and fail (exit 5) BEFORE editing/committing — otherwise it
# would leave a committed turn with the token still open under the old owner (lane deadlock).
tick_a log task.created RELAY-TURN-noown --agent boss >/dev/null
tick_a claim RELAY-TURN-noown --agent boss --paths "z/**" >/dev/null
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-noown aider good; rc=$?
[ "$rc" -eq 5 ] && pass "unowned token -> shim refuses before the turn (exit 5)" || fail "unowned token should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "unowned token -> no commit made" || fail "shim committed despite not owning the token"
[ "$(tok_field RELAY-TURN-noown claimer)" = "boss" ] && pass "unowned token -> claimer still boss (no resurrection)" || fail "claimer changed: $(tok_field RELAY-TURN-noown claimer)"

# --- (3) approved turn: STATUS Approved -> rtl_enforce closes the token (tick done) -------
seed_token RELAY-TURN-appr
run_shim RELAY-TURN-appr aider approve; rc=$?
[ "$rc" -eq 0 ] && pass "aider turn (approve) exits 0" || fail "approve turn rc=$rc"
grep -q "STATUS: Approved" "$A/relay.md" && pass "aider set STATUS Approved in the relay file" || fail "STATUS not Approved"
[ "$(tok_field RELAY-TURN-appr status)" = "done" ] && pass "terminal STATUS -> token closed (tick done)" || fail "token not done: status=$(tok_field RELAY-TURN-appr status)"
# reset the relay file STATUS for later cases
git -C "$A" checkout -- relay.md 2>/dev/null || true; printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reset relay STATUS" >/dev/null 2>&1

# --- (4) off-lane edit -> reverted + fail (exit 6), shared guard ----------
seed_token RELAY-TURN-bad
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-bad aider bad; rc=$?
[ "$rc" -eq 6 ] && pass "off-allowlist edit -> shim fails (exit 6)" || fail "expected exit 6, got $rc"
[ ! -f "$A/offlane.md" ] && pass "off-lane file was reverted/removed" || fail "off-lane file should be gone"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a violating turn" || fail "should not commit on violation"
# A failed (exit 6) turn intentionally leaves the token claimed; tick caps concurrent claims per agent,
# so release aider's slot before the next case (the real driver reaps/escalates a failed lane the same way).
tick_a release RELAY-TURN-bad --agent aider --to boss >/dev/null 2>&1 || true

# --- (5) commit-bypass: aider committing off-lane -> reset + fail (proves --no-auto-commits matters) ---
seed_token RELAY-TURN-bypass
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-bypass aider commitbypass; rc=$?
[ "$rc" -eq 6 ] && pass "aider commit during turn -> shim fails (exit 6)" || fail "commit-bypass should exit 6, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "sneaked commit reset to BEFORE_HEAD" || fail "HEAD should reset"
[ ! -f "$A/sneaky.md" ] && pass "off-lane committed file removed by reset" || fail "sneaky.md should be gone"
tick_a release RELAY-TURN-bypass --agent aider --to boss >/dev/null 2>&1 || true  # free aider's slot (see case 4)

# --- (6) quoted path: off-lane file with a space -> reverted + fail -------
seed_token RELAY-TURN-space
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-space aider spacefile; rc=$?
[ "$rc" -eq 6 ] && pass "off-lane path with space -> shim fails (exit 6)" || fail "spacefile should exit 6, got $rc"
[ ! -f "$A/off lane.md" ] && pass "spaced off-lane file reverted (-z parsing)" || fail "'off lane.md' should be removed"
tick_a release RELAY-TURN-space --agent aider --to boss >/dev/null 2>&1 || true  # free aider's slot (see case 4)

# --- (7) empty output on clean exit -> fail (exit 5) ----------------------
seed_token RELAY-TURN-empty
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-empty aider empty; rc=$?
[ "$rc" -eq 5 ] && pass "empty-output-on-exit-0 -> shim fails (exit 5)" || fail "empty output should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a phantom/empty turn" || fail "empty turn must not commit"
tick_a release RELAY-TURN-empty --agent aider --to boss >/dev/null 2>&1 || true  # free aider's slot (see case 4)

# --- (8) AIDER-SPECIFIC: missing OPENROUTER_API_KEY -> fail fast (exit 5) before any mutation ---
seed_token RELAY-TURN-nokey
before="$(git -C "$A" rev-parse HEAD)"
log="$WORK/aider-nokey.$$.log"; : >"$log"
env -u OPENROUTER_API_KEY RELAY_AGENT=aider RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-nokey AIDER_AGENT=aider \
  RELAY_PEER=claude-a AIDER_BIN="$STUB" AIDER_TURN_ROOT="$A" AIDER_LOG="$log" STUB_MODE=good TICK_REPO_ROOT="$A" \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 5 ] && pass "missing OPENROUTER_API_KEY -> shim exits 5 before the turn" || fail "no-key should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit / no mutation when the key is missing" || fail "no-key must not mutate"

# --- (9) pre-existing dirty file is NOT reverted; turn still succeeds ------
seed_token RELAY-TURN-ambient
printf 'unrelated WIP\n' > "$A/ambient.md"
run_shim RELAY-TURN-ambient aider good; rc=$?
[ "$rc" -eq 0 ] && pass "pre-existing dirty file -> turn still succeeds" || fail "ambient WIP must not fail the turn (rc=$rc)"
[ -f "$A/ambient.md" ] && pass "pre-existing ambient WIP left untouched (not reverted)" || fail "ambient.md was destroyed (regression!)"
rm -f "$A/ambient.md"

# --- (10) worktree isolation: aider's relay edit must survive the copy-back (GH-22 shared path) ---
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reseed relay for wt-iso" >/dev/null 2>&1
seed_token RELAY-TURN-wt
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-wt aider good RELAY_WORKTREE_ISOLATION=1; rc=$?
[ "$rc" -eq 0 ] && pass "wt-iso: turn exits 0" || fail "wt-iso good turn rc=$rc"
grep -q "aider-stub" "$A/relay.md" && pass "wt-iso: aider's relay block PRESERVED (copy-back)" || fail "wt-iso: aider's output LOST"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "wt-iso: turn committed (output not dropped)" || fail "wt-iso: no commit — output discarded"

# --- (11) RELAY dispatch: the shared marathon-agent.sh (relay-drive's --agent-cmd) routes aider ----
# This is the same dispatcher a driven /relay run uses, so it proves Aider is reachable as a relay
# turn-taker, not just marathon. AIDER_AGENT=aider + RELAY_AGENT=aider -> execs aider-turn.sh.
DISPATCH="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/marathon-agent.sh"
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
git -C "$A" add relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "reseed relay for dispatch" >/dev/null 2>&1
seed_token RELAY-TURN-disp
before="$(git -C "$A" rev-parse HEAD)"
env RELAY_AGENT=aider RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-disp AIDER_AGENT=aider RELAY_PEER=claude-a \
  MARATHON_BUILDER=aider MARATHON_REVIEWER=claude-a AIDER_BIN="$STUB" AIDER_TURN_ROOT="$A" \
  AIDER_LOG="$WORK/disp.log" STUB_MODE=good OPENROUTER_API_KEY="$FAKE_ORKEY" TICK_REPO_ROOT="$A" \
  bash "$DISPATCH" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "marathon-agent.sh dispatches RELAY_AGENT=aider -> aider-turn.sh (exit 0)" || fail "dispatch exit=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "dispatched aider relay turn committed (reachable via relay --agent-cmd)" || fail "dispatched turn did not commit"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
