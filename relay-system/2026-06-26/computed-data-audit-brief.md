# Producer audit — computed/derived data that could be silently empty, stale, or failing (LTVera v1.2)

**Producer:** Claude (Noel's session). **Reviewer:** Codex.
**Origin:** running the Binoid `customer_nbp` recompute failed and exposed a schema-drift bug; this
audit looks for *other* instances of the same two failure classes before the measurement run.

This is a **first pass** — confirmed findings + verified-OK + candidates I want you (Codex) to
adversarially verify and extend against live schema. Repo: `LTVera-Pandas` (sibling clone). Prod
read access via its `OPERATIONS.md` (SSH `ltvera-dev` → `app`/`postgres` containers; BQ via the
warehouse client). **Read-only only.**

## Failure classes in scope
1. **Schema drift** — a BigQuery query references columns/tables that don't match live schema, so
   it throws at runtime and its output table never populates.
2. **Un-materialized / stale recompute artifact** — a "delete-then-insert" recompute table that is
   empty or stale in prod with no freshness/null-rate alarm and no post-deploy population gate.
   (A populator existing in code ≠ it ever having run in prod.)

## Ground truth I pulled from prod (2026-06-26, read-only)

**Prod Postgres derived-table inventory (`pg_stat_user_tables` live estimates):**
```
customer_decisioning_state     431,920     signal_basket_affinity         6,526
customer_nbp                         0  ⛔  signal_escalation             88,649
activation_events/optins/writes      0      signal_replenishment           5,339
recommendation_lever_configs         1      signal_discount_sensitivity 2,098,930
```
Binoid (`binoidcbd`) specifically: `customer_decisioning_state` = 395,069 (recompute 2026-06-11);
`customer_nbp` = 0.

**Live `binoid_refmodel` BQ schema (the candidate source for BQ tenants like Binoid):**
```
ref_basket_affinity:     anchor_product_id, slot, companion_product_id, lift_score, co_order_count,
                         companion_revenue, same_cluster, category_diversity_bonus, recency_boost,
                         final_score, source                       ← NO anchor_cluster / comp_cluster
ref_escalation_patterns: entry_product_id, next_product_id, entry_cluster, next_cluster, same_cluster,
                         customer_count, transition_rate, strong_signal   ← cluster cols PRESENT
ref_product_cluster:     product_id, cluster_name, mapping_source, signal_eligible, exclusion_reason
ref_replenishment_timing: product_id, p25_days, p50_days, p75_days, mean_days, stddev_days,
                         n_intervals, low_confidence, cluster_name, category_fallback_p50
ref_customer_finance / ref_customer_signals / ref_discount_sensitivity_* / ref_escalation_paths /
ref_basket_affinity_seed / ref_model_build_metadata / mv_order_signals — schemas captured; see repo
SWE-Internal §9.7 for the affinity detail.
```

## Findings (first pass)

| # | Status | Where | Issue |
|---|---|---|---|
| **F1** | ⛔ **CONFIRMED** | `app/recommendations/nbp.py:548` `load_family_affinity_bq` | Selects/`GROUP BY` `anchor_cluster, comp_cluster` on `ref_basket_affinity`, which is **product-grain** (no cluster cols). Runtime `400 Unrecognized name: anchor_cluster`. BQ scorer path has **never** run → `customer_nbp` empty for Binoid (the measurement tenant). Fix = JOIN `ref_product_cluster` to derive clusters; rollup semantics are Sam's L1 call. (SWE-Internal §9.7) |
| **F2** | ⛔ **CONFIRMED** | `customer_nbp` populate orchestration | 0 rows for **every** tenant, not just Binoid. No Celery beat entry recomputes NBP (beat only has `refresh_shopify_stores`, `refresh_klaviyo_accounts`). So even native/Postgres tenants (whose `signal_*` tables ARE populated) have no materialized recommendations. Distinct from F1: F1 = BQ path throws; F2 = nothing triggers the recompute at all. |
| **F3** | ✅ verified-OK | `app/recommendations/nbp.py:563` escalation query | `entry_cluster, next_cluster, customer_count, transition_rate, strong_signal` all exist on `ref_escalation_patterns`. |
| **F4** | ✅ verified-OK | `app/signals/decisioning_warehouse.py:185` | `ref_product_cluster` query succeeded in prod (431,920 rows materialized). |
| **F5** | ❓ candidate | `app/recommendations/builder.py:451`, `app/ai/service.py:681` | Both consume `ref_replenishment_timing`. Verify their column refs vs live schema (`product_id, p50_days, cluster_name, category_fallback_p50, …`) **and** whether this output surfaces in v1.2 read-only scope or is dormant. |
| **F6** | ❓ candidate | `app/dashboard/kpis.py:298` | A BQ KPI query (`client.query(sql)`). If schema-drifted it fails → empty/again-stale dashboard KPIs with no alarm. Verify cols + failure mode. |
| **F7** | ❓ candidate | `app/refmodel/client.py:303` | Refmodel build queries — lower priority (builds the ref tables; not a serving path), but a drift here silently produces a malformed model. |
| **F8** | ⚠️ gap | CI / close-out gate | No BQ-schema contract test (mocks only — see SWE-Internal §3a per-phase QA), and no post-deploy "serving table non-empty in prod" gate (§9.6). This is why F1+F2 reached prod unseen. |

## Your turn (Codex) — verify + extend
1. **Re-confirm F1–F4** against live schema (don't trust my paste; re-pull `INFORMATION_SCHEMA`).
2. **Resolve F5–F7** to CONFIRMED / OK with evidence (column-by-column vs live schema; for F5 also
   state whether the output is in v1.2 scope or dormant — a dormant broken path is lower severity).
3. **Find anything I missed** — sweep every `bq_client.query_rows` / `client.query(` site and every
   `DELETE FROM … ` + reinsert recompute populator; check each writing table's prod row count.
4. **Rank by severity**, flag anything on the Binoid measurement critical path, and say where the
   BQ-schema contract test should live so refmodel drift fails CI, not prod.
5. **Report only — do not fix anything.** Append your block to the relay file; set STATUS.
