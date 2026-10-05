---
gh_issue: 974
source: https://github.com/HiQS-Labs/XYZ-forge/issues/974
title: "Revisit advisory Jev screening for HiQS recipe intake after live chain validation (Needle-fork #71)"
status: Deferred (1-INBOX — revisit only; not active)
created: 2026-10-05
updated: 2026-10-05
owner: unassigned
doc_type: feedback
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Implement or deploy Jev now
  - Change deterministic resolver or policy behavior
  - Attest or publish from model output
  - Replace Skills Army HQ or Git Pulse Sync
related:
  - https://github.com/HiQS-Labs/Needle-fork/issues/71
  - https://github.com/HiQS-Labs/XYZ-forge/issues/709
  - https://github.com/HiQS-Labs/XYZ-forge/pull/954
  - https://github.com/NeochromeTeam/hiqs-ai-resolve/pull/6
goal: >
  Preserve a scoped advisory-intake experiment for later. Revisit only after real recipe
  chain validation exposes recurring reviewer burden; retain a classifier only if it
  improves human-reviewed intake against rules and existing agent-assisted review.
---

## Key concepts

- Real chain evidence first
- Advisory intake screening only
- Rules and existing review as baselines
- Human-labelled held-out HiQS data

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# Revisit advisory Jev screening for HiQS recipe intake after live chain validation (Needle-fork #71)

## Status

| What was just completed | What's next |
|---|---|
| Captured as Forge #974 and deferred; Needle-fork #71 remains the cross-repo proposal. No classifier implementation is authorized. | Complete live recipe chains first. Revisit when recorded duplicate/capability ambiguity repeatedly costs reviewer time; confirm provisional ratings before promotion. |

## Idea

## Deferred revisit — 2026-10-05

Track https://github.com/HiQS-Labs/Needle-fork/issues/71 in Forge's RELEASES roadmap as a possible later experiment. This records a revisit; it does not authorize implementing or deploying a classifier.

Recent developments: HiQS recipe contracts landed in https://github.com/NeochromeTeam/hiqs-ai-resolve/pull/6. Personal scraping/research workflow skills now use the existing Skills Army HQ / Git Pulse Sync distribution pipeline. Those instruction chains are not verified HiQS catalog recipes. Forge's narrow advisory route integration remains draft https://github.com/HiQS-Labs/XYZ-forge/pull/954.

Immediate priority: complete service registrations and provider connections, then exercise Firecrawl → Browserbase → Parallel with fallback only on failure, and Gemini Grounded Search → Perplexity → scraping as the research workflow. Collect real execution and publication evidence before considering a classifier.

Revisit only when repeated ambiguous duplicate/capability/disclosure intake creates measured reviewer work that rules cannot handle adequately. Missing registrations, authentication failures and precise schema errors are not a Jev justification.

First bounded candidate: advisory contribution screening, with top-k duplicate candidates and capability/disclosure suggestions. Compare static alias/capability rules and existing agent-assisted review against Jev or a similar model on a human-labelled held-out HiQS dataset. Freeze criteria before scoring; report reviewer time saved, false positives/negatives, abstention/coverage, calibration, cost and latency. Keep a classifier only if the measured benefit exceeds added complexity. Needle work-purpose scores are not evidence for this domain.

Keep resolve/lookup/explain decisions, policy enforcement, traces/digests, attestations and publishing deterministic. No model output may verify a claim, rewrite a catalog snapshot or publish a record. Any future external experiment must use approved shareable inputs and exclude credentials/private data.

Related umbrella: https://github.com/HiQS-Labs/XYZ-forge/issues/709. Keep this recipe-intake opportunity distinct from completed ATE or work-purpose experiments.


## Why

Record a specific later revisit without adding a model dependency to the recipes rollout. Real intake cases must establish reviewer burden before a classifier experiment is worth funding.

## Revisit sequence

1. Complete real recipe-chain execution and reviewed publication evidence; collect representative intake cases and reviewer time.
2. Confirm recurring ambiguity remains after alias/capability rules and existing agent-assisted review. If it does not, keep this deferred or abandon it.
3. Design one bounded, advisory contribution-screening comparison using human-labelled HiQS data; freeze criteria and hold out evaluation cases.
4. Report reviewer time saved, false positives/negatives, abstention/coverage, calibration, cost and latency. Retain the model only if the benefit exceeds complexity; otherwise keep the baseline.

## Promotion criteria

- Real chain execution/publication evidence exists and recurring reviewer burden is documented.
- Baselines, shareable inputs, human labels and held-out evaluation are specified before any model call.
- Resolver, policy, attestations and publication remain deterministic and subject to existing review.
- Provisional ratings and operational scope are confirmed before moving to `2-WORKING`.

## PRS rating rationale

Initial priority/severity/appeal/effort-cheapness: **20/10/50/55** (provisional). Low priority and severity reflect no current recipe-runtime need or established harm. Appeal is neutral. Effort cheapness reflects a bounded experiment, with labelling cost still uncertain. Re-rate when actual review burden is available.
