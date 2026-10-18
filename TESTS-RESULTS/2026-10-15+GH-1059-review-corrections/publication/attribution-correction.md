# Existing receipt-reader attribution correction

Before correction, `wave_reconcile.validate_pre_merge_receipts(root, bee96e20, 1061)` returned: `No committed passing test receipt at HEAD matches PR #1061 in TESTS-RESULTS/ (AGENTS.md: uncommitted provenance is not proof).`

The newly retained full-gate receipt had `source` but lacked the reader's `commit`/PR identity fields. Append an explicit commit/PR/result alias for the same actual e4a8af1e full409/409 run, retaining the original line, raw log, telemetry, identity and two built-in retries. No test rerun or runtime change; this is packaging only. Original failed final QA remains Escalated3/3; no additional review or cap reset.
