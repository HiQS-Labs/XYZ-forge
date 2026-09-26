# Retained copy — GitHub issue #831 body

Source: https://github.com/HiQS-Labs/XYZ-forge/issues/831 · fetched 2026-09-26T02:46:10Z · retained so an offline reviewer can grade against the requirements.

---

> **Operator decision, 2026-09-25**, recorded on #802 ([comment](https://github.com/HiQS-Labs/XYZ-forge/issues/802#issuecomment-5841529958)). This issue implements it. It supersedes #819, #815, #816 and #817, which already point here through #802. It overrides the GH-509 and GH-544 rails and #819's landing gate.

## Problem

Every merge into `development` triggers a hosted wave-reconcile that runs all ~421 suites sequentially on macOS, whatever the merge changed. That takes about 61–76 minutes of suite time, and a merge waits for it before the next one can land. Any single red suite, even one that tests a spin-off, withholds the qualification receipt and rolls back the merge's doc and ledger closeout.

On 2026-09-25 the reconcile for #828, which changed only docs, the ledger and the CHANGELOG, failed after 79 minutes on one flaky suite for the Skills Army mini publisher (`gh620-skills-army-mini-sync.sh`, #830). The re-run cost another 80 minutes and held up #821.

Tests also keep growing. There were 208 suites in mid-August and there are 419 registered now, most of them one `gh<N>-*.sh` per fixed issue (#815). The same suites run up to four times per change: the pre-push hook, `ci-local.sh`, the hosted reconcile, and the `main` promotion boundary.

## Decision

1. **No new tests.** This is enforced by rules and skill text, with no guard suite and no code-owner gate:
   - an `AGENTS.md` rule;
   - remove the instructions that produce new tests, in `/start-task`, `/express`, and the marathon and relay briefs;
   - Codex QA flags any new test file as a finding.

   Verification uses an existing suite, or a manual check recorded in `TESTS-RESULTS/`.
2. **Three tiers, one classifier.** `utils/ci-route.sh` picks the tier for the pre-push hook, for the hosted reconcile after each merge, and for promotion to `main`.

   | Tier | Runs when a change touches only… | What runs |
   |---|---|---|
   | **Small** | docs, `PROJECT/`, the ledger, skill files | PDDA gate; PDDA, reconcile and merge-cleanup suites; releases ledger suites; the #816 canaries |
   | **Medium** | code outside the core harness: `utils/`, skill scripts, hq, telemetry, standup, radar, releases code | Small plus the touched area's existing tier-2 suites |
   | **Large** | the core harness: `src/`, `bin/tick`, `relay-automation/`, marathon, relay, poll, express, reconcile, `validate.sh`, hooks, vendoring | Small plus the core harness suites |
3. **Every other suite goes off.** It is removed from `validate.sh`'s registry, and its file is kept.
4. **Fold in two cleanups:**
   - an `AGENTS.md` test-freeze note, landed first;
   - cut GH-732's parked ledger row as superseded by #802.

A name-based estimate of the split is ~57 Small, ~180 core and ~180 off. Replacing it with the real mapping is the first job of the plan.

## Acceptance

- A docs-only or skill-file-only merge is qualified by the Small tier in minutes, not by the full suite. The hosted reconcile still produces its receipt and does its closeout.
- A core-harness change still runs Small plus the core suites, locally and hosted.
- An "off" suite runs nowhere by default, and its file is still in `test/`.
- The rules and skill text no longer instruct agents to add tests, and `AGENTS.md` says new tests are not accepted.
- The first hosted reconcile after this lands shows the tier it chose and how long it took.

## Non-goals

- Deleting test files. That can come later.
- New gate machinery of any kind: no new lanes, runners, telemetry, or guard suites.
- Moving tests to another repository (#816).

Related: #802 (retrospective and decision), #819, #815, #816 and #817 (superseded), #805 and PR #811 (test admission), #830 and #829 (the failure that prompted this), #821 (gh251 cost, landed).

