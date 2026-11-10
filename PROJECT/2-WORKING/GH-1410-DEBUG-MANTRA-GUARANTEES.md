---
title: "GH-1410: Verify symptom relevance and preserve guarantees"
status: active
created: 2026-11-10
updated: 2026-11-10
owner: Codex
goal: "Sharpen debug-mantra step 3 without a second skill or new execution authority."
gh_issue: 1410
---

## Status

| What was just completed | What's next |
|---|---|
| Bounded wording and relative-link checks; express review attempt timed out | Independent review and normal PR qualification; managed deployment after landing |

## Scope and acceptance

- Step 3 requires evidence that the candidate addresses the reported failure path, distinguishing a related synthetic defect.
- Trace existing guarantees through code, tests and prior fix rationale; try combined inputs against the candidate.
- Explain assertion changes; label unresolved checks. No new test suite, gate, runner or authority.
- Existing PDDA documentation gate and independent review must qualify delivery.

## Merge evidence

Not landed. Express docs preflight refused `skill-unattested`; the agy relay timed out at its 180-second cap without a valid verdict/attestation. Normal PR fallback retains the source edit; deployed collection is unchanged. Publication is draft until review and required checks qualify the final head.

## Lessons Learned (For Future Agents)

A targeted red control verifies a behavior change, not preservation of prior guarantees. Exercise the intersection of inputs previously tested separately. A review timeout is not approval and must not be replaced by a fabricated attestation.
