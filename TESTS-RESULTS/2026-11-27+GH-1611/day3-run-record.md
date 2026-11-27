RUN-RECORD-VERSION: 1
LANDING_CLONE: ~/flywheel-day3-run

# Flywheel Day 3 run record — ledger #1611 — "Prove checkpoint recovery"

<!-- derived from build_queue.py (GH-1527) --daily-goals 1611 as of 2026-11-27; edited by the run owner to the actual Day 3 authority and order -->

- UTC launch: 2026-11-27T16:05:41Z (operator launch authority 2026-11-27, issued although #1611's title says 2026-11-28)
- Dispatch deadline: 2026-11-27T20:35:00Z (epoch 1795811700); evidence/handback reserve 20:35-21:05Z (5 h window incl. 30 min reserve)
- Base: origin/development 3f2ffa35315e99640cd60fdcf836f65787e2abce
- Roles: builder codex (gpt-6.2-sol), reviewer agy; one execution owner (run owner session), parent = observer/recovery agent

## Authority granted (one grant, covers the whole run)
- Dispatch and PR publication for the two declared inputs only (#1626, then #792), through the existing Jog -> Preflight -> Marathon path.
- IN-RUN LANDING IS NOT AUTHORIZED. The run opens PRs and stops at them; the parent lands through merge-cleanup.
- Merge, deploy, installed-skill update, issue closing, ledger rewrites outside the owner writers: NOT granted.
- Decision defaults (KS-11, fail-closed) apply as written in the Kickstart skill; round cap is at most 4 review rounds, then the consult tie-break; a Consult-Adjudicated result is never recorded as approved and is never auto-merged.
- One repair sub-session at a time within the 30 min incidental reserve, recorded as assisted.
- Status: NO MERGE GRANT. Dispatch authority: operator, via the parent's launch brief of 2026-11-27.

## Queue (execution order)
1. #1626 merge-cleanup: a landing dry run deletes retained scratch clones (raw primary item; capture and contract prepared BEFORE launch by the parent, so raw-intake credit is not claimed).
2. #792 gen4_campaign.make_sandbox deletes the existing clone before checking it is disjoint from the source repo (independently qualified post-checkpoint successor).

## Needs the operator (the run parks these and keeps going)
- Kickstart's classifier lists #1626 as "unclassified; operator picks scope". The operator's #1611 plan and launch brief name it as the Day 3 raw item, so it is dispatched through Jog under that decision, not through the classifier's queue.
- Not queued: GH-1315 (parked in the published Jog queue after exhausting 3 attempts on Day 2; must not be selected by a wake), "Final QA pass on development" (no landings occur in this run, so no final QA staleness gate applies).

## Handback checkpoint 1 (2026-11-27, item boundary after GH-1626)

State at the deliberate handback, to be re-verified by a fresh observer (this section is a claim, not proof):
- Wake 1 command (finished, exit 0): jog run --target-root ~/flywheel-day3-exec --builder codex --reviewer agy --max-tasks 1 --supervise-until 1795811700; log ~/flywheel-day3-scratch/wake1.log (UTC 16:07:19Z to 16:31:48Z).
- GH-1626: execution gh1626-exec1, one builder turn (codex) and one review turn (agy, Approved on head c91560364023), pre-advance gate green, lane head fd811951f0b5dae07077d36fe9dbe90c36b7c440, receipt commit e14a44bd6e630c7d235c4f6d509a5992c6c6ce16 on origin lane branch marathon/gh-1626-dry-run-scratch-prune-2026-11-27, PR #1651 (base development, head e14a44bd6). Jog row: parked, awaiting-landing, attempt 1.
- Receipt push first refused (no gate attempt reservation); resolved with one manual reservation (task GH-1626-start-task) and jog resume 1626, no builder turn. Marathon's own PR step hit the shared GraphQL rate limit; PR opened by hand through the REST API.
- Next eligible action: GH-792 (pending, attempts 0). GH-1315 is parked and must not be selected. GH-1626 must not be re-dispatched, re-pushed or re-opened.
- Authority, deadline and attempts are unchanged: dispatch deadline 2026-11-27T20:35:00Z (epoch 1795811700); no merge grant; GH-1626 Jog attempts 1/3, native lane gh-1626-dry-run-scratch-prune 1 of 2 consumed (its record is still state active in the execution clone's attempt-history), and the manual publication reservation GH-1626-start-task was completed and archived (attempt-finish) in the coordinator accounting root.
- Roots: coordinator and Jog writer ~/flywheel-day3-run; execution clone ~/flywheel-day3-exec; checkpoint clone ~/flywheel-day3-ckpt.
- Wake 2 (the resume), exactly: jog run --target-root ~/flywheel-day3-exec --builder codex --reviewer agy --max-tasks 1 --supervise-until 1795811700

## Events
BASELINE: origin/development 3f2ffa353 includes #1641, #1643, #1644, #1647; queue empty at launch except parked history; hosted regression sweep wave-reconcile run 46025387193 in progress on 8b10e1227 (parent will message on failure, then hold).
INTERVENTION: I-1 2026-11-27T16:05:41Z #1626 packet (capture, contract, probe) and #792 packet prepared by the parent before launch; recorded as assisted preparation.
APPLIED: I-1 → applied disclosed in this record and in the Day 3 handback
INTERVENTION: I-2 2026-11-27T16:32:42Z GH-1626 receipt publication needed one manual gate attempt reservation (gate_receipt.py attempt-start, task GH-1626-start-task) and jog resume 1626; PR #1651 opened by hand over REST after the shared GraphQL rate limit stopped Marathon's PR step
APPLIED: I-2 → applied receipt e14a44bd6 published, PR #1651 opened, reservation finished and archived 2026-11-27T16:36:15Z
GATE: GH-1626 head fd811951f0b5dae07077d36fe9dbe90c36b7c440 full green (duration not recorded)
BASELINE: GH-1626 delivered as PR #1651 (head e14a44bd6e630c7d235c4f6d509a5992c6c6ce16, lane head fd811951f); row parked awaiting-landing; GH-792 pending 0 attempts; item boundary reached 2026-11-27T16:36Z
