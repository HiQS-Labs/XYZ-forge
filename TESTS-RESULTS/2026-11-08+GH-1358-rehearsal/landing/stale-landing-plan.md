# Changed-head scheduled landing refusal

One-shot launchd invocation of existing merge-cleanup with the prior approved1372
head624f52c8. Launch ONLY after remote1372 is verified at repaired8ef5dcc06.
Expected: existing pinned-head guard refuses before merge/reconcile/queue mutation.
Record actual remote head, primary before/after, exit/logs and counter preservation.
This exercises the actual authorized landing tool on a real changed candidate; it
is not Jog automatic landing or a successful autonomous progression claim.
No repeat schedule, workload dispatch, new gate, extra supervisor or head rewrite.
Then normal reviewed current-head merge-cleanup resumes with the user authorization.
