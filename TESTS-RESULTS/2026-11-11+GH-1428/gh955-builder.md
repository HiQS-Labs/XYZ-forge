### Round 1 · Builder · codex

- Changed `app/dashboard/snapshots.py`: select all active tenants, including internal tenants, and use the existing `serves_from_postgres` predicate inside `tenant_session` instead of requiring a connected Shopify source. Existing timezone, missing-row backfill, RLS session, and logging paths remain in place.
- Added `tests/test_dashboard_snapshot_refresh_filter.py`: persisted snapshot generation/backfill and subsequent midnight refresh for internal/external tenants with orders and absent/disconnected Shopify; empty Postgres backfill and timezone preservation; inactive/BigQuery-only exclusion. Added a seven-case no-Postgres scheduling check that executes the actual tenant-selection SQL against in-memory SQLite while isolating serving and writer dependencies.
- Root cause: the scheduled writer used a narrower eligibility policy than the dashboard reader; fix site: scheduled writer selection; the canonical reader predicate already expresses the required serving policy, so no new policy was introduced.
- Red control: the focused no-Postgres check on the original implementation failed 6 cases and passed 1. Candidate: all 7 cases passed.
- Verification command: `PYTHONDONTWRITEBYTECODE=1 <jog-clone>/.venv/bin/python -m pytest -q -p no:cacheprovider tests/test_dashboard_snapshot_refresh_filter.py::test_refresh_selection_and_schedule_without_database --basetemp=.relay-scratch/pytest-unit`.
- Postgres-backed regression verification was attempted only for `::test_refreshes_tenants_with_orders_without_connected_shopify`; pytest exited because sandbox access to `localhost:55461` was denied. Persisted-row/KPI assertions remain unverified here; harness must run the specified gate with database access. Evidence: `.relay-scratch/baseline.log`, `.relay-scratch/baseline-unit.log`, `.relay-scratch/verification-unit.log`.
- Scope note for reviewer: existing `tests/test_dashboard_snapshots.py::test_midnight_task_refreshes_when_local_hour_is_zero` expects a no-Shopify tenant to have no snapshot. That assertion conflicts with this brief's required empty-Postgres serving policy and will need reconciliation outside this turn's permitted files. It was not edited or run.
- Ask-self orientation attempted; unavailable at its configured external path. No git commands or full project gates were run.

Handing off to claude-reviewer — claude-reviewer, take your turn.

