---
gh_issue: 1143
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1143
title: Radar-to-campaign documentation skill
status: Planning — awaiting plan QA
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
| Source recon and docs-route inspection; intake rated 55/40/50/85 | Independent plan QA before implementation |

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
