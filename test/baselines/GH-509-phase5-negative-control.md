# GH-509 Phase 5 — negative control: removing the macOS boundary's `workflow_dispatch` trigger

Date: 2026-08-13 · Branch: `fix/gh509-macos-dispatch-off` · Suite: `test/gh509-gate-evidence.sh`

## What changed and why a control was needed

`boundary-macos` was gated on `workflow_dispatch OR push to main`. The dispatch trigger was removed
after the org's August usage showed **75 macOS minutes = $4.65 net against a $10 monthly budget** —
more than 2,740 Ubuntu minutes ($4.44 net) cost, because macOS bills ~10× *and* draws no
included-minute discount on a private repo.

The change touches a **coupled pair**: `utils/gate-status.sh` decides which hosted runs contain a
macOS job by mirroring that `if:`. Case 5 of this suite exists because an earlier draft of that
filter accepted any successful push/dispatch and reported an ubuntu-only run as boundary evidence.
Removing the trigger re-opens the identical false green **from the other direction**: a
`workflow_dispatch` run now contains no macOS job at all, so a filter still accepting it would
manufacture promotion evidence out of an ubuntu-only run. Both assertions were therefore rewritten,
and both had to be witnessed red.

## Why the first control run was insufficient, and what replaced it

`fail()` in `test/_setup.sh:122` exits on the first failure unless `TEST_SOFT_FAIL=1`. The first
control run therefore aborted after assertion 1 and **never exercised assertion 2** — a red that
proves one assertion and silently says nothing about the other. Re-run under `TEST_SOFT_FAIL=1`, and
then mutated one file at a time so each assertion is witnessed **failing alone**. One failure per
mutation is the property that separates a precise assertion from a blunt one; an assertion that
fires on both mutations would not distinguish which half drifted.

## Four directions, observed

| # | Source state | Result |
|---|---|---|
| RED | both files at `origin/development` (dispatch still armed) | **15 passed, 2 failed** — both new assertions fail |
| RED-B | workflow reverted, filter fixed | **16 passed, 1 failed** — only the boundary-`if:` assertion fails |
| RED-C | filter reverted, workflow fixed | **16 passed, 1 failed** — only the status-filter assertion fails |
| GREEN | both fixed | **17 passed, 0 failed** |

Verbatim failure text (RED):

```
-- case 5: the status filter mirrors the boundary job's own trigger
  FAIL: GH-509: gate-status.sh's filter does not mirror boundary-macos's if: — a dispatch run has no macOS job in it, so accepting one reports an ubuntu-only run as boundary evidence
  FAIL: GH-509: boundary-macos's trigger changed — gate-status.sh's filter must change with it, and re-arming workflow_dispatch re-opens the ~$1.25-1.50-per-dispatch spend

  gh509-gate-evidence: 15 passed, 2 failed
```

## The assertion-shape decision, recorded

Both halves assert on the **specific deciding line**, not on whether a string appears anywhere in the
file:

- the status filter's `if ev ==` line, extracted with `grep -E '^[[:space:]]*if ev =='`
- the boundary job's own `if:` line, extracted from its block with `awk '/^  boundary-macos:/{f=1} f && /^[[:space:]]*if:/{print; exit}'`

This is load-bearing rather than stylistic. `workflow_dispatch` is still a **legitimate** trigger at
the workflow level — it drives the ubuntu full route — and both files discuss it in prose comments.
A whole-file `grep -q workflow_dispatch` would pass against a re-armed boundary purely on the
strength of the `on:` block or a comment, so the assertion would become decoration exactly when it
was needed. RED-B is the direction that proves this: the workflow file there still contains
`workflow_dispatch` several times over, and the assertion still fails on the one line that decides.

## Honest limit

These assert what the workflow **declares**. They cannot prove GitHub's runtime scheduling — that a
dispatch now really produces no macOS job is a claim about the platform's evaluation of `if:`, and
witnessing it needs a hosted dispatch, which is the spend this change exists to stop. The observable
substitute is the invoice: macOS minutes should stop accruing.
