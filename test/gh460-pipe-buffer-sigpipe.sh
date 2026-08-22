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
# Narrow on purpose: this asserts about the ONE site with the original evidence. (The "366 files" once
# quoted here was a measurement error — `grep -lc` prints a line per file SEARCHED, not per match. The
# real figures are 52 files / 285 occurrences; see section (6) for what #472 actually converted.)
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

# ── (6) GH-472: the same shape is gone from every file that sets `pipefail` ─────────────────
# Two assertions, deliberately: an EXPLICIT named-file list and a DERIVED scan. codex's plan review
# asked for the named list as the required guard, because a shell-grammar regex cannot reliably infer
# dynamic option state and a derived list can silently drift to empty. The derived scan is kept as a
# second, clearly-secondary check, because a file that GAINS `pipefail` later is the silent path back
# into this bug and no named list can see that coming.
#
# SCOPE OF THE CLAIM, stated because it is narrower than it looks. `pipefail` is not a property of a
# file; a caller can source one after enabling it, invoke `bash -o pipefail <file>`, export SHELLOPTS,
# or call a function from a pipefail context. What is asserted here is the SUPPORTED invocation:
# validate.sh runs each test as `bash test/<file>`, a fresh shell, so options are not inherited from
# the runner. The ~47 other files carrying this shape run with `set -u` only and are harmless UNDER
# THAT BOUNDARY — not categorically. A future sourced-library use should be a deliberate review
# decision, which is why this paragraph exists rather than a bare list.
#
# The fix applied to all 43 sites was to drop `q` from grep's flag cluster and redirect its stdout,
# NOT a here-string. `<<<` appends a newline that `printf '%s'` does not — measured: 1 byte becomes 2,
# and `grep -Fq ''` on empty input flips from no-match to match — so it is not semantics-preserving,
# which matters at the `-Fx` site. Dropping `-q` leaves the input byte-identical and simply lets grep
# read to EOF, so there is no reader to lose. A writer-side `{ printf … || true; }` was also tried and
# does NOT work: printf is a builtin, so SIGPIPE kills the pipeline's left subshell before `|| true`
# can run (measured: still 141).
GH472_FILES="test/gh308-frozen-twin-guard.sh test/gh438-acceptance-recheck.sh
test/gh284-p3-release-milestone.sh test/pdda-roadmap-coverage.sh utils/pdda-local-checks.sh
test/pdda-local-checks.sh"
# ANY producer piped into `grep -q`, not just printf. The first version matched `printf` only, and
# codex's QA review found what that missed: two `grep -v … | grep -qF` transcript scans with the
# identical failure. The producer is irrelevant — what matters is that `grep -q` can stop reading while
# something upstream is still writing.
gh472_shape() {  # <file> -> prints offending "line:text", with the file's REAL line numbers
  # Spellings covered after codex's QA round 2: a short cluster (-q, -Fq, -qiE), SEPARATE options
  # (-F -q), the long form (--quiet), and an explicit `command grep`. Numbering is done with grep -n on
  # the file itself and comments are filtered afterwards — the first version stripped comments FIRST,
  # which renumbered every hit and is why my reported line numbers disagreed with the reviewer's.
  # GH-544: the leading `(^|[^|])` is load-bearing — without it the SECOND `|` of a logical `||`
  # matched, so `cmd A || grep -q B` was reported as a SIGPIPE shape. It is not a pipeline at all: the
  # two sides never share a file descriptor and nothing can receive SIGPIPE. Found when an assertion
  # in test/ci-workflow.sh changed from `&&` to `||` and this suite went red with nothing piped
  # anywhere. Verified both directions: `a || grep -q x` no longer matches, while `b | grep -q y` and
  # the no-space `c|grep -Fq z` still do.
  grep -nE '(^|[^|])\|[[:space:]]*(command[[:space:]]+)?grep([[:space:]]+-[A-Za-z]+)*[[:space:]]+(-[A-Za-z]*q[A-Za-z]*|--quiet)([[:space:]]|$)' "$1" 2>/dev/null \
    | grep -vE '^[0-9]+:[[:space:]]*#'
}
named_bad=0
for rel in $GH472_FILES; do
  if [ -n "$(gh472_shape "$ROOT_REPO/$rel")" ]; then
    fail "GH-472: $rel sets pipefail and still pipes a variable into \`grep -q\` — the SIGPIPE shape is back"
    named_bad=$((named_bad + 1))
  fi
done
[ "$named_bad" -eq 0 ] \
  && pass "GH-472: all 6 pipefail-setting files that pipe repo-wide output are free of the piped \`grep -q\` shape (43 sites converted)" \
  || fail "GH-472: $named_bad of the 6 named files regressed"

# Derived, for files that do not exist yet. TWO conditions, not one — and the first draft of this
# assertion had only the first, which is how it caught its own author: `pipefail` alone flagged 35 more
# files and was a far broader claim than the fix behind it.
#
# The dangerous property is not `pipefail`; it is `pipefail` AND a payload that GROWS WITH THE
# REPOSITORY. That is what turned GH-460 from fine to blocking with no code change. The ~35 other
# pipefail files pipe fixture-sized output — a stub's stdout, one line, one number — which cannot reach
# the 64KB buffer no matter how large the repo gets. Converting them would be ~200 more edits for no
# measurable risk, and codex's plan review was explicit: do not expand this to all 285 occurrences.
#
# So the derived condition mirrors the at-risk definition exactly: sets pipefail AND invokes a
# repo-wide tool. A static check cannot measure payload growth, but "runs something that walks the
# repo" is a good and honest proxy for it.
#
# Known limits, accepted rather than papered over: full-line comments are stripped, but this cannot see
# a multiline pipeline or the shape inside a string literal. The named list above is the gate; this is
# the early-warning.
REPO_WIDE='pdda\.sh|pdda-local-checks|gate_inventory|swarm_preflight|git grep|git ls-files'
derived_bad=""
while IFS= read -r cand; do
  case " $GH472_FILES " in *" $cand "*) continue ;; esac
  # gh460 itself pipes deliberately: case (1) above EXECUTES the pre-fix shape as its control.
  case "$cand" in */gh460-pipe-buffer-sigpipe.sh) continue ;; esac
  grep -qE 'set -[a-zA-Z]*o pipefail|set -o pipefail|_setup\.sh' "$ROOT_REPO/$cand" 2>/dev/null || continue
  grep -qE "$REPO_WIDE" "$ROOT_REPO/$cand" 2>/dev/null || continue
  [ -n "$(gh472_shape "$ROOT_REPO/$cand")" ] && derived_bad="$derived_bad $cand"
done <<EOF
$(cd "$ROOT_REPO" && git ls-files 'test/*.sh' 'utils/*.sh' 'utils/**/*.sh' 'relay-automation/*.sh' 2>/dev/null)
EOF
[ -z "$derived_bad" ] \
  && pass "GH-472: no NEW script both sets pipefail and pipes repo-wide output into \`grep -q\`" \
  || fail "GH-472: a pipefail script piping repo-wide output carries the shape:$derived_bad"

# ── (7) the known exposure this PR cannot fix, pinned so it cannot grow ─────────────────────
# codex's QA review found the worst instance of this class, and it is NOT a flaky test:
#
#   relay-automation/agy-turn.sh:254   and   relay-automation/consult.sh:224
#     grep -v -e … "$LOG" | grep --quiet -F "$ROOT"
#
# Both set `set -euo pipefail` (:4). On a large transcript the downstream `grep -q` matches and exits,
# the upstream `grep -v` takes SIGPIPE, pipefail makes the pipeline non-zero, the `if` evaluates FALSE —
# and the branch that reports an isolation breach is skipped. It FAILS OPEN, on a containment check, on
# input that is model-generated and therefore unbounded. That is strictly worse than a false red.
#
# It is not fixed here for one reason: both files carry the GH-308 FROZEN banner, where Python is
# authoritative and the Bash twins must not be edited. GH-308 does provide a sanctioned escape (a commit
# carrying a Frozen-twin-exception), but invoking it belongs to a decision about containment, not to a
# PR about pipe hygiene. Recorded on #472 for the operator.
#
# The authoritative lane is clean: rtl.narration_mentions_root reads the transcript line by line in
# Python with no pipe at all, and per GH-410 the result is advisory there rather than turn-failing. The
# Bash path runs only when XYZ_PYTHON=0 is set explicitly or python3 is missing/<3.8.
#
# So this asserts two things instead of fixing it: the Python path stays pipe-free, and the exposed set
# stays EMPTY — any instance under relay-automation/ now fails this gate.
grep -nE '\|[[:space:]]*grep[[:space:]]+-[A-Za-z]*q' "$ROOT_REPO/utils/py/rtl.py" >/dev/null 2>&1 \
  && fail "the Python transcript scan now pipes into grep -q — the authoritative lane has acquired the Bash lane's fail-open" \
  || pass "GH-472: no shell-pipe-into-grep -q text in utils/py/rtl.py (a text check, NOT proof that narration_mentions_root stays line-by-line — codex's QA said so and it is right)"

exposed=""
while IFS= read -r cand; do
  grep -qE 'set -[a-zA-Z]*o pipefail' "$ROOT_REPO/$cand" 2>/dev/null || continue
  [ -n "$(gh472_shape "$ROOT_REPO/$cand")" ] && exposed="$exposed $cand"
done <<EOF
$(cd "$ROOT_REPO" && git ls-files 'relay-automation/*.sh' 2>/dev/null)
EOF
# HISTORY, kept because the reasoning is the reusable part. Five files under relay-automation/ carried
# this shape; four were GH-308 FROZEN and all four set `set -euo pipefail` at :4, so each was a genuine
# fail-open:
#   agy-turn.sh / consult.sh   — `grep -v … | grep -qF "$ROOT"` fails open on an ISOLATION BREACH check,
#     on model-generated (unbounded) transcript input. The worst of the set.
#   marathon-drive.sh (x2)     — `git diff --name-only | grep -q .` and
#     `git status --porcelain | grep -qE '^(\?\?|A )'` fail open on CHANGE detection: "no new test was
#     added" when one was.
#   poll.sh                    — `git status --porcelain | grep -q . && return 1 || return 0` returns
#     "clean" for a DIRTY tree.
#
# I first deferred all four as untouchable and asserted the exposed set instead. codex's QA rejected
# that as "an inventory/debt tripwire, not a mitigation" — a green gate that knowingly permits a
# fail-open — and pointed out that GH-308 documents `Frozen-twin-exception` for exactly this: a safety
# defect in a frozen twin. That was the right call, so all four are fixed here under per-file
# exceptions, and the expected exposure is now ZERO.
expected=""
[ "$(printf '%s' "$exposed" | tr ' ' '\n' | sort | tr -d '\n')" = "$(printf '%s' "$expected" | tr ' ' '\n' | sort | tr -d '\n')" ] \
  && pass "GH-472: the known GH-308-frozen exposure set under relay-automation/ is EMPTY — all four frozen fail-opens are fixed" \
  || fail "GH-472: the frozen-shim exposure set changed (expected none, got:$exposed) — either one was fixed (update this gate) or a new one appeared"

echo "gh460-pipe-buffer-sigpipe: $PASS pass, $FAIL fail"
