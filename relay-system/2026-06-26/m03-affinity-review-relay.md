# RELAY · Codex review — M0 CWM affinity-query fix (LTVera v1.2)

NEXT: codex
STATUS: Changes requested
ROUND: 1 / 1

## ▶ TAKE YOUR TURN — read this first
You are **codex**, the Reviewer. Adversarially review an investor-facing scoring fix before merge.
Read-only — do **not** edit the LTVera repo; append your findings block to THIS file.

1. **Read the Producer brief** (self-contained: context, the diff, the 5 things to verify):
   `/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-06-26/m03-affinity-review-brief.md`
2. **The code** is in the sibling clone `/Users/noelsaw/Documents/GH Repos/LTVera-Pandas` (branch
   `fix/m0-cwm-affinity-query`): `app/recommendations/nbp.py` (the fix) and
   `app/signals/decisioning_warehouse.py` (the cluster-mapping precedent). Read-only **prod** access
   via that repo's `OPERATIONS.md` — **SELECT / INFORMATION_SCHEMA only**. Prioritise verifying #2
   (does `ref_product_cluster` have exactly one row per `product_id`? a fan-out would corrupt scores).
3. **Append ONE block** at the bottom, above the marker: grade each of the brief's 5 items
   `[Blocker]`/`[Should]`/`[Nit]`/`[OK]` with evidence, then a **Verdict** (safe to merge to
   `development`?) and a **Basis** line (behaviorally proven vs textual).
4. **Set the header:** `STATUS: Approved` if safe to merge (nits OK), else `STATUS: Changes requested`.
5. **Hand off the lock**, then stop:
   `TICK_REPO_ROOT="/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm" "/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick" done RELAY-m03-affinity-1 --agent codex`
6. **Stop.** One-line result to the operator.

## Setup
- Artifact: the M0 fix (`af1e9cb`) on branch `fix/m0-cwm-affinity-query`.
- DoD: codex grades the 5 checks + Verdict + sets STATUS.
- Reviewer: **codex**. Producer: operator's Claude session.
- Lock: `tick` task **RELAY-m03-affinity-1**.
- Started: 2026-06-26

## Ground rules
1. Single source of truth; append one block at the bottom, never edit earlier turns.
2. Read-only on prod + the LTVera repo — findings only, no fixes.
3. Tight: cite real `file:line` and table/column names.
4. Evidence contract: `Basis:` — behaviorally proven (re-queried live) vs textual only.

---
## Log

### Codex review — 2026-06-26
1. `[OK]` CWM correctness: `app/recommendations/nbp.py:569-573` is the right weighted-mean shape, and `co_order_count` is the only support column available on `ref_basket_affinity`. In the refmodel build it is `COUNT(DISTINCT a.order_id)` (`pipelines/reference_model/build_reference_model.sql:233-241`), so this is support-weighted by co-order volume, which is structurally consistent with the escalation rollup's support-weighting at `app/recommendations/nbp.py:585-595`. The only caveat is naming: this is not literally customer-weighted.
2. `[OK]` Join fan-out / double-count: live BigQuery check on `ltvera-gce-and-bigquery.binoid_refmodel.ref_product_cluster` returned `rows_total=1943`, `distinct_products=1943`, `duplicate_rows=0`, and `HAVING COUNT(*) > 1` returned no rows. The table build also starts from one `products` row per `product_id` and emits one row/product (`pipelines/reference_model/build_reference_model.sql:73-77`, `:79-129`). Current live data does not fan out either join in `app/recommendations/nbp.py:575-576`.
3. `[OK]` `signal_eligible` filter on candidates: the fix's `product_clusters` CTE (`app/recommendations/nbp.py:561-565`) matches the decisioning backbone predicate in `app/signals/decisioning_warehouse.py:71-77`. Live join audit on `ref_basket_affinity` found `anchor_ineligible=0`, `comp_ineligible=0`; the only dropped rows were 4 anchors with `cluster_name IS NULL`, so filtering both anchor and companion does not currently discard valid eligible candidate clusters.
4. `[Should]` Edge cases: the live data proves the implementation is not the stated CWM in one real edge. `pdf_seed` rows are materialized with `final_score = NULL` at `pipelines/reference_model/build_reference_model.sql:307-320`, and one surviving cross-cluster row (`anchor_product_id=1540936`, `companion_product_id=806591`, source `pdf_seed`) has `co_order_count=111` with `final_score IS NULL`. In `app/recommendations/nbp.py:570-573`, BigQuery skips that row in `SUM(final_score * co_order_count)` but still includes its `co_order_count` in the denominator, so `Gummies & Ingestibles -> Vapes & Disposables` comes out `0.3445627980` instead of the true non-null weighted value `0.3539094428`. Blast radius is limited today: 4 cross-cluster `pdf_seed` rows have `final_score IS NULL`, but only 1 carries positive weight; the ranking order inside the `Gummies & Ingestibles` anchor cluster does not flip.
5. `[Nit]` DRY: the `product_clusters` CTE in `app/recommendations/nbp.py:561-565` duplicates the same mapping predicate used in `app/signals/decisioning_warehouse.py:71-77`, but the surrounding queries are different enough that I would not block this fix on extracting a helper. The maintenance risk is predicate drift, not immediate correctness.

Verdict: Changes requested. Not safe to merge to `development` yet; the runtime failure is fixed, but one live investor-facing affinity edge is still numerically wrong because null-score weight leaks into the denominator.

Basis: behaviorally proven for live BigQuery cardinality, schema, null/weight counts, and the affected cluster-edge score; textual for the code-path comparison and DRY assessment.
