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

RAW means an existing open GitHub issue, including a daily-goals issue, without requiring a roadmap row, capture or contract. Conveyor owns explicit issue/daily-goals intake: read the named issue, preserve its goal text and holds, and identify linked open issue candidates before preparation. Unlinked or ambiguous goals remain recorded holds for decomposition; this slice does not invent issue-creation authority. 10days retains its age-window entrypoint. Accept RAW daily-goal requests at intake. For selected unprepared work, bounded medium research is the default; deepen when evidence justifies risk or actual effort. Reuse applicable research. Unknowns remain visible holds, and risk deferral requires an explicit batch-scoped request. Preparation grants no dispatch authority. Preserve original acceptance, operator scores/overrides, ownership and cumulative budgets.

This slice implements OL-09 instructions through existing Conveyor and 10days. OL-10 actual stale/held admission refusal remains separately open in this issue; do not claim runtime enforcement from prose. No runtime code, new queue/state/schema, test suite, new daemon, installed skill edit, #1328 amendment, or live backlog execution. No dependency on landing PR #1491 for these instruction changes. This PR will use Refs #1476, not close the whole issue.

## Recon and smallest viable bet

Base: `f346d8908a42cd6e7e92f80657f9e7a21208e0ae`. The source Conveyor flow already accepts missing rows/contracts and grounds preparation, but Step 2 has no medium-depth default or bounded research selection contract. 10days Step 2 immediately excludes completed-folder captures; Step 3 defaults to binary INCLUDE/EXCLUDE, scores appeal from clarity and forcibly clears overrides; Step 8 mixes holds into exclusions. Its Step 5 --deep refreshes preflight, not research depth. Jog already owns a detailed preparation/admission handoff. No runtime discovery is needed for this instruction-only change.

Smallest bet: own one research-depth policy in Conveyor and link 10days to it, correcting conflicting selection/reporting text. Existing open #1476 already owns the ask; prior-art query medium research preparation found no matching open/merged PR or existing-fix candidate, with no API errors. This is bounded search, not exhaustive prior-art proof. Graph primary generation 2026-11-16T19:03:06Z reports no recorded gaps/metadata match for the four relevant skill paths; exact source at the stated base was read for material claims.

Alternative rejected: merely adding another umbrella paragraph leaves contradictory consumer instructions intact. A new research runner or automatic readiness gate is unnecessary for OL-09 and would expand into OL-10. Reversibility Easy: revert source instructions through normal review; retain intake and evidence, never erase held tasks.

## Ordered implementation and verification

1. Review this plan before changing skill instructions. Keep primary-owned rating checkpoint; use the existing independent relay protocol, valid verdict/Basis and actual attestation. Preserve round budgets.
2. Add Conveyor's canonical RAW preparation policy before its flow: accept raw requests without manufacturing contracts, distinguish already-prepared freshness reuse from medium research, default one read-only research child for selected unprepared work, and deepen on concrete state/authority/recovery uncertainty or credible high actual effort. Before launching research, record its numeric deadline and remaining authorized budget in the parent selection/recon note (before a capture or preflight packet exists); carry that record into the eventual packet; set proportionate per-run bounds, not mandatory global 20/60/90-minute defaults. No automatic cap renewal. If a supported child route is unavailable, record the hold and next owner rather than silently substitute. Medium output covers baseline, owner/state/dependency boundaries, discriminating checks, bounded artifacts, acceptance, foreseeable approvals/runtime needs, unknowns and next owner. Human/product decisions stay held. Distinguish read-only research from independent preparation review and publication.
3. Update all conflicting 10days locations: completed-folder guardrail and Step 2, Step 3 sanity filter/ratings/verdict schema, Step 4 research and contract sniff, Step 5 terminology, Step 6 preflight disposition, and Step 8 reporting. Consume the policy within its existing batch owner. A completed folder alone cannot exclude an open request. HELD is a reporting disposition, not a new persisted queue state. EXCLUDE requires affirmative delivered/duplicate/not-work/superseded evidence; unknown reproduction/access is held. Preserve live issue authority. Use start-task rating policy (neutral appeal50 absent operator value, cheapness inverted, no forced clearing/rescoring). Step 3 validity researchers report provisional findings/ratings only, with no ledger writes. Selected means the parent has explicitly committed a bounded candidate set after validity triage; it does not mean ready or admitted. In Step 4, before contract authoring, reuse fresh preparation or dispatch one read-only medium research child per selected unprepared issue under the canonical Conveyor policy. Do not repeat medium research already evidenced by Step 3. Children must not invoke Conveyor Steps 3–6, write captures/ledger, publish, or execute. The parent preparation owner alone advances capture/contract/review after research. Correct Conveyor Step 4 pickup wording too: the canonical primary writer persists committed preparation selection before dispatch per #1328, not every shortlist; selection is not execution admission. Preserve malformed operator overrides and hold for an operator decision rather than clearing them. Keep acceptance copying, probe execution, overlap, auto-fire readiness prerequisites and wave ownership unchanged. Correct their disposition text: contract sniff failures are HELD; preflight exit 4 alone is not proof of delivery and is HELD pending evidence distinguishing already-fixed behavior from invalid/wrong-polarity probes. Affirmatively verified delivery may be excluded. Remove automatic low-risk exclusion unless risk-deferral mode was explicitly requested. Explain that marathon-plan --deep refreshes preflight and does not select research depth. Report held and excluded separately.
4. Validate main consumer path and adjacent reuse path by a manual instruction walk with predeclared expected dispositions: ordinary RAW no-contract input gets medium research; valid prepared input gets freshness reuse; unresolved access/product decision gets a visible hold; high-risk state boundary gets deeper bounded investigation; explicit risk-deferral gets scoped deferral only. Use minimal paper scenarios, no fake product work, model calls or builder dispatch; old conflicting text is the red control. This proves instruction consistency, not behavioral compliance by a model or actual admission interception. Do not tick OL-09 in #1400 on this PR. Its checkbox stays unchecked until a real bounded run witnesses the preparation behavior; state this in the PR, CHANGELOG and evidence.
5. Run classified docs checks, retained provenance and independent final relay QA. Final diff limited to Conveyor/10days instructions, this plan, CHANGELOG, required governance checkpoint and evidence. Publish reviewed source PR to development, no automatic merge/deployment. Record actual checks/reviews and open OL-10/real-follow-up work. No new test suites or speculative runner.

## Round 1 dispositions and falsifying scenario matrix

Round 1 FAIL is preserved in `relay-system/2026-11-16/gh1476-plan-qa/`. B1 and S1–S6 accepted; remaining plan review budget is 2 of 3 rounds. No production source changed before approval.

Each row must name the old instruction that gives the wrong result (or missing rule), the revised owner/line, and expected output. Run the main Conveyor path and the 10days consumer where applicable; a paper pass is documentation consistency only.

| Scenario | Required result / falsifier |
| --- | --- |
| Open raw issue, no row or contract | Accepted for preparation; no READY claim; medium child after committed selection. Missing intake or research rule fails. |
| Named daily-goals issue with linked task and ambiguous unlinked goal | Conveyor preserves goal/holds, prepares linked candidate, holds ambiguous goal; dropping it or silently creating work fails. |
| Fresh prepared item | Reuse evidenced preparation after freshness check; redundant research child fails. |
| Open issue with completed-folder capture | Reconcile live request; folder alone never excludes. |
| Low-risk legitimate task, no deferral request | Remains eligible; sanity filter cannot silently discard it. |
| Unknown access/reproduction, bad contract, or wrong-polarity probe returning 4 | HELD with reason/next owner; EXCLUDE on absence of evidence fails. Independently confirmed delivered item remains EXCLUDE. |
| High-risk state/authority boundary or credible high effort | Bounded deeper investigation/decision/spike or explicit hold; unchanged shallow research fails. |
| Explicit batch risk-deferral | Applies only in that batch, preserves tasks and approvals; a global default or bypass fails. |
| Operator score/override, including malformed override | Preserve valid values, neutral appeal absent value, hold malformed value; automatic clearing fails. |
| Shortlist and research child | Read-only/provisional, no ledger or Conveyor Steps 3–6; selected parent writes through primary before research dispatch. |
| Research before packet exists / budget exhausted | Pre-existing parent note records deadline and remaining budget; no dispatch on exhausted budget or renewed cap. |
| Completed paper walk and reviewed instruction PR | OL-09 remains unchecked; OL-10, rubric amendment, global time defaults and deployment remain unclaimed. |

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
