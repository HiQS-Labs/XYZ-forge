---
title: "Marathon lane PR body carries Closes #<issue>"
status: Complete
created: 2026-10-27
updated: 2026-10-27
owner: noelsaw1
gh_issue: 1234
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1234
doc_type: project
goal: "A Jog-dispatched Marathon lane PR closes its issue; other lanes only reference it"
phases: 1
---

# GH-1234: marathon lane PR body carries `Closes #<issue>`

## Problem (observed)

GH-1175 Phase 0, PR #1225 (2026-10-26). Marathon's lane PR for issue #416 had the body "Automated
marathon closeout for phase `gh-416-doc-trues-up-batch` (GH-561)." and `closingIssuesReferences: []`.
wave_reconcile treats a PR with no closing keyword as mention-only (GH-202), so merging it would have
left #416 OPEN and its doc in 2-WORKING. Fixed by hand by appending `Closes #416` before the merge.

Traced at base `5cab70c8`:

- `utils/py/marathon_drive.py:2667` `open_lane_pr()` calls `relay-automation/marathon-closeout.sh`
  with `--notes "Automated marathon closeout for phase \`<phase>\` (GH-561)."`. That is the only
  automated caller.
- The issue number is already derived in the same scope: `lane_issue_number()` (`:1579`), and in the
  receipt's `issue` field via `_derive_issue_number` (`:128`).
- A multi-phase issue must not close on its first lane PR. The frontmatter
  `umbrella|multiphase|multi_phase` declaration is **not** a reliable signal: plan QA round 1 found
  `PROJECT/2-WORKING/GH-648-HEADLESS-TURN-TIMEOUT/CAPTURE.md` (a nine-phase umbrella) without it.
  The reliable signal is the caller. Jog runs one issue as one Marathon phase (GH-280, one-phase
  executor). `marathon.sh` runs YAML waves, where one issue may span several phases.

## Requirements

1. When Jog dispatches the lane (one issue, one phase), the lane PR body carries `Closes #<issue>`.
2. Every other lane (marathon.sh waves, direct drives) carries `Refs #<issue>`. It never closes, so
   a multi-phase umbrella cannot close early.
3. A lane with no derivable issue keeps today's body.
4. No change to `marathon-closeout.sh` (manual use unchanged).

## Preflight bet check

- **Outcome sought:** merging a Jog/Marathon lane PR closes its issue, so reconcile moves the doc and
  ledger row without a hand edit.
- **Smallest viable bet:** one opt-in driver flag, `--lane-closes-issue`, which only Jog passes
  (`_marathon_argv_from_invocation`, `utils/py/jog_run.py:494`). `open_lane_pr()` appends
  `Closes #N` with the flag and `Refs #N` without it.
- **Alternatives rejected:**
  - The frontmatter umbrella flag: unreliable (GH-648 counterexample).
  - Parsing a MARATHON.yaml to count phases: the driver has no reliable link to its owning plan.
  - Teaching `marathon-closeout.sh` an `--issue` flag: a second place for the rule.
  - Always writing `Closes`: it closes umbrellas early.
- **Rollback:** revert one commit. Without the flag, every lane gets `Refs`, which is strictly safer
  than today and never closes anything.

## Plan

1. `utils/py/marathon_drive.py`:
   - add `parser.add_argument("--lane-closes-issue", action="store_true")`, next to
     `--allow-trunk-commit` (`:1091`), with a help line naming GH-1234;
   - in `open_lane_pr()`, set `issue = lane_issue_number()`. With an issue, append
     `\n\nCloses #<issue>` when the flag is set, otherwise `\n\nRefs #<issue>`. Without one, leave
     the body unchanged.
2. `utils/py/jog_run.py` `_marathon_argv_from_invocation`: when `invocation.get("issue")` is set and
   the flag is absent, append `--lane-closes-issue`.
3. The frozen Bash `marathon-drive.sh` fallback (`XYZ_PYTHON=0`, or python3 below 3.8) is not
   changed (GH-308). Jog only runs it when Python is unusable, which the default path never
   selects. This is a documented limitation.

## Non-goals

- Closing keywords for marathon.sh wave lanes. Whether a wave phase finishes its issue stays with
  wave_reconcile's existing open/umbrella rules.
- Lanes that bundle several issues (only the first derived issue counts, the same rule as
  `lane_issue_number`).
- Changing marathon-closeout.sh, wave_reconcile, or the frozen Bash driver.
- New tests (AGENTS.md *No new tests*, GH-831).

## Verification

- Existing suites: `test/gh280-jog-marathon-adapter.sh` (the Jog to Marathon adapter),
  `test/gh402-branch-enforcement.sh` (the lane PR attempt, around :292), and the routed final gate.
- Manual smoke under `TESTS-RESULTS/2026-10-27+GH-1234/`, run in a disposable clone, with a stub
  `gh` on PATH that records `gh pr create` argv. It drives `open_lane_pr` through a real driver run on
  a lane branch, using the gh402 harness shape:
  - **Main:** with `--lane-closes-issue`, the body ends `Closes #N`. **Red control:** at base it does
    not.
  - **Adjacent:**
    - without the flag the body ends `Refs #N`;
    - with no derivable issue the body is unchanged;
    - `_marathon_argv_from_invocation` adds the flag exactly once for an invocation with `issue`, and
      not for one with `issue: null`.

## Rating (2026-10-27)

`rated 65/55/50/85`.

- **sev 55:** a merged lane silently leaves its issue open and its doc and ledger row stale. It is
  recoverable by hand, and nothing is lost.
- **pri 65:** every Jog/Marathon lane hits it, and it blocks unattended landing (#1175). One observed
  incident; trend unknown.
- **appeal 50:** neutral.
- **effort 85:** a few lines plus a no-op refactor.

## Status

| What was just completed | What's next |
|---|---|
| Implemented; smoke PASS (TESTS-RESULTS/2026-10-27+GH-1234/smoke.md); final QA approved (codex, attested) | PR ready; awaiting merge |
