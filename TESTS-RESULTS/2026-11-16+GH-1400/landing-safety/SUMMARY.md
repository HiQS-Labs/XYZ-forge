# Landing safety follow-up

Model-free baseline reproduced both review findings: alignment overwrote an ignored untracked log and lease acquisition changed a parked row to running. The fixed candidate c03bdfb8f preserves the log, refuses held/mismatched selection without consuming an attempt, and accepts a matching pending row. Existing supervision controls passed 23/23 with exact required IDs and unchanged clone identity. The stricter published() check now requires ledger cleanliness as well as matching remote HEAD.

Independent Claude follow-up review approved and attested; see relay-system/2026-11-16/gh1491-landing-safety-claude-review-status.md. Optional fixture expansion and protection of the pre-existing non-supervised checkpoint switch are deferred outside this supervised change; no claim of complete protection for that older path. Reviewer temporary branch mutation was restored by its owner, with reported reflog-only residue.

Historical check.py/review-fixes.py controls remain original experiment records, not fresh acceptance proof. Current adoption receipt and checkpoint claims use followup.py/results. Gate-exit exclusions are source-reviewed; independent exit-0/108 mutations are not newly demonstrated. No new suite was registered.

The earlier408/408 gate predates these two safety changes; final full gate pending. No merge readiness is inferred from the earlier gate alone.
