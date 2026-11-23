# Closing at merge, the appeal axis, and rows at work start — GH-1333 decisions 4-6

Recorded 2026-11-04. The operator decided the three questions the 2026-11-03 record left open, plus two follow-ups raised by QA of #1340. The canonical rule text is in [PROJECT/PDDA.md](../PROJECT/PDDA.md), under "GitHub issue intake" (Lifecycle) and section H. The full operator-approved rule set, with stable IDs, is at the top of [#1328](https://github.com/HiQS-Labs/XYZ-forge/issues/1328) (G4, G5, G6, G6a, G6b and interim rules C1-C3).

4. **The merge step closes an issue under two conditions** (rule G4): a recorded independent review assertion that the delivered lane covers the whole issue, or a non-empty `## Acceptance` checklist with every item checked. Otherwise it leaves the issue open with one "delivered, left open because <reason>" comment. A mention is never authority; never use a negated close keyword.
5. **The appeal axis stays as it is** (rule G5): neutral 50 unless the operator supplies a value. 91 of 112 recent ratings are 50, so appeal adds a near-constant to the sum; that is accepted.
6. **A ledger row is created when work starts, not at filing** (rule G6). Filing no longer means a row; the row and its stored rating appear at pickup (`jog add`, `start-task`, promotion to `2-WORKING`). Until then the rating proposal lives in the issue body.
   - **D-b** (rule G6b): selection means committing an issue to an actual execution batch or marathon; its row is created on the primary before dispatch, or an existing proposal row is reused with its rating.
   - **D-a** (rule G6a): the 69 existing "Queue / parked intake" rows stay as proposals; no migration now; revisit about a month after the cutover.

Why: "a row exists" was standing in for "someone is working on this", and it was created at filing. 208 of 300 open issues had no row, so the backlog looked unregistered when it was simply unstarted, and admission rejected issues for a missing row instead of a missing plan. Ratings stored at filing were mostly placeholders.

Status: **policy decided, not yet implemented.** Today's intake tools and the coverage check still write and require a row at capture. The change lands as one cutover (#1340 Tasks 2, 3, 4, 6 and the Task 11 rating contract, with Task 5 as the #1298 rollout instruction). Closing at merge is #1340 Task 7. Until they land, interim rules C1 (closing keywords) and C2 (no row-writing intake for new unstarted work) apply.

Expected signal: after the cutover, new issues filed through intake have no row until pickup, the inbox coverage check stays green for them, and the admission census stops reporting "no ledger row" as a rejection reason. After Task 7, every merged lane either closes its issue under one of the two conditions or leaves exactly one reason comment. Revisit if issues go missing between filing and pickup, or duplicates appear.

Rollback: the policy is text. Revert this record and the PDDA.md edits. Nothing in the code changed with this record.
