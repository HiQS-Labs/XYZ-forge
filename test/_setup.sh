#!/usr/bin/env bash
# Shared setup for tick test scripts. Source this from each test.
#
# Run 2: local transport — both agents share TICK_REPO_ROOT=$A. tick_b is an
# alias for tick_a; git push/pull between clones is not needed for event
# visibility. $B and $REMOTE are retained for tests that still use git
# operations (e.g. git config user.name), but coordination state lives in $A.
#
# Provides:
#   $TICK     — path to bin/tick
#   $WORK     — temp working dir for this test
#   $REMOTE   — bare remote repo path
#   $A        — shared TICK_REPO_ROOT (both tick_a and tick_b read/write here)
#   $B        — second git clone (kept for git ops; NOT used as TICK_REPO_ROOT)
#   tick_a    — run tick with TICK_REPO_ROOT=$A
#   tick_b    — run tick with TICK_REPO_ROOT=$A (same as tick_a)
#   tick_in   — run tick in arbitrary root: tick_in <dir> <args...>
#   pass / fail — assertion helpers; tests exit 1 on first fail
#
# Usage: source _setup.sh <test-name>

set -u
set -o pipefail

# Clean up ambient environment variables that can leak and break tests.
# Each test case sets the relay/aider env it actually needs, so inherited runner
# state should never decide whether the shim behaves like a builder or reviewer.
for _var in \
  RELAY_WORKTREE_ISOLATION \
  ALLOW_PATHS \
  RELAY_ARTIFACT_FILE \
  RELAY_FILE \
  RELAY_TASK \
  RELAY_AGENT \
  AIDER_AGENT \
  AIDER_FLAGS \
  AIDER_MODEL \
  RELAY_PEER \
  RTL_ARTIFACT \
  RTL_LOG \
  RTL_TRACE
do
  unset "$_var"
done

TEST_NAME="${1:-unnamed}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TICK="$(cd "$HERE/.." && pwd)/bin/tick"
export TICK

WORK="$(mktemp -d -t "tick-${TEST_NAME}.XXXXXX")"
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/fixture-guard.sh"   # GH-10: shared fixture containment
fixture_guard_init "$WORK"   # GH-10: pin the sandbox root
export WORK
# Most tests end with a bare `exit 0`, which is correct under fail-fast (a failed
# assertion exits 1 before reaching it). Under TEST_SOFT_FAIL=1 that would report
# a failing file as green, so the trap re-asserts a non-zero code when any
# assertion failed. With TEST_SOFT_FAIL unset this preserves the code verbatim.
trap '_rc=$?; rm -rf "$WORK"; if [ "${TEST_SOFT_FAIL:-0}" = "1" ] && [ "${FAIL:-0}" -gt 0 ]; then exit 1; fi; exit "$_rc"' EXIT

REMOTE="$WORK/remote.git"
A="$WORK/agent-a"
B="$WORK/agent-b"
export REMOTE A B

# -b main is load-bearing, not cosmetic. Without it the bare repo's HEAD follows the machine's
# init.defaultBranch, which git still defaults to `master` when unset. Only `main` is ever pushed
# below, so on such a host the remote HEAD points at a ref that never comes into existence: every
# clone warns "remote HEAD refers to nonexistent ref, unable to checkout" and lands with an UNBORN
# HEAD and no commits. Anything that then asks for HEAD — `git worktree add --detach <p> HEAD` in
# rtl_worktree_begin, for one — dies with "invalid reference: HEAD", and the suite fails for a
# reason that has nothing to do with what it is testing. Pinning it here removes the suite's silent
# dependency on a global git setting no doc mentions.
git init -q --bare -b main "$REMOTE"

# Seed remote with an empty initial commit so clones have something to track.
SEED="$WORK/.seed"
git init -q "$SEED"
git -C "$SEED" config user.email seed@t
git -C "$SEED" config user.name seed
git -C "$SEED" commit -q --allow-empty -m "init"
git -C "$SEED" branch -M main
git -C "$SEED" remote add origin "$REMOTE"
git -C "$SEED" push -q -u origin main
rm -rf "$SEED"

git clone -q "$REMOTE" "$A"
git clone -q "$REMOTE" "$B"
for d in "$A" "$B"; do
  git -C "$d" config user.email "${d##*/}@t"
  git -C "$d" config user.name "${d##*/}"
done

tick_in() {
  local dir="$1"; shift
  TICK_REPO_ROOT="$dir" "$TICK" "$@"
}

tick_a() { tick_in "$A" "$@"; }
tick_b() { tick_in "$A" "$@"; }  # local transport: shares TICK_REPO_ROOT with tick_a

# Bind TICK_REPO_ROOT to the shared coordination root by default, so a test that
# calls `$TICK ...` directly (instead of the tick_a/tick_b wrappers) still
# targets $A rather than hitting an unbound var under `set -u`. The wrappers
# override it per-call via tick_in; this is just the sane default for new tests.
# (Run-4 feedback: TICK_REPO_ROOT was unbound when scaffolding handoff-exclusive.sh.)
export TICK_REPO_ROOT="$A"

# GH-402: fixtures may drive a marathon on their own `main`, and that is not the defect the branch
# guard exists to catch.
#
# Every fixture here is a CLONE OF A BARE REPO this file creates, so it has a real `origin/HEAD` and
# sits on `main` — indistinguishable, to the driver, from an operator about to land a marathon on a
# shared trunk. Eight suites went red on the guard's first full run, and `test/marathon-drive.sh`
# alone has ~98 driver invocations: threading `--allow-trunk-commit` through every call site would be
# a permanent tax on every future marathon fixture, and the churn would be far more likely to
# introduce a mistake than the guard is to catch one here.
#
# Declared ONCE, in the one file every fixture already sources, and declared as what it is: a test
# harness saying branch protection is not the thing under test. The guard itself is still exercised —
# `test/gh402-branch-enforcement.sh` unsets this for the cases that must refuse, so the protection
# has a suite that proves it fires rather than a suite that silently never reaches it.
export MARATHON_ALLOW_TRUNK_COMMIT=1

# GH-520: give every fixture a default REVIEWER binary, for the same reason and in the same place
# as the line above.
#
# `marathon_drive.py` probes the reviewer binary before the guards, the preflight and the dispatch
# (`_probe_agent_bin`), and `--reviewer codex` is the default in essentially every marathon fixture.
# Stubbing the *builder* is the obvious half — it is the thing the test drives — so the reviewer
# stays invisible until a machine without `codex` runs the suite. A fixture that misses it never
# reaches the code it was written to test, and its assertions read the probe's message instead.
#
# That is not hypothetical and it is not a flake: it has now happened three times. GH-232 recorded
# it in a `ci.yml` comment (`driver-lock.sh`/`xyz-harness-hooks.sh` stubbed CLAUDE_BIN/AGY_BIN but
# not CODEX_BIN), and on 2026-08-11/12 three more suites — gh402, gh514, gh388 — shipped green
# locally and were red on every ubuntu run for a whole session. The comment did not prevent the
# recurrence, which is the actual finding: this needs a default, not another warning.
#
# Worse than a flake, because a fail-fast can satisfy an ABSENCE assertion for the wrong reason:
# `gh514` asserts on the absence of a Python traceback, which a run that dies at the probe also
# produces. Those three happened to fail closed; nothing in the design guarantees the next one will.
#
# Declared ONCE, here, as what it is: the harness saying the reviewer binary is not the thing under
# test. The probe is still exercised — `test/marathon-drive.sh` sets an explicitly MISSING binary
# for the cases that must refuse, so it has a suite proving it fires rather than one that silently
# never reaches it. A fixture that needs its own reviewer behaviour still overrides CODEX_BIN
# inline, exactly as the shim suites already do.
_CODEX_STUB="$WORK/_default-codex-stub"
cat > "$_CODEX_STUB" <<'CODEX_STUB_EOF'
#!/usr/bin/env bash
# GH-520 default reviewer stub: present on PATH-probe, does nothing, succeeds.
exit 0
CODEX_STUB_EOF
chmod +x "$_CODEX_STUB"
export CODEX_BIN="${CODEX_BIN:-$_CODEX_STUB}"

PASS=0
FAIL=0
pass() { echo "  PASS: $*"; PASS=$((PASS+1)); }
# TEST_SOFT_FAIL=1 keeps going after a failed assertion so one run enumerates every
# gap instead of stopping at the first. Default (unset/0) is fail-fast, unchanged.
# Soft-fail output is a lead list, not a verdict: later assertions may cascade off
# the state a failed one left behind. The file-level pass/fail stays authoritative.
fail() { echo "  FAIL: $*" >&2; FAIL=$((FAIL+1)); [ "${TEST_SOFT_FAIL:-0}" = "1" ] || exit 1; }

echo "== test: $TEST_NAME =="
echo "  workdir: $WORK"
