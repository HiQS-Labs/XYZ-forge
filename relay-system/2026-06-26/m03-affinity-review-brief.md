# Producer brief — review the M0 CWM affinity-query fix (LTVera v1.2)

**Producer:** Claude (Noel). **Reviewer:** Codex. Adversarial review of an **investor-facing
scoring** change before merge. Read-only; report findings, don't edit the LTVera repo.

Repo: `/Users/noelsaw/Documents/GH Repos/LTVera-Pandas` (currently on branch
`fix/m0-cwm-affinity-query`, commit `af1e9cb`). Prod read access via that repo's `OPERATIONS.md`
(BQ via the warehouse client; SELECT/INFORMATION_SCHEMA only).

## Context
`load_family_affinity_bq` ([app/recommendations/nbp.py:548](app/recommendations/nbp.py)) queried
`ref_basket_affinity` for `anchor_cluster`/`comp_cluster`, which don't exist — the table is
product-grain — so the query threw at runtime and `customer_nbp` was empty in prod (root cause:
SWE-Internal §9.7). Sam's L1 call (M0.2, 2026-06-26): roll product pairs up to the cluster edge
with a **customer-weighted mean (CWM)** of `final_score`, not MAX.

## The fix (commit af1e9cb)
```sql
WITH product_clusters AS (
    SELECT product_id, cluster_name
    FROM `…binoid_refmodel.ref_product_cluster`
    WHERE cluster_name IS NOT NULL AND signal_eligible
)
SELECT
    ac.cluster_name AS anchor_cluster,
    cc.cluster_name AS comp_cluster,
    SUM(ba.co_order_count) AS co_order_count,
    SAFE_DIVIDE(SUM(ba.final_score * ba.co_order_count), SUM(ba.co_order_count)) AS affinity_score
FROM `…ref_basket_affinity` AS ba
JOIN product_clusters AS ac ON ac.product_id = ba.anchor_product_id
JOIN product_clusters AS cc ON cc.product_id = ba.companion_product_id
WHERE ac.cluster_name != cc.cluster_name
GROUP BY ac.cluster_name, cc.cluster_name
```
Downstream code unchanged — it still reads `row["anchor_cluster"|"comp_cluster"|"co_order_count"|"affinity_score"]`.

**Producer's own checks:** replayed against prod `binoid_refmodel` → 23 cluster-pair rows across
all 6 clusters (old query errored). `test_load_family_affinity_bq_shapes_candidates_from_refmodel`
+ the schema-contract test pass.

## Verify these (be adversarial)
1. **CWM correctness** — is `SAFE_DIVIDE(SUM(final_score*co_order_count), SUM(co_order_count))` a
   correct customer-weighted mean? Is `co_order_count` the right weight (vs. e.g. customer_count)?
   Compare to the escalation path's weighting at `nbp.py:563-574` — consistent?
2. **Join fan-out / double-count (highest-risk)** — does `ref_product_cluster` have **exactly one
   row per `product_id`**? If a product maps to >1 cluster, the two joins fan out and distort both
   the weighted numerator and `SUM(co_order_count)`. Check the live table (is there a unique key on
   product_id?). This is the one that would silently corrupt the scores.
3. **`signal_eligible` filter on candidates** — mirrors the decisioning backbone
   (`decisioning_warehouse._build_sql`, which filters `cluster_name IS NOT NULL AND signal_eligible`).
   Correct to apply on BOTH anchor and companion, or does it wrongly drop valid candidate clusters?
4. **Edge cases** — `affinity_score` NULL when `SUM(co_order_count)=0` (SAFE_DIVIDE) → downstream
   `float(... or 0.0)`; the `ac.cluster_name != cc.cluster_name` cross-cluster filter; any rows
   where `final_score` is NULL.
5. **DRY** — the `product_clusters` CTE duplicates the decisioning path's cluster mapping. Worth a
   shared helper, or acceptable given they're different queries/modules?

## Your task
Grade each (1–5): `[Blocker]` wrong/corrupts scores · `[Should]` fix before merge · `[Nit]` ·
`[OK]`. Verify #2 against live schema if you can. Verdict: **safe to merge to development?**
Basis line (behaviorally proven vs textual). Report only — append to the relay file, set STATUS.
