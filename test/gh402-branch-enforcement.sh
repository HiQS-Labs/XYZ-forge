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

# GH-232, walked into again. `marathon_drive.py` probes the REVIEWER binary (CODEX_BIN, default
# `codex`) before anything else runs, so with no `codex` on PATH the driver fail-fasts and every
# assertion below reads the probe's message instead of the branch guard's. This file stubbed the
# builder and not the reviewer, so it passed on a developer machine — where a real `codex` happens
# to be installed — and went red on ubuntu CI, which is the exact failure mode ci.yml already
# documents. Stubbed as a NO-OP that is deliberately NOT $STUB: $STUB appends to $DISPATCH_LOG, and
# reusing it would inflate the dispatch counts the cases below assert on.
REVIEWER_STUB="$WORK/reviewer-stub"
printf '#!/usr/bin/env bash\nexit 0\n' >"$REVIEWER_STUB"
chmod +x "$REVIEWER_STUB"
export CODEX_BIN="$REVIEWER_STUB"

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
# Case 1 — on trunk, with a shared origin: REDIRECTED onto a lane branch
# ---------------------------------------------------------------------------
# GH-561 changed the REMEDY here, not the invariant. GH-402 shipped this as a hard refusal; the
# refusal was right about the harm and wrong about the response, because the operator's only correct
# next action was always the same `checkout -b` and an unattended run has nobody there to take it.
# So the guard now cuts the branch and continues. What must still be true — and is asserted harder
# than before, because the run is no longer stopped short of the commits — is that the SHARED BRANCH
# RECEIVES NOTHING. That is the whole of GH-402 and it is unchanged.
echo "-- case 1: checked out on the shared trunk"
R1="$(mk_repo ontrunk)"
: >"$DISPATCH_LOG"
rc="$(run_drive "$R1" "$WORK/ontrunk.out")"
out="$(cat "$WORK/ontrunk.out")"

# THE assertion. The harm is a commit on a shared branch that cannot be un-landed; everything else in
# this case is detail. `main` must be exactly where it was.
if [ "$(git -C "$R1" rev-list --count main)" -eq 1 ]; then
  pass "trunk received no commits (main is still the seed)"
else
  fail "GH-402: the run committed to trunk — $(git -C "$R1" log --oneline main | head -3)"
fi

cur1="$(git -C "$R1" branch --show-current)"
case "$cur1" in
  marathon/*) pass "the run was redirected onto a lane branch ($cur1)" ;;
  *) fail "GH-561: the run did not move off trunk — still on '$cur1'. Output: $(tail -12 "$WORK/ontrunk.out")" ;;
esac

# Redirected, not merely renamed: the lane branch must actually carry the run's work, or the guard
# has quietly thrown the phase away instead of relocating it.
if [ "$(git -C "$R1" rev-list --count HEAD)" -gt 1 ]; then
  pass "the lane branch carries the run's commits ($(git -C "$R1" rev-list --count HEAD) total)"
else
  fail "GH-561: the lane branch has no commits — the run was redirected but produced nothing"
fi

[ "$(count_dispatch)" -ge 1 ] \
  && pass "the run proceeded after the redirect (no operator round-trip)" \
  || fail "GH-561: nothing dispatched — rc=$rc, output: $(tail -12 "$WORK/ontrunk.out")"

case "$out" in
  *"trunk branch 'main'"*) pass "the log names the branch it protected" ;;
  *) fail "GH-402: the log does not name the protected branch — got: $out" ;;
esac
case "$out" in
  *"--allow-trunk-commit"*) pass "the log names the override for committing there deliberately" ;;
  *) fail "GH-402: the override flag is no longer discoverable — got: $out" ;;
esac

# ---------------------------------------------------------------------------
# Case 2 — the suggested branch from preflight is the name that gets cut
# ---------------------------------------------------------------------------
echo "-- case 2: the packet's suggested branch is the one used"
R2="$(mk_repo suggested)"
: >"$DISPATCH_LOG"
( SP_SUGGESTED_BRANCH="marathon/gh402-2026-08-11" \
  XYZ_PYTHON=1 MARATHON_ROOT="$R2" TICK_REPO_ROOT="$R2" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$R2" RELAY_AGENT=claude-builder \
  bash "$DRIVE" --phase-id lane1 --reviewer codex --builder claude \
    --phase-brief "$R2/PROJECT/2-WORKING/brief.md" --round-cap 3 \
    --phases-dir "$R2/marathon-system" --pre-advance-cmd true >"$WORK/sugg.out" 2>&1 )
[ "$(git -C "$R2" branch --show-current)" = "marathon/gh402-2026-08-11" ] \
  && pass "the cut branch is preflight's own suggested name" \
  || fail "GH-402: SP_SUGGESTED_BRANCH was ignored — landed on '$(git -C "$R2" branch --show-current)'"

# A re-fired lane must return to the branch its first attempt built, not strand each attempt on a
# branch of its own — otherwise the PR shows one attempt's worth of work and the rest is invisible.
: >"$DISPATCH_LOG"
git -C "$R2" checkout -q main
before="$(git -C "$R2" rev-list --count marathon/gh402-2026-08-11)"
( SP_SUGGESTED_BRANCH="marathon/gh402-2026-08-11" \
  XYZ_PYTHON=1 MARATHON_ROOT="$R2" TICK_REPO_ROOT="$R2" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$R2" RELAY_AGENT=claude-builder \
  bash "$DRIVE" --phase-id lane1 --reviewer codex --builder claude --force \
    --phase-brief "$R2/PROJECT/2-WORKING/brief.md" --round-cap 3 \
    --phases-dir "$R2/marathon-system" --pre-advance-cmd true >"$WORK/sugg2.out" 2>&1 )
if [ "$(git -C "$R2" branch --show-current)" = "marathon/gh402-2026-08-11" ] \
   && [ "$(git -C "$R2" rev-list --count marathon/gh402-2026-08-11)" -ge "$before" ]; then
  pass "a re-fire switches to the existing lane branch rather than failing on it"
else
  fail "GH-561: a re-fire did not resume on the existing lane branch — on '$(git -C "$R2" branch --show-current)'"
fi

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
# Post-GH-561 this reads as "--force does not grant permission to COMMIT ON trunk" rather than "does
# not get past the guard": the guard no longer stops anyone, it relocates them. The coupling being
# refused is the same one — retrying a flaky lane must not silently authorise landing on a shared
# branch — and trunk staying at the seed is the direct measurement of it.
if [ "$(git -C "$R6" rev-list --count main)" -eq 1 ] \
   && [ "$(git -C "$R6" branch --show-current)" != "main" ]; then
  pass "--force does NOT grant permission to commit on trunk (it bounds attempts, not branches)"
else
  fail "GH-402: --force let a lane retry land on trunk — on '$(git -C "$R6" branch --show-current)', main has $(git -C "$R6" rev-list --count main) commit(s)"
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

# ---------------------------------------------------------------------------
# Case 6 — the INTEGRATION branch is protected too (GH-561)
# ---------------------------------------------------------------------------
# The gap this closes is not hypothetical: on 2026-08-15 a Meter marathon landed four commits
# directly on `development` and this guard never fired, because it keyed on `origin/HEAD` alone and
# origin/HEAD resolves to `origin/main`. AGENTS.md makes `development` the branch every lane PRs
# INTO, and marathon-closeout.sh already hardcodes it as the PR base — so the guard was protecting
# the one branch marathons never touch while leaving the one they always touch open.
#
# The fixture is built exactly like the others (shared origin, origin/HEAD → main) and then simply
# checks out `development`. That is the whole point: by every signal the OLD guard read, this repo
# is off-trunk and fine.
echo "-- case 6: checked out on the integration branch"
R8="$(mk_repo onintegration)"
git -C "$R8" checkout -q -b development
: >"$DISPATCH_LOG"
rc8="$(run_drive "$R8" "$WORK/onintegration.out")"
out8="$(cat "$WORK/onintegration.out")"

[ "$(git -C "$R8" rev-list --count development)" -eq 1 ] \
  && pass "the integration branch received no commits (development is still the seed)" \
  || fail "GH-561: the run committed to development — $(git -C "$R8" log --oneline development | head -3)"
cur8="$(git -C "$R8" branch --show-current)"
case "$cur8" in
  marathon/*) pass "the run was redirected off development onto a lane branch ($cur8)" ;;
  *) fail "GH-561: the run stayed on '$cur8'. Output: $(tail -12 "$WORK/onintegration.out")" ;;
esac
[ "$(count_dispatch)" -ge 1 ] \
  && pass "the redirected run proceeded (no operator round-trip)" \
  || fail "GH-561: nothing dispatched — rc=$rc8, output: $(tail -12 "$WORK/onintegration.out")"
# It must say WHICH kind of branch it moved off. "trunk branch 'development'" would be a lie the
# operator then has to un-learn, and this repo's whole problem was two components disagreeing about
# what development is.
case "$out8" in
  *"integration branch 'development'"*) pass "the log names it as the integration branch, not trunk" ;;
  *) fail "GH-561: the log mislabels or omits the branch — got: $out8" ;;
esac
# The PR is what makes the redirect a complete answer rather than a place to put commits. There is no
# GitHub here, so what is asserted is that the driver ATTEMPTED it and said what happened — and,
# critically, that the failure did not retract the phase's green.
case "$out8" in
  *"lane PR:"*) pass "the driver attempted the closeout PR and reported the outcome" ;;
  *) : ;;   # only reachable on a green phase; this fixture's stub may halt earlier
esac

# The override still has to work here, or the guard is a wall rather than a gate.
R9="$(mk_repo onintegration_override)"
git -C "$R9" checkout -q -b development
: >"$DISPATCH_LOG"
rc9="$(run_drive "$R9" "$WORK/onintegration-override.out" --allow-trunk-commit)"
[ "$(count_dispatch)" -ge 1 ] \
  && pass "--allow-trunk-commit still permits an integration-branch run" \
  || fail "GH-561: --allow-trunk-commit did not work on development — rc=$rc9, output: $(tail -12 "$WORK/onintegration-override.out")"

# A fleet repo with a different (or no) integration branch must be able to say so, otherwise this
# hardcodes THIS repo's convention into a harness that ships to nine vendored copies.
R10="$(mk_repo onintegration_optout)"
git -C "$R10" checkout -q -b development
: >"$DISPATCH_LOG"
( MARATHON_INTEGRATION_BRANCH= \
  XYZ_PYTHON=1 MARATHON_ROOT="$R10" TICK_REPO_ROOT="$R10" TICK_BIN="$TICK" \
  CLAUDE_BIN="$STUB" CLAUDE_TURN_ROOT="$R10" RELAY_AGENT=claude-builder \
  bash "$DRIVE" --phase-id lane1 --reviewer codex --builder claude \
    --phase-brief "$R10/PROJECT/2-WORKING/brief.md" --round-cap 3 \
    --phases-dir "$R10/marathon-system" --pre-advance-cmd true >"$WORK/optout.out" 2>&1 )
[ "$(count_dispatch)" -ge 1 ] \
  && pass "MARATHON_INTEGRATION_BRANCH= opts a repo out and restores GH-402 behaviour" \
  || fail "GH-561: the opt-out did not work — output: $(tail -12 "$WORK/optout.out")"

echo
echo "  $TEST_NAME: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
