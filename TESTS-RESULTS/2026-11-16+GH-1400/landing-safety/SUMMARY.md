# Landing safety follow-up

Model-free baseline reproduced both review findings: alignment overwrote an ignored untracked log and lease acquisition changed a parked row to running. The fixed candidate c03bdfb8f preserves the log, refuses held/mismatched selection without consuming an attempt, and accepts a matching pending row. Existing supervision controls passed 23/23 with exact required IDs and unchanged clone identity. The stricter published() check now requires ledger cleanliness as well as matching remote HEAD.

Independent Claude follow-up review approved and attested; see relay-system/2026-11-16/gh1491-landing-safety-claude-review-status.md. Optional fixture expansion and protection of the pre-existing non-supervised checkpoint switch are deferred outside this supervised change; no claim of complete protection for that older path. Reviewer temporary branch mutation was restored by its owner, with reported reflog-only residue.

Historical check.py/review-fixes.py controls remain original experiment records, not fresh acceptance proof. Current adoption receipt and checkpoint claims use followup.py/results. Gate-exit exclusions are source-reviewed; independent exit-0/108 mutations are not newly demonstrated. No new suite was registered.

Final full gate on 0c13b793f745236eebe29b333666015da6513457: 408/408, exit0, clone identity unchanged. Live relay-self-sufficiency explicitly skipped; not promotion evidence. Publication skips the duplicate valued-clone push hook using XYZ_SKIP_PREPUSH=1, relying on this disposable-clone run. Publication adds only final evidence.
