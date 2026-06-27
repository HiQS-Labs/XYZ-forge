# Phase kwfs68 — #68 Route HPOS edit URLs through get_edit_url at the call site

**Issue:** kissplugins/KISS-woo-fast-search #68 (bug, high, HPOS). Branch off `development`.

**Goal:** `format_order_data_for_output()` at `includes/class-kiss-woo-search.php:960` hardcodes the
legacy `post.php?post=…&action=edit` URL, so on HPOS stores every "View Order" link 404s/misredirects.
`KISS_Woo_Order_Formatter::get_edit_url($order_id)` already handles both storage modes correctly
(`includes/class-kiss-woo-order-formatter.php:117-141`). Use it.

**Files you may edit:** `includes/class-kiss-woo-search.php` only.

## Gate contract (publish-the-needle) — READ THIS, the gate has a blind spot

The gate already verifies `get_edit_url()`'s HPOS-vs-legacy branching (it reflects into the private
method and forces `get_edit_post_link` empty to exercise both branches). That invariant is **already
green** — it proves the *helper* works, **not** that the call site uses it. Do not be misled by a green
`#68`: your actual job is the call-site swap, which the current gate does **not** catch.

- [ ] Replace the hardcoded `$edit_link = admin_url('post.php?post=…&action=edit')` at
      `class-kiss-woo-search.php:960` with `KISS_Woo_Order_Formatter::get_edit_url($order_id)`.
- [ ] Ensure **no** `post.php?post=` literal remains anywhere in `format_order_data_for_output()`
      (or its siblings in this file). The maintainer is adding a grep assertion for this — build to it.
- [ ] Confirm `get_customer_orders_page()` pagination links flow through the same helper.

## Definition of done

- [ ] `bash tests/run.sh` `#68` invariant **passed** (helper branching).
- [ ] No hardcoded legacy `post.php?post=` URL remains in the order-formatting paths of this file
      (reviewer confirms by reading the diff).

## Out of scope

- Do not converge the formatters here — that is phase kwfs70, which depends on this phase and edits the
  same file. Keep this change to the URL swap so kwfs70 starts from a clean base.
