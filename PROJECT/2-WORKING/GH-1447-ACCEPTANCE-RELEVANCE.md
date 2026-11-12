---
issue: 1447
title: Acceptance relevance and complete outcome accounting
status: planned
created: 2026-11-12
updated: 2026-11-12
owner: Codex
doc_type: improvement
goal: Make acceptance relevance and incomplete requested outcomes visible without new machinery
---

# Acceptance relevance and complete outcome accounting

## Status

| What was just completed | What's next |
|---|---|
| Existing review/closeout and historical probe failure traced at 712a73b4. | Plan QA Approved; wording and7-case replay complete; spike1448 filed. Final QA and normal gated PR publication next. |

## Observed

start-task Step6 already asks where the unchanged candidate is rejected; it does not explicitly ask what artifact/behavior the check observes. Flywheel existing handoff preserves objective/evidence/budgets, but lacks explicit final mapping of every outcome and later amendment. GH1386 retained 2026-11-11 SUMMARY records python3 -c promotion refusal before builder, repaired by unchanged assertions in manual_probe.py. Current jog_run.lint_probe checks trivial commands and filesystem paths; swarm_preflight.eval_probes evaluates command exit status. Neither proves semantic relevance.

## Plan

1. Extend existing start-task Step6 with the requested artifact/behavior-to-outcome question; no new review stage. Extend Flywheel existing handoff with current-request accounting and subtask/integration distinction.
2. One bounded offline replay: extract exact historical GH1171/GH1315 inline commands from f98ad1d9 and repaired file commands from811d5823; call current lint_probe without executing inherited commands. Use empty/trivial/missing/supported-file controls. Compare admission parsing/evaluation boundaries by source; do not claim live workflow or semantic correctness from lint success. Max one replay plus one correction of replay setup; no runtime implementation in this task.
3. Retain inputs, source hashes, results and manual content consumer checks under TESTS-RESULTS/2026-11-12+GH-1447. Determine whether a surgical validator follow-up is justified. File separate idea spike after replay with its uncertainty and existing fix site.
4. Independent final Codex relay, normal classified gate in disposable fullclone, PR to development. No merge/deploy.

## Acceptance

- [ ] Preparation review asks what each acceptance check observes and why it establishes the requested outcome.
- [ ] Flywheel final report maps every requested outcome/amendment to evidence or unresolved disposition; local completion does not imply integration.
- [ ] Bounded replay preserves real input provenance and tests empty/trivial refusal plus valid control; semantic validity remains explicitly unproved.
- [ ] Independent plan/final QA and applicable normal publication gate pass, and separate exploration issue is linked.

## Blast radius and rollback

Easy: only two skill instruction files plus docs/evidence/ledger. Consumers are existing review packets and Flywheel closeout, no runtime or authority change. Revert instruction commit to rollback. No new scripts installed, suites, gates, hooks, queue, provider calls from replay or unlazy imports. Potential follow-up runtime change requires its own plan/acceptance, not automatic expansion here.

## Ratings

rated65/55/50/80: user-directed priority; false readiness wastes runs and risks overstating results, no proven data loss; neutral appeal; cheap reused seams. Concrete GH1386 historical example and LTV1014 reported irrelevant green regressions; 14-day comparative recurrence trend unknown, not zero.

## Verification

Content red control is previous instruction absence; fixed exact sentence/placement checks and main/adjacent consumer read-through. Replay syntax result has no claim of final delivery. Existing classifier chooses normal gate; no new test suite. Independent QA recorded in relay-system.

## Lessons Learned

NO_ENTRY pending replay; wording alone cannot demonstrate improved agent compliance.

## Replay disposition and follow-up

7/7 expected command-form/path classifications. Inline python -c mismatch reproduced; no inherited command executed or semantic validity proved. Follow-up https://github.com/HiQS-Labs/XYZ-forge/issues/1448 is NEEDS-SPIKE, rated proposal60/55/50/70, not admitted/no ledger row. Codex advisory answered, Agy credit429; all findings dispositioned in committed evidence. No current runtime fix.
