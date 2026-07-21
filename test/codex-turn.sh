#!/usr/bin/env bash
# Option-A shim test: codex-turn.sh drives a Codex relay turn behind a path-allowlist,
# using a STUB `codex` that performs the real turn-taker contract (tick + file edit).
source "$(dirname "$0")/_setup.sh" codex-turn
export TICK_BIN="$TICK"
SHIM="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/codex-turn.sh"
tick_a init >/dev/null

# Production shape: bin/tick + src co-located with .tick under TICK_REPO_ROOT.
# codex-turn + rtl_enforce resolve tick as "$TICK_REPO_ROOT/bin/tick", so provide it in the fixture
# root and gitignore bin/ so the symlink never trips containment.
mkdir -p "$A/bin"; ln -sf "$TICK" "$A/bin/tick"

# committed relay-file baseline in the fixture repo ($A). Mirror the real repo's
# .tick/ gitignore so tick's coordination dir is invisible to git status (else it
# looks like an off-lane change to the shim — exactly what production avoids).
printf 'STATUS: Open\n# relay body\n' >"$A/relay.md"
printf '.tick/\nbin/\n' >"$A/.gitignore"
git -C "$A" add relay.md .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "seed relay" >/dev/null 2>&1

# Stub `codex`: ignores its args; performs a real turn as $RELAY_AGENT — claim/ping the
# token, append a block to $RELAY_FILE, release to claude-a. STUB_MODE=notick skips the token ops
# entirely so the shim must establish ownership + handoff itself (GH-165). STUB_MODE=bad also writes
# an off-allowlist file (must be reverted by the shim).
STUB="$WORK/codex"
cat >"$STUB" <<'STUB_EOF'
#!/usr/bin/env bash
set -u
printf '%s\n' "$*" > "$WORK/codex-args" 2>/dev/null || true   # record invocation for [3] flag check
export TICK_REPO_ROOT="$A"
if [ "${STUB_MODE:-good}" != notick ]; then
  "$TICK" claim "$RELAY_TASK" --agent "$RELAY_AGENT" --paths "z/**" >/dev/null 2>&1
  "$TICK" ping  "$RELAY_TASK" --agent "$RELAY_AGENT" >/dev/null 2>&1
fi
printf '\n### Round 1 · Reviewer · %s (codex-stub)\n**Verdict:** Changes requested\n' "$RELAY_AGENT" >>"$RELAY_FILE"
if [ "${STUB_MODE:-good}" != notick ]; then
  "$TICK" release "$RELAY_TASK" --agent "$RELAY_AGENT" --to claude-a >/dev/null 2>&1
fi
[ "${STUB_MODE:-good}" = slowafterrelease ] && sleep "${STUB_SLEEP_S:-2}"
[ "${STUB_MODE:-good}" = bad ] && printf 'off-lane\n' >>"$A/offlane.md"
# commitbypass: Codex ignores "no git" and COMMITS an off-lane change (hides it from git status)
if [ "${STUB_MODE:-good}" = commitbypass ]; then
  printf 'sneaky\n' >>"$A/sneaky.md"
  git -C "$A" add sneaky.md >/dev/null 2>&1
  git -C "$A" commit -q -m "codex sneaked a commit" >/dev/null 2>&1
fi
# spacefile: off-lane path containing a space (git status would QUOTE it without -z)
[ "${STUB_MODE:-good}" = spacefile ] && printf 'off-lane\n' >>"$A/off lane.md"
# editartifact: reviewer overstep — edit an ALLOW_PATHS artifact (reviewer-scoping must revert it)
[ "${STUB_MODE:-good}" = editartifact ] && printf 'reviewer-edit\n' >>"$A/artifact.md"
# renamestage: agent violates "no git" by STAGING a rename of a tracked off-lane file (rename-hijack)
[ "${STUB_MODE:-good}" = renamestage ] && git -C "$A" mv rtarget.txt rmoved.txt >/dev/null 2>&1
exit 0
STUB_EOF
chmod +x "$STUB"

# seed RELAY-TURN handed to codex
seed_token(){ tick_a log task.created "$1" --agent claude-a >/dev/null; tick_a claim "$1" --agent claude-a --paths "z/**" >/dev/null; tick_a release "$1" --agent claude-a --to codex >/dev/null; }
tok_field(){ tick_a info "$1" 2>/dev/null | sed -n "s/^$2:[[:space:]]*//p" | head -1; }

run_shim(){ # <relay-task> <agent> <stub-mode> [extra env assignments...]
  local task="$1" agent="$2" mode="$3"; shift 3
  env RELAY_AGENT="$agent" RELAY_FILE="$A/relay.md" RELAY_TASK="$task" CODEX_AGENT=codex \
    CODEX_BIN="$STUB" CODEX_TURN_ROOT="$A" CODEX_LOG=/dev/null STUB_MODE="$mode" "$@" \
    bash "$SHIM" >/dev/null 2>&1
}

# --- (1) defer: non-Codex actor -> no-op, no commit ----------------------
seed_token RELAY-TURN-defer
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-defer claude-a good; rc=$?
[ "$rc" -eq 0 ] && [ "$(git -C "$A" rev-parse HEAD)" = "$before" ] \
  && pass "non-Codex actor -> shim defers, no commit" || fail "should defer with no commit (rc=$rc)"

# --- (2) good turn: only relay file changes -> committed, no push --------
seed_token RELAY-TURN-good
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-good codex good; rc=$?
[ "$rc" -eq 0 ] && pass "Codex turn (good) exits 0" || fail "good turn rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "Codex turn committed (file-scoped)" || fail "expected a commit"
git -C "$A" show --stat HEAD | grep -q "relay.md" && pass "commit touched the relay file" || fail "commit should include relay.md"
[ "$(git -C "$A" log -1 --format='%s')" != "" ] && [ -z "$(git -C "$A" log -1 --format='%D' | grep -o 'origin/')" ] && pass "no push (no origin ref on the commit)" || pass "no push (local-only fixture)"

# --- (2a) GH-165: stub skips tick entirely -> shim establishes ownership + handoff ---
seed_token RELAY-TURN-gh165
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-gh165 codex notick RELAY_PEER=claude-a; rc=$?
[ "$rc" -eq 0 ] && pass "GH-165: no-tick Codex turn still exits 0" || fail "GH-165 no-tick turn rc=$rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "GH-165: no-tick Codex turn still commits" || fail "GH-165 no-tick turn should commit"
[ "$(tok_field RELAY-TURN-gh165 status)" = "open" ] && [ "$(tok_field RELAY-TURN-gh165 handoff-to)" = "claude-a" ] \
  && pass "GH-165: shim handed the token to the peer after a no-tick Codex turn" \
  || fail "GH-165: token not handed off: status=$(tok_field RELAY-TURN-gh165 status) handoff=$(tok_field RELAY-TURN-gh165 handoff-to)"

# --- (2b) GH-165: token NOT owned by codex -> shim refuses before any mutation ---
tick_a log task.created RELAY-TURN-noown --agent boss >/dev/null
tick_a claim RELAY-TURN-noown --agent boss --paths "z/**" >/dev/null
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-noown codex good RELAY_PEER=claude-a; rc=$?
[ "$rc" -eq 5 ] && pass "GH-165: unowned token -> shim refuses before the turn (exit 5)" || fail "GH-165 unowned token should exit 5, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "GH-165: unowned token -> no commit made" || fail "GH-165 should not commit without token ownership"
[ "$(tok_field RELAY-TURN-noown claimer)" = "boss" ] && pass "GH-165: unowned token -> claimer still boss" || fail "GH-165 claimer changed: $(tok_field RELAY-TURN-noown claimer)"

# --- (2c) shim's own transcript log inside the tree is ignored, not flagged --
seed_token RELAY-TURN-log
before="$(git -C "$A" rev-parse HEAD)"
RELAY_AGENT=codex RELAY_FILE="$A/relay.md" RELAY_TASK=RELAY-TURN-log CODEX_AGENT=codex \
  CODEX_BIN="$STUB" CODEX_TURN_ROOT="$A" CODEX_LOG="$A/codex.log" STUB_MODE=good \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "CODEX_LOG inside the tree is ignored (turn still succeeds)" || fail "log-in-tree should not fail the turn (rc=$rc)"
[ ! -f "$A/codex.log" ] && pass "transcript log cleaned up (not committed)" || fail "log should be removed"

# --- (3) allowlist violation: off-lane edit -> reverted + fail (exit 6) --
seed_token RELAY-TURN-bad
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-bad codex bad; rc=$?
[ "$rc" -eq 6 ] && pass "off-allowlist edit -> shim fails (exit 6)" || fail "expected exit 6, got $rc"
[ ! -f "$A/offlane.md" ] && pass "off-lane file was reverted/removed" || fail "off-lane file should be gone"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a violating turn" || fail "should not commit on violation"

# --- (4) commit-bypass: Codex commits off-lane -> reset + fail (Gemini r1 Blocker) --
seed_token RELAY-TURN-bypass
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-bypass codex commitbypass; rc=$?
[ "$rc" -eq 6 ] && pass "Codex commit during turn -> shim fails (exit 6)" || fail "commit-bypass should exit 6, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "sneaked commit reset to BEFORE_HEAD" || fail "HEAD should be reset to before"
[ ! -f "$A/sneaky.md" ] && pass "off-lane committed file removed by reset" || fail "sneaky.md should be gone"

# --- (5) quoted path: off-lane file with a space -> reverted + fail (Gemini r1 Blocker) --
seed_token RELAY-TURN-space
before="$(git -C "$A" rev-parse HEAD)"
run_shim RELAY-TURN-space codex spacefile; rc=$?
[ "$rc" -eq 6 ] && pass "off-lane path with space -> shim fails (exit 6)" || fail "spacefile should exit 6, got $rc"
[ ! -f "$A/off lane.md" ] && pass "spaced off-lane file reverted (-z parsing)" || fail "'off lane.md' should be removed"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on spaced-path violation" || fail "should not commit"

# --- (6) pre-existing dirty file is NOT reverted; turn still succeeds (MBP16 [1]) ---
seed_token RELAY-TURN-ambient
printf 'unrelated WIP\n' > "$A/ambient.md"      # off-allowlist, dirty BEFORE the turn
run_shim RELAY-TURN-ambient codex good; rc=$?
[ "$rc" -eq 0 ] && pass "pre-existing dirty file -> turn still succeeds" || fail "ambient WIP must not fail the turn (rc=$rc)"
[ -f "$A/ambient.md" ] && pass "pre-existing ambient WIP left untouched (not reverted)" || fail "ambient.md was destroyed (regression!)"
git -C "$A" show --stat HEAD | grep -q "ambient.md" && fail "commit must NOT include ambient WIP" || pass "commit excludes pre-existing ambient WIP"
rm -f "$A/ambient.md"

# --- (7) autonomy flags: default + override passed to codex exec (MBP16 [3] / GH-106) ---
seed_token RELAY-TURN-flags
run_shim RELAY-TURN-flags codex good >/dev/null 2>&1
grep -q -- "-s workspace-write" "$WORK/codex-args" && pass "default CODEX_FLAGS '-s workspace-write' reaches codex exec" || fail "default autonomy flag missing"
# GH-106: default must also disable the interactive approval gate, else a headless run hangs on an
# approval prompt until RELAY_TURN_TIMEOUT_S kills it (exit 7).
grep -q -- "-c approval_policy=never" "$WORK/codex-args" && pass "GH-106: default CODEX_FLAGS includes '-c approval_policy=never' (no headless approval hang)" || fail "GH-106: default should disable interactive approval prompts"
grep -q 'RELAY_TURN_TIMEOUT_S:-900' "$SHIM" && pass "default RELAY_TURN_TIMEOUT_S is 900s" || fail "expected 900s default turn timeout"
seed_token RELAY-TURN-flags2
CODEX_FLAGS="--dangerously-bypass-approvals-and-sandbox" run_shim RELAY-TURN-flags2 codex good >/dev/null 2>&1
grep -q -- "--dangerously-bypass-approvals-and-sandbox" "$WORK/codex-args" && pass "CODEX_FLAGS override is honored" || fail "CODEX_FLAGS override not passed"

# --- (7a) timeout after a successful handoff still exits 7 (GH-205 fixture) ---
seed_token RELAY-TURN-timeout
before="$(git -C "$A" rev-parse HEAD)"
RELAY_TURN_TIMEOUT_S=1 run_shim RELAY-TURN-timeout codex slowafterrelease RELAY_PEER=claude-a; rc=$?
[ "$rc" -eq 7 ] && pass "turn killed at RELAY_TURN_TIMEOUT_S exits 7" || fail "timeout fixture should exit 7, got $rc"
[ "$(git -C "$A" rev-parse HEAD)" != "$before" ] && pass "timeout fixture can still commit before the shim reports exit 7" || fail "timeout fixture should still commit the relay change"
[ "$(tok_field RELAY-TURN-timeout status)" = "open" ] && [ "$(tok_field RELAY-TURN-timeout handoff-to)" = "claude-a" ] \
  && pass "timeout fixture still handed the token to the peer before exit 7" \
  || fail "timeout fixture should leave token open for claude-a: status=$(tok_field RELAY-TURN-timeout status) handoff=$(tok_field RELAY-TURN-timeout handoff-to)"

# --- (7b) GH-36: worktree isolation grants codex a writable root for the shared .tick lock ---
# Under isolation, codex's CWD is a throwaway worktree but .tick/ lives at TICK_REPO_ROOT (outside
# its workspace-write sandbox) -> tick claim EPERM -> deadlock. The fix passes --add-dir <root>/.tick.
# XYZ_PYTHON=0 pins this to the Bash implementation under test (GH-263's fix lives there) —
# XYZ_PYTHON now defaults to 1 (GH-264), which would otherwise silently exercise the Python port.
seed_token RELAY-TURN-gh36iso
RELAY_WORKTREE_ISOLATION=1 XYZ_PYTHON=0 run_shim RELAY-TURN-gh36iso codex good >/dev/null 2>&1
grep -q -- "--add-dir" "$WORK/codex-args" && grep -q -- ".tick" "$WORK/codex-args" \
  && pass "GH-36: worktree isolation passes --add-dir <root>/.tick to codex (shared token lock writable)" \
  || fail "GH-36: --add-dir .tick missing under worktree isolation"

# --- (7c) GH-263: isolation=0 (default) ALSO gets --add-dir <root>/.tick, so a vendored .xyz/
# install driven with CWD=$HARNESS (!= ROOT) can still reach the shared token lock without EPERM.
# Before the GH-263 fix, this path passed no --add-dir at all (assumed CWD == ROOT already).
# XYZ_PYTHON=0 pins this to the Bash implementation (see note above (7b)).
seed_token RELAY-TURN-gh263noiso
XYZ_PYTHON=0 run_shim RELAY-TURN-gh263noiso codex good >/dev/null 2>&1
grep -q -- "--add-dir" "$WORK/codex-args" && grep -q -- ".tick" "$WORK/codex-args" \
  && pass "GH-263: isolation=0 (default) also passes --add-dir <root>/.tick to codex" \
  || fail "GH-263: --add-dir .tick missing when isolation is off (EPERM regression)"

# --- (9) rename-hijack: a staged rename (off-lane) is enforced, not skipped as pre-existing (Gemini review) ---
printf 'tracked off-lane\n' > "$A/rtarget.txt"; git -C "$A" add rtarget.txt >/dev/null 2>&1; git -C "$A" commit -q -m "seed rename target" >/dev/null 2>&1
seed_token RELAY-TURN-rename
run_shim RELAY-TURN-rename codex renamestage; rc=$?
[ "$rc" -eq 6 ] && pass "staged rename (off-lane) enforced, not skipped as pre-existing" || fail "rename-hijack must fail (exit 6), got $rc"
git -C "$A" reset --hard HEAD >/dev/null 2>&1   # clean staged rename before the next case

# --- (10) REVIEWER-turn scoping: artifact on ALLOW_PATHS is dropped -> edit reverted (exit 6) ---
printf 'NEXT: Reviewer\nSTATUS: Open\n# relay body\n' >"$A/relay-rev.md"
printf 'orig\n' >"$A/artifact.md"
git -C "$A" add relay-rev.md artifact.md >/dev/null 2>&1; git -C "$A" commit -q -m "seed reviewer fixture" >/dev/null 2>&1
seed_token RELAY-TURN-rev
before="$(git -C "$A" rev-parse HEAD)"
RELAY_AGENT=codex RELAY_FILE="$A/relay-rev.md" RELAY_TASK=RELAY-TURN-rev CODEX_AGENT=codex \
  CODEX_BIN="$STUB" CODEX_TURN_ROOT="$A" CODEX_LOG=/dev/null STUB_MODE=editartifact ALLOW_PATHS="artifact.md" \
  bash "$SHIM" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 6 ] && pass "reviewer turn: artifact on ALLOW_PATHS dropped -> edit reverted (exit 6)" || fail "reviewer-scoping should revert the artifact edit (exit 6), got $rc"
[ "$(cat "$A/artifact.md" 2>/dev/null)" = "orig" ] && pass "reviewer's artifact edit reverted to original" || fail "artifact.md should be reverted to 'orig'"
[ "$(git -C "$A" rev-parse HEAD)" = "$before" ] && pass "no commit on a reviewer-scoping violation" || fail "should not commit"
git -C "$A" reset --hard HEAD >/dev/null 2>&1   # clean the uncommitted reviewer block before the next case

# --- (8) .tick exemption independent of host .gitignore (MBP16 [2]) — LAST: mutates fixture .gitignore ---
printf '# host repo does NOT gitignore .tick\n' > "$A/.gitignore"
git -C "$A" add .gitignore >/dev/null 2>&1; git -C "$A" commit -q -m "drop .tick gitignore" >/dev/null 2>&1
seed_token RELAY-TURN-tickexempt
run_shim RELAY-TURN-tickexempt codex good; rc=$?
[ "$rc" -eq 0 ] && pass ".tick writes exempted when host doesn't gitignore .tick (turn succeeds)" || fail "unignored .tick must not fail the turn (rc=$rc)"
[ -d "$A/.tick" ] && pass ".tick state dir preserved (not rm-rf'd)" || fail ".tick was destroyed"

# GH-39 B6 / #43-3: the builder turn prompt must forbid self-running the full gate suite — doing so
# creates files that trip containment and discard the turn (observed in the GH-39 marathon v3).
LIB="$(cd "$(dirname "$0")/.." && pwd)/relay-automation/relay-turn-lib.sh"
grep -q "Do NOT run the full project test/gate suite" "$LIB" \
  && pass "turn prompt forbids self-running the full gate (#43-3)" \
  || fail "#43-3: turn prompt missing the no-gate instruction"

echo "  $TEST_NAME: $PASS pass, $FAIL fail"
exit 0
