### (1) ANSWER

A documented, reasoned deviation is fundamentally different from a silent one. The 0.2.0 precedent exists to prevent *silent* scope drops (closing an issue while pretending the original criteria were met, which masks gaps). When a solution successfully pivots because the original criteria were discovered to be flawed, holding the issue open creates administrative friction without product value. The correct path is to explicitly amend the stale criteria to reflect the learned constraints, and then close it. This preserves the historical "why" without leaving ghost issues hanging on technicalities.

### (2) FINDINGS

**#388 — marathon run-log durability**
**[Pass] — Verdict: B — AMEND CRITERIA, THEN CLOSE.**
**Justification:** The implementation pivoted for a very good reason: a log co-located within its target repository inherently shares that repository's durability lifecycle. Refusing to run in this state would needlessly break valid workflows, including the project's own test harness. The shipped work solved the real-world problem (preventing ephemeral log loss to random temp directories). The written criterion is the stale artifact here.
**Replacement criterion wording:** *"A default log path resolving to a non-durable root AND outside the target repo must fail the run. Paths resolving inside the target repo are permitted, inheriting the repo's durability."*

**#358 — CI lock flake**
**[Blocker] — Verdict: C — KEEP OPEN.**
**Justification:** The real problem this issue tracks is the CI lock flake losing records. Shipping the Phase 1 instrumentation did not solve this problem; it merely made it observable. The issue is actively red in CI today, meaning the required observation has been captured and Phase 2 (the actual fix) is now unblocked. Closing an actively red CI defect because the "instrumentation phase" shipped would be a textbook silent scope drop.
**What would close it:** A fix for the root cause identified by the new instrumentation, resulting in a reliably green CI assertion.

**#354 — Concurrent Swarms**
**[Blocker] — Verdict: C — KEEP OPEN.**
**Justification:** This is a broad parent tracking issue. The fact that the release's manifest only claimed "Phase 1" does not mean the overarching issue is complete. The real-world capability of "Concurrent Swarms" remains unshipped. Closing a broad parent issue because one narrow slice of it was delivered by successor tickets (#376/#448) guarantees silent scope loss for all remaining phases.
**What would close it:** Completion of the remaining phases for concurrent swarms, or explicitly extracting the unbuilt phases into new, standalone issues so this parent can be safely retired.

### Decision Rule

When shipped work solves the underlying problem but diverges from the written acceptance criteria, **amend the criteria to match reality, then close the issue.** Do not close it silently (which destroys the historical 'why' and causes scope loss) and do not hold it open on technicalities (which destroys the utility of issue states). The acid test is *net effectiveness*: if the real-world defect is mitigated or the capability achieved, document the pivot as the new truth and close it. If the defect persists or the capability is incomplete, the issue stays open.

### (3) RECOMMENDATION

Amend #388's criteria and close it, but keep #358 and #354 open to prevent abandoning active CI failures and unbuilt core capabilities.
