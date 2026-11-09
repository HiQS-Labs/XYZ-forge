# CodeRabbit follow-up consumer check

Before: step1 could choose start-task solely because a sweep needed a fresh clone, before selecting 10days. After: step1 selects the explicit owner first and sends requested 10days to step2 for its own issue/clone preparation; generic start-task is only for a task without an existing execution owner. PASS by instruction read and nonempty before/after assertions.

Adjacent paths: existing verified ready PR still goes directly to step6, and standalone start-marathon still requires exact dry-run-approved plan/order confirmation. PASS. Rollback now covers skill/index, GP/AGENTS and optional10days coordination/recovery together while retaining dirty-lane preservation. Active plan contains no machine-specific collection path. Native cleanup evidence remains unchanged.

Command: python3 source/boundary assertions and manual consumer read, exit0. No runtime sweep, new test suite or gate. Independent review did not run for these narrow follow-up corrections; earlier compatibility approval is scoped to its recorded revision.
