# Relay System — Efficacy Log

A running record of the Producer/Reviewer **relay** runs (file-based, turn-based review loops)
used on this plugin, and the concrete defects each one caught. Purpose: document whether the
relay system actually earns its cost — i.e. does an independent reviewer surface real problems
the Producer's own work + testing missed?

Each relay is one Markdown thread in `relay-system/<date>/`. The Producer builds and disposes;
the Reviewer (a *different* model or a fresh session) proposes graded findings and sets a verdict;
the loop ends on **Approved**.

**Headline:** across 3 relays, independent reviewers surfaced **9 distinct findings** the
Producer had already shipped or planned — including a real coverage regression vs stock
WooCommerce and a fix that landed in the wrong function. None were caught by the Producer's own
testing. Two of the three relays needed multiple rounds to reach Approved.

---

## Relay 1 — Plan review: native search intercept
- **Thread:** [`2026-06-15/intercept-woo-fields.md`](2026-06-15/intercept-woo-fields.md)
- **Reviewer:** Codex CLI (different model) · **Rounds:** 2 · **Outcome:** Approved
- **Artifact:** the `INTERCEPT-WP-WOO-FIELDS.md` implementation plan (pre-code).
- **Caught (4 findings, all verified valid against installed source):**
  1. **[Blocker]** Plan assumed order-search methods return rows keyed `order_id`; they actually return `id` (`format_order_for_output()`). Reading `order_id` would have returned **empty** — a silent no-op.
  2. **[Blocker]** Customer numeric-ID branch + multisite visibility check from core was missing.
  3. **[Should]** Order-filter scope guard was too abstract to implement (named the concrete screen-id gate).
  4. **[Should]** Short-term (<3 char) result limit + `try/catch` fallback only lived in QA notes, not steps.
- **Value:** caught a would-be empty-result bug *before any code was written*.

## Relay 2 — Implementation QA: release 1.3.1 (intercept + 2 fixes)
- **Thread:** [`2026-06-15/qa-release-1-3-1.md`](2026-06-15/qa-release-1-3-1.md)
- **Reviewer:** Codex CLI (different model) · **Rounds:** 2 · **Outcome:** Approved
- **Caught:**
  1. **[Blocker]** The native order intercept dropped **registered-customer** order searches — it only covered order-number + *guest* orders, while stock WooCommerce searches billing fields across **all** orders. A real **coverage regression vs stock**: searching the orders list by a registered customer's email/name would return fewer results than WC's own search. Fixed by unioning `search_customers()` matches' order lists; live-verified 8/8 coverage.
  2. **[Should]** Customer numeric-ID branch was missing core's multisite `get_user_in_current_site()` visibility guard.
- **Value:** the Producer's own live tests had used an order number and a guest-style email — never a *registered* customer's email — so this regression passed every prior check.

## Relay 3 — Implementation QA: customer order pagination (1.3.2)
- **Thread:** [`2026-06-15/qa-pagination.md`](2026-06-15/qa-pagination.md)
- **Reviewer:** Claude subagent (**same model**, fresh context — driven fully automated in-session) · **Rounds:** 3 · **Outcome:** Approved
- **Caught:**
  1. **[Should]** First-page render used a *global* `LIMIT count*limit*5`; under multi-customer skew one busy customer could **starve** a co-matched customer's first page to empty. Fixed by per-customer first-page fetch (also makes page-1 ordering identical to later pages).
  2. **[Should]** HPOS order-count omitted `type='shop_order'`, so refunds could inflate the header total → **phantom trailing page**.
  3. **[Blocker, round 2]** The Producer's round-2 fix for (2) **landed in the wrong method** — it filtered the single-customer `get_order_count()` instead of the batch `get_order_counts_hpos()` that actually feeds the badge. The Producer's "live (classic)" proof had exercised the legacy path and never tested the HPOS code it claimed to fix. Corrected in round 3.
- **Value (notable):** even a **same-model** relay caught a mis-targeted fix + a self-deceiving verification claim. The honest caveat (same model → shared blind spots) held — it took 3 rounds and the reviewer's catch hinged on tracing the data flow, not novel domain knowledge — but it still prevented shipping a non-fix.

---

## Observations on efficacy
- **Different-model reviewers (Codex)** found the highest-severity, domain-specific issues (the stock-WC coverage regression, the empty-result key bug) — issues rooted in WooCommerce behavior.
- **Same-model reviewer (Claude subagent)** still earned its keep: it caught a wrong-method fix and an over-claimed verification, both via careful data-flow tracing. Weaker than a different model for *novel* blind spots, but effective at *consistency/traceability* checks.
- **Multi-round was the norm**, not the exception: 2 of 3 relays needed ≥2 review rounds; one needed 3. A single review pass would have shipped real bugs in every case.
- **Cost note:** different-model relays (Codex) spent external credits; the same-model relay ran fully in-session via a subagent (no external credits) — a cheaper fallback when credits are scarce, at some loss of independence.

_Last updated: 2026-06-15._
