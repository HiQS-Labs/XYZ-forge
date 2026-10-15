---
gh_issue: 1088
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1088
title: "start-task: orchestrator smoke check (main path + one adjacent path) before final relay QA"
status: Proposed (1-INBOX — plan drafted, awaiting plan QA)
created: 2026-10-15
doc_type: plan
goal: The orchestrator runs the changed entry point once on its main path and once on one adjacent real-world path, records it as a manual check, and hands that receipt to the final reviewer.
effort: 1
complexity: 1
risk: 1
phases: 1
---

# GH-1088: start-task orchestrator smoke check

## Problem (observed)

`skills/1-hourly/start-task/SKILL.md` (base `d48aa774`) has no step in which the orchestrator runs the
change itself before the independent reviewer sees it.

- Step 7 (≈L216-251) runs existing suites and the routed gate. These prove nothing regressed, but
  rarely drive the new behaviour as an operator will.
- Step 8 (≈L253) is the independent Codex review, which grades code and evidence.
- Step 9 (≈L274) checks the diff for scope and accidental files, and the PR's base, head and checks.
- Step 6 (≈L211) says "Do not silently substitute a self-review or consult." That is correct, but
  nothing else prompts the author to run the change once.

**Evidence (GH-1064, #1069).** After Codex final QA approved, outside reviewers found three
behavioural bugs, each one step past the happy path:

- #1074: `--resume` landing only new PRs exited 0 with the earlier batch's QA pending.
- #1074: a record without `landed_order` read as "nothing landed".
- #1084: a plain rerun without `--resume` after landing exited 0, bypassing the QA gate.

Nobody ran the resume or rerun once. The green suites and approved review did not cover them.

## Requirements

1. After implementation and focused checks, before final relay QA, the orchestrator runs the changed
   entry point once on its **main path** and once on **one adjacent real-world path**. Adjacent
   means the nearest variation an operator will actually hit: a resume, a rerun, a second invocation,
   or empty or already-done input.
2. Record the commands, observed output and verdict as a manual check under
   `TESTS-RESULTS/<date>+GH-<n>/` with provenance. There are no new suites or tests (GH-831).
3. The receipt goes to the final reviewer as evidence. It never replaces or substitutes for the
   independent review, and it never counts as one.
4. Scale it to the change. For documentation-only work, read the changed instruction once from its
   consumer's entry point, or skip with a one-line reason.
5. A smoke failure is a defect to fix (or a blocker to record) before final QA, not a note to the reviewer.

## Smallest surface

The only file changed is `skills/1-hourly/start-task/SKILL.md`:

- **Step 7:** append one short paragraph, "Smoke the change before final QA".
- **Step 8:** add the smoke receipt to the list of evidence the final review receives.
- **The recited summary, item 4:** add a few words so the step is visible at recitation.

## Non-goals

- No new test framework, runner, script, gate or registry entry.
- No change to the independent-review requirement, or to step 6's "no self-review" rule.
- No change to other skills (relay-xyz, workhorse, swe).
- No refresh of the deployed Skills Army copy. That is a post-merge step; the deployed copy is
  already behind the repo (it lacks GH-1059).

## Preflight bet check

- **Outcome sought:** fewer behavioural defects reach the independent reviewer and outside reviewers.
  The author catches the obvious resume, rerun or second-run bugs first.
- **Smallest viable bet:** a few sentences in an existing step, plus a manual-check receipt using the
  existing `TESTS-RESULTS/` convention.
- **Alternative rejected:** a new smoke-test suite or runner. GH-831 forbids it, and it doesn't
  scale to a docs-only change.
- **Alternative rejected:** asking the reviewer to run the code. That blurs the author and reviewer
  roles, and reviewers run headless in isolated worktrees.
- **Rollback:** revert the single-file edit.

## Dependencies and risks

- Instruction-only change. The gh609 contract (`test/gh609-sdlc-agent-gaps.sh`) pins start-task's
  resume-reconciliation wording; this edit leaves that text untouched.
- The gh615 and gh616 start-task suites are switched off (GH-831).
- Risk: smoke runs that mutate shared state. Mitigation: the paragraph points to the existing rule —
  mutation-heavy runs use a disposable full clone.

## Verification

- `utils/ci-route.sh pull_request` on the changed paths gives `route=docs tier=1`, so the final gate is
  `bash utils/pdda/pdda.sh run`, run once on the final commit.
- `bash test/gh609-sdlc-agent-gaps.sh` stays green, since the start-task contract text is unchanged.
- **Manual check:** apply the new step to this change itself, as a docs-only smoke. Read step 7→8 as
  an agent would, from the recited summary through to the final-QA packet. Confirm that the smoke
  receipt appears in step 8's evidence list. Record this under `TESTS-RESULTS/2026-10-15+GH-1088/`.

## Rating (2026-10-15)

Rating: pri 55 / sev 45 / appeal 50 / effort 85.

- **Severity 45:** this is a process gap, not a crash. In GH-1064 it let three medium behavioural bugs
  ship past an approved review (#1074, #1084). Each was caught before harm, but only by outside reviewers.
- **Priority 55:** the operator asked for it directly. It applies to every start-task run.
- **Appeal 50:** neutral; the operator gave no desirability score.
- **Effort 85:** a single-file instruction edit.
- **Recurrence:** one confirmed episode (GH-1064, 2026-10-14/15). The trend is unknown, since there
  is no prior tracking of this class.

## State

| Issue | Clone / branch | State | PR |
|---|---|---|---|
| [#1088](https://github.com/HiQS-Labs/XYZ-forge/issues/1088) | `XYZ-forge-gh1088-start-task-smoke-check-2026-10-15` / `docs/XYZ-forge-gh1088-start-task-smoke-check-2026-10-15` | plan drafted | — |
