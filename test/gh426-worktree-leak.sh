#!/usr/bin/env bash
# GH-426 — a file created by an isolated turn must not exist in ANY repo on disk afterwards.
#
# The issue's headline reading is that worktree teardown leaks the creation into the harness repo.
# **Measured, that is not what happens**, and the measurement is recorded here because the issue's
# own text asks for it ("Stated as the place to look first, not as a diagnosis — a builder that
# treats this as the answer will produce a fix shaped like the guess rather than like the defect").
#
# What a per-invocation log of the agent binary actually shows is TWO invocations:
#
#     INVOCATION cwd=<harness>            argv=whoami            <-- the GH-375 auth pre-flight
#     INVOCATION cwd=<isolation worktree> argv=... -p <prompt>   <-- the turn itself
#
# The worktree IS correctly based on AGY_TURN_ROOT (its git-common-dir resolves to the fixture, which
# is criterion 3, already satisfied), containment DOES fire (exit 6), and the worktree copy IS
# discarded. The file that reaches the harness comes from the FIRST invocation — the auth probe,
# which ran with the caller's CWD, outside the turn's containment entirely. A reproducing stub writes
# on every invocation; real `agy whoami` does not, which is why this looked like a teardown defect.
#
# The fix is therefore narrow and is about an assumption, not a leak: the probe now runs in a
# throwaway directory, because "the binary we shell out to happens not to write" is a claim about
# someone else's program rather than a property this harness enforces.
#
# Criterion 2 says assert absence in BOTH repos, because checking only the declared target is what
# let this pass unnoticed in GH-410's suite. This file does that, and adds the invocation-level
# assertion that actually distinguishes the two explanations.
#
# Usage: bash test/gh426-worktree-leak.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh426-worktree-leak

SHIM="$ROOT_DIR/relay-automation/agy-turn.sh"
[ -f "$SHIM" ] || { fail "agy-turn.sh missing"; exit 1; }

# A uniquely-named probe file, so nothing here can pass or fail on residue from another run — the
# original investigation lost time to exactly that, re-reading a leftover offlane.md as a fresh leak.
PROBE="gh426probe-$$-$RANDOM.md"

FIX="$WORK/fixture"
git init -q "$FIX"
git -C "$FIX" config user.email f@t
git -C "$FIX" config user.name f
printf 'STATUS: Open\n# relay\n' >"$FIX/relay.md"
printf '.tick/\n' >"$FIX/.gitignore"
git -C "$FIX" add -A >/dev/null 2>&1
git -C "$FIX" commit -q -m seed

INVLOG="$WORK/invocations.log"
STUB="$WORK/agy-stub"
cat >"$STUB" <<STUB_EOF
#!/usr/bin/env bash
set -u
# The git-common-dir is recorded HERE, from inside the invocation, because by the time the suite
# looks the isolation worktree has already been torn down — an earlier draft asserted criterion 3
# against a path that no longer existed and reported "could not resolve", which is not a verdict.
echo "INVOCATION cwd=\$PWD common=\$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || echo none) argv=\$1" >>"$INVLOG"
# Writes on EVERY invocation, relative to CWD. Deliberately the same shape as
# test/gh410-containment-advisory.sh's stub — reproducing the original conditions, not a tidied-up
# version of them, because the tidied-up version is what would hide this.
printf 'off-lane\n' >>"./$PROBE"
printf '\n## agy-stub\nSTATUS: Approved\n' >>"\${AGY_TURN_ROOT}/relay.md" 2>/dev/null || true
exit 0
STUB_EOF
chmod +x "$STUB"

harness_before="$(cd "$ROOT_DIR" && git status --porcelain | LC_ALL=C sort)"

RELAY_AGENT=agy RELAY_FILE="$FIX/relay.md" RELAY_TASK="T-GH426-$$" AGY_AGENT=agy \
  TICK_REPO_ROOT="$FIX" \
  AGY_BIN="$STUB" AGY_TURN_ROOT="$FIX" AGY_LOG="$WORK/agy.log" \
  ALLOW_PATHS="relay.md" RELAY_WORKTREE_ISOLATION=1 \
  bash "$SHIM" >"$WORK/shim.out" 2>&1
rc=$?

# ---------------------------------------------------------------------------
# The containment verdict must still fire. A "fix" that contains the file by weakening the verdict
# inverts the issue's first non-goal, so this is asserted before anything else.
# ---------------------------------------------------------------------------
[ "$rc" -eq 6 ] \
  && pass "containment still fails the turn on an off-lane worktree write (exit 6)" \
  || fail "GH-426 non-goal violated: expected exit 6, got $rc. Output: $(cat "$WORK/shim.out")"

# ---------------------------------------------------------------------------
# Criterion 1+2 — absent from BOTH repos. Checking only the declared target is the known-bad
# assertion that let this go unnoticed; it is spelled out separately here so a future edit cannot
# quietly drop the harness half.
# ---------------------------------------------------------------------------
[ ! -e "$FIX/$PROBE" ] \
  && pass "the created file is absent from the declared target repo" \
  || fail "GH-426: the off-lane creation survived in the target repo: $FIX/$PROBE"

if [ ! -e "$ROOT_DIR/$PROBE" ]; then
  pass "the created file is absent from the HARNESS repo (the half GH-410's test never checked)"
else
  rm -f "$ROOT_DIR/$PROBE"   # never leave litter in a live repo, even when failing
  fail "GH-426: the off-lane creation leaked into the harness repo: $ROOT_DIR/$PROBE"
fi

harness_after="$(cd "$ROOT_DIR" && git status --porcelain | LC_ALL=C sort)"
[ "$harness_before" = "$harness_after" ] \
  && pass "the harness repo's git status is unchanged by the turn" \
  || fail "GH-426: the turn changed the harness working tree:
$(diff <(printf '%s\n' "$harness_before") <(printf '%s\n' "$harness_after"))"

# ---------------------------------------------------------------------------
# The mechanism, asserted — this is what separates the real cause from the reported one.
# ---------------------------------------------------------------------------
inv_count="$(/usr/bin/grep -c INVOCATION "$INVLOG" 2>/dev/null || echo 0)"
[ "$inv_count" -ge 2 ] \
  && pass "the agent binary is invoked more than once per turn ($inv_count) — the auth probe, then the turn" \
  || fail "expected at least 2 invocations (auth probe + turn), saw $inv_count — the fixture no longer reproduces the reported conditions"

probe_cwd="$(/usr/bin/grep 'argv=whoami' "$INVLOG" 2>/dev/null | head -1 | sed 's/^INVOCATION cwd=//; s/ common=.*//')"
if [ -z "$probe_cwd" ]; then
  fail "no auth-probe invocation recorded — this suite can no longer observe the real mechanism"
elif [ "$probe_cwd" = "$ROOT_DIR" ]; then
  fail "GH-426: the auth probe still runs with CWD=the harness repo ($probe_cwd) — anything it writes lands outside containment and is never reverted"
else
  pass "the auth probe runs outside any real repo (cwd=${probe_cwd##*/})"
fi

# Criterion 3: the worktree's base repo must match AGY_TURN_ROOT when the two differ. Asserted from
# the turn invocation's own CWD, which is the worktree, rather than from a log line claiming it.
turn_line="$(/usr/bin/grep -v 'argv=whoami' "$INVLOG" 2>/dev/null | head -1)"
turn_cwd="$(printf '%s' "$turn_line" | sed 's/^INVOCATION cwd=//; s/ common=.*//')"
turn_common="$(printf '%s' "$turn_line" | sed 's/.* common=//; s/ argv=.*//')"
fix_real="$(cd "$FIX" && pwd -P)"
if [ -z "$turn_cwd" ] || [ "$turn_cwd" = "$ROOT_DIR" ]; then
  fail "the turn invocation did not run in an isolation worktree (cwd=$turn_cwd)"
elif [ "$turn_common" = "none" ]; then
  fail "the turn's CWD is not inside a git worktree at all (cwd=$turn_cwd)"
elif [ "$turn_common" = "$fix_real/.git" ] || [ "$turn_common" = "$FIX/.git" ]; then
  pass "the isolation worktree's base repo IS the declared target (criterion 3 holds)"
else
  fail "GH-426 criterion 3: the worktree's base repo ($turn_common) is not the declared target ($fix_real/.git)"
fi

echo
echo "  $TEST_NAME: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
