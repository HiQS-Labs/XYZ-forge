# RELAY · GH-72 near-duplicate guard review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-22.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh72-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **review_gh72.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-22

### Artifact — review_gh72.md
````
# Review — GH-72: near-duplicate guard for semantic cross-sell (commit c4c95e6)

Branch `gh-71-72-hardening` in LTVera-Pandas. **Read the actual files in this worktree.** Review-only: report findings, do not edit.

## Why this change exists

GH-68 shipped pgvector semantic cross-sell flag-OFF, because on Bounce's real catalog every nearest neighbor is a *variant of the anchor* (flavors, `V1`, `OLD` stored as separate `products` rows). Enabling it rendered `"Cross-sell Beast Mode BLEND to Beast Mode buyers"` — the same product — and that card **evicted** a genuine co-order recommendation.

## What changed (`c4c95e6`)

1. **Ceiling** — `LeverConfig.cross_sell_semantic_ceiling` (0.95); candidate must satisfy `floor <= similarity < ceiling`. Plain frozen-dataclass field, deliberately NOT in `_DESCRIPTORS` (matches how `cross_sell_semantic_floor` is done).
2. **Wider fetch** — `_NEIGHBOR_FETCH = 25` (was `limit=5`), since the whole top-5 can be siblings.
3. **Distinct `product_type` required** — unknown type declines rather than guesses.
4. **Retired rows excluded** — `_RETIRED_TITLE_MARKERS` (`OLD`, `V1` variants) + non-active `status`, on both sides of the pair.
5. **Semantic no longer evicts co-order** — `_cross_sell_recommendations()` now does `chosen_co = rows[:_MAX_PER_FAMILY]` and semantic fills only leftover slots (was: reserved a slot unconditionally).
6. **Companion dedup** — the same companion can't be recommended from two near-duplicate anchors.

Tests: 47 green (43 baseline + 4 new). The fixture places each rejection behind exactly one rule so a test can prove which guard fired.

## Live prod probe (read-only, before/after)

```
BEFORE:  Beast Mode -> Beast Mode Blend      (1.00)  same product, evicted a co-order card
AFTER:   Beast Mode -> Creatine Gummies      (0.925) Pre-Workout Gummies -> Creatine Gummies
```

## What to scrutinize (most severe first)

1. **Is the 0.95 ceiling defensible, and is a hard-coded default the right design?** Live data shows genuine bridges at 0.918–0.928 and near-duplicates at ≥0.95 — a narrow margin. Is that dangerously tight? Would a different signal (shared token overlap in titles, `product_clusters.cluster_name`, shared `handle` prefix) discriminate variants more robustly than a raw similarity threshold?
2. **Residual leak.** A prod row titled `"Pre-Workout Gummies - Beast Mode - Fruit Punch V2 faire"` still qualifies against the `Beast Mode` anchor: it is a variant, but its `product_type` differs from its parent and `_RETIRED_TITLE_MARKERS` catches `V1` but not `V2` or channel suffixes like `faire`. Is the marker-list approach fundamentally too brittle? What would you use instead?
3. **`_is_retired` correctness** — check the marker matching (`app/recommendations/semantic_cross_sell.py`). Any false positives on legitimate titles (a product genuinely named "…Gold" or containing "old" as a substring — does the leading-space/prefix trick actually prevent that)?
4. **Distinct-`product_type` rule** — is declining when either type is `NULL` right, or does it silently disable semantic for catalogs that don't populate `product_type`? Should it fall back to `product_clusters.cluster_name`?
5. **Slot rule** — confirm semantic can never evict a co-order card now, and that the family cap `_MAX_PER_FAMILY` still holds.
6. **Preserved invariants** — fail-closed (no pgvector/embedding error escapes `build_recommendations()`), tenant isolation (explicit `tenant_id` + RLS backstop), flag still default-OFF.
7. **Test quality** — do the 4 new tests actually prove what they claim? Any tautological or weak assertion?

Report `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]` with `file:line`, then a **Verdict** (Approved | Changes requested | Blocked).
````
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer: agy
- **[Should]** 0.95 ceiling (`app/recommendations/levers.py:98`) is dangerously tight and brittle as a hardcoded default. Consider using `product_clusters.cluster_name` or `handle` prefix overlap to discriminate variants more robustly.
- **[Blocker]** `_RETIRED_TITLE_MARKERS` list (`app/recommendations/semantic_cross_sell.py:34`) is brittle and leaks `V2`, `V3`, or channel suffixes like `faire`. Consider using regex to match trailing version numbers or rely on Shopify's `published_scope` or `status` instead.
- **[Blocker]** `_is_retired` (`app/recommendations/semantic_cross_sell.py:51`) naively matches substrings. `" old"` will match legitimate titles containing the word "old" (e.g. "Good Old Style"), and `" v1"` matches `" v10"`. Use regex with word boundaries (e.g. `\b(?:v[1-9]|old)\b`).
- **[Blocker]** Declining on `NULL` `product_type` (`app/recommendations/semantic_cross_sell.py:155`) silently disables semantic cross-sells for catalogs that don't populate it. Fall back to checking `product_clusters.cluster_name` distinctness when `product_type` is missing.
- **[Pass]** Semantic cross-sell correctly fills leftover slots and never evicts a co-order card (`app/recommendations/builder.py:386`).
- **[Pass]** Invariants are preserved: fail-closed via catch-all (`app/recommendations/builder.py:483`), tenant isolation enforced (`app/recommendations/semantic_cross_sell.py:121`), and flag remains default-OFF (`app/recommendations/levers.py:89`).
- **[Should]** The assertion in `test_semantic_candidates_respect_band_and_exclusions` (see `tests/test_semantic_cross_sell.py` in the diff) is weak: it asserts `exclude_pairs` was respected, but the comment claims it "leaves no candidate for A". Assert `not any(p.anchor_id == ids["A"] ...)` instead.

**Verdict:** Changes requested

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
