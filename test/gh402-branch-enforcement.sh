#!/usr/bin/env bash
# GH-402 — a marathon must not commit to the receiving repo's trunk just because that is what
# happened to be checked out.
#
# `marathon/<slug>-<date>` is advisory text printed into a preflight packet, and nothing enforced it.
# The driver is the last common point on every commit path — relay renders, escalations, transcripts
# all funnel through it — so the refusal lives there, and this suite drives the real driver rather
# than asserting on source text.
#
# WHAT THE GUARD KEYS ON, and why the fixtures are built the way they are: it fires only when
# `origin/HEAD` resolves, i.e. on a trunk that is actually SHARED. The harm is that a marathon's
# turns commit continuously, so a run that lands on trunk cannot be un-landed by stopping it — only
# by rewriting history someone else may already have pulled. With no remote there is no someone
# else and `git reset` undoes everything, so blocking there would spend a hard stop on a fully
# recoverable state. Every fixture here therefore builds a real bare origin; the no-remote case is
# asserted as an explicit NON-block rather than left untested.
#
# Usage: bash test/gh402-branch-enforcement.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh402-branch-enforcement
PY="${PYTHON:-python3}"
DRIVE="$ROOT_DIR/relay-automation/marathon-drive.sh"

# _setup.sh exports MARATHON_ALLOW_TRUNK_COMMIT=1 so the other ~200 marathon fixtures in this suite
# are not each forced to declare it (see the rationale there). This file is the one that must NOT
# inherit it: it exists to prove the guard fires. Unset here, and re-declared explicitly in the two
# cases below that are supposed to get past it — so every bypass in this file is visible at its own
# call site rather than ambient.
unset MARATHON_ALLOW_TRUNK_COMMIT

DISPATCH_LOG="$WORK/dispatched.log"
STUB="$WORK/builder-stub"
cat >"$STUB" <<STUB_EOF
#!/usr/bin/env bash
echo DISPATCHED >>"$DISPATCH_LOG"
exit 0
STUB_EOF
chmod +x "$STUB"

# <label> — a clone with a real origin whose HEAD is a genuine default branch.
mk_repo() {
  local label="$1"
  local bare="$WORK/$label.git"
  local d="$WORK/$label"
  git init -q --bare "$bare"
  git init -q "$d"
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  git -C "$d" symbolic-ref HEAD refs/heads/main
  printf '.tick/\n' >"$d/.gitignore"
  mkdir -p "$d/PROJECT/2-WORKING"
  printf '# brief\n\nDo the thing.\n' >"$d/PROJECT/2-WORKING/brief.md"
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" commit -q -m seed
  git -C "$d" remote add origin "$bare"
  git -C "$d" push -q -u origin main
  # This is what makes the trunk SHARED rather than merely local.
  git -C "$d" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
  printf '%s' "$d"
}

run_drive() { # <repo> <out> [extra driver args...]
  local d="$1" out="$2"; shift 2
  ( XYZ_PYTHON=1 MARATHON_ROOT="$d" TICK_REPO_ROOT="$d" TICK_BIN="$TICK" \
      CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$d" RELAY_AGENT=claude-builder \
      bash "$DRIVE" --phase-id lane1 --reviewer codex --builder claude \
        --phase-brief "$d/PROJECT/2-WORKING/brief.md" --round-cap 3 \
        --phases-dir "$d/marathon-system" --pre-advance-cmd true "$@" >"$out" 2>&1 )
  printf '%s' $?
}

count_dispatch() { local n; n="$(/usr/bin/grep -c DISPATCHED "$DISPATCH_LOG" 2>/dev/null | head -1)"; printf '%s' "${n:-0}"; }

# ---------------------------------------------------------------------------
# Case 1 — on trunk, with a shared origin: REFUSED
# ---------------------------------------------------------------------------
echo "-- case 1: checked out on the shared trunk"
R1="$(mk_repo ontrunk)"
: >"$DISPATCH_LOG"
rc="$(run_drive "$R1" "$WORK/ontrunk.out")"
out="$(cat "$WORK/ontrunk.out")"

[ "$rc" -ne 0 ] && pass "a run on trunk is refused (exit $rc)" \
                || fail "GH-402: a marathon on trunk ran to completion"
[ "$(count_dispatch)" -eq 0 ] \
  && pass "no builder turn was dispatched" \
  || fail "GH-402: a turn was dispatched before the refusal"

# Nothing may have been committed. This is the assertion that matters most — the whole harm is a
# commit that cannot be un-landed, so "refused" must mean the tree is untouched.
if [ "$(git -C "$R1" rev-list --count HEAD)" -eq 1 ]; then
  pass "the receiving repo has no new commits (HEAD is still the seed)"
else
  fail "GH-402: the run committed to trunk before refusing — $(git -C "$R1" log --oneline | head -3)"
fi

case "$out" in
  *"trunk branch 'main'"*) pass "the refusal names the branch it is protecting" ;;
  *) fail "GH-402: the refusal does not name the branch — got: $out" ;;
esac
case "$out" in
  *"checkout -b"*) pass "the refusal gives the exact command to cut a branch" ;;
  *) fail "GH-402: the refusal offers no remedy" ;;
esac
case "$out" in
  *"--allow-trunk-commit"*) pass "the refusal names the override" ;;
  *) fail "GH-402: the refusal does not mention the override flag" ;;
esac

# ---------------------------------------------------------------------------
# Case 2 — the suggested branch from preflight is used in the message when available
# ---------------------------------------------------------------------------
echo "-- case 2: the packet's suggested branch appears in the remedy"
R2="$(mk_repo suggested)"
: >"$DISPATCH_LOG"
( SP_SUGGESTED_BRANCH="marathon/gh402-2026-08-11" \
  XYZ_PYTHON=1 MARATHON_ROOT="$R2" TICK_REPO_ROOT="$R2" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$R2" RELAY_AGENT=claude-builder \
  bash "$DRIVE" --phase-id lane1 --reviewer codex --builder claude \
    --phase-brief "$R2/PROJECT/2-WORKING/brief.md" --round-cap 3 \
    --phases-dir "$R2/marathon-system" --pre-advance-cmd true >"$WORK/sugg.out" 2>&1 )
case "$(cat "$WORK/sugg.out")" in
  *"marathon/gh402-2026-08-11"*) pass "the refusal uses preflight's own suggested branch name" ;;
  *) fail "GH-402: SP_SUGGESTED_BRANCH was ignored — the operator has to invent a name" ;;
esac

# ---------------------------------------------------------------------------
# Case 3 — off trunk: allowed. The control that stops this blocking everything.
# ---------------------------------------------------------------------------
echo "-- case 3: on a feature branch, the run proceeds"
R3="$(mk_repo offtrunk)"
git -C "$R3" checkout -q -b marathon/probe
: >"$DISPATCH_LOG"
rc3="$(run_drive "$R3" "$WORK/offtrunk.out")"
if [ "$(count_dispatch)" -ge 1 ]; then
  pass "a run on a feature branch still dispatches ($(count_dispatch) turn(s))"
else
  fail "GH-402: the guard blocked a run that was NOT on trunk — rc=$rc3, output: $(tail -12 "$WORK/offtrunk.out")"
fi
/usr/bin/grep -q "BLOCKED" "$WORK/offtrunk.out" \
  && fail "GH-402: a feature-branch run was reported as blocked" \
  || pass "a feature-branch run is not reported as blocked"

# ---------------------------------------------------------------------------
# Case 4 — the two documented ways past the guard
# ---------------------------------------------------------------------------
echo "-- case 4: the override flag and the preflight carve-out"
R4="$(mk_repo override)"
: >"$DISPATCH_LOG"
rc4="$(run_drive "$R4" "$WORK/override.out" --allow-trunk-commit)"
[ "$(count_dispatch)" -ge 1 ] \
  && pass "--allow-trunk-commit permits a trunk run" \
  || fail "GH-402: --allow-trunk-commit did not work — rc=$rc4, output: $(tail -12 "$WORK/override.out")"

R5="$(mk_repo carveout)"
: >"$DISPATCH_LOG"
( SP_SKIP_BRANCH_PROMPT=1 \
  XYZ_PYTHON=1 MARATHON_ROOT="$R5" TICK_REPO_ROOT="$R5" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$R5" RELAY_AGENT=claude-builder \
  bash "$DRIVE" --phase-id lane1 --reviewer codex --builder claude \
    --phase-brief "$R5/PROJECT/2-WORKING/brief.md" --round-cap 3 \
    --phases-dir "$R5/marathon-system" --pre-advance-cmd true >"$WORK/carve.out" 2>&1 )
[ "$(count_dispatch)" -ge 1 ] \
  && pass "the risk=1/independent-zone carve-out permits a trunk run without the flag" \
  || fail "GH-402: SP_SKIP_BRANCH_PROMPT=1 did not exempt the run — output: $(tail -12 "$WORK/carve.out")"

# --force must NOT be a way past this. Retrying a flaky lane cannot silently grant permission to
# land on trunk; that coupling is only obvious after it has happened.
R6="$(mk_repo forceonly)"
: >"$DISPATCH_LOG"
rc6="$(run_drive "$R6" "$WORK/force.out" --force)"
if [ "$(count_dispatch)" -eq 0 ] && /usr/bin/grep -q "BLOCKED" "$WORK/force.out"; then
  pass "--force does NOT bypass the branch guard (it bounds attempts, not branches)"
else
  fail "GH-402: --force bypassed the branch guard — a lane retry now grants permission to land on trunk"
fi

# ---------------------------------------------------------------------------
# Case 5 — no remote: deliberately NOT blocked, and asserted so
# ---------------------------------------------------------------------------
echo "-- case 5: a repo with no shared trunk is not blocked"
R7="$WORK/noremote"
git init -q "$R7"
git -C "$R7" config user.email t@t
git -C "$R7" config user.name t
git -C "$R7" symbolic-ref HEAD refs/heads/main
printf '.tick/\n' >"$R7/.gitignore"
mkdir -p "$R7/PROJECT/2-WORKING"
printf '# brief\n' >"$R7/PROJECT/2-WORKING/brief.md"
git -C "$R7" add -A >/dev/null 2>&1
git -C "$R7" commit -q -m seed
: >"$DISPATCH_LOG"
rc7="$(run_drive "$R7" "$WORK/noremote.out")"
if [ "$(count_dispatch)" -ge 1 ]; then
  pass "a repo with no origin is not blocked (nothing is shared; git reset undoes everything)"
else
  fail "GH-402: a remote-less repo was blocked — the guard is firing where the harm cannot occur. rc=$rc7, output: $(tail -12 "$WORK/noremote.out")"
fi

echo
echo "  $TEST_NAME: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
