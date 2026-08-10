#!/usr/bin/env bash
# gate-evidence: {"form":"pre-fix-replay","observed":true,"result":"reproducer: bash test/gh460-pipe-buffer-sigpipe.sh. The pre-fix SHAPE is executed directly under `set -o pipefail` against a synthetic payload well past the 64KB pipe buffer: `printf '%s' \"$big\" | grep -Fq MARKER` exits 141 (128+13, SIGPIPE) even though the marker IS present, because grep -q exits on the match and printf is still writing. The same shape with a payload that fits the buffer exits 0, and the post-fix file-based form exits 0 at BOTH sizes. So the failure is attributable to payload size and to the pipe, not to the assertion's subject. Pre-fix result: non-zero, marker found. Post-fix result: zero. Both observed in one run, plus a static assertion that the production site no longer carries the shape."}
# GH-460: the tier1 "flake" was a SIGPIPE race against the pipe buffer, and it had no regression test.
#
# test/pdda-local-checks.sh did `printf '%s' "$real_out" | grep -Fq "SUMMARY [...]"`. `grep -q` exits
# the instant it matches, so once $real_out outgrew the 64KB pipe buffer printf was still writing when
# the reader vanished: SIGPIPE, and under _setup.sh's `set -o pipefail` that became the PIPELINE's
# status, breaking an && chain and failing an assertion whose subject had not changed. Five consecutive
# CI runs on identical code went pass/fail/fail/pass/fail, and it eventually blocked every open PR.
#
# The fix (grep a file) shipped WITHOUT a test, because the thing fixed was itself a test file. Both a
# codex and an agy review of the merged work independently called that the top gap, and both were
# right about why: the original site's coverage depends on the REAL repository's output size, so
# reverting the fix would leave the suite green until PROJECT/3-COMPLETED/ naturally grew past the
# buffer again — the exact silent-until-it-isn't behaviour that produced the incident.
#
# So this pins the shape synthetically, with a payload chosen to exceed the buffer deterministically
# rather than waiting for the repo to supply one:
#   (1) the pre-fix shape FAILS on a large payload whose marker is present   <- the defect, executed
#   (2) the same shape PASSES on a small payload                             <- size is the variable
#   (3) the post-fix file form PASSES at both sizes                          <- the fix, executed
#   (4) the production site no longer carries the piped shape                <- guards the revert
#   (5) its failure message still names WHICH summary is missing             <- the diagnosability half
#
# (2) is what makes this a control rather than a demonstration. Without it, (1) only shows "this
# pipeline failed"; with it, the difference is isolated to the payload crossing the buffer.
#
# (5) matters as much as the crash. The original failure dumped the entire run output and named
# nothing, so it was twice diagnosed as the unrelated GH-268 frontmatter WARN sitting at the top of
# that dump — a warn-only advisory that was never the assertion.
set -euo pipefail

source "$(dirname "$0")/_setup.sh" gh460-pipe-buffer-sigpipe
ROOT_REPO="$(cd "$(dirname "$0")/.." && pwd)"
SITE="$ROOT_REPO/test/pdda-local-checks.sh"

MARKER="SUMMARY [pdda-local-check-completed-status]"
# 1 MiB of filler after the marker. The marker is FIRST so grep -q exits immediately and printf is
# guaranteed to still be writing; the size is far past any plausible pipe capacity (64KB on Linux and
# macOS today) so this does not depend on the platform's exact buffer.
big="$(python3 -c 'import sys; print(sys.argv[1]); print("x"*1048576, end="")' "$MARKER")"
small="$MARKER"

# The pre-fix shape, executed. `|| rc=$?` rather than `set -e` abort: the non-zero status IS the
# observation here.
pipe_shape() {  # <payload> -> pipeline exit status
  local rc=0
  ( set -o pipefail; printf '%s' "$1" | grep -Fq "$MARKER" ) || rc=$?
  printf '%s' "$rc"
}
file_shape() {  # <payload> -> exit status of the post-fix form
  local rc=0 f="$WORK/payload.txt"
  printf '%s\n' "$1" > "$f"
  ( set -o pipefail; grep -Fq "$MARKER" "$f" ) || rc=$?
  printf '%s' "$rc"
}

# ── (1) the defect, executed ───────────────────────────────────────────────────────────────
rc_big="$(pipe_shape "$big")"
[ "$rc_big" -ne 0 ] \
  && pass "control: the pre-fix shape FAILS on a >64KB payload (exit $rc_big) even though the marker is present — SIGPIPE promoted to the pipeline status by pipefail" \
  || fail "control: the pre-fix shape passed on a 1MiB payload — this platform's pipe did not overflow, so the whole file proves nothing here"

# Report the signal explicitly when it is the classic one; a different non-zero status still counts as
# the defect, so this is a note rather than a second gate.
[ "$rc_big" -eq 141 ] \
  && pass "control: the status is 141 (128+13 = SIGPIPE), naming the mechanism rather than just 'non-zero'" \
  || pass "control: pipeline failed with $rc_big (non-zero is the defect; 141 would name SIGPIPE explicitly)"

# ── (2) same shape, small payload -> passes. Size is the variable. ──────────────────────────
rc_small="$(pipe_shape "$small")"
[ "$rc_small" -eq 0 ] \
  && pass "control: the SAME shape passes on a payload that fits the buffer — the failure is attributable to size, not to the assertion" \
  || fail "control: the pre-fix shape also failed on a tiny payload (exit $rc_small) — something other than the buffer is broken, and (1) is not evidence about GH-460"

# ── (3) the fix, executed, at both sizes ───────────────────────────────────────────────────
for label in big small; do
  eval "payload=\$$label"
  rc="$(file_shape "$payload")"
  [ "$rc" -eq 0 ] \
    && pass "the post-fix file-based form passes on the $label payload (exit 0) — there is no reader to lose" \
    || fail "the post-fix form failed on the $label payload (exit $rc)"
done

# ── (4) the production site no longer carries the shape ────────────────────────────────────
# Narrow on purpose: this asserts about the ONE site with evidence, not about the ~366 files that
# share the pattern harmlessly (issue #472 tracks that class). A repo-wide lint here would be a large
# blind sweep with no evidence per site.
#
# COMMENT LINES ARE STRIPPED FIRST, and that was not foresight — the first version of this assertion
# went red against the fixed file, because it matched the COMMENT documenting the rule ("never
# `printf "$real_out" | grep -q`") rather than any code. Same shape as the GH-64 scanner flagging its
# own explanatory comment: a text guard sees prose. Anything asserting about source text needs to say
# which lines count.
if grep -vE '^[[:space:]]*#' "$SITE" | grep -Eq 'printf .*"\$real_out" *\| *grep'; then
  fail "test/pdda-local-checks.sh has gone back to piping \$real_out into grep — the GH-460 incident is reintroduced"
else
  pass "test/pdda-local-checks.sh does not pipe \$real_out into grep (the reverted-fix guard)"
fi
grep -q 'real_out_file' "$SITE" \
  && pass "it reads the captured output from a file instead" \
  || fail "the file-based capture is gone from test/pdda-local-checks.sh"

# ── (5) the diagnosability half of the fix ─────────────────────────────────────────────────
grep -q 'check(s) did not run against the real repo:\$missing' "$SITE" \
  && pass "the failure message names WHICH summary is missing — the original named nothing and was twice misread as an unrelated WARN" \
  || fail "the failure message no longer names the missing check; a future failure is a bare output dump again"

echo "gh460-pipe-buffer-sigpipe: $PASS pass, $FAIL fail"
