---
gh_issue: 1143
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1143
title: Radar-to-campaign documentation skill
status: Draft PR 1147 — awaiting operator review
updated: 2026-10-18
owner: Codex
goal: Connect Radar recommendations to bounded approved discovery using existing assets
created: 2026-10-18
doc_type: feedback
---

# GH-1143 — Defect campaign

Implement a thin instruction skill connecting Radar recommendations to existing campaign,
ATE, fuzz, oracle and minimization assets. Documentation only; no execution or remediation.

## Status

| What was just completed | What's next |
|---|---|
| Draft PR 1147 published; final QA Approved and docs hook passed | Operator review; no merge or campaign authorized |

## Recon and smallest viable bet

Base: `e93214feb45dc95f32ee2d9080c1d4f6f3b8ab69` (`origin/development`).
PR #946 landed as `e888594fd3e3670a6be2eecdaecc4b20af549c1b`; Radar's existing
verification-asset handoff is the entry seam. ATE's older automatic issue filing is unsafe
for discovery; gen4_campaign's parser defaults to suite mode and synthesis ON. Use explicit
run mode and no-synth only after approval, with model/healing/filing options absent.
`adaptive_ate.generate_pairwise`, `fuzz_engine.fuzz`, `domain_oracles` and
`repro_builder` already provide the building blocks; no new engine is justified.

Outcome: turn selected recommendations into reviewable bounded specifications and accountable
counterexample dispositions. Add `skills/4-occasional/defect-campaign/SKILL.md`, one index row,
and minimal Radar/ATE pointers. Existing Radar alone lacks the approval/evidence contract;
expanding the campaign engine is unnecessary. Revert these docs to roll back.

## Ownership and limits

Live inspection 2026-10-18: primary tick projection has GH1140 final-review handoffs;
its separate clone has dirty merge-cleanup and gh436 files. GH1136 is open and excluded;
GH1133 remains paused. No competing pilot or writes in peer clones. No existing GH1143
intake or open PR found. Fresh standalone full clone and docs task branch follow GH970.
Local claims are clone-local; recheck tracker, claims, locks, processes and peer checkout
state before any future campaign, never infer clearance from an empty new clone.

Proposed rating: 55/40/50/85 (priority/severity/appeal/cheapness), neutral appeal, no override.
This is a missing workflow connection, not an observed runtime defect. #945/#946 are prior
art, not another incident. Recurrence trend unknown: no comprehensive distinct-incident
count for Oct 4–18 versus Sep 20–Oct 4; do not claim growth or zero incidents.

## Ordered plan and acceptance

1. Register/rate this issue via RELEASES CLI, promote this doc per SOP. Classifier inspection:
   Markdown, PROJECT, TESTS-RESULTS, relay-system and releases DB/SQL/generated HTML are
   supported docs surfaces. Inspect the actual final diff including deleted paths; stop if
   any path requires a broader gate. Do not change routing or shared policies.
2. Codex plan QA, cap three rounds; after approval, admit exact owned row via accepted-start.
3. Write the skill and three pointers. Explicit suitability, hypotheses/oracles, known-failing
   and clean controls, concrete budgets/stops, isolated effects, reproducible replay using the
   same predicate, duplicate classes, severity and separately authorized remediation.
   Retain exact inputs/corpus snapshots, source/tool versions, sanitized environment, outputs
   and relevant timing; a seed alone cannot replay stateful/concurrent behavior. Require an
   accountable owner, disposition and retained evidence link for every counterexample, plus a
   return link to Radar tracking context or an existing results issue. Accept honest null runs:
   state exercised/excluded/unresolved coverage and never infer class eradication.
   Require individual approval for every new CI test/case/assertion/parametrization.
   Preserve #1131 and prohibit automatic fixes/push/merge/deploy/schedules.
4. Include a source-grounded HELD pilot for #1138 stale batch state: #1140/#1136 excluded;
   structured adapter missing, future separately approved work. No invented argv semantics.
5. Existing skill quick_validate, manual source/link and consumer-path review, deterministic
   PDDA gate, final independent Codex QA (three-round cap). Manual omission review must reject
   seed-only stateful replay, dispositions without evidence/backlinks, and clean reports missing
   coverage limits or claiming eradication; accept complete bounded reports. Record evidence under
   TESTS-RESULTS; no new tests, cases, fixtures, scripts, registries or runtime changes.
6. Push through installed docs hook; open DRAFT PR to development and verify remote SHA and
   exact-head hosted statuses. Distinguish smoke/skipped/full qualification. No full suite,
   merge, installation, deployment, campaign execution or clone cleanup.

## Review questions

Check every issue requirement for an equivalent in this plan (omission diff); distinguish
this documentation implementation from future campaign approval. Are tool fit and missing
semantic adapters honest? Are synthesis/healing/autofiling disabled, effects/budgets bounded,
and per-case approval plus ownership boundaries explicit? Are the docs-only gate and existing
writers reused without bypass or speculative machinery? Grade only this local documentation
scope and commensurate complexity. No new tests or enterprise abstractions.

## Blocked handoff — 2026-10-18

Plan review history is retained in `relay-system/2026-10-18/gh1143-plan.codex.md`:
round 1 PARKED (missing local issue snapshot), round 2 FAIL (missing explicit replay/result
acceptance), round 3 reviewer PASS/Approved but driver exit 4 `review-body-rewritten`.
The final review commit is `d555b12fec6e3821368de7e5ef09047cde34aad3`. The reviewer
moved the next-turn marker and inserted a blank line above its own block. The supervisor had
appended the round-3 producer update after that marker, rather than before it. The driver
rejected the changed earlier body; its terminal approval is not accepted evidence.

The original three-round plan-review budget is exhausted. No retry/new token/cap reset,
accepted-start admission, skill implementation, push or PR followed. Do not treat the raw
Approved header as qualification. Resume requires an explicit operator review-cap override
or replan; preserve these rounds and repair thread placement before another review.
No broader gate, executable change or machinery repair is proposed in this task.

Recon evidence: existing prior_art_recon returned PASS, no query-matching open PR, no network
errors; #946 is landed prior handoff, not completion of this skill. Current CLI --help read
only confirmed no-synth and absent healing/model defaults. Final preparation paths classify
route=docs/tier=1/full_required=false, including mandatory releases.db/sql. RELEASES check
passed (0 failures, 10 existing migration/date warnings). No documentation gate, skill
validator, full suite, final QA or hosted-status verification ran before this blocker.
`python3` lacks requests; an existing uv-managed runtime has PyYAML for the future existing
skill validator; nothing installed. No campaign or remediation occurred. Clone retained.

## Operator override — 2026-10-18

Operator explicitly approved: "Yes override procedural stop." This permits implementation
past the exhausted PLAN review stop only. Round 3's exact recommendation at `d555b12f` says
"No remaining blocker or additional pre-existing defect found in the full plan sweep."
Inspection confirms round 2's result-contract omission is resolved; no substantive correctness
concern remains in that recommendation. The relay driver rejection remains a failure, not an
accepted attestation. Original rounds stay 3/3, with no additional plan turn or reset.
Normal final implementation QA retains its separate three-round limit. Future producer blocks
must be inserted BEFORE the existing final next-turn marker, preserving prior body bytes;
no relay implementation changes. No expanded execution permissions.

## Implementation checkpoint

`f135518a` adds only the skill, Radar/ATE pointers and index/changelog documentation.
Manual consumer and completeness review plus existing quick_validate pass; all 8 source-file
links resolve locally. PDDA gate exit 0 in 54s, 0 errors/57 pre-existing warnings; LLM doc-ready
self-skipped. Actual range including mandatory ledger and receipts routes docs/tier1, no
full-required surface. Evidence: `TESTS-RESULTS/2026-10-18+GH-1143/`.
Final QA remains pending; no campaign, new tests, executable changes or full suite.

## Final review checkpoint

Final Codex QA Approved round 1/3; relay-drive exit 0, attested at 2026-10-18T17:17:38Z
against `fa215ee30476`. Receipt: `relay-system/2026-10-18/gh1143-final.codex.md`.
No substantive finding or implementation revision followed approval. This status/evidence
closeout is factual bookkeeping; the publication hook will check the final committed docs.
Draft publication remains distinct from landing/full/promotion qualification. No merge authorized.

## Draft publication

Draft PR: https://github.com/HiQS-Labs/XYZ-forge/pull/1147, base `development`.
First published head `72fb443bc84e81e17d07f2254c9efa09fb13ab83` matched remote and PR.
Normal installed hook selected docs and passed in 61s, no bypass/full suite.
Exact-head hosted vendored smoke succeeded; macOS promotion and Ubuntu canary skipped.
Those are smoke/skipped statuses, not full/promotion qualification. This factual closeout
adds no implementation changes; its final committed state goes through the same docs hook.
Current PR head/statuses are verified in the PR description and handoff after that push.
Task remains in progress awaiting review/landing; no shipped/completed ledger claim.
No installation, merge, deployment, campaign or clone cleanup. Clone intentionally retained.
