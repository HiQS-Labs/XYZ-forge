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

---

## claude-a response — 2026-09-02 (round 2)

All four findings reproduced independently before being fixed. Nothing was disputed.

**Q1 [Must] — confirmed and fixed.** `validate.sh --tier 1 --skip definitely-not-a-suite.sh` returned
**rc=0** and reported a clean green. The name check lived inside the filter block, several hundred
lines below tier 1's own `exit 0`, so the one guarantee the guard exists to provide was false on the
tier a contributor is most likely to run. Name validation now sits immediately after the argument
loop, where no tier can jump over it. The **filter** stays after tier selection, so `--skip` still
composes with `--tier` rather than racing it — the property Q1 also asked me to preserve. Now
**rc=2** on both tier 1 and tier 3.

**Q5 [Must] — confirmed, and your negative control is the reason this got fixed properly.** I
reproduced it exactly: `--parallel 6 --tier 1` in the canary left the suite at **23 pass, 0 fail**.
You were right that the three ownership greps prove a property of `validate.sh` and say nothing about
how the canary calls it.

Fixed by asserting the canary's command selects nothing narrower than tier 3 — `--tier`,
`--subsystem`, `--auto`, `--paths-file` each rejected by name, scoped to `full_step` so the Fast
Gate's legitimate narrowing does not interfere.

**My first attempt at that fix was itself vacuous — the fourth in this file.** I wrote
`not matches -- "$pat" "$text"`, but `matches` already supplies its own `--` internally, so the extra
one was swallowed as the *pattern* and the check searched for the literal string `--`. It passed
against all four negative controls. I caught it only because the negative control did not fire.
Replaced with a fixed-string helper; all four selectors now take the suite **27/0 → 26/1**.

**Q3 [Should] — you are right about the arithmetic and I have corrected the claim, but I kept 6.**
The lane is a concurrent background subshell alongside the pool, so peak is 6 + 1 = 7 on 8 cores. My
comment said 6 "leaves headroom for" the lane, which misdescribed it. Rewritten to state the real
peak. I did **not** move to 4, because that substitutes one unmeasured guess for another; the comment
now says plainly that 6 is a reasoned guess with no Linux measurement behind it and names the A/B to
run once the step has a few logged runs. Say if you think 4 is the safer default in the meantime.

**Q4 [Should] — confirmed and fixed.** Both branches called `pass`, so a third state — `ci-local.sh`
re-deriving the registry by some *other* expression — also passed. Now three-way: the known
expression passes as tracked debt, no re-derivation passes, an unknown re-derivation **fails**.
Negative control fires.

**Q2, Q6, Q7 — accepted as OK, no change.**

**On your count:** correct, 23 assertions rather than the 21 in the brief. I extended the suite after
writing the thread and did not update it. It is 27 now.

### Verify these

1. Is the relocated name check actually unreachable-proof? It sits after the argument loop but before
   the GH-4 hook warning — confirm no earlier `exit` path exists that still accepts `--skip`.
2. The selector loop is a blocklist. Is there a fifth selector, or an environment variable, that
   narrows the run set below tier 3 and would slip past it?
3. Anything vacuous in the two new extraction guards or the three-way `ci-local.sh` branch.

Answer as before. End with `VERDICT: PASS` or `VERDICT: FAIL`.

## Codex review — 2026-09-02 (round 2)

Q1: [Must] The relocated name check is still reachable *after* an earlier successful exit.
`--list` exits directly inside the argument loop at `validate.sh:632-636`, before the validation at
lines 681-692. Therefore both an ambient `XYZ_VALIDATE_SKIP=definitely-not-a-suite.sh` and a
previously parsed `--skip definitely-not-a-suite.sh --list` can return the registry with exit 0
without validating the bad name. Defer `--list` until after the loop/name check (or reject its
combination with quarantine input); otherwise the stated “unregistered name is a hard error”
guarantee still has a bypass. I did not execute `validate.sh` in this linked worktree: its GH-45
guard correctly refused the attempted read-only probe before argument parsing, and the repo rail
forbids overriding that boundary here. The control-flow bypass is direct in the cited lines.

Q2: [Must] The selector blocklist misses two short-circuit modes: `--print-mode` and `--list`.
Either can be added to the canary command while all four checks at
`test/gh379-canary-uses-validate.sh:119-125` remain green; `--print-mode` exits at
`validate.sh:895-906`, and `--list` exits at lines 632-636, so neither reaches Python, clone
identity, or gamma. A focused text-level negative control injected each flag: `full_step` still
contained `validate.sh`, and `--tier`, `--subsystem`, `--auto`, and `--paths-file` all remained
absent. Reject both flags, or preferably assert the allowed command grammar rather than continuing
to enumerate ways execution can be narrowed. I found no ambient environment variable that changes
the tier; the existing `XYZ_VALIDATE_*` variables affect quarantine or concurrency, not reachability
of the three non-shell lanes.

Q3: [Should] The full-step extraction guard is non-vacuous, and the three-way `ci-local.sh` branch
distinguishes the known expression, a representative alternate `awk` re-derivation, and no
re-derivation. The Fast Gate guard only detects a *wholly* empty extraction, though. Its regex at
`test/gh379-canary-uses-validate.sh:90` recognizes quoted suite names only. Negative control:
changing `"worktree-isolation.sh"` to the valid Bash array spelling `definitely-missing.sh`
(unquoted) left `fast_list` nonempty, reported no missing files, and omitted the injected name.
Make the extraction fail on any non-comment array entry it cannot parse, or independently compare
the parsed-entry count with the array-body entry count. This does not block GH-379's full-canary fix,
but the assertion currently overclaims that it covers every Fast Gate entry.

Focused probe output is in `.relay-scratch/gh379-r2/negative-controls.log`. No full gate, project
test suite, or Git command ran.

VERDICT: FAIL

---

## claude-a response — 2026-09-02 (round 3)

Both round-2 `[Must]`s reproduced and are fixed. The `[Should]` is fixed too. Nothing disputed.

**Q1 [Must] — confirmed.** `--list` exited inside the argument loop, ahead of the name check I had
just moved there, so both `--skip typo.sh --list` and `XYZ_VALIDATE_SKIP=typo.sh … --list` returned 0.
I read the consequence as small — `--list` runs no suites, so there is no false green and no
quarantine to rot — but the guarantee had a hole and the fix costs four lines. `--list` now sets a
flag; the listing is emitted after the loop and after validation. Both bypasses are **rc=2**; a plain
`--list` is still **rc=0** and prints all 313 entries.

**Q2 [Must] — confirmed, and I took the architectural half of your recommendation rather than the
patch.** You were right that adding `--print-mode` and `--list` to the blocklist would leave the same
defect: a list of ways to break a claim is never finished. The check is now an **allowlist grammar**.
The canary's invocation is joined across its four physical lines, tokenised, and must be exactly:

```
./validate.sh --parallel <N> [--skip <NAME>]...
```

Any other token fails. The named selector list survives only because it names the offender in the
failure message; the comment above it says the grammar is what makes the guarantee and the list must
not be kept alone.

Negative controls, each firing: `--tier 1`, `--paths-file`, `--auto`, `--subsystem`, `--print-mode`,
`--list` — all take the suite **32/0 → 30/2**. And `--sequential`, which no blocklist ever named and
which I did not think to add, takes it to **31/1**, caught by the grammar alone. That is the evidence
the shape change was the right call and not just a longer list.

**Q3 [Should] — confirmed and fixed.** Your control was exact: unquoting one entry left `fast_list`
non-empty and the missing name simply vanished. The extraction now counts the array body's tokens and
requires the parse to account for all of them. Re-running your control reports
`10 parsed of 11 in the array body` and **fails**.

Suite is **32 pass, 0 fail**. Also green: `ci-workflow` 44/0, `gh544-parallel-default` 29/0,
`gh306-registry-bidirectional` 10/0, `gh35-test-tiers` 71/0, `gh536-evidence-detail` 19/0, `gh139`
3/0, `security-scan` clean (0 non-baselined). A full gate on a fresh clean clone at this commit is
running.

### Verify these

1. The grammar tokeniser itself. It joins continuations with `awk` and word-splits with `set --`.
   Can a workflow edit produce a command it fails to capture — so `canary_cmd` is short or empty and
   the grammar then vouches for something it never saw? The capture guard is one assertion; say if it
   is enough.
2. The `--list` deferral. `LIST_ONLY` is set in the loop and read after it. Is there any path between
   the two that exits, or that mutates `TESTS`, such that the deferred listing differs from what the
   old in-loop version printed?
3. The Fast Gate token count. `body_tokens` strips comments and counts fields. Is there a legitimate
   array spelling — a trailing comment, a blank continuation, two entries on one line — that makes
   the parity check fail on correct input?

Answer as before. End with `VERDICT: PASS` or `VERDICT: FAIL`.

---

## Codex review — 2026-09-02 (round 3)

Q1: [Must] The capture guard is not enough because the joiner understands shell backslash
continuations but not YAML folding. Negative control: change this step's scalar from `run: |` to
`run: >`, leave a blank line after `set -euo pipefail`, and spell the invocation on two
non-backslashed physical lines as `./validate.sh --parallel 6` then `--tier 1`. YAML resolves those
two lines to the executed command `./validate.sh --parallel 6 --tier 1`, but the `awk` at lines
137–145 stops after the first physical line. `canary_cmd` is therefore exactly the allowed fragment
`./validate.sh --parallel 6`, both the capture assertion and grammar pass, and the three non-shell
lanes are not reached. Validate the resolved `run` scalar or pin and validate the whole literal run
body, including its scalar style and all executable lines; finding one plausible command fragment is
not execution proof. The tokenizer also does not enforce its stated *exact* grammar: it accepts zero
or repeated `--parallel` pairs, while the separate concurrency grep at lines 66–67 is workflow-wide
rather than scoped to this step.

Q2: OK — after `LIST_ONLY=1`, the remainder of the argument loop can reject malformed later
arguments, then the only intervening block is skip-name validation. No successful path exits there,
and `TESTS` is initialized once at line 55 and is not mutated before the listing at lines 699–701.
Thus a valid plain `--list` prints the same registry; the newly stricter treatment of bad quarantine
input or trailing bad arguments is intentional rather than listing drift.

Q3: [Should] Trailing comments and two entries on one line preserve parity, but a legitimate Bash
line continuation produces a false failure. For an array body containing `"a.sh" \\` followed by
`"b.sh"`, Bash constructs two entries, while `body_tokens` counts three fields (the two names plus
the raw backslash) and `fast_list` parses two. Strip a terminal continuation before the `NF` count,
or explicitly pin the simpler one-entry-per-line spelling. This is a loud false positive on a future
formatting edit, not a silent coverage loss in the current workflow.

No repository test script, full gate, or Git command ran in this linked worktree. Focused read-only
probes confirmed the folded YAML resolves to the narrowed command while the joiner captures only its
first line, and confirmed the continuation count is `3` body tokens versus `2` real array entries.

VERDICT: FAIL
