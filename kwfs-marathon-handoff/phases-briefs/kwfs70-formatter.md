# Phase kwfs70 — #70 Converge the order formatters on one key contract

**Issue:** kissplugins/KISS-woo-fast-search #70 (tech-debt, medium). Branch off `development`.
**Depends on:** kwfs68 (same file — runs after the #68 URL swap lands).

**Goal:** Three methods convert order data to JSON arrays with different key sets, so a fix to one path
silently breaks another (the `wc_price()` HTML-in-total regression already happened):
1. `format_order_for_output()` (`class-kiss-woo-search.php:1835-1863`)
2. `format_order_data_for_output()` (`class-kiss-woo-search.php:955-1002`)
3. `format_from_raw()` (`class-kiss-woo-order-formatter.php:54-106`)

Converge them on one canonical key contract.

**Files you may edit:** `includes/class-kiss-woo-search.php`,
`includes/class-kiss-woo-order-formatter.php`, `admin/kiss-woo-admin.js`.

## Gate contract (publish-the-needle)

The gate **statically extracts the declared return-array key sets** of `format_from_raw()`,
`format_order_data_for_output()`, and `format_order_for_output()` and asserts the three sets are
**identical**. It checks set-equality, **not** specific names — you choose the names, but all three
literals must carry exactly the same keys.

- [ ] Pick ONE canonical key set and make all three return-array literals use it verbatim. Reconcile
      `number`/`order_number`, `date`/`date_display`, and `total`/`total_display` to single names.
- [ ] The canonical set **must include `payment` and `shipping` keys** (this de-risks #69). Values may
      be empty where unavailable — *value correctness is human-verify, not gated here.*
- [ ] **Static-extraction caveat:** the gate reads plain `'key' => …` literal entries. Do **not** build
      keys dynamically (variable keys, conditional `if` branches that add keys, array spreads) or the
      extractor will misread the set and the phase will churn. Keep all three literals flat and explicit.
- [ ] Prefer making `format_from_raw()` canonical and having `format_order_data_for_output()` delegate
      to it; delete the duplicate once equivalent.
- [ ] Update `admin/kiss-woo-admin.js` `renderOrdersTable()` and the wholesale/recent renderer to the
      unified shape; removing the JS `|| ''` fallbacks must not blank a column.

## Definition of done

- [ ] `bash tests/run.sh` `#70` invariant **passed** (three key sets identical, `payment`+`shipping`
      present).
- [ ] No regression in Total rendering (no raw HTML/`<span>` leakage, no double-escape) — reviewer
      confirms from the diff.

## Out of scope

- Actual payment/shipping **values** and the wholesale/recent display correctness are #69 — keys present
  here, values verified by a human against a store (see `tests/HUMAN-VERIFY.md`).
