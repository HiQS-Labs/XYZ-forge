### Round 1 · Reviewer · claude-reviewer

swept file: yes — reviewed `app/dashboard/snapshots.py` and `tests/test_dashboard_snapshot_refresh_filter.py` in full, not only the diff.

#### Implementation review — `app/dashboard/snapshots.py`

**Acceptance criteria coverage:**

1. ✅ `refresh_dashboards_at_local_midnight` now selects all active tenants with `Tenant.status == "active"` only (no Shopify or is_internal filter), then gates on `serves_from_postgres` inside the per-tenant session. Directly addresses the brief.
2. ✅ Internal tenants pass through `serves_from_postgres`: they have orders → `has_orders=True` → returns True. Tenants with no orders and no BigQuery warehouse also return True ("requires Postgres serving"). Both categories now receive snapshots.
3. ✅ Midnight scheduling (`is_local_midnight`) and missing-row backfill (`missing = db.get(DashboardSnapshot, tenant_id) is None`) logic are unchanged.
4. ✅ Regression tests in `tests/test_dashboard_snapshot_refresh_filter.py` are present and exercised.

**Pre-existing code — no new defects introduced:**
- `_upsert` IntegrityError double-write race handler (lines 136–144): pattern is correct; it handles concurrent inserts, not corruption.
- `is_local_midnight` hourly window is intentional (task may run multiple times per hour).
- `read_postgres_dashboard` empty-tile fallback on missing/malformed row is consistent with the rest of the page read path.

**[Advisory] Misleading event name (pre-existing, not introduced here):** `dashboard.snapshot.timezone_skipped` (line 184) fires when the timezone is set but unknown — the tenant is NOT actually skipped; backfill proceeds. This is a logging observability issue only, not a correctness bug.

**[Advisory] Conflicting test outside permitted scope:** `tests/test_dashboard_snapshots.py:164` asserts `db_session.get(DashboardSnapshot, no_shop.id) is None`, i.e. that a no-Shopify tenant with no orders gets NO snapshot at midnight. Under the new `serves_from_postgres` policy (no orders + no bigquery_warehouse → serves from Postgres → eligible), this tenant WILL be refreshed, breaking that assertion. The builder correctly identified this conflict and noted it is outside the permitted file scope (`tests/test_dashboard_snapshots.py` is not in the artifact list). The phase gate (`.venv/bin/pytest -q tests/test_dashboard_snapshot_refresh_filter.py`) does not run that file.
- Observed input: `no_shop` tenant — `status="active"`, `is_internal=False`, `timezone="America/Los_Angeles"`, no Shopify DataSource, no orders, no BigQuery warehouse.
- Affected scope: `tests/test_dashboard_snapshots.py::test_midnight_task_refreshes_when_local_hour_is_zero`.
- Action required: reconcile that test in a follow-on turn or PR.

#### Test review — `tests/test_dashboard_snapshot_refresh_filter.py`

- `test_refreshes_tenants_with_orders_without_connected_shopify`: 4 cases (2×internal × 2×shopify_status). Exercises backfill (UTC 18:00) then midnight refresh (UTC+8 → LA midnight). Checks `computed_at`, `kpis`, and `top_recommendations` shape after each call. Correct.
- `test_missing_snapshot_backfill_preserves_timezone_scheduling`: Covers None and invalid timezone; verifies backfill fires, then subsequent non-midnight call does NOT overwrite. Correct.
- `test_refresh_skips_inactive_and_bigquery_only_tenants`: Two negative cases (inactive; active + BigQuery warehouse). Verifies no snapshot is created. Correct.
- `test_refresh_selection_and_schedule_without_database` (7 parametrize cases, `@pytest.mark.nodb`): SQLite-backed tenant selection; mocks `tenant_session`, `serves_from_postgres`, and `refresh_dashboard_snapshot`. Covers internal=True/False, inactive, bad/None timezone, non-midnight non-missing scenario. Assertion inside `scoped_session` (`assert tenant_id == expected_id`) fires only for active tenants — set before the call, single-tenant fixture — no logic error. Builder reports all 7 pass vs. 6 failures on the original. [Unverified — needs clone run for Postgres-backed tests]

**Verdict:** Approved

The implementation is correct per the acceptance criteria. The one outstanding item (reconciling `test_dashboard_snapshots.py:164`) is out of scope for this phase and should be tracked separately.

