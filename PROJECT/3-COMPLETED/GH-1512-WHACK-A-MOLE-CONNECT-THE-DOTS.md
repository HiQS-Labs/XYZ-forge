---
gh_issue: 1512
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1512
title: "whack-a-mole: chain connect-the-dots on invariant; debug-mantra: escalate unread paths to recon"
status: Complete
created: 2026-11-17
updated: 2026-11-17
doc_type: feedback
owner: Codex
goal: Chain connect-the-dots in whack-a-mole on the invariant, and escalate unread fail paths to recon in debug-mantra.
effort: 1
complexity: 1
risk: 1
phases: 1
ratings_provisional: false
---

# GH-1512 — whack-a-mole: chain connect-the-dots on invariant; debug-mantra: escalate unread paths to recon

Canonical discussion: [Issue #1512](https://github.com/HiQS-Labs/XYZ-forge/issues/1512).

## Status

| What was just completed | What's next |
|---|---|
| Step 7 executed: skill edits applied, pdda docs gate green (0 errors), candidate-bound publisher suites passed (gh620: 28/28, gh589: 39/39), smoke check complete, evidence recorded under TESTS-RESULTS/2026-11-17+GH-1512/. | Final Codex relay QA (Step 8). |

## Problem & Recon

- `skills/3-weekly/whack-a-mole/SKILL.md`: Currently chains `debug-mantra`, `recon`, and `sanity-check`. In §5 ("Understand the top cluster"), after uncovering root cause and the violated invariant, it jumps to drafting mechanism and remediation. But a recurring defect class is often already solved in another subsystem. Without checking existing subsystems via `/connect-the-dots`, engineers risk creating redundant parallel guard mechanisms or reinventing what already exists.
- `skills/1-hourly/debug-mantra/SKILL.md`: In Mantra 2 ("Know the fail path"), tactics include attaching a debugger, source tracing + knob enumeration, and in-code instrumentation. However, when a fail path traverses unread or unfamiliar modules, tracing without a map leads to blind guessing. Adding `recon` as an explicit escalation ensures engineers map unread surfaces before formulating root-cause hypotheses.

## Commensurate Complexity & Non-Goals

- Non-goal: No new sections in either skill document.
- Non-goal: No edits to the verbatim recital block in `debug-mantra/SKILL.md`.
- Non-goal: No new test suites, test files, or test registry entries (per `AGENTS.md` No new tests, GH-831).
- Non-goal: No runtime code or tooling changes; docs-only modifications.

## The Preflight Bet Check (Solution-Fit)

- **Outcome sought:** Guide agents and operators investigating recurring bugs to check for existing invariant enforcers with `connect-the-dots` before designing new mechanisms, and guide debugging sessions to map unfamiliar fail paths with `recon` before forming hypotheses.
- **Smallest viable bet:**
  1. Add one step (one sentence plus a separate hand-off line) to `skills/3-weekly/whack-a-mole/SKILL.md` §5 linking `../connect-the-dots/SKILL.md`.
  2. Add one sentence to `skills/1-hourly/debug-mantra/SKILL.md` §2 explanatory text linking `../recon/SKILL.md`.
- **Alternatives rejected:**
  - Creating a separate skill or sub-workflow for invariant checking (rejected: unnecessary ceremony and abstraction; existing skills can be directly chained).
  - Modifying the core 4-mantra recital block (rejected: would break the canonical, widely memorized recital text).
- **Rollback / containment:** Clean git revert of the two skill markdown files. Reversibility is Easy.

## Ordered Implementation & Verification

1. **Pre-implementation Plan QA (Step 6):** Run Codex relay review on this plan until Approved (max 3 rounds).
2. **Execute edits (Step 7):**
   - In `skills/3-weekly/whack-a-mole/SKILL.md`, insert step 4 in §5:
     ```markdown
     4. Invariant enforcer discovery: before proposing a new mechanism, run [connect-the-dots](../connect-the-dots/SKILL.md) on the violated rule (the invariant) to discover existing subsystems that already protect or enforce it, and name any existing enforcer in the umbrella issue.
        Hand off candidate modules and unaddressed gaps to §6.
     ```
     (Renumber remaining steps in §5 accordingly).
   - In `skills/1-hourly/debug-mantra/SKILL.md`, add to item 2 in §2:
     "When the fail path spans modules you have not read, run [recon](../recon/SKILL.md) on that path before forming the hypothesis."
3. **Verification & Gates:**
   - Confirm docs route by feeding changed paths to stdin:
     `git diff --name-only origin/development...HEAD | bash utils/ci-route.sh pull_request`
     and assert output contains `docs_only=true`, `route=docs`, and `tier=1`.
   - Run deterministic docs gate: `bash utils/pdda/pdda.sh run` and verify zero errors.
   - Run publisher suites bound to candidate commit:
     Create disposable `-gate` clone from origin (`https://github.com/HiQS-Labs/XYZ-forge.git`), checkout/fetch the exact candidate commit SHA, verify pre/post clone identity and matching skill bytes, and run:
     `bash test/gh620-skills-army-mini-sync.sh`
     `bash test/gh589-xyz-mini-sync.sh`
     Retain command output, exit codes, and `provenance.jsonl` under `TESTS-RESULTS/2026-11-17+GH-1512/publisher-suites/`.
   - Smoke check: read changed instructions from consumer entry points (read-only verification).
4. **Final Codex Relay QA (Step 8):** Relay review of the diff and test evidence.
5. **PR & Checkout Retirement (Step 9):** Push branch, open PR, post closeout comment on #1512, and retire task checkout with `merge_cleanup.py --retire-published-pr`.

## Acceptance Mapping

- [ ] `skills/3-weekly/whack-a-mole/SKILL.md` §5 updated with connect-the-dots step on invariant and umbrella issue naming, relatively linked (one sentence + separate hand-off line).
- [ ] `skills/1-hourly/debug-mantra/SKILL.md` §2 updated with recon escalation when fail path spans unread modules, relatively linked in explanatory text.
- [ ] No changes to the verbatim mantra recital block.
- [ ] No new sections added.
- [ ] No new tests or test registry entries (GH-831).
- [ ] Deterministic docs gate `utils/pdda/pdda.sh run` passes with zero errors.
- [ ] Publisher suites pass in disposable gate clone exercising the candidate commit SHA with attributable evidence under `TESTS-RESULTS/`.

## Rating Rationale

Rated: 60/50/50/85 (priority 60, severity 50, appeal 50 neutral, effort 85 cheapness).
- Priority 60: prevents recurring defect proliferation and redundant code.
- Severity 50: docs-only enhancement to debugging and triage methodologies.
- Appeal 50: neutral standard value per GH-1333 decision 5.
- Effort 85: very high cheapness; two surgical single-sentence additions.

## Lessons Learned (For Future Agents)

Pending implementation evidence; NO_ENTRY at planning time.
