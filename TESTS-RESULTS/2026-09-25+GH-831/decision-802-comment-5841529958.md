# Retained copy — operator decision on #802 (comment 5841529958)

Source: https://github.com/HiQS-Labs/XYZ-forge/issues/802#issuecomment-5841529958 · fetched 2026-09-26T02:46:10Z.

---

## Operator decision, 2026-09-25: no new tests, and the gate is cut to three tiers

This supersedes the [subtract-first recommendation](https://github.com/HiQS-Labs/XYZ-forge/issues/802#issuecomment-5827095720) and #819's landing gate wherever they conflict.

**Why now.** This thread and #819 dealt only with the local pre-push gate. The hosted reconcile after every merge still runs all 421 suites, sequentially, whatever the merge changed. On 2026-09-25 it spent 79 minutes on #828, a change to docs, the ledger and the CHANGELOG. It then failed on one flaky suite for a spin-off publisher, `gh620-skills-army-mini-sync.sh` (#830). The re-run costs another 80 minutes and holds up the next merge.

### Decisions

1. **No new tests.** This is enforced by rules and skill text, not by another test:
   - a rule in `AGENTS.md`: no new `test/` suites and no new registry entries;
   - remove the instructions that produce tests today, in `/start-task`, `/express`, and the marathon and relay briefs;
   - Codex QA flags any new test file as a finding.

   Verification uses an existing suite or a manual check recorded in `TESTS-RESULTS/`.

2. **Three tiers, one classifier.** `utils/ci-route.sh` picks the tier for the pre-push hook, for the hosted reconcile after each merge, and for promotion to `main`.

   | Tier | Runs when a change touches only… | What runs | Hosted sequential cost today |
   |---|---|---|---|
   | **Small** | docs, `PROJECT/`, the ledger, skill files | PDDA gate; PDDA, reconcile and merge-cleanup suites; releases ledger suites; the #816 canaries | 57 suites, ~18 min |
   | **Medium** | code outside the core harness: `utils/`, skill scripts, hq, telemetry, standup, radar, releases code | Small plus that area's existing tier-2 suites | minutes |
   | **Large** | the core harness: `src/`, `bin/tick`, `relay-automation/`, marathon, relay, poll, express, reconcile, `validate.sh`, hooks, vendoring | Small plus the core harness suites | ~180 suites, ~60 min |

   Two suites account for 11 of Small's 18 minutes: `gh549-work-events.sh` and `gh436-merge-cleanup.sh`. With both moved to Medium, Small takes about 7 minutes.

3. **Every other suite goes off.** It is removed from `validate.sh`'s registry, and its file is kept, so re-adding one line brings it back. That is about 180 suites and 15 minutes. Deleting them can come later.

The core/off counts are an estimate from suite names. Producing the real mapping is the first job of the plan.

**Rules this overrides:** GH-509 (only a full sequential run qualifies), GH-544 (full gate before every push) and #819's "full gate once per landing".

### Effect on this thread's plan

| Item | Now |
|---|---|
| 1. Full gate once per landing (#819) | Replaced by the tiered gate. |
| 2. Fast static guards first (#817) | The canaries in Small take its place. |
| 3. Freeze new gate machinery for 30 days | Permanent: no new tests. |
| 4. Delete before fixing | #821 (the gh251 cost, #808) lands first. #805's folding becomes turning suites off. |
| 5. Collapse the CI backlog; one standing reconcile issue | Still open. There have been 8 auto-filed "needs attention" issues since 2026-09-18. |

**Next:** once #821 lands, `/start-task` opens the tracking issue. It holds the plan with the real core/off mapping, gets a Codex plan review, and then a PR. I will link it here.

— **Opus 5.5**

