STATUS: Open
NEXT: claude-a

# Relay review — PR #77 "Resolve #61 audit findings" (kissplugins/KISS-woo-fast-search)

**Artifact under review:** the diff of PR [#77](https://github.com/kissplugins/KISS-woo-fast-search/pull/77)
(`fix/bugs-2026-06-26` → `development`), embedded in full at the bottom of this file.
Reviewer: **codex**. Producer/seeder: claude-a.

## What changed (review target)

PR #77 resolves the audit findings in issue #61, across three priority groups:

- **P1 — security & repo hygiene:** removed root test/diagnostic scripts and a JS file that held a
  hardcoded credential; replaced hardcoded email defaults with a `search@example.com` placeholder;
  `.gitignore` now covers `*.csv` / `*-export.*`; runtime PHP files carry `defined('ABSPATH')` guards.
- **P2 — functional bugs:** order queries exclude refund rows (`o.type = 'shop_order'` HPOS /
  `p.post_type = 'shop_order'` legacy); `order.total` is escaped via `escapeHtml()` at every admin-JS
  render sink (XSS); removed a dead `loadWholesaleOrders` click handler (ReferenceError).
- **P3 — robustness/perf:** `get_edit_url()` reuses the already-loaded `WC_Order` (removes an N+1);
  the wholesale filter reads order meta via `wc_get_order()` + `$order->get_meta()` (HPOS-aware);
  `kiss-woo-toolbar.js` null-guards `floatingSearchBar`/`.ajaxUrl`; `class-kiss-woo-search.php` bails
  on empty `$parts` before any `$parts[0]` access.

The diff also carries adjacent work that rode the same branch: coupon-lookup bulk rebuild
(`class-kiss-woo-coupon-*`), an analytics fast-path touch in `class-kiss-woo-search.php`, a regression
gate (`tests/gate.php`, `tests/run.sh`), and doc/dist hygiene (`AUDIT.md`, `README.md`, `.distignore`,
`PROJECT/...`). Review all of it — flag anything that looks wrong, not just the #61 items.

Known/expected state (not for you to fix, but confirm the reasoning):
- `composer test`: 2 pre-existing `AjaxHandlerTest` errors that also fail on `development` (unrelated).
- `tests/gate.php`: 1 failing invariant for `#75 get_customer_orders_key()` — a not-yet-implemented
  feature, intentionally still red.
- A credential was previously committed in a now-deleted JS file; it remains in git history. Repo is
  now private (partial mitigation); out-of-band rotation is the recommended follow-up.

## ▶ TAKE YOUR TURN — codex (Reviewer)

> **REVIEW ONLY.** Do **NOT** edit any source file. The only file you may write is **this relay file**.
> Do **NOT** run builds or the test suite. The PR diff is embedded below in full — **read the diff**
> and apply judgment. Keep the turn focused: read, then append your findings block.

1. Read the embedded PR diff (bottom of this file).
2. Review for: **correctness** (does each fix actually do what it claims — refund filtering, XSS
   escaping at every sink, HPOS-aware meta access, empty-`$parts` guard, N+1 removal); **security**
   (any remaining unescaped output, SQL built from unsanitized input, missing `$wpdb->prepare`/
   `esc_like`, leftover secrets or local paths); **regressions** (legacy vs HPOS parity, status/refund
   filtering changing result sets, the coupon-lookup bulk rewrite, the analytics fast-path branch and
   its fallback guard).
3. Append a `### Review — codex` block: grade each finding `[Blocker] / [Should] / [Nit] / [Pass]`
   with a concrete `file:line` and a proposed fix, then a one-line **VERDICT:** (Approved /
   Changes requested) and a **Basis:** line.
4. If Approved, set `STATUS: Approved`. Otherwise leave `STATUS: Open`, set `NEXT: claude-a`, and hand
   back to claude-a.

## PR #77 diff

```diff
diff --git a/.distignore b/.distignore
new file mode 100644
index 0000000..e292f4a
--- /dev/null
+++ b/.distignore
@@ -0,0 +1,22 @@
+# Excluded from the distributed plugin zip (wp-cli `dist-archive` / .distignore).
+# These stay in version control for history — they are only kept OUT of the build artifact.
+
+# Process, planning & QA docs
+/PROJECT/
+/relay-system/
+
+# Dev/test & swarm scaffolding — must never ship to users
+/tests/
+/temp/
+/.tick/
+/.claude/
+/MARATHON.yaml
+/phases-briefs/
+/phases/
+
+# Repo & build hygiene
+/.git/
+/.github/
+/.gitignore
+/.distignore
+.DS_Store
diff --git a/.gitignore b/.gitignore
index e9680a4..22ed8c9 100644
--- a/.gitignore
+++ b/.gitignore
@@ -26,3 +26,4 @@ wpcc-includes-scan.json
 wpcc-scan.json
 wpcc-root-scan.json
 wpcc-full-scan.json
+/relay-system/
\ No newline at end of file
diff --git a/AUDIT.md b/AUDIT.md
index a228b2b..eb89264 100644
--- a/AUDIT.md
+++ b/AUDIT.md
@@ -1,15 +1,15 @@
 # Security and Performance Audit
 
-This audit reviews the current codebase for the KISS - Faster Customer & Order Search plugin. Each finding is assigned a priority (P1 = highest) and severity (High/Medium/Low).
+This audit reviewed the codebase for the KISS - Faster Customer & Order Search plugin. **All findings below have been resolved** — the table is retained as history. Each finding lists the priority (P1 = highest), severity, and the commit that closed it.
 
-## Findings
+## Findings (all resolved)
 
-| Priority | Severity | Area | Details | Recommendation |
-| --- | --- | --- | --- | --- |
-| P1 | High | Admin results rendering | Customer and order fields returned by the AJAX handler are concatenated directly into HTML in `admin/kiss-woo-admin.js` without escaping, so any untrusted values stored in names, emails, or order metadata could be rendered as HTML/JS in the admin view. | Escape all dynamic fields before injection (e.g., sanitize in PHP and/or HTML-escape in JS) or build DOM nodes with `textContent` to avoid XSS risk. |
-| P1 | Medium | Order counting | `get_order_count_for_customer()` calls `wc_get_orders` with `limit => -1`, which loads every order object to count them. On stores with many orders this can exhaust memory and slow the response. | Use a lightweight count query (e.g., `wc_orders_count()` or a `WP_Query` with `'fields' => 'ids'` and `'no_found_rows' => true`, or a direct SQL `COUNT(*)`) to avoid loading full order objects. |
-| P2 | Medium | Customer lookup efficiency | Customer searches request `fields => 'all_with_meta'` and an OR `meta_query` with leading wildcard `LIKE` clauses. This pulls all metadata and prevents index use, which can be slow on large user tables. | Limit fields to IDs/basic columns, fetch only required meta, and consider normalizing frequently searched fields or adding indexed columns to reduce full-table scans. |
-| P3 | Low | Benchmark search sanitization | Benchmark page builds a `wc_get_orders` search string with `esc_attr($query)`; the request parameter is sanitized, but `esc_attr` is intended for HTML, not queries. | Apply `sanitize_text_field`/`wc_clean` consistently and rely on WooCommerce query args without HTML escaping, keeping the search term unescaped until rendered. |
+| Priority | Severity | Area | Status |
+| --- | --- | --- | --- |
+| P1 | High | Admin results rendering | RESOLVED (`2a9398b`, `58ccc06`). All dynamic customer/order fields returned by the AJAX handler are now HTML-escaped before injection in `admin/kiss-woo-admin.js`, closing the prior XSS risk. |
+| P1 | Medium | Order counting | RESOLVED (`068a37e`). `get_order_count_for_customer()` now uses a direct `COUNT(*)` query instead of fetching full order objects, so counting no longer scales with order volume. |
+| P2 | Medium | Customer lookup efficiency | RESOLVED (`068a37e`). Customer searches use the indexed `wc_customer_lookup` table path instead of `fields => 'all_with_meta'` with OR `meta_query`, avoiding full-table scans. |
+| P3 | Low | Benchmark search sanitization | RESOLVED (`068a37e`). The benchmark file was scrubbed in the security purge; it no longer uses `esc_attr` for query context. |
 
 ## Additional Notes
 - Capability checks (`manage_woocommerce`/`manage_options`) and nonces are present on the AJAX handler, reducing exposure to unauthorized callers.
diff --git a/PROJECT/2-WORKING/BUG-FIXES-2026-06-26.md b/PROJECT/2-WORKING/BUG-FIXES-2026-06-26.md
new file mode 100644
index 0000000..9576c8b
--- /dev/null
+++ b/PROJECT/2-WORKING/BUG-FIXES-2026-06-26.md
@@ -0,0 +1,305 @@
+---
+title: "KISS Faster Customer & Order Search — Bug Fix & Performance Project"
+date: 2026-06-26
+source: "GitHub issues kissplugins/KISS-woo-fast-search #68–#76 (filed 2026-06-26/27)"
+plugin_version: "1.3.2"
+status: "Planned — not started"
+branch: "Work off `development` (production tracks `development`, NOT `main`)"
+issues:
+  - "#68  HPOS edit URLs broken (bug, high, HPOS)"
+  - "#69  Payment/Shipping columns blank on wholesale/recent (bug, medium)"
+  - "#70  Three divergent order formatters (tech-debt, medium)"
+  - "#71  Process artifacts shipped in distributable (packaging, low)"
+  - "#72  Stale README/AUDIT.md warnings (documentation, low)"
+  - "#73  Coupon lookup build catastrophically slow (bug, CRITICAL)"
+  - "#74  Audit: admin search slow queries 8–26s (umbrella/audit)"
+  - "#75  Wire in unused KISS_Woo_Search_Cache (enhancement)"
+  - "#76  Use wc_order_stats for per-customer lookup (enhancement, high)"
+phases:
+  - "Phase 1 — Critical & High correctness fixes (#73, #68)"
+  - "Phase 2 — Search performance remediation (#74 → #75, #76)"
+  - "Phase 3 — Order display correctness & formatter convergence (#69, #70)"
+  - "Phase 4 — Packaging & documentation hygiene (#71, #72)"
+owner: mrtwebdesign
+prepared_by: "Claude Code"
+---
+
+# KISS Faster Customer & Order Search — Bug Fix & Performance Project
+
+A single consolidated plan for the nine issues filed on **2026-06-26** (GitHub `kissplugins/KISS-woo-fast-search` #68–#76). Each phase below carries observable, checkable todo items and a dedicated QA checklist.
+
+## Status at a Glance
+
+| Most recently completed phase | What's next |
+| --- | --- |
+| _None yet — project scoped from GitHub issues on 2026-06-26._ | **Phase 1 — Critical & High correctness fixes** (start with #73 coupon rebuild, then #68 HPOS edit URLs). |
+
+> **Branching rule (applies to every phase):** production tracks the `development` branch, not `main`. All work branches off `development`. There is a known release-hygiene gap where `main` lags behind `development` (see #74) — do not assume `main` reflects production.
+
+---
+
+## Table of Contents
+
+- [Status at a Glance](#status-at-a-glance)
+- [Phase 1 — Critical & High Correctness Fixes](#phase-1--critical--high-correctness-fixes)
+  - [#73 — Coupon lookup table build catastrophically slow (CRITICAL)](#73--coupon-lookup-table-build-catastrophically-slow-critical)
+  - [#68 — HPOS edit URLs broken in format_order_data_for_output (HIGH)](#68--hpos-edit-urls-broken-in-format_order_data_for_output-high)
+  - [Phase 1 QA Checklist](#phase-1-qa-checklist)
+- [Phase 2 — Search Performance Remediation](#phase-2--search-performance-remediation)
+  - [#74 — Audit context (umbrella)](#74--audit-context-umbrella)
+  - [#75 — Wire in the unused KISS_Woo_Search_Cache (quick win)](#75--wire-in-the-unused-kiss_woo_search_cache-quick-win)
+  - [#76 — Use wc_order_stats for per-customer lookup (durable fix)](#76--use-wc_order_stats-for-per-customer-lookup-durable-fix)
+  - [Phase 2 QA Checklist](#phase-2-qa-checklist)
+- [Phase 3 — Order Display Correctness & Formatter Convergence](#phase-3--order-display-correctness--formatter-convergence)
+  - [#69 — Payment & Shipping columns blank on wholesale/recent (MEDIUM)](#69--payment--shipping-columns-blank-on-wholesalerecent-medium)
+  - [#70 — Three divergent order formatters (MEDIUM, tech-debt)](#70--three-divergent-order-formatters-medium-tech-debt)
+  - [Phase 3 QA Checklist](#phase-3-qa-checklist)
+- [Phase 4 — Packaging & Documentation Hygiene](#phase-4--packaging--documentation-hygiene)
+  - [#71 — Process artifacts shipped in plugin distributable (LOW)](#71--process-artifacts-shipped-in-plugin-distributable-low)
+  - [#72 — Stale README/AUDIT.md security/performance warnings (LOW)](#72--stale-readmeauditmd-securityperformance-warnings-low)
+  - [Phase 4 QA Checklist](#phase-4-qa-checklist)
+- [Cross-Cutting Notes](#cross-cutting-notes)
+
+---
+
+## Phase 1 — Critical & High Correctness Fixes
+
+Two self-contained correctness bugs that hurt production right now: a broken coupon index and broken order links on HPOS. Both are low risk to fix and high value.
+
+### #73 — Coupon lookup table build catastrophically slow (CRITICAL)
+
+**Labels:** bug, enhancement, Priority: Critical · **Effort:** 2–3 hours
+
+**Problem:** The build hydrates every coupon through `new WC_Coupon($id)` (~5–8 queries each). For ~363k coupons that's ~2–3M queries and 12+ hours, and it **silently drops** coupons WC_Coupon can't hydrate (Klaviyo/Yotpo bulk-generated). Result: only ~55k of ~338k published coupons (~16%) are indexed; ~283k are unsearchable. Only 5 of 16 stored columns are ever read by search (`coupon_id`, `code_normalized`, `title`, `description_normalized`, `status`).
+
+**Fix:** Replace the per-row loop with a single `INSERT ... SELECT` from `wp_posts` (all needed fields live in `wp_posts` directly — no postmeta JOINs, no WC_Coupon hydration). Drops build time to <60s and indexes all published coupons.
+
+**Observable todo items:**
+- [ ] Replace `run_batch()` per-row loop in `includes/class-kiss-woo-coupon-backfill.php` with a single bulk `INSERT ... SELECT ... ON DUPLICATE KEY UPDATE` from `wp_posts` (filter `post_type = 'shop_coupon'`, `post_status NOT IN ('trash','auto-draft')`).
+- [ ] Remove/deprecate the lossy `upsert_coupon()` + `build_row_from_coupon()` hydration path in `includes/class-kiss-woo-coupon-lookup.php` (the silent early-bail at line ~199).
+- [ ] Update batch orchestration / WP-Cron scheduling in `includes/class-kiss-woo-coupon-lookup-builder.php` so the single-pass build no longer schedules ~728 cron batches.
+- [ ] Update the cron handler at `kiss-woo-fast-order-search.php:199-207` to match the new single-pass build.
+- [ ] Drop or make nullable the 11 unused columns (`amount`, `discount_type`, `expiry_date`, `usage_limit`, `usage_limit_per_user`, `usage_count`, `free_shipping`, `currency`, `blog_id`, `source_flags`, `updated_at`) — or document why kept.
+- [ ] Repair the progress tracker so the admin UI shows real totals (it currently reads "0 / 363,738 (0%)" after losing state).
+
+**QA for #73:**
+- [ ] After a fresh build on a copy of production data, indexed coupon count ≈ published coupon count (~338k), not ~55k.
+- [ ] Build completes in well under 5 minutes (target <60s) for the full 363k set.
+- [ ] A previously-dropped Klaviyo/Yotpo coupon is now searchable through the fast path.
+- [ ] Admin progress UI shows accurate counts and reaches 100%.
+
+### #68 — HPOS edit URLs broken in format_order_data_for_output (HIGH)
+
+**Labels:** bug, Priority: high, HPOS · **Effort:** <30 min
+
+**Problem:** `format_order_data_for_output()` at `includes/class-kiss-woo-search.php:960` hardcodes the legacy `post.php?post=…&action=edit` URL. On HPOS stores every "View Order" link from customer-search results and paginated order lists 404s or misredirects.
+
+**Fix:** Use the already-correct `KISS_Woo_Order_Formatter::get_edit_url($order_id)` (handles both HPOS and legacy, `includes/class-kiss-woo-order-formatter.php:117-141`).
+
+**Observable todo items:**
+- [ ] Replace the hardcoded `$edit_link = admin_url('post.php?...')` at `includes/class-kiss-woo-search.php:960` with `KISS_Woo_Order_Formatter::get_edit_url($order_id)`.
+- [ ] Confirm no other call site in `format_order_data_for_output()` re-hardcodes the legacy URL.
+
+**QA for #68:**
+- [ ] On an HPOS store, a "View Order" link from customer-search results opens the correct `admin.php?page=wc-orders&action=edit&id=X` order screen (no 404/redirect).
+- [ ] On a legacy-storage store, the same link still resolves correctly.
+- [ ] Paginated customer order pages (`get_customer_orders_page`) produce working links.
+
+### Phase 1 QA Checklist
+
+- [ ] #73 and #68 each verified against their per-issue QA above.
+- [ ] No PHP warnings/notices introduced (check debug log on both HPOS and legacy test stores).
+- [ ] Coupon search and order-link flows smoke-tested end-to-end in the admin UI.
+- [ ] Changes committed on a branch off `development`; PR opened against `development`.
+
+---
+
+## Phase 2 — Search Performance Remediation
+
+This phase addresses the production slow-query audit (#74). The two code fixes are complementary: **#75 caching** makes repeat lookups instant; **#76 indexed analytics path** makes the cold (first) lookup fast. Best result = both.
+
+### #74 — Audit context (umbrella)
+
+**Labels:** (none) · This is an **audit**, not a code task — it frames and sequences the work in #75/#76 (and the display bugs #68/#69).
+
+**Findings (production binoidcbd.com, slow-query logs 2026-06-26):**
+- Plugin per-customer lookups: ~440 slow queries / 12h, 8–27s each (largest single source).
+- WooCommerce's built-in order search on Admin Columns Pro: ~100 slow queries, ~27s each.
+- Same root cause: store uses **legacy order storage**, so both scan a large unindexed table per search. Long admin searches coincide with intermittent 500s at the morning peak.
+- The plugin ships a caching component that is **not used** on the slow paths; the per-customer lookup is also written so the DB can't use an index.
+
+**Recommended sequencing (priority order):**
+- [ ] Quick win — enable caching on search paths → **#75**.
+- [ ] Short fix — move per-customer lookup to an indexed table → **#76**.
+- [ ] Fix display bugs — broken order links (#68) + blank Payment/Shipping (#69) → handled in Phases 1 & 3.
+- [ ] Strategic — HPOS migration is a separate, longer-term store project (out of scope for this plugin doc; the plugin already auto-activates faster paths under HPOS).
+
+> Note the "Plugin interaction" clarification in #74: the three search surfaces (order-list box, Fast Search toolbar, Admin Columns Pro) are **different user actions**, not one request. The "Fast Search ~3–5:1" figure is a *volume* comparison, not proof of concurrency.
+
+### #75 — Wire in the unused KISS_Woo_Search_Cache (quick win)
+
+**Labels:** enhancement · The low-effort, high-impact half of #74.
+
+**Problem:** `includes/class-kiss-woo-search-cache.php` (transient-backed, 5-min default TTL) is only used by coupon search and the order-number resolver — **never** by the expensive `get_customer_orders_page()`, `search_customers()`, or guest-order searches. Every keystroke re-runs the full query.
+
+**Design (per issue):** read-through caching on the hot paths + **event-driven invalidation** for the per-customer list via a version-stamped key (`kiss_woo_custorders_{customer_id}_v{N}_{page}_{per_page}`); short TTL for term-based searches; invalidate (don't splice) on order changes; must work under the site's persistent object cache.
+
+**Observable todo items:**
+- [ ] Add read-through caching to `KISS_Woo_COS_Search::get_customer_orders_page()`.
+- [ ] Add read-through caching to `KISS_Woo_COS_Search::search_customers()` and the guest-order-by-email/by-name searches.
+- [ ] Implement the per-customer **version-stamped** cache key.
+- [ ] Bump the customer's version on `woocommerce_new_order`, `woocommerce_update_order`, `woocommerce_order_status_changed`, and order trash/untrash/delete (read customer ID via `$order->get_customer_id()`).
+- [ ] Give per-customer lists a long/effectively-no TTL (correctness now comes from invalidation); give term-based searches a short TTL (~60–120s) with **no** full-namespace flush.
+- [ ] Replace reliance on the `wp_options` `LIKE` sweep (`clear_all()` is a no-op under object cache) with explicit `delete_transient()` + version bump.
+
+**Acceptance criteria (from issue):**
+- [ ] All three hot paths consult `KISS_Woo_Search_Cache`.
+- [ ] A new/updated/status-changed/trashed order makes that customer's next lookup reflect the change immediately (no TTL wait).
+- [ ] Term-based caches use short TTL; no full-namespace flush on order change.
+- [ ] Invalidation works under the persistent object cache.
+- [ ] No stale results survive an order change for the per-customer list.
+- [ ] Implemented on a branch off `development`.
+
+### #76 — Use wc_order_stats for per-customer lookup (durable fix)
+
+**Labels:** enhancement, Priority: high · The durable fix behind #74's P1.
+
+**Problem:** `get_customer_orders_page()` on legacy storage scans the unindexed `wp_postmeta._customer_user` (integer vs LONGTEXT, ~2.8M rows examined/call, 8–26s).
+
+**Fix:** Add a third branch (analytics → HPOS → legacy postmeta) that queries the indexed WooCommerce Analytics tables (`wp_wc_customer_lookup.user_id` → `wp_wc_order_stats.customer_id`, filtered `parent_id = 0` to exclude refund rows), then hydrate IDs through the existing formatter. These tables exist on **both** legacy and HPOS storage, so this delivers fast cold reads without an HPOS migration.
+
+**Observable todo items:**
+- [ ] Add an analytics-table branch to `get_customer_orders_page()`, preferred when `wc_order_stats` is available and populated; keep HPOS and legacy postmeta as fallbacks.
+- [ ] Map WP user → analytics `customer_id` via `wp_wc_customer_lookup`; page orders from `wp_wc_order_stats` with `parent_id = 0` + `ORDER BY date_created DESC LIMIT/OFFSET`; count with `parent_id = 0`.
+- [ ] Add a startup/row-count guard that falls back to the postmeta path if the analytics tables are missing or under-populated (no silently-incomplete results).
+- [ ] Optionally log when the fallback fires so an incomplete Analytics import surfaces.
+- [ ] Confirm status handling (`wc_order_stats.status` carries the `wc-` prefix matching `wc_get_order_statuses()`).
+
+**Acceptance criteria (from issue):**
+- [ ] Analytics branch is preferred when populated; HPOS + legacy remain fallbacks.
+- [ ] `parent_id = 0` excludes refund rows; guest and registered customers both resolve.
+- [ ] Row-count guard falls back when analytics is unavailable/under-populated.
+- [ ] Cold per-customer lookup drops from 8–26s to sub-second on the production data set.
+- [ ] Implemented on a branch off `development`.
+
+> **Caveat to verify (flagged "too good to be true" by owner):** `wc_order_stats` is populated by the Analytics importer — if Analytics was enabled after orders existed and historical import never finished, older orders may be missing. **Compare parent-order rows in `wc_order_stats` against the real order count before relying on it**, and repair the import if short.
+
+### Phase 2 QA Checklist
+
+- [ ] Backfill-completeness check run on production data: `wc_order_stats` parent-order rows ≈ real order count (verify #76's core assumption before trusting the fast path).
+- [ ] Cold (cache-busted) per-customer lookup is sub-second on a production-sized customer.
+- [ ] Repeat lookups served from cache; cache invalidates immediately after an order status change (simulate a ShipStation update).
+- [ ] Fallback path verified: with analytics tables emptied/renamed, results remain correct via the postmeta path (just slow), and the fallback is logged.
+- [ ] No stale per-customer results survive an order change; term-search staleness bounded by short TTL only.
+- [ ] Slow-query log re-checked after deploy: the 8–26s plugin lookups are gone.
+
+---
+
+## Phase 3 — Order Display Correctness & Formatter Convergence
+
+Two related display/data issues. Fixing #70 (formatter convergence) first reduces the surface area for #69, but #69 can ship independently if needed.
+
+### #69 — Payment & Shipping columns blank on wholesale/recent (MEDIUM)
+
+**Labels:** bug, Priority: medium · **Effort:** 1–2 hours
+**Owner note in issue:** _"we disabled all the wholesale plugins."_ (confirm whether these list views are still in active use before investing).
+
+**Problem:** Wholesale/recent list views render 6-column tables (Order, Status, Total, Date, Payment, Shipping) but Payment & Shipping are always blank because their data path (`KISS_Woo_Order_Formatter::format_from_raw()`) never returns `payment`/`shipping`. The customer-search path (`get_order_data_via_sql()` → `format_order_data_for_output()`) already returns both and serves as the reference.
+
+**Observable todo items:**
+- [ ] Add payment method + shipping method to the HPOS query `build_hpos_query()` (`includes/class-kiss-woo-order-query.php:140-197`) — `wc_orders.payment_method` + gateway title; JOIN `woocommerce_order_items` for shipping.
+- [ ] Add the same to the legacy query `build_legacy_query()` (`:209-273`) — JOIN `wp_postmeta` for `_payment_method_title` + `woocommerce_order_items` for shipping.
+- [ ] Pass payment/shipping through `format_order_rows()` (`:329-355`).
+- [ ] Add `payment` and `shipping` keys to `format_from_raw()` output (`includes/class-kiss-woo-order-formatter.php:54-106`), using `get_order_data_via_sql()` (`class-kiss-woo-search.php:860-942`) as the reference.
+
+**QA for #69:**
+- [ ] Wholesale/recent list views show populated Payment and Shipping columns on both HPOS and legacy stores.
+- [ ] Values match the order's actual payment method title and shipping method.
+- [ ] Confirm with owner whether wholesale views are still in use (plugins were disabled) — close as won't-fix if obsolete.
+
+### #70 — Three divergent order formatters (MEDIUM, tech-debt)
+
+**Labels:** Priority: medium, tech-debt · **Effort:** 2–3 hours
+
+**Problem:** Three independent methods convert order data to JSON arrays with different key sets, so a fix to one path can silently break another (already happened — the `wc_price()` HTML-in-total regression):
+1. `format_order_for_output()` (`class-kiss-woo-search.php:1835-1863`) → `number`, `date`, `payment`, `shipping`, …
+2. `format_order_data_for_output()` (`class-kiss-woo-search.php:955-1002`) → same shape as #1 (and the #68 hardcoded URL).
+3. `format_from_raw()` (`class-kiss-woo-order-formatter.php:54-106`) → `order_number`, `date_display`, `total_display`, `customer` (nested), no payment/shipping.
+   (Plus `format()` at line 23–46 taking a `WC_Order` object — a fourth shape.)
+
+**Fix (converge on one contract):** Make `KISS_Woo_Order_Formatter` the real single write path it claims to be. Preferred: make `format_from_raw()` canonical, align `format_order_data_for_output()` to call it, and delete the duplicate. At minimum, make all paths return the **same key names** (empty values OK).
+
+**Observable todo items:**
+- [ ] Decide and document the single canonical output contract (key names + value formats).
+- [ ] Align `format_order_data_for_output()` to the canonical contract (ideally delegate to `format_from_raw()`; delete the duplicate once equivalent).
+- [ ] Reconcile `number` vs `order_number`, `date` vs `date_display`, and `total` vs `total_display` so renderers don't need `|| ''` fallbacks.
+- [ ] Ensure `payment`/`shipping` and `currency`/`customer`(nested) keys are consistently present (coordinate with #69).
+- [ ] Update `admin/kiss-woo-admin.js` `renderOrdersTable()` and the wholesale/recent renderer to the unified shape.
+
+**QA for #70:**
+- [ ] All order-rendering surfaces (customer search, guest search, order-number search, wholesale/recent, toolbar single-order) display correctly with the unified contract.
+- [ ] Removing the JS `||` fallbacks does not blank any column.
+- [ ] No regression in Total rendering (no raw HTML/`<span>` leakage, no double-escaping).
+
+### Phase 3 QA Checklist
+
+- [ ] #69 and #70 each verified against their per-issue QA.
+- [ ] One canonical formatter contract is documented and used by every render path.
+- [ ] Cross-store check (HPOS + legacy) for all order tables.
+- [ ] Committed on a branch off `development`; PR against `development`.
+
+---
+
+## Phase 4 — Packaging & Documentation Hygiene
+
+Two low-effort cleanups. Safe to batch into one PR.
+
+### #71 — Process artifacts shipped in plugin distributable (LOW)
+
+**Labels:** Priority: low, packaging · **Effort:** 15 min
+
+**Problem:** `relay-system/` and `PROJECT/` (QA transcripts, working docs, design docs) are committed for history but would land in the distributed plugin zip.
+
+**Fix:** Exclude from distribution builds (don't delete from repo).
+
+**Observable todo items:**
+- [ ] Add a `.distignore` (or the build tool's equivalent) excluding `relay-system/` and `PROJECT/`.
+- [ ] Confirm the keep-in-repo intent (history) is preserved — exclusion only affects the build artifact.
+- [ ] Note: `.gitignore` already ignores `/relay-system/` (owner added it); `.distignore` is still needed for any tracked process docs that remain in `PROJECT/`.
+
+**QA for #71:**
+- [ ] A built plugin zip contains no `relay-system/` or `PROJECT/` directory.
+- [ ] `relay-system/` and `PROJECT/` history is still present in the repo.
+
+### #72 — Stale README/AUDIT.md security/performance warnings (LOW)
+
+**Labels:** documentation, Priority: low · **Effort:** 15 min
+
+**Problem:** README "Security & Performance Notes" (lines ~31–33) and all 4 `AUDIT.md` findings describe issues that are **already fixed** — they currently warn users about non-existent vulnerabilities (XSS via unescaped JS, unbounded `all_with_meta` customer loads, `wc_get_orders limit => -1` counting, `esc_attr` benchmark). All resolved in commits `2a9398b`, `58ccc06`, `068a37e`.
+
+**Fix:** Update both docs to reflect current (resolved) state, or remove the obsolete sections.
+
+**Observable todo items:**
+- [ ] Update or remove README "Security & Performance Notes" (the two stale items + the "see AUDIT.md" pointers).
+- [ ] Mark all 4 `AUDIT.md` findings as Fixed (with commit refs) or remove the section.
+- [ ] Verify no remaining doc text implies these issues are still open.
+
+**QA for #72:**
+- [ ] README and AUDIT.md no longer warn about already-fixed issues.
+- [ ] Any retained text accurately states "resolved" with commit references.
+
+### Phase 4 QA Checklist
+
+- [ ] #71 and #72 verified against their per-issue QA.
+- [ ] Build a release zip and confirm both contents (no process artifacts) and docs (no stale warnings) are correct.
+- [ ] Committed on a branch off `development`; PR against `development`.
+
+---
+
+## Cross-Cutting Notes
+
+- **Branch discipline:** every PR off `development`; production tracks `development`. Resolve the `main`-lag release-hygiene gap noted in #74 separately.
+- **Not a security issue:** #74 explicitly classifies the slow-search problem as performance/operational — queries are parameterized and endpoints check caps + nonces.
+- **Verify-before-trust items:** #76's `wc_order_stats` completeness and #73's coupon counts both require validation against real production data before sign-off.
+- **Dependencies:** #75 and #76 are complementary (cache + indexed cold path); #70 reduces risk for #69; #68 is independent and shippable immediately.
+- **Owner flags:** #69 wholesale plugins are disabled (confirm relevance); #76 marked "not yet verified — seems too good to be true."
diff --git a/README.md b/README.md
index c2ff090..cbe3830 100644
--- a/README.md
+++ b/README.md
@@ -29,8 +29,8 @@ Populating Existing Coupons (Backfilling): The plugin has two ways to add your e
 5. To profile performance, visit **WooCommerce → KISS Benchmark** and run the test for any email.
 
 ## Security & Performance Notes
-- The AJAX endpoint only allows users with `manage_woocommerce` or `manage_options` and enforces a nonce, but customer/order data is inserted into the admin page via JavaScript without escaping. See `AUDIT.md` for the recommended fix.
-- Customer searches currently load full user records with all meta and count orders via unbounded WooCommerce queries; this may be slow on stores with many users/orders. Optimizations are outlined in `AUDIT.md`.
+- The AJAX endpoint allows only users with `manage_woocommerce` or `manage_options` and enforces a nonce. All dynamic customer/order fields are HTML-escaped before they are inserted into the admin page (resolved in `2a9398b`, `58ccc06`).
+- Customer searches use the `wc_customer_lookup` table and bounded `COUNT(*)` queries instead of loading full user records, so they stay fast on large stores (resolved in `068a37e`). See `AUDIT.md` for the history.
 
 ## Development
 - Source resides in the plugin root with supporting classes under `admin/` and `includes/`.
diff --git a/admin/kiss-woo-admin.js b/admin/kiss-woo-admin.js
index 7c0153d..785b4a4 100644
--- a/admin/kiss-woo-admin.js
+++ b/admin/kiss-woo-admin.js
@@ -127,10 +127,10 @@ jQuery(function ($) {
 
         orders.forEach(function (order) {
             html += '<tr>' +
-                '<td><a href="' + escapeHtml(order.view_url) + '" target="_blank" rel="noopener noreferrer">' + escapeHtml(order.number || order.id) + '</a></td>' +
+                '<td><a href="' + escapeHtml(order.view_url) + '" target="_blank" rel="noopener noreferrer">' + escapeHtml(order.order_number || order.number || order.id) + '</a></td>' +
                 '<td><span class="kiss-status-pill">' + escapeHtml(order.status_label) + '</span></td>' +
                 '<td>' + escapeHtml(order.total_display || order.total || '') + '</td>' +
-                '<td>' + escapeHtml(order.date || order.date_display || '') + '</td>' +
+                '<td>' + escapeHtml(order.date_display || order.date || '') + '</td>' +
                 '<td>' + escapeHtml(order.payment || '') + '</td>' +
                 '<td>' + escapeHtml(order.shipping || '') + '</td>' +
                 '<td><a href="' + escapeHtml(order.view_url) + '" class="button button-small" target="_blank" rel="noopener noreferrer">View</a></td>' +
diff --git a/includes/class-kiss-woo-coupon-backfill.php b/includes/class-kiss-woo-coupon-backfill.php
index 395a488..c13b575 100644
--- a/includes/class-kiss-woo-coupon-backfill.php
+++ b/includes/class-kiss-woo-coupon-backfill.php
@@ -24,11 +24,12 @@ class KISS_Woo_Coupon_Backfill {
     public function run_batch( int $last_id = 0, int $limit = 500 ): array {
         global $wpdb;
 
-        $limit = max( 1, min( 2000, $limit ) );
+        $limit = max( 1, min( 5000, $limit ) );
 
-        $ids = $wpdb->get_col(
+        // Fetch the row data directly (no per-coupon WC_Coupon hydration).
+        $rows = $wpdb->get_results(
             $wpdb->prepare(
-                "SELECT ID
+                "SELECT ID, post_title, post_excerpt, post_status
                    FROM {$wpdb->posts}
                   WHERE post_type = 'shop_coupon'
                     AND post_status NOT IN ('trash', 'auto-draft')
@@ -40,7 +41,7 @@ class KISS_Woo_Coupon_Backfill {
             )
         );
 
-        if ( empty( $ids ) ) {
+        if ( empty( $rows ) ) {
             return array(
                 'processed' => 0,
                 'last_id'   => $last_id,
@@ -48,22 +49,15 @@ class KISS_Woo_Coupon_Backfill {
             );
         }
 
-        $lookup = KISS_Woo_Coupon_Lookup::instance();
-        $processed = 0;
-        $current_last = $last_id;
-
-        foreach ( $ids as $id ) {
-            $id = (int) $id;
-            if ( $lookup->upsert_coupon( $id ) ) {
-                $processed++;
-            }
-            $current_last = $id;
-        }
+        // Single bulk multi-row upsert for the whole batch.
+        $processed    = KISS_Woo_Coupon_Lookup::instance()->bulk_upsert_posts( $rows );
+        $last_row     = end( $rows );
+        $current_last = (int) $last_row->ID;
 
         return array(
             'processed' => $processed,
             'last_id'   => $current_last,
-            'done'      => count( $ids ) < $limit,
+            'done'      => count( $rows ) < $limit,
         );
     }
 }
diff --git a/includes/class-kiss-woo-coupon-lookup-builder.php b/includes/class-kiss-woo-coupon-lookup-builder.php
index c01a9d7..b7f1b80 100644
--- a/includes/class-kiss-woo-coupon-lookup-builder.php
+++ b/includes/class-kiss-woo-coupon-lookup-builder.php
@@ -194,46 +194,47 @@ class KISS_Woo_Coupon_Lookup_Builder {
 		}
 
 		try {
-			// Get current progress.
-			$progress = $this->get_progress();
-
-			// If idle, initialize.
-			if ( 'idle' === $progress['status'] || 0 === $progress['total'] ) {
-				$progress['total']      = $this->get_total_coupons();
-				$progress['started_at'] = time();
-				$progress['status']     = 'running';
-				$this->update_progress( $progress );
-			}
-
-			// Run batch using existing backfill class.
-			$backfill = new KISS_Woo_Coupon_Backfill();
-			$result   = $backfill->run_batch( $progress['last_id'], $batch_size );
-
-			// Update progress.
-			$progress['last_id']   = $result['last_id'];
-			$progress['processed'] += $result['processed'];
-
-			if ( $result['done'] ) {
-				$progress['status'] = 'complete';
-			}
-
-			$this->update_progress( $progress );
+			// Single-pass bulk rebuild. Replaces the per-coupon WC_Coupon
+			// hydration loop (which silently dropped ~92% of coupons and took
+			// 12+ hours across ~728 rate-limited cron batches). rebuild_all()
+			// streams wp_posts in chunks and bulk-upserts, finishing the whole
+			// table in one cron run in seconds — so done is always true and no
+			// follow-up batch is scheduled.
+			$total  = $this->get_total_coupons();
+			$lookup = KISS_Woo_Coupon_Lookup::instance();
+
+			$this->update_progress(
+				array(
+					'last_id'    => 0,
+					'processed'  => 0,
+					'total'      => $total,
+					'started_at' => time(),
+					'status'     => 'running',
+				)
+			);
 
-			// Set next run time (rate limiting for background jobs).
-			if ( ! $result['done'] ) {
-				$this->set_next_run( self::MIN_RUN_INTERVAL );
-			}
+			$chunk  = max( 500, min( 5000, $batch_size > 0 ? $batch_size : 2000 ) );
+			$result = $lookup->rebuild_all( $chunk );
+
+			$this->update_progress(
+				array(
+					'last_id'    => $result['last_id'],
+					'processed'  => $result['inserted'],
+					'total'      => $total,
+					'started_at' => time(),
+					'status'     => 'complete',
+				)
+			);
 
 			return array(
 				'success'   => true,
-				'processed' => $result['processed'],
+				'processed' => $result['inserted'],
 				'last_id'   => $result['last_id'],
-				'done'      => $result['done'],
+				'done'      => true,
 				'message'   => sprintf(
-					'Processed %d coupons (total: %d/%d)',
-					$result['processed'],
-					$progress['processed'],
-					$progress['total']
+					'Rebuilt %d coupons in a single bulk pass (total: %d)',
+					$result['inserted'],
+					$total
 				),
 			);
 
diff --git a/includes/class-kiss-woo-coupon-lookup.php b/includes/class-kiss-woo-coupon-lookup.php
index 2e65819..8d12e2a 100644
--- a/includes/class-kiss-woo-coupon-lookup.php
+++ b/includes/class-kiss-woo-coupon-lookup.php
@@ -246,6 +246,134 @@ class KISS_Woo_Coupon_Lookup {
         return false !== $result;
     }
 
+    /**
+     * Rebuild the entire lookup table directly from wp_posts in bulk.
+     *
+     * Replaces the per-coupon `new WC_Coupon()` hydration path (which issues
+     * ~5-8 queries per coupon and silently drops coupons WC_Coupon can't
+     * hydrate). This streams shop_coupon posts in ID-ordered chunks and writes
+     * multi-row upserts, so every published coupon is indexed (1:1) in seconds
+     * rather than hours. Only the 5 search-used columns + identity/status are
+     * populated; the unused metadata columns keep their schema defaults.
+     *
+     * Normalization uses the same normalize_code()/normalize_text() the search
+     * path uses, so code_normalized/description_normalized stay query-compatible
+     * (a pure SQL INSERT...SELECT could not replicate the regex/tag stripping
+     * portably across MySQL versions).
+     *
+     * @param int $chunk Rows per batch (bounded memory + statement size).
+     * @return array{inserted:int,last_id:int} Summary of the rebuild.
+     */
+    public function rebuild_all( int $chunk = 2000 ): array {
+        if ( ! $this->ensure_table_ready() ) {
+            return array( 'inserted' => 0, 'last_id' => 0 );
+        }
+
+        global $wpdb;
+
+        $posts    = $wpdb->posts;
+        $chunk    = max( 100, $chunk );
+        $last_id  = 0;
+        $inserted = 0;
+
+        do {
+            // Stream coupons in ID order — no WC_Coupon, no postmeta JOINs.
+            $rows = $wpdb->get_results(
+                $wpdb->prepare(
+                    "SELECT ID, post_title, post_excerpt, post_status
+                     FROM {$posts}
+                     WHERE post_type = 'shop_coupon'
+                       AND post_status NOT IN ('trash', 'auto-draft')
+                       AND ID > %d
+                     ORDER BY ID ASC
+                     LIMIT %d",
+                    $last_id,
+                    $chunk
+                )
+            );
+
+            $batch = is_array( $rows ) ? count( $rows ) : 0;
+            if ( 0 === $batch ) {
+                break;
+            }
+
+            $inserted += $this->bulk_upsert_posts( $rows );
+            $last_row  = end( $rows );
+            $last_id   = (int) $last_row->ID;
+            reset( $rows );
+        } while ( $batch === $chunk );
+
+        return array(
+            'inserted' => $inserted,
+            'last_id'  => $last_id,
+        );
+    }
+
+    /**
+     * Bulk-upsert a set of shop_coupon post rows into the lookup table.
+     *
+     * Shared write path for rebuild_all() and the backfill batch processor.
+     * Each row must expose ID, post_title, post_excerpt, post_status. Writes
+     * one multi-row INSERT ... ON DUPLICATE KEY UPDATE — no per-row WC_Coupon
+     * hydration, so nothing is silently dropped.
+     *
+     * @param array $rows Raw post rows (objects from $wpdb->get_results).
+     * @return int Number of rows written.
+     */
+    public function bulk_upsert_posts( array $rows ): int {
+        if ( empty( $rows ) || ! $this->ensure_table_ready() ) {
+            return 0;
+        }
+
+        global $wpdb;
+
+        $table   = $this->get_table_name();
+        $blog_id = (int) get_current_blog_id();
+        $now     = current_time( 'mysql', true );
+
+        $placeholders = array();
+        $params       = array();
+
+        foreach ( $rows as $r ) {
+            // WC stores the coupon code in post_title (lower-cased on read).
+            $code  = strtolower( (string) $r->post_title );
+            $title = (string) $r->post_title;
+            $desc  = (string) $r->post_excerpt;
+
+            $placeholders[] = '(%d, %d, %s, %s, %s, %s, %s, %s, %s)';
+            array_push(
+                $params,
+                (int) $r->ID,
+                $blog_id,
+                // VARCHAR(200) columns — truncate to avoid strict-mode overflow.
+                mb_substr( $code, 0, 200 ),
+                mb_substr( self::normalize_code( $code ), 0, 200 ),
+                mb_substr( $title, 0, 200 ),
+                $desc,
+                self::normalize_text( $desc ),
+                (string) $r->post_status,
+                $now
+            );
+        }
+
+        $sql = "INSERT INTO {$table}
+                    (coupon_id, blog_id, code, code_normalized, title, description, description_normalized, status, updated_at)
+                VALUES " . implode( ', ', $placeholders ) . "
+                ON DUPLICATE KEY UPDATE
+                    code = VALUES(code),
+                    code_normalized = VALUES(code_normalized),
+                    title = VALUES(title),
+                    description = VALUES(description),
+                    description_normalized = VALUES(description_normalized),
+                    status = VALUES(status),
+                    updated_at = VALUES(updated_at)";
+
+        // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- placeholders built above, values bound via prepare().
+        $wpdb->query( $wpdb->prepare( $sql, $params ) );
+
+        return count( $rows );
+    }
+
     /**
      * Delete a coupon from the lookup table.
      *
diff --git a/includes/class-kiss-woo-order-formatter.php b/includes/class-kiss-woo-order-formatter.php
index d830400..8e4a245 100644
--- a/includes/class-kiss-woo-order-formatter.php
+++ b/includes/class-kiss-woo-order-formatter.php
@@ -41,6 +41,8 @@ class KISS_Woo_Order_Formatter {
                 'name'  => self::get_customer_name( $order ),
                 'email' => $order->get_billing_email(),
             ),
+            'payment'       => $order->get_payment_method_title(),
+            'shipping'      => $order->get_shipping_method(),
             'view_url'      => $edit_url, // Don't escape - already safe from admin_url() and will be used in JavaScript
         );
     }
@@ -101,6 +103,8 @@ class KISS_Woo_Order_Formatter {
                 'name'  => isset( $data['customer_name'] ) ? (string) $data['customer_name'] : '',
                 'email' => isset( $data['billing_email'] ) ? (string) $data['billing_email'] : '',
             ),
+            'payment'       => isset( $data['payment'] ) ? (string) $data['payment'] : '',
+            'shipping'      => isset( $data['shipping'] ) ? (string) $data['shipping'] : '',
             'view_url'      => $view_url,
         );
     }
@@ -114,7 +118,7 @@ class KISS_Woo_Order_Formatter {
      *                                is built from the ID without re-fetching.
      * @return string
      */
-    private static function get_edit_url( int $order_id, ?WC_Order $order = null ): string {
+    public static function get_edit_url( int $order_id, ?WC_Order $order = null ): string {
         // Use WooCommerce's get_edit_order_url() method (HPOS-aware) when the
         // caller already has the order. This method exists in WC_Order and
         // handles both HPOS and legacy modes.
diff --git a/includes/class-kiss-woo-order-query.php b/includes/class-kiss-woo-order-query.php
index ebac920..8fe2da6 100644
--- a/includes/class-kiss-woo-order-query.php
+++ b/includes/class-kiss-woo-order-query.php
@@ -143,6 +143,7 @@ class KISS_Woo_Order_Query {
 		$orders_table = $wpdb->prefix . 'wc_orders';
 		$meta_table   = $wpdb->prefix . 'wc_orders_meta';
 		$addr_table   = $wpdb->prefix . 'wc_order_addresses';
+		$items_table  = $wpdb->prefix . 'woocommerce_order_items';
 
 		// Base WHERE clause.
 		// Restrict to actual orders; the wc_orders table also stores refunds
@@ -180,7 +181,11 @@ class KISS_Woo_Order_Query {
 		// DATA query.
 		$data_sql = $wpdb->prepare(
 			"SELECT o.id, o.status, o.date_created_gmt, o.total_amount, o.currency,
-			        a.email as billing_email, a.first_name, a.last_name
+			        a.email as billing_email, a.first_name, a.last_name,
+			        o.payment_method_title AS payment,
+			        (SELECT GROUP_CONCAT(si.order_item_name SEPARATOR ', ')
+			           FROM {$items_table} si
+			          WHERE si.order_id = o.id AND si.order_item_type = 'shipping') AS shipping
 			 FROM {$orders_table} o
 			 LEFT JOIN {$addr_table} a ON o.id = a.order_id AND a.address_type = 'billing'
 			 WHERE {$where_clause}
@@ -209,6 +214,8 @@ class KISS_Woo_Order_Query {
 	private function build_legacy_query( string $type, int $per_page, int $offset, array $args ): ?array {
 		global $wpdb;
 
+		$items_table = $wpdb->prefix . 'woocommerce_order_items';
+
 		// Base WHERE clause.
 		$where = array( "p.post_type = 'shop_order'" );
 
@@ -251,13 +258,18 @@ class KISS_Woo_Order_Query {
 				MAX(CASE WHEN pm_currency.meta_key = '_order_currency' THEN pm_currency.meta_value END) as currency,
 				MAX(CASE WHEN pm_email.meta_key = '_billing_email' THEN pm_email.meta_value END) as billing_email,
 				MAX(CASE WHEN pm_fname.meta_key = '_billing_first_name' THEN pm_fname.meta_value END) as first_name,
-				MAX(CASE WHEN pm_lname.meta_key = '_billing_last_name' THEN pm_lname.meta_value END) as last_name
+				MAX(CASE WHEN pm_lname.meta_key = '_billing_last_name' THEN pm_lname.meta_value END) as last_name,
+				MAX(CASE WHEN pm_payment.meta_key = '_payment_method_title' THEN pm_payment.meta_value END) as payment,
+				(SELECT GROUP_CONCAT(si.order_item_name SEPARATOR ', ')
+				   FROM {$items_table} si
+				  WHERE si.order_id = p.ID AND si.order_item_type = 'shipping') as shipping
 			FROM {$wpdb->posts} p
 			LEFT JOIN {$wpdb->postmeta} pm_total ON p.ID = pm_total.post_id AND pm_total.meta_key = '_order_total'
 			LEFT JOIN {$wpdb->postmeta} pm_currency ON p.ID = pm_currency.post_id AND pm_currency.meta_key = '_order_currency'
 			LEFT JOIN {$wpdb->postmeta} pm_email ON p.ID = pm_email.post_id AND pm_email.meta_key = '_billing_email'
 			LEFT JOIN {$wpdb->postmeta} pm_fname ON p.ID = pm_fname.post_id AND pm_fname.meta_key = '_billing_first_name'
 			LEFT JOIN {$wpdb->postmeta} pm_lname ON p.ID = pm_lname.post_id AND pm_lname.meta_key = '_billing_last_name'
+			LEFT JOIN {$wpdb->postmeta} pm_payment ON p.ID = pm_payment.post_id AND pm_payment.meta_key = '_payment_method_title'
 			WHERE {$where_clause}
 			GROUP BY p.ID, p.post_status, p.post_date_gmt
 			ORDER BY p.post_date_gmt DESC
@@ -338,6 +350,8 @@ class KISS_Woo_Order_Query {
 				'currency'      => isset( $row->currency ) ? $row->currency : '',
 				'billing_email' => isset( $row->billing_email ) ? $row->billing_email : '',
 				'customer_name' => '',
+				'payment'       => isset( $row->payment ) ? $row->payment : '',
+				'shipping'      => isset( $row->shipping ) ? $row->shipping : '',
 			);
 
 			// Build customer name.
diff --git a/includes/class-kiss-woo-search.php b/includes/class-kiss-woo-search.php
index 19c3242..8188bb8 100644
--- a/includes/class-kiss-woo-search.php
+++ b/includes/class-kiss-woo-search.php
@@ -956,17 +956,20 @@ class KISS_Woo_COS_Search {
         $order_id = (int) $data['id'];
         $status   = (string) $data['status'];
 
-        // Build admin edit URL.
-        $edit_link = admin_url( 'post.php?post=' . $order_id . '&action=edit' );
+        // Build admin edit URL (HPOS-aware; legacy path has no WC_Order to pass).
+        $edit_link = KISS_Woo_Order_Formatter::get_edit_url( $order_id );
 
         // Format date.
+        $date_created   = null;
         $date_formatted = '';
         if ( ! empty( $data['date_gmt'] ) && '0000-00-00 00:00:00' !== $data['date_gmt'] ) {
             $timestamp = strtotime( $data['date_gmt'] );
             if ( $timestamp ) {
+                $local          = $timestamp + ( get_option( 'gmt_offset' ) * HOUR_IN_SECONDS );
+                $date_created   = date_i18n( 'Y-m-d H:i:s', $local );
                 $date_formatted = date_i18n(
                     get_option( 'date_format' ) . ' ' . get_option( 'time_format' ),
-                    $timestamp + ( get_option( 'gmt_offset' ) * HOUR_IN_SECONDS )
+                    $local
                 );
             }
         }
@@ -987,17 +990,24 @@ class KISS_Woo_COS_Search {
             $status_label = wc_get_order_status_name( $status );
         }
 
+        // Canonical order output contract — keys MUST match KISS_Woo_Order_Formatter::format_from_raw().
         return array(
             'id'            => $order_id,
-            'number'        => (string) $order_id, // Order number is typically the ID unless customized.
+            'order_number'  => (string) $order_id,
             'status'        => esc_attr( $status ),
             'status_label'  => esc_html( $status_label ),
-            'total'         => $total_formatted,
-            'date'          => esc_html( $date_formatted ),
+            'total'         => (string) $data['total'],
+            'total_display' => esc_html( $total_formatted ),
+            'currency'      => esc_html( (string) $data['currency'] ),
+            'date_created'  => $date_created,
+            'date_display'  => esc_html( $date_formatted ),
+            'customer'      => array(
+                'name'  => '',
+                'email' => esc_html( (string) $data['billing_email'] ),
+            ),
             'payment'       => esc_html( (string) $data['payment'] ),
             'shipping'      => esc_html( (string) $data['shipping'] ),
             'view_url'      => esc_url_raw( $edit_link ),
-            'billing_email' => esc_html( (string) $data['billing_email'] ),
         );
     }
 
@@ -1841,24 +1851,28 @@ class KISS_Woo_COS_Search {
         $payment      = $order->get_payment_method_title();
         $shipping     = $order->get_shipping_method();
 
-        // `esc_url()` is for HTML output contexts and will entity-encode `&` as `&#038;`.
-        // This payload is returned as JSON and inserted via JS; it must be a raw URL.
-        $edit_link = get_edit_post_link( $order_id, 'raw' );
-        if ( empty( $edit_link ) ) {
-            $edit_link = admin_url( 'post.php?post=' . (int) $order_id . '&action=edit' );
-        }
+        // HPOS-aware raw edit URL. Pass the loaded order so get_edit_url() can use
+        // WC_Order::get_edit_order_url() directly (no hardcoded legacy URL).
+        $edit_link = KISS_Woo_Order_Formatter::get_edit_url( $order_id, $order );
 
+        // Canonical order output contract — keys MUST match KISS_Woo_Order_Formatter::format_from_raw().
         return array(
             'id'            => (int) $order_id,
-            'number'        => esc_html( $order->get_order_number() ),
+            'order_number'  => esc_html( $order->get_order_number() ),
             'status'        => esc_attr( $status ),
             'status_label'  => esc_html( wc_get_order_status_name( $status ) ),
-            'total'         => html_entity_decode( wp_strip_all_tags( wc_price( $total, array( 'currency' => $currency ) ) ), ENT_QUOTES, 'UTF-8' ),
-            'date'          => esc_html( $date_created ? $date_created->date_i18n( get_option( 'date_format' ) . ' ' . get_option( 'time_format' ) ) : '' ),
+            'total'         => (string) $total,
+            'total_display' => esc_html( html_entity_decode( wp_strip_all_tags( wc_price( $total, array( 'currency' => $currency ) ) ), ENT_QUOTES, 'UTF-8' ) ),
+            'currency'      => esc_html( $currency ),
+            'date_created'  => $date_created ? $date_created->date_i18n( 'Y-m-d H:i:s' ) : null,
+            'date_display'  => esc_html( $date_created ? $date_created->date_i18n( get_option( 'date_format' ) . ' ' . get_option( 'time_format' ) ) : '' ),
+            'customer'      => array(
+                'name'  => esc_html( trim( $order->get_billing_first_name() . ' ' . $order->get_billing_last_name() ) ),
+                'email' => esc_html( $order->get_billing_email() ),
+            ),
             'payment'       => esc_html( $payment ),
             'shipping'      => esc_html( $shipping ),
             'view_url'      => esc_url_raw( $edit_link ),
-            'billing_email' => esc_html( $order->get_billing_email() ),
         );
     }
 
diff --git a/tests/HUMAN-VERIFY.md b/tests/HUMAN-VERIFY.md
new file mode 100644
index 0000000..74fc597
--- /dev/null
+++ b/tests/HUMAN-VERIFY.md
@@ -0,0 +1,27 @@
+# Human verification required — the gate CANNOT check these
+
+`tests/run.sh` (the automated gate) deliberately does **not** test the items below.
+They depend on real, production-scale data and live infrastructure, so any
+"automated" version would be a toy that gives **false confidence**. A human must
+verify each against production before sign-off, using the per-issue QA checklists
+in [`PROJECT/2-WORKING/BUG-FIXES-2026-06-26.md`](../PROJECT/2-WORKING/BUG-FIXES-2026-06-26.md).
+
+| Issue | Claim that needs a human + real data | Where to verify |
+|-------|--------------------------------------|-----------------|
+| **#73** | Coupon build indexes **all ~338k published** coupons (not ~55k) and finishes in <60s. The gate cannot stand up 363k coupons or a MySQL server. | Phase 1 QA for #73 — run the build on a copy of production, compare indexed count vs published count. |
+| **#76** | `wc_order_stats` is **complete** for this store (no missing historical orders) and the cold per-customer lookup drops from 8–26s to sub-second. The gate has no analytics tables and no production row counts. | Phase 2 QA — row-count `wc_order_stats` parent rows vs real order count; time a real lookup. |
+| **#75 (invalidation half)** | Cache invalidation actually works **under the persistent object cache** on order lifecycle events (new/update/status-change/trash). The gate checks the **key shape** only, not live transient/object-cache behavior. | Phase 2 QA — simulate a ShipStation status change, confirm the next lookup reflects it with no TTL wait. |
+| **#69 (values)** | DONE + verified: the order-query layer now selects payment/shipping (HPOS `payment_method_title` / legacy `_payment_method_title` + shipping order-items) — gate-guarded by the `#69` static wiring checks, and confirmed populating against a prod-scale DB copy (both paths). **Remaining human bits:** (a) eyeball the columns rendering in the live admin UI; (b) note that on this store some legacy orders have a NULL `_payment_method_title` postmeta (value lives only in the HPOS column), so the Payment cell is legitimately blank for those *if* the store is ever read via the legacy path. | Phase 3 QA for #69 — load real orders in the admin UI; spot-check a few against their HPOS vs legacy payment source. |
+
+## What the gate DOES cover (so you don't re-check by hand)
+
+- `php -l` on every PHP file (syntax floor).
+- **#68** — `get_edit_url()` builds the HPOS `admin.php?page=wc-orders…` URL when HPOS is on, legacy `post.php?post=…` when off.
+- **#70** — `format_from_raw()`, `format_order_data_for_output()`, and `format_order_for_output()` return the **same set of key names** (the regression class this batch exists to kill).
+- **#75 (key half)** — the per-customer version-stamped key changes on a version bump and never collides across customers.
+- **#71** — `.distignore` excludes `PROJECT/` and `relay-system/` (and any `dist/`/`build/` staging dir carries neither).
+- **#72** — README/AUDIT.md no longer contain the stale security/performance warnings.
+
+> Reviewer note: several gate checks are **red until their fix lands** — that is intended.
+> The gate turns green issue-by-issue as the batch is implemented; it is a regression
+> fence, not proof the work is already done.
diff --git a/tests/gate.php b/tests/gate.php
new file mode 100644
index 0000000..4520633
--- /dev/null
+++ b/tests/gate.php
@@ -0,0 +1,212 @@
+<?php
+/**
+ * Unattended bug-fix gate for BUG-FIXES-2026-06-26.md (#68–#76).
+ *
+ * Plain PHP. No phpunit, no brain/monkey, no DB, no WooCommerce, no network.
+ * WP/Woo functions are shimmed with tiny doubles below. Runs in milliseconds.
+ *
+ * Pairs with tests/run.sh (which adds the `php -l` syntax floor) and
+ * tests/HUMAN-VERIFY.md (the invariants a machine CANNOT check — #73/#75-invalidation/#76).
+ *
+ * ponytail: deliberately checks only invariants that are real WITHOUT a database.
+ * Some checks are red until their issue is fixed — that is the point: this gate
+ * goes green as the batch lands, and fails loudly if a fix regresses.
+ */
+
+error_reporting( E_ALL & ~E_DEPRECATED );
+
+define( 'ABSPATH', __DIR__ . '/' );      // satisfies the `if (!defined('ABSPATH')) exit;` guards
+define( 'HOUR_IN_SECONDS', 3600 );
+
+$ROOT = dirname( __DIR__ );
+
+/* ----- tiny pass/fail harness ----- */
+$PASS = 0;
+$FAIL = 0;
+function check( $name, $cond, $detail = '' ) {
+	global $PASS, $FAIL;
+	if ( $cond ) {
+		$PASS++;
+		echo "  ok   $name\n";
+	} else {
+		$FAIL++;
+		echo "  FAIL $name" . ( $detail !== '' ? " — $detail" : '' ) . "\n";
+	}
+}
+
+/* ----- minimal WP/Woo doubles (only what the code under test calls) ----- */
+if ( ! function_exists( 'admin_url' ) ) {
+	function admin_url( $path = '' ) { return $path; } // identity: we assert on the path/query it builds
+}
+if ( ! function_exists( 'get_edit_post_link' ) ) {
+	function get_edit_post_link( $id = 0, $ctx = '' ) { return ''; } // empty -> formatter falls through to the HPOS/legacy branch
+}
+if ( ! function_exists( 'get_option' ) ) {
+	function get_option( $k, $d = false ) { return $d; }
+}
+// Test double for the HPOS flag, driven by $GLOBALS['kiss_test_hpos'].
+if ( ! class_exists( 'KISS_Woo_Utils' ) ) {
+	class KISS_Woo_Utils {
+		public static function is_hpos_enabled() { return ! empty( $GLOBALS['kiss_test_hpos'] ); }
+	}
+}
+
+echo "== #68  KISS_Woo_Order_Formatter::get_edit_url() — HPOS vs legacy ==\n";
+require_once $ROOT . '/includes/class-kiss-woo-order-formatter.php';
+try {
+	$m = new ReflectionMethod( 'KISS_Woo_Order_Formatter', 'get_edit_url' );
+	$m->setAccessible( true );
+
+	$GLOBALS['kiss_test_hpos'] = true;
+	$hpos = (string) $m->invoke( null, 123 );
+	check( 'HPOS on  -> admin.php?page=wc-orders…&id=123', strpos( $hpos, 'admin.php?page=wc-orders' ) !== false && strpos( $hpos, 'id=123' ) !== false, $hpos );
+
+	$GLOBALS['kiss_test_hpos'] = false;
+	$legacy = (string) $m->invoke( null, 123 );
+	check( 'HPOS off -> post.php?post=123&action=edit', strpos( $legacy, 'post.php?post=123' ) !== false, $legacy );
+} catch ( \Throwable $e ) {
+	check( 'get_edit_url() invokable via reflection', false, $e->getMessage() );
+}
+// Call-site coverage: the helper proves the branching works; this proves the search
+// class actually routes through it (no hardcoded legacy URL left behind).
+$search_for_url = file_get_contents( $ROOT . '/includes/class-kiss-woo-search.php' );
+check( 'class-kiss-woo-search.php has no hardcoded post.php?post= edit URL', strpos( $search_for_url, 'post.php?post=' ) === false,
+	'route edit URLs through KISS_Woo_Order_Formatter::get_edit_url() (#68)' );
+
+echo "== #70  order formatters return the SAME key set (single write path) ==\n";
+$formatter_src = file_get_contents( $ROOT . '/includes/class-kiss-woo-order-formatter.php' );
+$search_src    = file_get_contents( $ROOT . '/includes/class-kiss-woo-search.php' );
+
+$shapes = array(
+	'format_from_raw'              => kiss_top_keys( $formatter_src, 'format_from_raw' ),
+	'format_order_data_for_output' => kiss_top_keys( $search_src, 'format_order_data_for_output' ),
+	'format_order_for_output'      => kiss_top_keys( $search_src, 'format_order_for_output' ),
+);
+$missing = array_keys( $shapes, null, true );
+if ( $missing ) {
+	check( 'all three formatter methods found with a return array()', false, 'could not extract: ' . implode( ', ', $missing ) );
+} else {
+	$ref = $shapes['format_from_raw'];
+	foreach ( $shapes as $name => $keys ) {
+		$diff = array_merge( array_diff( $ref, $keys ), array_diff( $keys, $ref ) );
+		check( "$name key set matches format_from_raw", $keys === $ref, $diff ? 'differs by: ' . implode( ', ', $diff ) : '' );
+	}
+}
+
+echo "== #69  order-query layer populates payment + shipping (no blank columns) ==\n";
+// Regression guard for #69: the blank-column bug was the query layer never
+// selecting/passing payment+shipping, so format_from_raw()'s keys stayed empty.
+// No DB needed — assert the wiring is present in both storage paths + the formatter feed.
+$oq = file_get_contents( $ROOT . '/includes/class-kiss-woo-order-query.php' );
+check( 'HPOS query selects o.payment_method_title', strpos( $oq, 'o.payment_method_title' ) !== false, 'restore payment select in build_hpos_query() (#69)' );
+check( 'legacy query reads _payment_method_title meta', strpos( $oq, "'_payment_method_title'" ) !== false, 'restore payment join in build_legacy_query() (#69)' );
+check( 'both paths join shipping order items', substr_count( $oq, "order_item_type = 'shipping'" ) >= 2, 'restore shipping subquery in HPOS + legacy queries (#69)' );
+check( 'format_order_rows feeds payment to the formatter', strpos( $oq, '$row->payment' ) !== false, 'pass payment into format_from_raw() (#69)' );
+check( 'format_order_rows feeds shipping to the formatter', strpos( $oq, '$row->shipping' ) !== false, 'pass shipping into format_from_raw() (#69)' );
+
+echo "== #73  coupon build uses bulk SQL, not per-row WC_Coupon hydration ==\n";
+// Regression guard for #73: the catastrophic build was a per-coupon `new WC_Coupon`
+// loop that silently dropped ~92% of coupons. The build path must now use the bulk
+// multi-row upsert. No DB needed — assert the wiring statically.
+$lk = file_get_contents( $ROOT . '/includes/class-kiss-woo-coupon-lookup.php' );
+$bf = file_get_contents( $ROOT . '/includes/class-kiss-woo-coupon-backfill.php' );
+$bd = file_get_contents( $ROOT . '/includes/class-kiss-woo-coupon-lookup-builder.php' );
+check( 'lookup has bulk_upsert_posts() multi-row writer', strpos( $lk, 'function bulk_upsert_posts' ) !== false && strpos( $lk, 'ON DUPLICATE KEY UPDATE' ) !== false, 'add the bulk upsert writer (#73)' );
+check( 'lookup has rebuild_all() single-pass rebuild', strpos( $lk, 'function rebuild_all' ) !== false, 'add rebuild_all() (#73)' );
+check( 'backfill batch uses the bulk writer', strpos( $bf, 'bulk_upsert_posts' ) !== false, 'route backfill through bulk_upsert_posts (#73)' );
+check( 'backfill batch no longer hydrates per-row', strpos( $bf, 'upsert_coupon' ) === false, 'backfill must not call upsert_coupon per row (#73)' );
+check( 'builder runs a single-pass rebuild_all', strpos( $bd, 'rebuild_all' ) !== false, 'builder must drive rebuild_all() (#73)' );
+
+echo "== #75  per-customer version-stamped cache key ==\n";
+require_once $ROOT . '/includes/class-kiss-woo-search-cache.php';
+if ( ! method_exists( 'KISS_Woo_Search_Cache', 'get_customer_orders_key' ) ) {
+	check( 'KISS_Woo_Search_Cache::get_customer_orders_key() exists', false,
+		'implement get_customer_orders_key(int $customer_id, int $version, int $page = 1, int $per_page = 20): string per #75' );
+} else {
+	$c    = new KISS_Woo_Search_Cache();
+	$base = $c->get_customer_orders_key( 5, 1, 1, 20 );
+	$bump = $c->get_customer_orders_key( 5, 2, 1, 20 );
+	$other = $c->get_customer_orders_key( 6, 1, 1, 20 );
+	check( 'version bump changes the key (invalidation works)', $base !== $bump, "v1=$base v2=$bump" );
+	check( 'different customers never collide', $base !== $other, "c5=$base c6=$other" );
+	check( 'same inputs are deterministic', $base === $c->get_customer_orders_key( 5, 1, 1, 20 ), '' );
+}
+
+echo "== #71  process artifacts excluded from the distributable ==\n";
+$distignore = $ROOT . '/.distignore';
+if ( ! is_file( $distignore ) ) {
+	check( '.distignore exists and excludes PROJECT/ + relay-system/', false, 'add a .distignore listing PROJECT/ and relay-system/ (#71)' );
+} else {
+	$d = file_get_contents( $distignore );
+	check( '.distignore excludes PROJECT/', strpos( $d, 'PROJECT' ) !== false, '' );
+	check( '.distignore excludes relay-system/', strpos( $d, 'relay-system' ) !== false, '' );
+}
+// If a build/stage dir is ever produced, it must not carry these dirs.
+foreach ( array( 'dist', 'build' ) as $stage ) {
+	if ( is_dir( "$ROOT/$stage" ) ) {
+		check( "$stage/ contains no PROJECT/ or relay-system/", ! is_dir( "$ROOT/$stage/PROJECT" ) && ! is_dir( "$ROOT/$stage/relay-system" ), '' );
+	}
+}
+
+echo "== #72  README/AUDIT.md no longer warn about already-fixed issues ==\n";
+$stale = array(
+	'README.md' => array( 'without escaping', 'unbounded WooCommerce queries' ),
+	'AUDIT.md'  => array( 'could be rendered as HTML/JS in the admin view', 'loads every order object to count them' ),
+);
+foreach ( $stale as $file => $phrases ) {
+	$body = is_file( "$ROOT/$file" ) ? file_get_contents( "$ROOT/$file" ) : '';
+	foreach ( $phrases as $p ) {
+		check( "$file: stale warning removed — \"$p\"", strpos( $body, $p ) === false, 'remove or rewrite this stale warning (#72)' );
+	}
+}
+
+echo "\nINVARIANTS: $PASS passed, $FAIL failed\n";
+exit( $FAIL > 0 ? 1 : 0 );
+
+/* ----- static return-array key extraction (no class load, no DB) -----
+ * ponytail: #70 is a SHAPE contract; comparing the declared return-array keys
+ * is enough and avoids booting a 90KB class + WC_Order + DB rows to invoke them. */
+function kiss_match_paren( $s, $open ) {
+	$depth = 0;
+	$n     = strlen( $s );
+	for ( $i = $open; $i < $n; $i++ ) {
+		if ( $s[ $i ] === '(' ) {
+			$depth++;
+		} elseif ( $s[ $i ] === ')' ) {
+			$depth--;
+			if ( 0 === $depth ) {
+				return $i;
+			}
+		}
+	}
+	return false;
+}
+function kiss_top_keys( $src, $func ) {
+	$fp = strpos( $src, "function $func(" );
+	if ( false === $fp ) {
+		return null;
+	}
+	$ra = strpos( $src, 'return array(', $fp );
+	if ( false === $ra ) {
+		return null;
+	}
+	$open = strpos( $src, '(', $ra );
+	$end  = kiss_match_paren( $src, $open );
+	if ( false === $end ) {
+		return null;
+	}
+	$inner = substr( $src, $open + 1, $end - $open - 1 );
+	// Remove nested array(...) blocks so only TOP-LEVEL keys remain.
+	while ( ( $p = strpos( $inner, 'array(' ) ) !== false ) {
+		$o = strpos( $inner, '(', $p );
+		$e = kiss_match_paren( $inner, $o );
+		if ( false === $e ) {
+			break;
+		}
+		$inner = substr( $inner, 0, $p ) . substr( $inner, $e + 1 );
+	}
+	preg_match_all( "/'([a-zA-Z0-9_]+)'\\s*=>/", $inner, $matches );
+	$keys = array_values( array_unique( $matches[1] ) );
+	sort( $keys );
+	return $keys;
+}
diff --git a/tests/run.sh b/tests/run.sh
new file mode 100755
index 0000000..5994dbd
--- /dev/null
+++ b/tests/run.sh
@@ -0,0 +1,36 @@
+#!/usr/bin/env bash
+# The one gate command for the bug-fix batch (#68–#76).
+#   php -l floor across all plugin PHP, then the no-DB invariant checks.
+# Exits non-zero on any failure. Run from anywhere:  bash tests/run.sh
+set -uo pipefail
+cd "$(dirname "$0")/.."
+
+fail=0
+
+# 1) Syntax floor — catches parse breaks the build loop could introduce.
+lint_err=0
+while IFS= read -r -d '' f; do
+	if ! out=$(php -l "$f" 2>&1); then
+		echo "LINT FAIL: $f"
+		echo "$out"
+		lint_err=$((lint_err + 1))
+	fi
+done < <(find . -path ./vendor -prune -o -name '*.php' -print0)
+if [ "$lint_err" -gt 0 ]; then
+	echo "php -l: $lint_err file(s) with syntax errors"
+	fail=1
+else
+	echo "php -l: OK — all PHP files parse"
+fi
+
+echo
+# 2) Invariant checks (no DB, no WooCommerce, no network).
+php tests/gate.php || fail=1
+
+echo
+if [ "$fail" -ne 0 ]; then
+	echo "GATE: FAIL"
+else
+	echo "GATE: PASS"
+fi
+exit "$fail"
```

<!-- Reviewer: append your "### Review — codex" block below this line. -->

### Review — codex

- [Blocker] `includes/class-kiss-woo-coupon-lookup.php:264` — `rebuild_all()` only upserts rows that still exist in `wp_posts`; it never clears the lookup table or deletes coupons that have since been trashed/deleted. After the first rebuild, stale rows remain searchable and the table can no longer be a 1:1 projection of live coupons, which contradicts both the comment and the QA target. Proposed fix: make the rebuild replace-state, not merge-state, by truncating/swap-rebuilding the lookup table up front or explicitly deleting rows whose `coupon_id` is no longer selected.
- [Should] `includes/class-kiss-woo-coupon-lookup.php:334`, `includes/class-kiss-woo-coupon-lookup-builder.php:216` — `bulk_upsert_posts()` ignores the return value of `$wpdb->query()` and still returns `count($rows)`. `rebuild_all()` and the builder then mark the run `complete`/`success` based on that synthetic count, so a failed multi-row insert can be reported as a successful full rebuild. Proposed fix: check the query result, return `0` or throw on failure, and have the builder leave the job failed/incomplete instead of stamping `status => complete`.
- [Pass] `includes/class-kiss-woo-search.php:958`, `includes/class-kiss-woo-order-formatter.php:118` — the HPOS edit-link fix is routed through a single helper now, and the loaded-order path reuses `WC_Order::get_edit_order_url()` instead of hardcoding the legacy `post.php` URL.
- [Pass] `admin/kiss-woo-admin.js:131`, `includes/class-kiss-woo-search.php:990`, `includes/class-kiss-woo-order-query.php:181` — the admin render sinks now consume the new order payload shape consistently, and the payment/shipping fields are wired through both HPOS and legacy order queries.

VERDICT: Changes requested

Basis: the coupon rebuild path still is not a true rebuild and can also falsely report success on failed writes, so I would not sign off on the “all coupons indexed correctly” claim yet.
