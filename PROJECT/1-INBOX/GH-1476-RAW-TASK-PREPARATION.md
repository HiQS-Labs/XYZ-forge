---
gh_issue: 1476
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1476
title: "GH-1476: Raw task preparation"
status: "Proposed (1-INBOX — plan QA pending)"
created: 2026-11-16
doc_type: feedback
owner: Codex
goal: Accept raw daily-goal tasks and research selected work consistently before execution admission.
effort: 2
complexity: 2
risk: 2
phases: 1
---

# Raw task preparation — OL-09 implementation slice

Canonical discussion: [Issue #1476](https://github.com/HiQS-Labs/XYZ-forge/issues/1476).
Umbrella: [Issue #1400](https://github.com/HiQS-Labs/XYZ-forge/issues/1400), 35% baseline; next four milestones OL-14, OL-09, OL-10, OL-12 target 55%.

## Requested outcome and boundaries

Accept RAW daily-goal requests at intake. For selected unprepared work, bounded medium research is the default; deepen when evidence justifies risk or actual effort. Reuse applicable research. Unknowns remain visible holds, and risk deferral requires an explicit batch-scoped request. Preparation grants no dispatch authority. Preserve original acceptance, operator scores/overrides, ownership and cumulative budgets.

This slice implements OL-09 instructions through existing Conveyor and 10days. OL-10 actual stale/held admission refusal remains separately open in this issue; do not claim runtime enforcement from prose. No runtime code, new queue/state/schema, test suite, new daemon, installed skill edit, #1328 amendment, or live backlog execution. No dependency on landing PR #1491 for these instruction changes. This PR will use Refs #1476, not close the whole issue.

## Recon and smallest viable bet

Base: `f346d8908a42cd6e7e92f80657f9e7a21208e0ae`. The source Conveyor flow already accepts missing rows/contracts and grounds preparation, but Step 2 has no medium-depth default or bounded research selection contract. 10days Step 2 immediately excludes completed-folder captures; Step 3 defaults to binary INCLUDE/EXCLUDE, scores appeal from clarity and forcibly clears overrides; Step 8 mixes holds into exclusions. Its Step 5 --deep refreshes preflight, not research depth. Jog already owns a detailed preparation/admission handoff. No runtime discovery is needed for this instruction-only change.

Smallest bet: own one research-depth policy in Conveyor and link 10days to it, correcting conflicting selection/reporting text. Existing open #1476 already owns the ask; prior-art query medium research preparation found no matching open/merged PR or existing-fix candidate, with no API errors. This is bounded search, not exhaustive prior-art proof. Graph primary generation 2026-11-16T19:03:06Z reports no recorded gaps/metadata match for the four relevant skill paths; exact source at the stated base was read for material claims.

Alternative rejected: merely adding another umbrella paragraph leaves contradictory consumer instructions intact. A new research runner or automatic readiness gate is unnecessary for OL-09 and would expand into OL-10. Reversibility Easy: revert source instructions through normal review; retain intake and evidence, never erase held tasks.

## Ordered implementation and verification

1. Review this plan before changing skill instructions. Keep primary-owned rating checkpoint; use the existing independent relay protocol, valid verdict/Basis and actual attestation. Preserve round budgets.
2. Add Conveyor's canonical RAW preparation policy before its flow: accept raw requests without manufacturing contracts, distinguish already-prepared freshness reuse from medium research, default one read-only research child for selected unprepared work, and deepen on concrete state/authority/recovery uncertainty or credible high actual effort. Before dispatch record numeric deadline and remaining authorized budget in the existing packet; set proportionate per-run bounds, not mandatory global 20/60/90-minute defaults. No automatic cap renewal. If a supported child route is unavailable, record the hold and next owner rather than silently substitute. Medium output covers baseline, owner/state/dependency boundaries, discriminating checks, bounded artifacts, acceptance, foreseeable approvals/runtime needs, unknowns and next owner. Human/product decisions stay held. Distinguish read-only research from independent preparation review and publication.
3. Update 10days Step 2/3/8 to consume that policy within its own batch owner. A completed folder alone cannot exclude an open request. HELD is a reporting disposition, not a new persisted queue state. EXCLUDE requires affirmative delivered/duplicate/not-work/superseded evidence; unknown reproduction/access is held. Preserve live issue authority. Use start-task rating policy (neutral appeal50 absent operator value, cheapness inverted, no forced clearing/rescoring). Researchers report provisional ratings; existing primary writer persists only committed execution selection, not every shortlist. Keep acceptance copying, preflight, overlap, auto-fire prerequisites and wave ownership unchanged. Report held and excluded separately.
4. Validate main consumer path and adjacent reuse path by a manual instruction walk with predeclared expected dispositions: ordinary RAW no-contract input gets medium research; valid prepared input gets freshness reuse; unresolved access/product decision gets a visible hold; high-risk state boundary gets deeper bounded investigation; explicit risk-deferral gets scoped deferral only. Use minimal paper scenarios, no fake product work, model calls or builder dispatch; old conflicting text is the red control. This proves instruction consistency, not behavioral compliance by a model or actual admission interception. Record remaining real-follow-up requirement before ticking OL-09 as operationally verified.
5. Run classified docs checks, retained provenance and independent final relay QA. Final diff limited to Conveyor/10days instructions, this plan, CHANGELOG, required governance checkpoint and evidence. Publish reviewed source PR to development, no automatic merge/deployment. Record actual checks/reviews and open OL-10/real-follow-up work. No new test suites or speculative runner.

## Acceptance mapping

- RAW missing-contract/no-row requests remain accepted for preparation, never fabricated as ready.
- Medium research defaults for selected unprepared work; applicable prepared evidence is reused.
- Concrete high risk/actual effort triggers deeper bounded investigation, a decision/spike, or a visible hold, never silent exclusion.
- Explicit risk-deferral is scoped to its batch and grants no approval bypass.
- Ratings preserve operator values; appeal is neutral otherwise. Primary selection writes remain canonical.
- Daily-goal intake retained; 10days stays batch owner and is not re-enqueued into Jog.
- OL-10 runtime admission, #1328 fourth-gate proposal and numeric global defaults are not claimed implemented.
- Source instruction changes are independently reviewed and checked; deployment and unattended qualification remain unproven.

## Rating rationale

2026-11-16: retain proposal 75/60/50/60, no operator override. Priority reflects the requested near-term preparation bottleneck; severity reflects observed workflow loss and selection uncertainty, not data corruption. Appeal50 neutral; cheapness60 assumes a bounded instruction change with existing owners. Recurrence window 2026-11-03–16 versus 2026-10-20–11-02: this task has concrete recent Sunday-trial preparation/review stalls and #1476 recon, but no deduplicated incident census for either window; trend unknown. Do not infer increasing frequency from repeated reports of the same run. Read-back from the canonical writer will be retained before review.

## Lessons Learned (For Future Agents)

Pending implementation evidence; NO_ENTRY at planning time.

## Merge evidence

- PR #1491 merged 2026-11-17 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
