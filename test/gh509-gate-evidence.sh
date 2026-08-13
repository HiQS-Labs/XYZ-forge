#!/usr/bin/env bash
# GH-509 — the local gate record and the operator surface that reads it.
#
# The record answers ONE question: "did anyone run the whole suite against THIS commit here?" It is
# explicitly NOT promotion evidence — an earlier draft of the plan let a local record qualify a
# commit, and the agy review called that circular: if self-reported evidence satisfies the boundary,
# the boundary is optional and buys nothing.
#
# The refusal is what makes the record worth anything, so it is tested directly. That is why
# `gate-record.sh` exists as its own script: inlined in ci-local.sh, exercising the dirty-tree path
# would have cost a ~15-minute suite run, and it would have shipped asserted-by-comment.
#
# Usage: bash test/gh509-gate-evidence.sh
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
source "$HERE/_setup.sh" gh509-gate-evidence

RECORD="$ROOT_DIR/utils/gate-record.sh"
STATUS="$ROOT_DIR/utils/gate-status.sh"

mk_repo() { # <label> -> path to a seeded git repo
  local d="$WORK/$1"
  git init -q "$d"
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  printf 'seed\n' >"$d/file.txt"
  git -C "$d" add -A >/dev/null 2>&1
  git -C "$d" commit -q -m seed
  printf '%s' "$d"
}

# ---------------------------------------------------------------------------
echo "-- case 1: a clean tree records, keyed to the commit"
R1="$(mk_repo clean)"
out="$(bash "$RECORD" --repo "$R1" 2>&1)"; rc=$?
sha1="$(git -C "$R1" rev-parse HEAD)"
[ "$rc" -eq 0 ] && pass "a clean tree records (exit 0)" || fail "GH-509: clean tree refused: rc=$rc $out"
[ -f "$R1/.gate-evidence/$sha1.txt" ] \
  && pass "the record is keyed to the commit hash" \
  || fail "GH-509: no record at .gate-evidence/<sha>.txt"
/usr/bin/grep -q "commit: $sha1" "$R1/.gate-evidence/$sha1.txt" \
  && pass "the record names the commit it attests to" \
  || fail "GH-509: the record does not name its commit"

# The disclaimer is load-bearing, not decoration: this file is the thing a future reader will find
# and reason from. If it stops saying what it is not, it starts being cited as what it is not.
/usr/bin/grep -q "NOT-promotion-evidence" "$R1/.gate-evidence/$sha1.txt" \
  && pass "the record states it is NOT promotion evidence" \
  || fail "GH-509: the record omits its own limit — it will be cited as promotion evidence"

# ---------------------------------------------------------------------------
echo "-- case 2: a dirty tree is REFUSED (the assertion this file exists for)"
R2="$(mk_repo dirty)"
printf 'uncommitted\n' >"$R2/file.txt"
out="$(bash "$RECORD" --repo "$R2" 2>&1)"; rc=$?
[ "$rc" -eq 3 ] && pass "a dirty tree is refused with its own exit code (3)" \
                || fail "GH-509: dirty tree not refused — rc=$rc: $out"
[ -d "$R2/.gate-evidence" ] \
  && fail "GH-509: a refused run still created .gate-evidence — the refusal is cosmetic" \
  || pass "a refused run writes nothing at all"
case "$out" in
  *"never tested"*) pass "the refusal explains WHY (the record would name an untested state)" ;;
  *) fail "GH-509: the refusal gives no reason: $out" ;;
esac
case "$out" in
  *file.txt*) pass "the refusal names what made the tree dirty" ;;
  *) fail "GH-509: the refusal does not name the offending path: $out" ;;
esac

# An untracked file counts. This is the case a `git diff`-based check would miss, and it is the
# common one — a new test file sitting beside the code it covers.
R3="$(mk_repo untracked)"
printf 'new\n' >"$R3/brand-new.txt"
rc=0; bash "$RECORD" --repo "$R3" >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 3 ] && pass "an UNTRACKED file also counts as dirty" \
                || fail "GH-509: untracked file did not block the record (rc=$rc)"

# ---------------------------------------------------------------------------
echo "-- case 3: a repo with no commits refuses distinctly"
R4="$WORK/nocommit"; git init -q "$R4"
rc=0; bash "$RECORD" --repo "$R4" >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 4 ] && pass "no-commit refuses with its own code (4), distinct from dirty (3)" \
                || fail "GH-509: no-commit case returned $rc, indistinguishable from another failure"

# ---------------------------------------------------------------------------
echo "-- case 4: the operator surface reads the record and never lies about the network"
out="$(bash "$STATUS" --no-network --repo "$R1" 2>&1)"
case "$out" in
  *"VERIFIED on this commit"*) pass "status reports a recorded commit as verified" ;;
  *) fail "GH-509: status did not read the record: $out" ;;
esac
case "$out" in
  *"not promotion evidence"*) pass "status repeats that a local record is not promotion evidence" ;;
  *) fail "GH-509: status presents a local record without its limit: $out" ;;
esac
case "$out" in
  *"UNKNOWN"*) pass "offline status reports UNKNOWN rather than inventing a verdict" ;;
  *) fail "GH-509: offline status did not admit it could not check: $out" ;;
esac

out="$(bash "$STATUS" --no-network --repo "$R2" 2>&1)"
case "$out" in
  *DIRTY*) pass "status flags a dirty working tree" ;;
  *) fail "GH-509: status did not flag a dirty tree: $out" ;;
esac
case "$out" in
  *"not recorded for this commit"*) pass "status reports an unrecorded commit as unrecorded" ;;
  *) fail "GH-509: status did not report the missing record: $out" ;;
esac

# ---------------------------------------------------------------------------
# The coupling that produced a real false positive during development, now pinned.
#
# gate-status.sh decides which hosted runs contain a boundary job by mirroring that job's `if:`.
# The first draft matched any successful push/dispatch and reported a push to `development` — an
# UBUNTU CANARY run that never touched macOS — as boundary evidence. The tool built to prevent false
# promotion evidence was manufacturing it. If the workflow's condition changes and this filter does
# not, that returns silently.
echo "-- case 5: the status filter mirrors the boundary job's own trigger"
WF="$ROOT_DIR/.github/workflows/ci.yml"
if /usr/bin/grep -q "workflow_dispatch" "$STATUS" && /usr/bin/grep -q 'br == "main"' "$STATUS"; then
  pass "the status filter names both boundary triggers (workflow_dispatch, push to main)"
else
  fail "GH-509: gate-status.sh's filter does not mirror boundary-macos's if: — a canary green can be reported as boundary evidence"
fi
if /usr/bin/grep -q "refs/heads/main" "$WF" && /usr/bin/grep -q "workflow_dispatch" "$WF"; then
  pass "the workflow still triggers the boundary on exactly those two"
else
  fail "GH-509: boundary-macos's trigger changed — gate-status.sh's filter must change with it"
fi

echo
echo "  $TEST_NAME: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
