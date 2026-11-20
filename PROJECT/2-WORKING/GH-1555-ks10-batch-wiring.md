---
issue: 1555
title: "kickstart(KS-10): wire merge-cleanup landing forecast, --landing-plan, canary_command, and 3+ PR batch defaults"
status: active
roadmap_id: rmi-01M7W49MGDR0ZHKB87S577AFWJ
parent_arc: 1541
milestone: KS-10
owner: antigravity
goal: "Wire kickstart/SKILL.md to merge-cleanup's existing landing forecast, --landing-plan, canary_command, GH-1066 sequence review, U5 pin revalidation, and fail-closed 3+ PR batch defaults."
created: 2026-11-20
updated: 2026-11-20
---

# GH-1555 (KS-10) — Kickstart Wiring for Merge-Cleanup Batch Planning (3+ PRs)

## Status

| What was just completed | What's next |
|---|---|
| Addressed Plan QA R1 blockers: specified supported 1–2 PR subset verification path (vs 3+ PR `build_landing_forecast` threshold at `merge_cleanup.py:2775-2776`), tightened GH-1066 sequence-review timing & reopen triggers (`merge-cleanup/SKILL.md:299,314-320`), and separated real CLI/fixture checks from truthful instruction-level scenario walkthrough evidence. | Complete Plan QA R2 approval, implement KS-10 in `skills/1-hourly/kickstart/SKILL.md`, run disposable-clone CLI checks + instruction walkthrough + PDDA under `TESTS-RESULTS/2026-11-20+GH-1555/`, and pass Final QA. |

## Objective
Wire `skills/1-hourly/kickstart/SKILL.md` to merge-cleanup's existing batch-planning machinery (`--landing-plan`, `--landing-reason`, `qualification.canary_command`, `ledger_merge.py` landing forecast, and GH-1066 sequence review) with fail-closed defaults for 3+ PR batches (issue #1541 KS-10, U5/U9). Docs-only change; no new dispatcher, runner, or test suite is created.

## Grounded Recon
- `skills/2-daily/merge-cleanup/scripts/ledger_merge.py:800-970`: `_conflict_hubs()` and landing forecast compute `recommendation` (`"direct"`, `"group"`, or `None` when incomplete/withheld, e.g., clean-set fold did not run at lines 934-941), `passes` (`direct in passes`), and `hubs`.
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2775-2776`: calls `build_landing_forecast(...)` ONLY when `len(listed_order) >= 3`; smaller subsets (1–2 PRs) use pin-verified dry runs rather than a 3+ PR landing forecast (`merge-cleanup/SKILL.md:285,291`).
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:403-415,2286`: `qualification.canary_command` already exists in project merge policy.
- `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:2493-2645,2836-2855`: requires `--landing-plan direct|group --landing-reason "<justification>"` for 3+ PR queues under `--execute`, compares the chosen plan against the dry-run forecast (`forecast_comparison`), and enforces `--prs N@<approved-full-sha>` pin revalidation.
- `skills/2-daily/merge-cleanup/SKILL.md:299,314-320`: GH-1066 independent sequence review runs when the batch is selected and MUST reopen affected review whenever batch members, ordering, or the integration base change.
- `PROJECT/PDDA.md:462-465`: honor configured `CHANGELOG_WRITES` mode (no task-branch `CHANGELOG.md` edit under default `off`/`landing`).

## Plan
1. **`skills/1-hourly/kickstart/SKILL.md` (docs-only):**
   - Add **Batch Planning & 3+ PR Landing Defaults (KS-10, U5/U9)** subsection:
     - **Forecast Acquisition & U5 Pin Revalidation:** obtain the landing forecast from merge-cleanup's dry run with exact `--prs N@<approved-full-sha>,...`. A newly ready PR or changed head/base/order NEVER silently joins an already-forecast batch; refresh pins and re-run dry-run forecast (for 3+ PRs) or clean dry-run verification (for 1–2 PRs) whenever membership, order, head SHA, or integration base changes.
     - **GH-1066 Independent Sequence Review:** complete the existing GH-1066 sequence review when the batch is selected (before the first merge, even when splitting into smaller passes) AND explicitly reopen affected review on any member, order, or integration-base change (`merge-cleanup/SKILL.md:299,314-320`).
     - **Deterministic Forecast Dispatch Defaults (3+ PR batches):**
       - *Complete `direct` or `direct in passes` forecast:* execute each approved pass with `--landing-plan direct --landing-reason "<reason>"`, refreshing `--prs` full-SHA pins (and reopening affected sequence review) after any base, head, or member change; honor configured `qualification.canary_command` and the existing post-batch sweep.
       - *`group` forecast (or conflict hubs):*
         - If the clean subset has **3+ PRs**, execute it ONLY after a fresh, complete 3+ PR dry-run forecast proves that subset folds clean and all its hard dependencies are met; record the remaining conflict hubs as a held separate batch (KS-11b).
         - If the clean subset has **1–2 PRs** (below `merge_cleanup.py:2775`'s `len >= 3` forecast threshold), NEVER pad with unrelated PRs to reach 3 and NEVER call a pin-only dry run a 3+ PR forecast: instead, either verify the 1–2 PR subset via a fresh pinned dry run proving clean landing simulation (zero conflicts and all hard dependencies met) plus sequence-review scope check, OR explicitly HOLD it with owner and recovery condition if cleanliness or dependencies are uncertain. Record the remaining conflict hubs as a held separate batch.
       - *Withheld / incomplete forecast (`recommendation: None`):* preserve the diagnostic verbatim and use the owner's bounded retry or hold path (zero dispatch); NEVER infer a clean set or dispatch blindly, even if valid `--landing-plan` flags could be supplied.
2. **Evidence & Paired Red/Green Checks (`TESTS-RESULTS/2026-11-20+GH-1555/`, no new test suite or dispatcher):**
   - **Real CLI / Fixture Probes (run in a disposable full clone, labeled distinctly as existing merge-cleanup contract measurements):**
     - Invoke `ledger_merge.py` forecast logic on a fixture whose clean-set fold did not run, recording exact output `recommendation: None` and the withheld diagnostic text.
     - Invoke `merge_cleanup.py --execute` on a 3+ PR queue without `--landing-plan`, recording the exact GH-1066 refusal exit code and message; verify `merge_cleanup.py:2775` threshold (`len >= 3`).
   - **Retained Instruction-Level Scenario Walkthrough (labeled explicitly as instruction-level evidence against the actual revised `SKILL.md` text, quoting decisive rules verbatim):**
     - Contrast pre-change `kickstart/SKILL.md` (no 3+ PR batch forecast/withheld-hold wiring -> operator question or ad-hoc dispatch) vs revised `kickstart/SKILL.md` across 5 scenarios: (1) withheld forecast (`recommendation: None`) -> preserved diagnostic + HOLD / zero dispatch; (2) complete `direct` / `direct in passes` -> `--landing-plan direct --landing-reason ...`; (3) `group` with 3+ PR clean subset vs 1–2 PR clean subset (no padding, distinct pin/dry-run check vs 3+ PR forecast, hubs recorded as held batch); (4) changed membership/head/base/order -> U5 pin revalidation + reopened GH-1066 sequence review; (5) post-batch sweep + `canary_command`.
   - Run `./utils/pdda/pdda.sh run` (0 errors), `utils/ci-route.sh`, and generate non-empty `provenance.jsonl`.

## Acceptance Criteria
- `skills/1-hourly/kickstart/SKILL.md` wires kickstart to merge-cleanup's existing forecast, `--landing-plan`, `canary_command`, GH-1066 sequence review (at selection + reopen on member/order/base change), U5 pin revalidation, 1–2 PR vs 3+ PR subset verification, and withheld-forecast HOLD.
- Disposable-clone CLI probes, truthfully labeled instruction walkthrough quoting revised `SKILL.md`, PDDA (0 errors), and `provenance.jsonl` retained under `TESTS-RESULTS/2026-11-20+GH-1555/`.
