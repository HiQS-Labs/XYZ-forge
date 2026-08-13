#!/usr/bin/env bash
# GH-514 — a repo that cannot TRACK the run's write-set must be refused BEFORE a turn is dispatched.
#
# `marathon.sh --help` has always described this failure: without `--target-root`, a repo that
# gitignores harness output makes marathon-drive's `git add` of RELAY.md / ESCALATION.md / the
# transcript fail, and the phase HALTs. Nothing checked it, so it surfaced as a halt AFTER a builder
# turn had been spent — and on the escalation path the record explaining the halt is itself one of
# the files that cannot be committed, so the run loses its own account of why it stopped.
#
# WHAT ACTUALLY CHANGES, corrected by this file's own negative control.
#
# The first draft of this suite asserted that the fix moves the failure EARLIER — that the unfixed
# tree dispatches a builder turn and only then falls over, so "zero dispatches" would be the
# discriminating assertion. **The control falsified that.** Pre-fix, zero turns are dispatched too:
# the relay render and its `git add` both happen before dispatch, so the run already dies first. The
# `marathon.sh` usage text is right that the phase HALTs, but it halts at render time.
#
# What the unfixed tree actually produces is this, as the operator's entire diagnosis:
#
#     The following paths are ignored by one of your .gitignore files:
#     marathon-system
#     hint: Use -f if you really want to add them.
#     Traceback (most recent call last):
#       File ".../marathon_drive.py", line 1955, in main
#         subprocess.run(["git", "-C", root, "add", "--", relay_file], check=True)
#     subprocess.CalledProcessError: Command '[...]' returned non-zero exit status 1.
#
# An unhandled Python traceback, from a driver that knew exactly what was wrong. So the assertions
# that discriminate are about the REFUSAL, not its timing: does it identify itself, name which rule
# matched and where, offer the remedy, and exit cleanly instead of crashing. The traceback assertion
# is the sharpest of them — it is present pre-fix and absent post-fix, in both directions.
#
# The dispatch count is KEPT, demoted from proof to guard: it does not discriminate today, and it
# must never regress into dispatching a turn before this check runs.
#
# The healthy case is the control that stops this guard becoming a new way for good runs to fail.
#
# Usage: bash test/gh514-write-set-trackable.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh514-write-set-trackable
PY="${PYTHON:-python3}"

DRIVE="$ROOT_DIR/relay-automation/marathon-drive.sh"

# A builder stub that records the fact it ran. Its content does not matter — its EXISTENCE in the log
# is the measurement.
DISPATCH_LOG="$WORK/dispatched.log"
STUB="$WORK/builder-stub"
cat >"$STUB" <<STUB_EOF
#!/usr/bin/env bash
echo "DISPATCHED" >>"$DISPATCH_LOG"
printf '\n### Round 1 · Builder\nwork\n' >>"\${RELAY_FILE:-/dev/null}" 2>/dev/null || true
exit 0
STUB_EOF
chmod +x "$STUB"

# GH-232, walked into again. `marathon_drive.py` probes the REVIEWER binary (CODEX_BIN, default
# `codex`) before anything else runs, so with no `codex` on PATH the driver fail-fasts and the
# discriminating assertion below reads the probe's message instead of the write-set refusal. This
# file stubbed the builder and not the reviewer, so it passed on a developer machine — where a real
# `codex` happens to be installed — and went red on ubuntu CI, which is the exact failure mode
# ci.yml already documents. That matters more here than in most suites: this one asserts on the
# ABSENCE of a traceback, and a fail-fast that never reaches the render satisfies that for entirely
# the wrong reason.
REVIEWER_STUB="$WORK/reviewer-stub"
printf '#!/usr/bin/env bash\nexit 0\n' >"$REVIEWER_STUB"
chmod +x "$REVIEWER_STUB"
export CODEX_BIN="$REVIEWER_STUB"

# Build a target fixture. <label> <extra-gitignore-line>
mk_target() {
  # Split, not `local a=$1 b=$2 c="$WORK/$a"`: macOS ships bash 3.2, which expands every RHS in a
  # `local` statement before applying any of the assignments, so `c` was built from an unset `a` and
  # every fixture path came out as "/PROJECT/...". The failures that produced looked like product
  # bugs in three separate assertions.
  local label="$1"
  local extra="$2"
  local d="$WORK/$label"
  git init -q "$d"
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  { printf '.tick/\n'; [ -n "$extra" ] && printf '%s\n' "$extra"; } >"$d/.gitignore"
  mkdir -p "$d/PROJECT/2-WORKING"
  printf '# brief\n\nDo the thing.\n' >"$d/PROJECT/2-WORKING/brief.md"
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" commit -q -m seed
  printf '%s' "$d"
}

run_drive() { # <target-dir> <out-file>
  local d="$1" out="$2"
  ( XYZ_PYTHON=1 MARATHON_ROOT="$d" TICK_REPO_ROOT="$d" TICK_BIN="$TICK" \
      CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$d" RELAY_AGENT=claude-builder \
      bash "$DRIVE" --phase-id lane1 --reviewer codex --builder claude \
        --phase-brief "$d/PROJECT/2-WORKING/brief.md" --round-cap 3 \
        --phases-dir "$d/marathon-system" --pre-advance-cmd true >"$out" 2>&1 )
  printf '%s' $?
}

# ---------------------------------------------------------------------------
# Case 1 — HOSTILE: the target ignores the directory the run must commit into
# ---------------------------------------------------------------------------
echo "-- case 1: the target gitignores marathon-system/"
HOSTILE="$(mk_target hostile 'marathon-system/')"
: >"$DISPATCH_LOG"
rc="$(run_drive "$HOSTILE" "$WORK/hostile.out")"

[ "$rc" -ne 0 ] \
  && pass "the hostile target is refused (exit $rc)" \
  || fail "GH-514: a hostile target ran to completion (exit 0)"

# A GUARD, not the proof — see the header. This passes pre-fix too, because the render's own
# `git add` already dies before dispatch. It stays because a future refactor that moves this check
# after dispatch would be a real regression and nothing else would catch it.
dispatches="$(/usr/bin/grep -c DISPATCHED "$DISPATCH_LOG" 2>/dev/null | head -1)"; dispatches="${dispatches:-0}"
if [ "$dispatches" -eq 0 ]; then
  pass "guard: no builder turn was dispatched before the refusal"
else
  fail "GH-514: $dispatches builder turn(s) were dispatched before the refusal — the check has moved after dispatch"
fi

# THE discriminating assertion. Pre-fix this path ends in an unhandled CalledProcessError traceback
# from `git add`; the driver knew exactly what was wrong and handed the operator a stack trace.
if /usr/bin/grep -qE "Traceback \(most recent call last\)|CalledProcessError" "$WORK/hostile.out"; then
  fail "GH-514: the run died with an unhandled Python traceback instead of a refusal — the driver knows what is wrong and is not saying it. Output: $(cat "$WORK/hostile.out")"
else
  pass "the run refuses cleanly — no unhandled traceback"
fi

out="$(cat "$WORK/hostile.out")"
case "$out" in
  *"BLOCKED before dispatch"*) pass "the refusal says it happened before dispatch" ;;
  *) fail "GH-514: the refusal does not identify itself — output was: $out" ;;
esac
case "$out" in
  *marathon-system*) pass "the refusal names the path that cannot be tracked" ;;
  *) fail "GH-514: the refusal does not name the offending path" ;;
esac
case "$out" in
  *".gitignore:"*) pass "the refusal names the ignore rule (file:line:pattern) that matched" ;;
  *) fail "GH-514: the refusal does not name WHICH rule matched — an operator cannot act on it" ;;
esac
case "$out" in
  *"--target-root"*) pass "the refusal names the remedy" ;;
  *) fail "GH-514: the refusal gives no remedy" ;;
esac

# The guard must not quietly repair the operator's repo.
if /usr/bin/grep -q '^marathon-system/$' "$HOSTILE/.gitignore"; then
  pass "the target's .gitignore was left alone (non-goal: no silent auto-repair)"
else
  fail "GH-514 non-goal violated: the guard edited the target's .gitignore"
fi

# ---------------------------------------------------------------------------
# Case 2 — HEALTHY: the control that stops this becoming a new failure mode
# ---------------------------------------------------------------------------
echo "-- case 2: the same fixture WITHOUT the hostile rule still dispatches"
OK_TARGET="$(mk_target healthy '')"
: >"$DISPATCH_LOG"
rc2="$(run_drive "$OK_TARGET" "$WORK/healthy.out")"

dispatches2="$(/usr/bin/grep -c DISPATCHED "$DISPATCH_LOG" 2>/dev/null | head -1)"; dispatches2="${dispatches2:-0}"
if [ "$dispatches2" -ge 1 ]; then
  pass "a trackable target still dispatches its builder turn ($dispatches2)"
else
  fail "GH-514: the guard blocked a HEALTHY target — it has become a new way for good runs to fail. rc=$rc2, output: $(tail -20 "$WORK/healthy.out")"
fi
case "$(cat "$WORK/healthy.out")" in
  *"BLOCKED before dispatch"*)
    fail "GH-514: the healthy target was reported as blocked" ;;
  *)
    pass "the healthy target is not reported as blocked" ;;
esac

# ---------------------------------------------------------------------------
# Case 3 — the check reads git's authority, not a hand-rolled .gitignore parser
# ---------------------------------------------------------------------------
# A rule in .git/info/exclude is invisible to anything that only reads .gitignore, and it is exactly
# the kind of local-state rule the release description means by "preserves the local-state contract".
echo "-- case 3: a rule in .git/info/exclude is honoured too"
EXCL="$(mk_target excluded '')"
printf 'marathon-system/\n' >>"$EXCL/.git/info/exclude"
: >"$DISPATCH_LOG"
rc3="$(run_drive "$EXCL" "$WORK/excl.out")"
d3="$(/usr/bin/grep -c DISPATCHED "$DISPATCH_LOG" 2>/dev/null | head -1)"; d3="${d3:-0}"
if [ "$d3" -eq 0 ] && /usr/bin/grep -q "BLOCKED before dispatch" "$WORK/excl.out"; then
  pass "an exclude-file rule is caught too (git check-ignore is the authority, not a .gitignore parser)"
else
  fail "GH-514: a .git/info/exclude rule was missed — the check is reading .gitignore itself instead of asking git. dispatches=$d3"
fi
case "$(cat "$WORK/excl.out")" in
  *"info/exclude"*) pass "and it names the exclude file as the matching source" ;;
  *) fail "GH-514: the refusal did not name .git/info/exclude as the source" ;;
esac

echo
echo "  $TEST_NAME: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
