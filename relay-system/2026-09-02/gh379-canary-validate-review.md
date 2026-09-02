---
Goal: Adversarially review the GH-379 fix on branch fix/gh379-canary-uses-validate
Date: 2026-09-02
NEXT: agy
STATUS: In Progress
---

# Context

**Branch under review:** `fix/gh379-canary-uses-validate`, one commit (`db8c9853`) on top of
`origin/development`, plus uncommitted follow-up fixes described below.

**Issue #379:** the hosted Ubuntu canary's full-suite step did not call `validate.sh`. It scraped the
`TESTS=(...)` array out of `validate.sh` with `sed`/`grep` and ran its own serial `for` loop, in order
to carry three skips. Three losses hid inside that:

1. **Parallelism.** GH-528 measured 946.0s → 184.3s at `--parallel 8` with byte-identical pass/fail
   sets. The hand-rolled loop was serial: 13m 14s, 88% of the canary job's wall.
2. **The contention-retry.** `validate.sh` re-runs a pooled failure alone before believing it. A bare
   for-loop has no such filter.
3. **Three non-shell lanes.** `python:test_python_layer.py`, `clone-identity-invariant` and
   `gamma-poison-staleness-probe` are not members of `TESTS`, so a `.sh`-only scrape never saw them.
   **They had never executed on Linux.** That is the serious half — a coverage hole dressed as a speed
   optimization.

## What the branch changes

| file | change |
|---|---|
| `validate.sh` | new `--skip <suite>` / `XYZ_VALIDATE_SKIP=a.sh,b.sh` quarantine mechanism, with three guards |
| `.github/workflows/ci.yml` | the canary step now runs `./validate.sh --parallel 6 --skip acorn-extract.sh --skip registry-lock-concurrency.sh --skip pdda-repo-contract.sh` |
| `test/gh379-canary-uses-validate.sh` | **new**, 21 assertions — the regression guard |
| `test/ci-workflow.sh` | two existing assertions **inverted** (see Q4) |

The three `--skip` guards, each because the opposite has already bitten this repo:

1. an unregistered name is a hard error (exit 2) — a typo'd skip that matches nothing looks identical
   to one that works;
2. every skip is echoed in the header AND repeated in the summary;
3. any skip disqualifies the run as promotion evidence, and skipping everything is refused rather
   than reported as a zero-test green.

## Two defects I already found and fixed — verify the fixes, do not re-report them

Both were in my own work, both found before handing this over. Named here so you spend your effort
elsewhere, and so you can check the fixes rather than the bugs.

**(a) `validate.sh` died one line before its own guard.** bash 3.2 (the macOS default) treats
`"${empty[@]}"` as an unbound variable under `set -u`, so `RUN_TESTS=("${_kept[@]}")` aborted with
`_kept[@]: unbound variable` before the "refusing a zero-test green" message could print. Reproduced,
then fixed by moving the guard above the assignment. Negative control: transposing them back takes the
suite 21/0 → 20/1.

**(b) An assertion in my own new test was vacuous.** It grepped the output for `^=== .*\.sh ===` — the
marker format of the CI for-loop this issue *deletes*. `validate.sh` never emits it, so the assertion
could not fail. Corrected to `^(Running |\[parallel\] )`, which is what `validate.sh` actually prints.

## Definition of Done

You give a verdict of **PASS** or **FAIL** on the branch, with every finding classified `[Must]`,
`[Should]`, or `[Note]`. A `[Must]` blocks the merge.

# Read before answering

- `validate.sh` — the `--skip` argparse case (~line 638), the `SKIP_SUITES` env parse (~line 616), the
  quarantine filter block (~line 981), the summary line (~line 1276)
- `.github/workflows/ci.yml` — the `Run validate.sh suite` step and its comment block (~line 450)
- `test/gh379-canary-uses-validate.sh` — all of it
- `test/ci-workflow.sh` — the two inverted assertions
- `git log -1 db8c9853` and `git diff origin/development...HEAD`

# Adjudicate these, numbered, one at a time

**Q1 — Is the quarantine filter in the right place?** It sits *after* the tier-2 `if` block closes and
*before* the GH-1 clone-identity snapshot. My claim is that `--skip` therefore composes with `--tier`
rather than racing it. Check the actual control flow: is `SKIPPED_SUITES=()` reachable on *every* path
that later reads `${#SKIPPED_SUITES[@]}` in the summary? A tier-1 or `--paths-file` run that exits or
branches around line 981 and still reaches line ~1276 would be an unbound-variable crash of exactly
the class described in (a).

**Q2 — Does `XYZ_VALIDATE_SKIP` compose correctly with `--skip`?** I parse the env *before* the flag
loop so the two accumulate. Argue the opposite case: is silent composition right, or should an
explicit flag override the environment the way `--parallel` overrides `XYZ_VALIDATE_PARALLEL`? Note the
inconsistency if you think it matters. Also check the IFS save/restore and the whitespace trim.

**Q3 — Is `--parallel 6` defensible on the 8-core runner, and is pinning it correct?** I pinned it
explicitly rather than inheriting the GH-544 default, reasoning that a canary which inherits cannot say
what it ran. But 6 is a guess with no measurement behind it, and GH-528's evidence is from a 10-core
Mac. Say whether the number is wrong, and whether an unmeasured pin is better or worse than an
inherited default.

**Q4 — Was inverting the two `ci-workflow.sh` assertions right, or did I delete real coverage?** They
previously required `ci.yml` and `ci-local.sh` to parse `TESTS` with the *same* expression, "so the two
cannot drift". I judged that this pinned *parity between two hand-rolled copies of the runner* rather
than forbidding copies — both stayed in agreement and both stayed wrong. I inverted them to: `ci.yml`
must not parse `TESTS` at all, and `ci-local.sh` is named as the remaining tracked copy. **Challenge
this specifically.** Is there a property the old pair protected that the new pair does not?

**Q5 — Hunt for more vacuous assertions in `test/gh379-canary-uses-validate.sh`.** I have already
shipped two in this one file. Assume there is a third. For each of the 21, ask: what input makes it
fail? If you cannot name one, say so. Pay particular attention to the `awk` range extraction of the
full-suite step and the `FAST_TESTS` list scrape — both are range expressions over YAML, and both can
capture nothing while appearing to work.

**Q6 — Is the coverage claim honest?** I assert the canary now runs the three non-shell lanes for the
first time on Linux. Is that actually true of the code path `./validate.sh --parallel 6` takes, or is
there a condition (tier, env, `RELAY_SELF_SUFFICIENCY_SKIP: "1"`) under which those lanes are still
skipped? If they are still skipped, the headline claim of this branch is false.

**Q7 — Anything else that would make this unsafe to merge.** Including: does the canary's `set -euo
pipefail` plus `./validate.sh` exit code still produce the intended job conclusion given
`continue-on-error: true`? Is anything in the deleted for-loop load-bearing and not replaced?

Answer each as `Q<n>: [Must|Should|Note] <finding>` or `Q<n>: OK — <one line why>`. End with
`VERDICT: PASS` or `VERDICT: FAIL`.

---

## Codex review — 2026-09-02

Q1: [Must] `SKIPPED_SUITES=()` is initialized on every path that reaches the summary, so I do not
find the proposed tier-2/`--paths-file` unbound-array crash. The filter is still too late: tier 1
exits at lines 917–922 before skip names are validated at lines 995–1001. An isolated probe of
`validate.sh --tier 1 --skip definitely-not-a-suite.sh` returned 0, contradicting the stated hard
error guarantee. Validate requested names immediately after argument parsing, then filter
`RUN_TESTS` after tier selection.

Q2: OK — composition is right for an additive set-valued quarantine; unlike the scalar concurrency
width, an explicit skip does not logically replace other requested skips. The comma split restores
`IFS`, trims both ends, ignores empty fields, and duplicates collapse when the selected run set is
filtered.

Q3: [Should] pinning is better than silently inheriting a changing default, but 6 is not supported by
the cited measurement and the rationale overstates its headroom. `validate.sh` runs the six-worker
pool alongside one serialized driver-lock lane, so the peak is seven suite processes on the
eight-core runner, not six. Measure 4/6 on that runner or pin the balanced four-worker width until
there is Linux evidence for 6.

Q4: [Should] removing the workflow's registry scrape is the correct inversion; the old parity check
protected agreement between two incomplete runners, a property no longer worth keeping. The new
`ci-local.sh` branch is not an assertion, though: both outcomes call `pass`, and a different
hand-rolled parse would also pass. Make it distinguish the known debt, no re-derivation, and an
unknown replacement re-derivation; otherwise the claimed tracking is only prose.

Q5: [Must] the central reachability assertion is vacuous. Negative control: replacing the canary
command with `./validate.sh --parallel 6 --tier 1` made the GH-379 test report **23 pass, 0 fail**,
even though tier 1 exits before Python, clone identity, and gamma-poison execute. The three ownership
greps prove only that result labels remain in `validate.sh`; they do not prove the canary selects the
tier-3 path that reaches them. Scope the command assertion to `full_step` and reject tier/selector
flags (or positively assert the effective tier-3 invocation). The two named extraction guards are
not vacuous: an empty full-step extraction fails its `validate.sh` check, and an empty `FAST_TESTS`
extraction fails `test -n`. Also, the file currently executes 23 assertions, not the stated 21.

Q6: OK — the current workflow command selects no tier, `TIER` defaults to 3, and
`RELAY_SELF_SUFFICIENCY_SKIP=1` only makes the registered live-agent shell suite self-skip. On this
path pytest and gamma are tier-3 lanes, while clone identity is unconditional after the shell suites;
all three are reachable. Q5 means that property is not regression-pinned.

Q7: [Note] current failure propagation is intact: a nonzero validator result fails the step under
`set -e`, the `if: always()` verdict observes the prior status, and job-level
`continue-on-error: true` keeps the Ubuntu result advisory. The validator replaces the deleted
loop's continue-through-failures behavior with pooled result collection and serial retry. No other
load-bearing loop behavior appears lost. Per the turn constraint, I reviewed the working-tree files
and did not run the requested Git log/diff. Focused evidence is under
`.relay-scratch/gh379-probe/test-output.log`, `.relay-scratch/gh379-tier1-control/test-output.log`,
and `.relay-scratch/gh379-probe/tier1-invalid-skip.log`; no full gate ran.

VERDICT: FAIL
