# Plan draft: #1189 Kimi K3.1 limited code review initial impressions

> draft; preflight and independent plan QA outstanding

- Request: `gh-1189-7e97a7338874` (tick `slot_073`)
- Draft status: **needs-recon** (held: no sourced write set)
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: 7e97a733887482f2e68ea219ad36d941a94b9903e5b2ce4c3f8e3fa6a70ed4d4 (updated 2026-10-24T16:57:17Z)
- Dependencies: none

## Scope

_Source: issue#1189:L35 (3. `[P1]` Catalog age-cutoff partition between `rank_new_arrivals` and `rank_best_sellers` (`app/campaigns/recipe_rankings.py:345`) — **Logically Sound, Pushed Back on Architectural / Scope Grounds**)_

- **What Kimi caught:** In `app/campaigns/recipe_rankings.py::_new_product_aggregate_query`, `basis == "arrival"` was updated to date arrivals via `launch_at = func.coalesce(Product.published_at, Product.shopify_created_at)` with a 14-day window (`NEW_ARRIVALS_WINDOW_DAYS = 14`), whereas `app/campaigns/ranking.py::_sellable_product` ages Best Sellers candidates by `Product.shopify_created_at <= cutoff` (`MIN_PRODUCT_AGE_DAYS = 14`). Kimi constructed a valid counterexample: a Shopify product drafted 60 days ago (`shopify_created_at`), published 2 days ago (`published_at`), and sold yesterday satisfies both `launch_at > cutoff` (admitted to New Arrivals) and `shopify_created_at <= cutoff` (admitted to Best Sellers), violating a strict zero-overlap partition. Kimi also noticed that modifying `app/campaigns/ranking.py` requires bumping `BEST_SELLERS_MODEL_VERSION` due to `tests/test_gh631_ranking_version_guard.py`.
- **Why we pushed back:**
  1. The issue specification (`#820`) explicitly constrained the v1 diff to 4 surgical deliverables (`recipe_rankings.py`, `config.py`, `service.py` + `campaigns.py` route, and Dispatch UI/state) and forbade touching other modules.
  2. The warehouse Best Sellers fallback (`app/campaigns/bq_ranking.py::_candidates_sql`) ages products by `p.created_at` (`COALESCE(pp.created_at, p.created_at)` on Woo) and the BigQuery `products` table has no `published_at` column — changing `app/campaigns/ranking.py` alone would break Postgres ↔ BigQuery Best Se

_Source: codex-authored (codex-authored)_

Review the reported Kimi K3.1 code review findings and their implications for the evaluation.

## Acceptance criteria

_missing_

## Open questions

_Source: codex-authored (codex-authored)_

What outcome is requested for these initial impressions, and what additional context appears beyond the truncated issue body?

_Source: codex-authored (codex-authored)_

What evidence supports the reported findings and comparative assessment?

## Write set

_none sourced_

## Unresolved file names

- none

## Contract probes

- none
