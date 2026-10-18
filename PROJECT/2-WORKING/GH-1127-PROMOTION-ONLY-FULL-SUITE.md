---
gh_issue: 1127
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1127
title: "Full-suite qualification at development → main promotion only; ledgers reconcile locally after each development merge"
status: Active
created: 2026-10-18
updated: 2026-10-18
owner: claude
goal: "Stop the routine hosted full-suite run on every development merge (#1131) while keeping one hosted full run, on the combined development tip, before every promotion"
doc_type: feature
effort: 2
complexity: 2
risk: 3
phases: 1
fix_probes:
  - "! grep -Eq '^  (pull_request|schedule):' .github/workflows/wave-reconcile.yml"
  - "grep -q 'MERGE_CLEANUP_USE_HOSTED' skills/2-daily/merge-cleanup/scripts/merge_cleanup.py"
---

# GH-1127 — promotion-only full suite; local ledger reconcile

Decision root: #1131 (operator, 2026-10-17). Issue #1127 is the brief. Also folds in the two Codex post-merge review findings filed on #1124 (comment by the Codex review, 2026-10-18): live docs still say hosted qualification is sequential, and `qualification_receipt_matches` ignores the receipt's new metadata.
Branch `feat/XYZ-forge-gh1127-promotion-only-full-suite-2026-10-18` off `development@4fd5dca8`.

## Status

| What was just completed | What's next |
|---|---|
| Recon at 4fd5dca8 and plan written | Codex plan QA → implement → covering suites → final Codex QA → PR → merge on green CI (operator-authorized) |

## Observed today (4fd5dca8)

- `.github/workflows/wave-reconcile.yml:3-10` fires on `pull_request: closed` into development **and** `schedule '23 */6 * * *'`, plus `workflow_dispatch`. Every event runs `--catch-up --gate --qualify` (`:64-70`) on `macos-latest` (`:27`): one hosted macOS full run per development merge (49–70 min sequential; 22 min validator / 27 min job under #1134's parallel gate).
- The schedule's catch-up calls `unreconciled_prs` / `unreconciled_commits` (`utils/py/wave_reconcile.py:1288-1420`, reached only when `--qualify` is set, `:1443-1445`). So removing only the PR trigger would still qualify every locally reconciled PR every 6 h.
- `merge_cleanup.py:run_post_merge_reconcile` (`:708-772`) waits up to 90 min for that hosted run (`wait_for_hosted_reconcile`, `:503-601`). It falls back to the **existing** local writer `run_local_wave_reconcile` (`:604-618`, `wave_reconcile.py --pr N`) only when no hosted run appears after a 60 s grace, or the hosted run is red. Without `--qualify`, that local writer reconciles the ledger, docs and PDDA (`wave_reconcile.py:2271-2407`, `:1790-1923`) and never qualifies.
- `batch_record.py:finalize_sweep_inputs` (`:282-314`) tells every above-tier-1 batch to rerun `validate.sh --parallel 4` locally in a throwaway clone (`:312`, shown at `:184-186`).
- Promotion is a GitHub PR from development to main (e.g. merge of #1036). `ci.yml:152` runs `boundary-macos` (`validate.sh --sequential`, full) only **after** a push to main. `test/ci-workflow.sh:254-259` pins that this job never runs on `pull_request` (cost guard: macOS bills about 10× Linux).
- Codex review finding: `qualification_receipt_matches` discards `(summary, meta)` at `wave_reconcile.py:585`, so receipt `mode`, `width`, `first_attempt_failures` and `retries` are never checked against the retained telemetry.
- Codex review finding: these still describe the old cadence: `AGENTS.md:216-219,432-434`, `ROUTER.md:117-126,140-143`, `skills/2-daily/merge-cleanup/SKILL.md:298-303`, `ci.yml:156` comment, `validate.sh:706-711,1309` comments.

## Preflight bet

- **Outcome:** a development merge costs the local reconcile only (minutes, not a 27–70 min hosted queue). The full registry still runs hosted on macOS, once, on the combined development tip, before it is promoted.
- **Smallest bet:** turn the hosted lane from automatic to on-demand, and make the already-shipped local writer the default. Promotion qualification is the same `wave-reconcile.yml` dispatched once on development. Its catch-up already gathers every receipt-less landing since cutover and qualifies them together in **one** integrated-snapshot run (`qualify_landings`, `:642-743`). That run is exactly the "combined candidate" #1127 asks for. No new workflow, job, scheduler, receipt schema or test file.
- **Rejected:** (a) adding `pull_request` → main to `boundary-macos`. That inverts a pinned cost guard (`ci-workflow.sh:254-259`), and the job still could not block without branch protection, which this agent cannot read or write (403 per #1127). (b) Deleting `wave-reconcile.yml`. `unreconciled_prs` dates its cutover from the file's add commit (`:1298-1302`), and five suites require the file. (c) Deleting `wait_for_hosted_reconcile`. `test/gh549-work-events.sh:628-654` and `test/gh674-merge-cleanup-hosted-lookup.sh` pin it, and it stays useful for an operator who dispatches the hosted lane deliberately.
- **Rollback:** restore the two triggers and flip the env default. Every receipt keeps its original meaning. Receipt-less landings from the interim are picked up by the next dispatched catch-up and qualified then, never retroactively marked passed.

## Changes (ordered, verification inline)

1. `.github/workflows/wave-reconcile.yml`: delete the `pull_request` and `schedule` triggers and keep `workflow_dispatch`. Replace the header comment with the #1131 contract: dispatch on `development` before every promotion; the run qualifies all landings since the last receipt in one snapshot and publishes their receipts. Leave the dead PR branch of `if:` and the args step (`:24-26`, `:65-66`) in place. Re-enabling is then a two-line trigger restore.
   Verify: existing `test/ci-workflow.sh` (it parses this file's timeout at `:288-299`), `test/gh421-auto-wave-reconcile.sh`, `test/gh684-hosted-lane-report.sh`, `test/gh740-hosted-lane-publish.sh`.
2. `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:run_post_merge_reconcile`: local by default. Wait for the hosted run only when `MERGE_CLEANUP_USE_HOSTED=1`. Otherwise call `run_local_wave_reconcile` straight away, with no 60 s grace and no hosted lookup. Both call sites stay in the function, so the gh549 AST pin `{wait_for_hosted_reconcile, run_local_wave_reconcile} <= post_calls` still holds unchanged. The dry-run log line names the chosen path. The local writer's own single-writer guard (`check_hosted_reconciler_in_flight`, `wave_reconcile.py:2192-2195`, exit 8 while any hosted run is active) is kept. That means a landing during a promotion dispatch stops instead of racing it, which is the existing contract.
   Verify: existing `test/gh549-work-events.sh`, `test/gh674-merge-cleanup-hosted-lookup.sh` (exercises the opt-in path; unchanged), `test/gh436-merge-cleanup.sh` (mocks the function).
3. `skills/2-daily/merge-cleanup/scripts/batch_record.py:finalize_sweep_inputs`: when the classifier selects the full gate, `command` becomes `gh workflow run wave-reconcile.yml --ref <integration>  # full registry, hosted, once before promotion (#1131); no local full rerun`. The Small (tier 1) command is unchanged, because a local Small run is cheap. The `gate` and `gate_reason` fields are unchanged.
   Verify: existing `test/gh436-merge-cleanup.sh` batch cases and any `sweep_inputs` assertion. Sweep the test tree for `"command"` against batch records first. Only `batch_record.py:186` reads it today.
4. `utils/py/wave_reconcile.py:qualification_receipt_matches` (`:585`): keep the returned `meta`. For each of `mode`, `width` and `first_attempt_failures` **present** in the entry, require equality with the recomputed meta. If `retries` is present, require `len(first_attempt_failures)`. Absent keys keep historical semantics, so every pre-#1134 receipt still matches.
   Verify: `gh740` (replays a receipt), `gh425`, and the committed `TESTS-RESULTS/2026-10-17+GH-1114/reader-controls.py.txt`, re-run. Manual check `TESTS-RESULTS/2026-10-18+GH-1127/receipt-meta-controls.log.txt`: the committed 65f70cc5 receipt plus telemetry replays True; the same receipt with `mode: sequential`, `width: 1`, `retries: 1` or `first_attempt_failures: ["x"]` each replays False; the committed 61e27ed8 receipt, which lacks the keys, replays True.
5. Docs, text only: `AGENTS.md:216-219,432-434`, `ROUTER.md:117-126,140-143`, `skills/2-daily/merge-cleanup/SKILL.md:298-303` (and its Phase 5 summary line if it names the hosted wait as default), `ci.yml:154-158` comment, and `validate.sh:706-711,1309` comments. Each names its evidence boundary:
   - development merge = local reconcile + pre-push gate
   - promotion = dispatched hosted `wave-reconcile` full run on the development tip (parallel per #1134), then the post-push `boundary-macos` sequential witness on main (unchanged, operator's call under #1131 to flip)
   - `ci-local.sh` stays sequential
   Add a 4-line promotion procedure to `AGENTS.md`: dispatch, wait green, open the development → main PR, `boundary-macos` witnesses main.
   Verify: `utils/pdda/pdda.sh run` clean; `test/gh544-parallel-default.sh`, which pins the ci.yml literal, still green.

## Non-goals

- `ci.yml` jobs and triggers, including `boundary-macos` mode (`:203`) and the advisory Ubuntu canary on development pushes (`:248-250`). The canary is advisory, Linux-billed and not qualification. Removing it is an operator option, not part of this change.
- Branch-protection or ruleset wiring that makes the promotion run a *required* check. That needs an authorized reader and writer (#1127 records the 403). Recorded as a carry-over for the operator.
- `wave_reconcile.py` catch-up, cutover or lifecycle logic; `ci-local.sh`; `validate.sh` behavior; the pre-push hook; any new test file or case (GH-831; per-case operator approval).
- Removing `wait_for_hosted_reconcile` or the hosted lane scripts.

## Risks

- **Interim gap:** landings between merges and the next dispatch carry no qualification receipt. That is the decision, not a defect. The receipts appear at the promotion dispatch.
- **A large first dispatch:** qualifying many landings at once is one run (an integrated snapshot), not N runs. Its log names the count.
- **Promotion without a dispatch:** procedural, not enforced (see non-goals). `boundary-macos` still runs the full registry on main afterwards, so a regression is caught post-promotion at worst. That is the same exposure as today's post-push design.

## Acceptance

| # | Check | Red control |
|---|---|---|
| A1 | wave-reconcile.yml has only `workflow_dispatch` as a trigger; ci-workflow, gh421, gh684, gh740 green | fix_probe 1 fails on the base commit |
| A2 | `run_post_merge_reconcile` without the env var calls the local writer and never `gh run list`; with `MERGE_CLEANUP_USE_HOSTED=1` it takes the hosted path; gh549, gh674, gh436 green | manual: monkeypatched `wait_for_hosted_reconcile` raising when the env is unset → not reached; reached when set |
| A3 | batch sweep command for a tier-3 batch is the dispatch line; tier-1 unchanged | manual: `finalize_sweep_inputs` on a stub record for each tier |
| A4 | receipt-meta controls as in step 4 | each tampered field → False; legacy receipt → True |
| A5 | docs name the new boundaries; `pdda.sh run` clean; gh544 green | — |
| A6 | Pre-push gate for the changed paths (routes full: workflow + core skill code) | — |

## Carry-overs (operator)

- [ ] Optional: make the promotion dispatch a required check via branch protection or a ruleset (authorized reader needed).
- [ ] Optional, under #1131: `ci.yml:203` boundary to `--parallel 4`; retire the advisory Ubuntu canary on development pushes.
