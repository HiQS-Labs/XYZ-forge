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
for arg in "$@"; do
  if [ "$arg" = "--help" ]; then
    if [ "${STUB_HAS_ADD_GITIGNORE_FILES:-0}" = 1 ]; then
      printf '  --add-gitignore-files  Add gitignored files to the chat\n'
    else
      printf 'aider help without the legacy gitignore flag\n'
    fi
    exit 0
  fi
done
# GH-119 test hook: when the test sets ARGS_DUMP, record exactly what the shim constructed —
if [ -n "${ARGS_DUMP:-}" ]; then
  echo "$@" > "${ARGS_DUMP}.all"
fi
files=(); reads=(); chf=".aider.chat.history.md"; while (($#)); do
  case "$1" in
    --file)              files+=("$2"); shift 2 ;;
    --read)              reads+=("$2"); shift 2 ;;
    --message)           shift 2 ;;
    --chat-history-file) chf="$2"; shift 2 ;;
    *)                   shift ;;
  esac
done
# --file (writable) vs --read (structurally read-only) — so the test can assert on the split
# without inventing a new inspection mechanism (mirrors how this stub already models Aider itself).
if [ -n "${ARGS_DUMP:-}" ]; then
  : >"$ARGS_DUMP"
  [ ${#files[@]} -gt 0 ] && for f in "${files[@]}"; do printf 'FILE:%s\n' "$f" >>"$ARGS_DUMP"; done
  [ ${#reads[@]} -gt 0 ] && for r in "${reads[@]}"; do printf 'READ:%s\n' "$r" >>"$ARGS_DUMP"; done
fi
[ "${STUB_MODE:-good}" = empty ] && exit 0           # blocked backend: exit 0, no output, no edit
printf 'aider-stub: edited for %s\n' "${RELAY_AGENT:-?}"   # stdout -> non-empty transcript
# Mimic real Aider: it ALWAYS writes a chat-history file, defaulting to .aider.chat.history.md in CWD.
# The shim MUST redirect it out of the repo (--chat-history-file); if it doesn't, the file lands as an
# untracked off-allowlist change and trips the guard (exit 6) — the GH-77 live-E2E bug. Honoring the
# flag here makes a future removal of the redirect detectable (the good-turn case would flip to exit 6).
mkdir -p "$(dirname "$chf")" 2>/dev/null || true; printf 'stub chat history\n' >>"$chf"
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
# GH-77 live-E2E regression: real Aider writes .aider.chat.history.md (the stub now mimics this). The shim
# MUST redirect it out of the repo via --chat-history-file; if the redirect is dropped, the file leaks
# untracked into the tree and the good turn above flips to exit 6. Assert nothing .aider.* leaked.
[ -z "$(ls -a "$A" 2>/dev/null | grep -i '^\.aider')" ] && pass "aider aux/history files redirected out of the tree (no .aider.* leak)" || fail "an .aider.* aux file leaked into the working tree (would trip off-allowlist, exit 6)"

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

# --- (12) GH-119: review-only turn (ALLOW_PATHS unset) — a file the reviewed diff touches must be
# passed as --read (structurally read-only, even under --yes-always), NEVER as --file (writable), so
# a model that spots the file in the diff text cannot slip an off-lane edit past containment.
mkdir -p "$A/src"; printf 'target content\n' >"$A/src/target.txt"
git -C "$A" add src/target.txt >/dev/null 2>&1; git -C "$A" commit -q -m "seed GH-119 target file" >/dev/null 2>&1
ARTIFACT="$WORK/gh119-review.diff"
cat >"$ARTIFACT" <<'DIFF_EOF'
diff --git a/src/target.txt b/src/target.txt
index 1111111..2222222 100644
--- a/src/target.txt
+++ b/src/target.txt
@@ -1 +1 @@
-target content
+target content, revised
DIFF_EOF
ARGS_DUMP="$WORK/gh119-args.$$"
seed_token RELAY-TURN-gh119
run_shim RELAY-TURN-gh119 aider good RELAY_ARTIFACT_FILE="$ARTIFACT" ARGS_DUMP="$ARGS_DUMP"; rc=$?
[ "$rc" -eq 0 ] && pass "GH-119: review-only turn with a reviewed artifact still exits 0" || fail "GH-119 turn rc=$rc"
grep -qx "READ:src/target.txt" "$ARGS_DUMP" 2>/dev/null \
  && pass "GH-119: diff-referenced file passed as --read" \
  || fail "GH-119: src/target.txt not passed as --read (dump: $(cat "$ARGS_DUMP" 2>/dev/null))"
if grep -qx "FILE:src/target.txt" "$ARGS_DUMP" 2>/dev/null; then
  fail "GH-119: src/target.txt must NOT be passed as --file (writable) on a review-only turn"
else
  pass "GH-119: diff-referenced file NOT passed as --file (structurally un-writable)"
fi
grep -qx "READ:$ARTIFACT" "$ARGS_DUMP" 2>/dev/null \
  && pass "GH-119: the reviewed artifact itself is passed as --read" \
  || fail "GH-119: artifact path not passed as --read"

# --- (13) GH-168 + GH-186: gitignore relay file still reaches aider across version drift. Old aider
# builds may still advertise/require --add-gitignore-files, while current builds removed it and now
# hard-fail if the flag is passed. The shim must decide from runtime CLI support, not hardcode either.
mkdir -p "$A/ignored-dir"
printf 'STATUS: Open\n# relay body\n' >"$A/ignored-dir/relay.md"
printf 'ignored-dir/\n' >>"$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1; git -C "$A" add -f ignored-dir/relay.md >/dev/null 2>&1; git -C "$A" commit -q -m "ignore ignored-dir" >/dev/null 2>&1
seed_token RELAY-TURN-gh168
ARGS_DUMP="$WORK/gh168-args.$$"
run_shim RELAY-TURN-gh168 aider good RELAY_FILE="$A/ignored-dir/relay.md" ARGS_DUMP="$ARGS_DUMP" STUB_HAS_ADD_GITIGNORE_FILES=1; rc=$?
[ "$rc" -eq 0 ] && pass "GH-168/GH-186: old aider turn exits 0" || fail "GH-168 old-aider turn rc=$rc"
grep -q -- "--no-gitignore" "${ARGS_DUMP}.all" 2>/dev/null \
  && pass "GH-168/GH-186: old aider still gets --no-gitignore" \
  || fail "GH-168 old-aider: --no-gitignore missing"
grep -q -- "--add-gitignore-files" "${ARGS_DUMP}.all" 2>/dev/null \
  && pass "GH-168/GH-186: old aider gets --add-gitignore-files when supported" \
  || fail "GH-168 old-aider: legacy --add-gitignore-files flag missing"
grep -qx "FILE:ignored-dir/relay.md" "$ARGS_DUMP" 2>/dev/null \
  && pass "GH-168/GH-186: old aider still sees the gitignored relay file as --file" \
  || fail "GH-168 old-aider: ignored-dir/relay.md not passed as --file (dump: $(cat "$ARGS_DUMP" 2>/dev/null))"

tick_a release RELAY-TURN-gh168 --agent aider --to boss >/dev/null 2>&1 || true
seed_token RELAY-TURN-gh186
ARGS_DUMP="$WORK/gh186-args.$$"
run_shim RELAY-TURN-gh186 aider good RELAY_FILE="$A/ignored-dir/relay.md" ARGS_DUMP="$ARGS_DUMP" STUB_HAS_ADD_GITIGNORE_FILES=0; rc=$?
[ "$rc" -eq 0 ] && pass "GH-168/GH-186: current aider turn exits 0" || fail "GH-186 current-aider turn rc=$rc"
grep -q -- "--add-gitignore-files" "${ARGS_DUMP}.all" 2>/dev/null \
  && fail "GH-186: current aider must NOT receive removed --add-gitignore-files flag" \
  || pass "GH-186: current aider omits the removed --add-gitignore-files flag"
grep -q -- "--no-gitignore" "${ARGS_DUMP}.all" 2>/dev/null \
  && pass "GH-186: current aider still gets --no-gitignore" \
  || fail "GH-186 current-aider: --no-gitignore missing"
grep -qx "FILE:ignored-dir/relay.md" "$ARGS_DUMP" 2>/dev/null \
  && pass "GH-186: current aider still sees the gitignored relay file as --file" \
  || fail "GH-186 current-aider: ignored-dir/relay.md not passed as --file (dump: $(cat "$ARGS_DUMP" 2>/dev/null))"

# --- (14) GH-147 Phase 2 (LM_STUDIO lane): AIDER_OPENAI_API_BASE selects the LM Studio / OpenAI-
# compatible seam — the shim must NOT require OPENROUTER_API_KEY on this seam, must pass
# --openai-api-base/--openai-api-key (dummy default) through to aider, and must default the model to
# openai/agents-a1 (mirrors consult.sh's run_aider(), same GH-147 env-var contract).
seed_token RELAY-TURN-lmstudio
before="$(git -C "$A" rev-parse HEAD)"
ARGS_DUMP="$WORK/lmstudio-args.$$"
log="$WORK/aider-lmstudio.$$.log"; : >"$log"
env -u OPENROUTER_API_KEY RELAY_AGENT=aider RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-lmstudio \
  AIDER_AGENT=aider RELAY_PEER=claude-a AIDER_BIN="$STUB" AIDER_TURN_ROOT="$A" AIDER_LOG="$log" \
  STUB_MODE=good TICK_REPO_ROOT="$A" AIDER_OPENAI_API_BASE="http://127.0.0.1:1234/v1" \
  ARGS_DUMP="$ARGS_DUMP" \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "GH-147: LM Studio seam (no OPENROUTER_API_KEY) -> turn still succeeds" || fail "LM Studio seam should not require OPENROUTER_API_KEY (rc=$rc)"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "GH-147: LM Studio seam turn committed" || fail "LM Studio seam turn should have committed"
grep -q -- "--openai-api-base http://127.0.0.1:1234/v1" "${ARGS_DUMP}.all" 2>/dev/null \
  && pass "GH-147: LM Studio base URL passed to aider" || fail "GH-147: --openai-api-base missing/wrong (dump: $(cat "${ARGS_DUMP}.all" 2>/dev/null))"
grep -q -- "--openai-api-key dummy" "${ARGS_DUMP}.all" 2>/dev/null \
  && pass "GH-147: LM Studio dummy key default passed to aider" || fail "GH-147: --openai-api-key dummy missing"
grep -q -- "--model openai/agents-a1" "${ARGS_DUMP}.all" 2>/dev/null \
  && pass "GH-147: LM Studio default model (openai/agents-a1) selected" || fail "GH-147: default model wrong"
tick_a release RELAY-TURN-lmstudio --agent aider --to boss >/dev/null 2>&1 || true  # free aider's slot (see case 4)

# --- (15) GH-147: explicit AIDER_OPENAI_API_KEY + AIDER_MODEL override the LM Studio defaults --------
seed_token RELAY-TURN-lmstudio-key
ARGS_DUMP="$WORK/lmstudio-key-args.$$"
log="$WORK/aider-lmstudio-key.$$.log"; : >"$log"
env -u OPENROUTER_API_KEY RELAY_AGENT=aider RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-lmstudio-key \
  AIDER_AGENT=aider RELAY_PEER=claude-a AIDER_BIN="$STUB" AIDER_TURN_ROOT="$A" AIDER_LOG="$log" \
  STUB_MODE=good TICK_REPO_ROOT="$A" AIDER_OPENAI_API_BASE="http://127.0.0.1:1234/v1" \
  AIDER_OPENAI_API_KEY="sk-local-test" AIDER_MODEL="openai/custom-model" \
  ARGS_DUMP="$ARGS_DUMP" \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "GH-147: LM Studio seam with explicit key/model -> turn succeeds" || fail "LM Studio explicit key/model turn rc=$rc"
grep -q -- "--openai-api-key sk-local-test" "${ARGS_DUMP}.all" 2>/dev/null \
  && pass "GH-147: explicit AIDER_OPENAI_API_KEY overrides the dummy default" || fail "GH-147: explicit key not passed through"
grep -q -- "--model openai/custom-model" "${ARGS_DUMP}.all" 2>/dev/null \
  && pass "GH-147: explicit AIDER_MODEL overrides the LM Studio default" || fail "GH-147: explicit model not passed through"
tick_a release RELAY-TURN-lmstudio-key --agent aider --to boss >/dev/null 2>&1 || true  # free aider's slot (see case 4)

# --- (16) GH-147 regression guard: default (OpenRouter) path stays byte-identical when
# AIDER_OPENAI_API_BASE is unset — no --openai-api-base/--openai-api-key flags leak into the
# invocation, and the OpenRouter default model is still selected (case 8 already proves the
# missing-OPENROUTER_API_KEY failure path; this proves the positive default path emits no LM Studio flags).
seed_token RELAY-TURN-default
ARGS_DUMP="$WORK/default-args.$$"
run_shim RELAY-TURN-default aider good ARGS_DUMP="$ARGS_DUMP"; rc=$?
[ "$rc" -eq 0 ] && pass "GH-147: default OpenRouter path (no AIDER_OPENAI_API_BASE) still exits 0" || fail "default path rc=$rc"
grep -q -- "--openai-api-base" "${ARGS_DUMP}.all" 2>/dev/null \
  && fail "GH-147: default path must NOT emit --openai-api-base" \
  || pass "GH-147: default path emits no --openai-api-base (byte-identical)"
grep -q -- "--model openrouter/anthropic/claude-3.5-sonnet" "${ARGS_DUMP}.all" 2>/dev/null \
  && pass "GH-147: default path still uses the OpenRouter default model" || fail "GH-147: default model regressed"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
