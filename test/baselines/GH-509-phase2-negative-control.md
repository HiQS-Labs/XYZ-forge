# GH-509 Phase 2 — recorded negative control: the ubuntu job is advisory

Per #419, a check never observed failing is not evidence. This records both new assertions in
`test/ci-workflow.sh` being **observed red**, each for its own reason, and green again on restore.

## What is being asserted, and what is deliberately NOT

These checks assert the workflow **declares** the advisory contract. They **cannot** assert GitHub's
runtime semantics — that `continue-on-error: true` at job level really does keep a workflow run green
while leaving the job's own conclusion queryable through the jobs API.

That gap is named rather than papered over. The acceptance criterion in
`PROJECT/2-WORKING/GH-509-CI-MINUTE-BURN.md` is a **witnessed hosted run**, not a green grep. This
file is evidence that the greps work, not that the platform behaves.

## Method

The two mutations are applied to the real `.github/workflows/ci.yml`, restored from a backup between
each, with the file's `git diff --stat` checked afterwards to prove the tree came back unchanged.

## Direction 1 — remove the job-level `continue-on-error`

```
sed -i '' '/^    continue-on-error: true$/d' .github/workflows/ci.yml
bash test/ci-workflow.sh

  FAIL: GH-509: the ubuntu job must be advisory — a Linux failure is portability drift, not breakage
  passed: 29
  failed: 1
```

**Exactly one** assertion fails. That matters: a mutation that reddens several checks at once cannot
distinguish a precise assertion from a blunt one.

Note also what did *not* happen. The job comment contains the literal text `continue-on-error: true`
in prose, and the assertion is anchored `^[[:space:]]*…[[:space:]]*$` so the comment cannot satisfy
it. A looser `grep -q continue-on-error` would have passed on the mutated file — an assertion that
can be satisfied by its own documentation is worth nothing.

## Direction 2 — remove `if: always()` from the verdict step

```
  FAIL: GH-509: the canary verdict lacks if: always() — it is skipped in the only case it matters
  passed: 29
  failed: 1
```

`if: always()` is the load-bearing half of the verdict step. Without it, the step is skipped whenever
an earlier step failed — so the canary goes silent in precisely the situation it exists to report on,
and every run that reaches the verdict is green by construction. A green-only canary is
indistinguishable from a working one until the day it matters.

### The `if: always()` assertion was rewritten, and the control re-run afterwards

Recorded because it would otherwise be invisible. The first draft of that assertion was
`awk … | grep -q ok`, and `test/ci-workflow.sh` sets `pipefail` — which is precisely the **GH-472
SIGPIPE shape**. The repo's own guard caught it on the first full `validate.sh` run:

```
FAIL: GH-472: a pipefail script piping repo-wide output carries the shape: test/ci-workflow.sh
```

Fixed by deleting the pipe rather than working around it — `awk` already carries an exit status, so
the pipe was never needed. `test/gh460-pipe-buffer-sigpipe.sh` is 12/0 after the change.

**The control above was then re-run against the rewritten assertion**, not inherited from the piped
version. That matters: a witnessed red for code that no longer exists is not evidence about the code
that shipped.

## Direction 3 — restore

```
  passed: 30
  failed: 0
$ git diff --stat .github/workflows/ci.yml
 .github/workflows/ci.yml | 50 +++++++++++++++++++++++++++++++++++++++++++++++-
```

30/0, and the diff is the Phase 2 change alone — no mutation residue.

## Why this job stopped being a gate

Recorded for whoever finds `continue-on-error: true` later and assumes it was laziness.

XYZ ships to **macOS developers**. Linux and Windows are on the roadmap and are not here yet, so a
ubuntu failure reports on a platform with no users. On 2026-08-12 all three CI failures were of that
shape — agent CLIs absent from the runner — and `development` sat red for **11 of 14 runs across ~5
hours and 8 commits** with nobody reading it. A red that means "would not work on a platform we do not
support" is worse than no red, because it trains everyone to ignore the channel that might one day say
something real.

**Advisory is not the same as read**, and this control does not claim otherwise — that critique came
from the agy review of the plan and was accepted. Making a job non-blocking supplies no reason for
anyone to look at it. The mechanism that makes the canary *read* is a separate acceptance criterion:
its status appears in the promotion output, at the moment a human is already deciding. If two
consecutive promotions ship with drift named and unresolved, this job has proven it is not actioned and
should be deleted rather than kept as decoration.
