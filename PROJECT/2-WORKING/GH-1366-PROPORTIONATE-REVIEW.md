---
title: "GH-1366: proportionate review wording"
status: "Working"
created: 2026-11-07
updated: 2026-11-07
owner: Codex
gh_issue: 1366
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1366
goal: Clarify existing red-control scope and appendix proportionality without changing test policy.
doc_type: enhancement
---

# GH-1366 — Proportionate review wording

## Status

| What was just completed | What's next |
|---|---|
| Audit and K3 review adjudicated; #1367 merged | Independent plan QA, then two scoped wording changes |

## Scope and recon

This is the first bounded slice of audit #1366, not completion of its eight-item umbrella.
Base: 49777b82d1be9ac915e9cdced5db2adb6018607f, including merged #1367.
The source-grounded Recon Map and K3 dispositions remain in the issue.
AGENTS.md's universal witnessed-red paragraph is read at startup through ROUTER.md.
GUIDING-PRINCIPLES.md item 13 already limits mandatory red controls to new or materially
changed decision gates. Its appendix ranks containment ahead of friction within doc review;
the merged North Star separately requires each control to earn its operational cost.
No runtime state, receipt schema, test runner or shared PDDA distribution changes.

Outcome: agents can distinguish unchanged coverage reruns from changed decision gates,
and do not interpret appendix tie-breakers as exemption from proportionality review.
Smallest bet: reuse the canonical scope and add one North Star pointer in the appendix.
Alternative rejected: a new guard/exception framework adds machinery to a prose ambiguity.
Reversibility: Easy — revert the two prose changes. Blast radius: startup readers and doc
reviewers gain narrower guidance; no new execution authority or weakened containment.

## Ordered implementation and acceptance

1. Scope AGENTS.md's witnessed-red requirement to new/materially changed decision gates,
   preserving the falsifiability rationale, existing-suite/manual evidence routes and examples.
   Explicitly say rerunning unchanged coverage does not require a fresh mutation.
   -> Expect new/changed gates still need a witnessed failure; unchanged reruns do not.
2. Clarify the appendix ordering is a doc-review tie-breaker applied subject to the North Star
   proportionality assessment. -> Expect containment protection stays, burdens can be reconsidered.
3. Read both instructions from ROUTER.md as a consumer and compare a changed gate with an
   unchanged rerun; record manual evidence and provenance. Run the classified docs gate,
   independent final QA, then publish a PR against development. -> Expect no runtime/test changes.

## Non-goals and verification boundary

Do not amend GH-831, add tests/guards, alter retry budgets, permit reviewer Git, edit intake,
change start-task skill or promotion, or redo Jog. The start-task recital clarification remains
on the umbrella. No new suite or registry entry. Existing PDDA gate covers docs; no runtime
smoke is applicable. Manual consumer review records the two policy cases; no new decision
gate is introduced and no destructive mutation is needed for this wording-only change.
Final source review is independent; text review is not a runtime pass.

## Rating rationale

2026-11-07: rated 65/35/50/90 for this bounded slice (higher effort axis means cheaper).
Priority follows explicit user selection; severity reflects confusing instructions and review
friction, not data loss. Appeal neutral. Easy two-file wording adjustment.
Recurrence windows: 2026-10-25..2026-11-07 versus 2026-10-11..2026-10-24.
Known example: #1365/#1367 and K3's #1366 comment; no complete incident census, unknown trend.
Prior-art search found #1366 and no matching PR; #1367 resolves general proportionality, not
these remaining exact paragraphs. No override score.

## Review and evidence

Plan QA pending. Final QA pending. Gate/consumer evidence pending.
Umbrella stays open after this slice lands.

## Lessons Learned (For Future Agents)

NO_ENTRY: no observed workflow outcome yet; textual clarification alone does not prove reduced friction.
