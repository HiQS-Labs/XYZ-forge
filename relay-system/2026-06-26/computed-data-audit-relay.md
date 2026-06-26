# RELAY · Codex audit — other un-computed/failing derived data (LTVera v1.2)

NEXT: codex
STATUS: Approved
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first
You are **codex**, the Reviewer/Auditor. The Producer (Claude) did a first-pass audit; your job is
to **adversarially verify and extend** it. This is an AUDIT — **read-only, report only**, you do
**not** edit the LTVera repo. Append your findings block to THIS file.

1. **Read the Producer brief** (self-contained: failure classes, prod ground-truth, findings F1–F8):
   - `/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-26/computed-data-audit-brief.md`
2. **The codebase under audit** is the sibling clone:
   `/Users/noelsaw/Documents/GH Repos/LTVera-Pandas`. Read-only **prod** access is documented in
   that repo's `OPERATIONS.md` (SSH GCE VM `ltvera-dev` → run queries in the `app` / `postgres`
   containers; BQ via the warehouse client). **SELECT / INFORMATION_SCHEMA only — never write.**
3. **Do the work in the brief's "Your turn" section:** re-confirm F1–F4 against live schema (re-pull
   `INFORMATION_SCHEMA`, don't trust the paste), resolve candidates F5–F7 to CONFIRMED/OK with
   column-level evidence, sweep for anything missed (every `query_rows`/`client.query(` site + every
   `DELETE FROM … `+reinsert recompute populator → check each writing table's prod row count), and
   rank by severity flagging the Binoid-measurement critical path.
4. **Append ONE block** at the bottom, above the marker, with graded findings: `[Confirmed-Broken]`
   · `[Likely-Broken]` · `[OK]` · `[Gap]` (missing test/alarm). Each: table → populating
   function (`file:line`) → dependency it breaks on → expected vs. actual schema → prod row
   count/freshness → severity. Then a **Verdict** (is the Producer's F1–F8 set correct + complete?)
   and a **Basis** line (which checks were behaviorally proven vs textual).
5. **Set the header:** `STATUS: Approved` if you confirm the audit stands (even with additions);
   `STATUS: Changes requested` if a Producer finding is wrong.
6. **Hand off the lock**, then stop:
   `TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" done RELAY-audit-cdata-1 --agent codex`
7. **Stop.** One-line result to the operator.

## Setup
- Artifact under review: the Producer audit brief (`computed-data-audit-brief.md`) + the live
  LTVera-Pandas repo.
- Definition of Done: codex files graded findings (verify F1–F8 + extend) + Verdict + sets STATUS.
- Reviewer: **codex**. Producer: the operator's Claude session.
- Lock: `tick` task **RELAY-audit-cdata-1**.
- Started: 2026-06-26

## Ground rules
1. This file is the single source of truth. Append one block at the bottom; never edit earlier turns.
2. Read-only on prod and on the LTVera repo — findings + evidence only, no fixes.
3. Tight: bullets, cite real `file:line` and real table/column names.
4. Evidence contract: log a `Basis:` — `behaviorally proven` (re-queried live schema) vs `textual only`.

---
## Log

### Codex audit — 2026-06-26
- [Confirmed-Broken] `customer_nbp` -> `app/recommendations/nbp.py:548-557` `load_family_affinity_bq` -> breaks on `binoid_refmodel.ref_basket_affinity.anchor_cluster` / `comp_cluster`; expected cluster-grain columns or a join through `ref_product_cluster`; actual live schema is product-grain only (`anchor_product_id`, `companion_product_id`, `co_order_count`, `final_score`, ...), and replaying the exact query fails `Unrecognized name: anchor_cluster`; prod state: `customer_nbp` = `0` rows overall and `binoidcbd` = `0`; severity: Critical, on the Binoid measurement path.
- [Confirmed-Broken] `customer_nbp` -> `app/workers/celery_app.py:78-89`, `app/workers/tasks.py:146-170`, `app/api/routes/admin.py:135-166` -> depends on a scheduler/materializer that does not exist; expected beat/post-sync trigger to populate the serving table; actual beat only schedules `refresh_shopify_stores` and `refresh_klaviyo_accounts`, while NBP is operator-triggered only; prod state: `customer_nbp` = `0` for `binoidcbd`, `bounce`, `bloomzhemp`, and `open-cdp`; severity: Critical, blocks all tenants even where source tables are healthy.
- [OK] `customer_nbp` BQ escalation side -> `app/recommendations/nbp.py:563-574` -> depends on `binoid_refmodel.ref_escalation_patterns.entry_cluster`, `next_cluster`, `customer_count`, `transition_rate`, `strong_signal`; live schema exposes all five columns, and replaying the aggregate returned rows; prod state: no evidence this side is drifted; severity: none.
- [OK] `customer_decisioning_state` (Binoid backbone) -> `app/signals/decisioning_warehouse.py:181-186` -> depends on `binoid_refmodel.ref_product_cluster.product_id`, `cluster_name`, `signal_eligible`; live ref table exists (`1943` rows), Binoid warehouse probes on `binoid_woo.orders` succeed, and prod `customer_decisioning_state` has `395069` `binoidcbd` rows (`updated_at 2026-06-11 23:53:58+00`); severity: none for the active measurement tenant.
- [OK] `ref_replenishment_timing` readers -> `app/recommendations/builder.py:395-413,445-492` and `app/ai/service.py:680-691` -> depend on `product_id`, `p50_days`, `cluster_name`, `category_fallback_p50`; live schema exposes those columns and sample reads succeed; this is a read-only prior path, not a materialized serving table; severity: none.
- [OK] dashboard BQ KPI path -> `app/dashboard/kpis.py:289-298,360-403` -> depends on Woo warehouse columns `orders.order_id`, `order_total`, `customer_id`, `order_date`, `order_status` plus `customers`; live Binoid KPI replay succeeded, `bloomz_woo` exposes the same column set, and tenants with Postgres orders bypass the BQ path entirely via `select_kpi_source`; severity: none.
- [OK] generic refmodel reads -> `app/refmodel/client.py:303-355` -> depend on the base tables existing rather than on hard-coded projected columns; live reads succeeded against `mv_order_signals`, `ref_discount_sensitivity_cohort`, `ref_model_build_metadata`, `ref_replenishment_timing`, and `ref_product_cluster`; severity: none.
- [Likely-Broken] `customer_decisioning_state` for other connected warehouse tenants -> `app/signals/service.py:82-120` -> depends on each connected tenant actually materializing a backbone rowset; expected non-empty rows after warehouse onboarding; actual prod state: `bloomzhemp` has a connected `bigquery_warehouse` data source but `customer_decisioning_state = 0`, and `open-cdp` has a connected `bigquery_warehouse` row plus stale native `signal_*` tables last updated `2026-05-28` but still `customer_decisioning_state = 0`; severity: Medium, outside the Binoid measurement path but blocks recommendation serving if those tenants are activated.
- [Likely-Broken] `open-cdp` warehouse decisioning adapter -> `app/signals/decisioning_warehouse.py:78-93` -> depends on Woo-shaped warehouse columns `order_id`, `order_status`, `billing_email`, `order_date`, `order_lines.order_id`, `line_id`, `resolved_product_id`; actual live `open_cdp_woo.orders` exposes Shopify-shaped columns (`order_token`, `email`, `shopify_created_at`, no `order_status`), and replaying the adapter's sales probe fails `Name order_status not found`; prod state: `open-cdp` has `0` backbone rows today; severity: Medium-Low, dormant until that BQ path is invoked.
- [Gap] CI/prod guardrails -> `tests/test_nbp.py:209-225`, `tests/test_signals.py:546-571`, and `tests/test_dashboard_kpis.py:147-252` all stub the BQ clients and therefore never assert live/reflected column contracts; expected a checked-in schema contract plus a post-deploy non-empty/freshness gate for `customer_decisioning_state` and `customer_nbp`; actual prod state: F1/F2 shipped and the Bloomz/Open-CDP backbone gaps remained invisible; severity: High process gap. The contract tests should live next to the adapters they protect: `tests/test_nbp.py` for `load_family_affinity_bq`, `tests/test_signals.py` for `compute_decisioning_state_from_warehouse`, and `tests/test_dashboard_kpis.py` for `BQWarehouseKpiSource`, backed by frozen column manifests for `binoid_refmodel` and the Woo warehouse schema.

Verdict: Producer F1-F8 are correct on substance; F5-F7 resolve `[OK]`; the set is not complete because it misses the connected-tenant `customer_decisioning_state` gaps (`bloomzhemp` unmaterialized, `open-cdp` warehouse schema incompatible with the BQ adapter).

Basis: behaviorally proven = live BigQuery schema pulls, live query replays (including the F1 failure), live refmodel reads, and prod Postgres row-count/freshness checks; textual only = absence of beat entries and the current test-surface coverage.
