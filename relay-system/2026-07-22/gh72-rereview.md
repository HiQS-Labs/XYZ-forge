# RELAY · GH-72 re-review — blocker fixes
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
6. **Commit only the relay file** (`relay(gh72-rereview): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **rereview_gh72.md** (embedded below — read it here).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-22

### Artifact — rereview_gh72.md
```
# Re-review — GH-72 blocker fixes (commit 5ec4853)

You reviewed `c4c95e6` on branch `gh-71-72-hardening` (LTVera-Pandas) and returned **Changes requested** (3 blockers, 2 shoulds). Addressed in `5ec4853`. **Read the actual files in this worktree.** Review-only.

## Dispositions

1. `[Blocker]` *`_is_retired` naive substring matching ("Good Old Style", "v10")* — **Implemented.** Replaced the marker list with word-boundary regexes: `_VERSION_TOKEN_RE = \bv\d+\b` (case-insensitive) anywhere in the title, and `"old"` accepted only as its own dash/pipe-delimited segment via `_SEGMENT_SPLIT_RE`. New unit test asserts "Good Old Style Protein" and "Olde Tyme Formula" are NOT retired, while "… V1 - OLD", "… V2 faire", "… V10" and `status='archived'` are.
2. `[Blocker]` *Marker list leaks V2/V3/channel suffixes* — **Implemented** by the same regex. Verified against the real prod row `"Pre-Workout Gummies - Beast Mode - Fruit Punch V2 faire"`, which is now correctly retired.
3. `[Blocker]` *Declining on NULL `product_type` silently disables the feature* — **Implemented.** Added a `_family()` resolver that falls back to `product_clusters.cluster_name` when `product_type` is absent; only when neither yields a family does it decline.
4. `[Should]` *0.95 ceiling is tight/brittle; use a structural signal* — **Implemented.** Added `_is_title_variant()`: when one title is a prefix of the other ("Beast Mode" vs "Beast Mode Blend") the pair is rejected regardless of vector distance, so variant detection no longer rests on the threshold alone. The ceiling is retained as a second line of defence. `_PREFIX_MIN_LEN = 8` guards against trivially-short titles.
5. `[Should]` *Weak exclusion assertion* — **Implemented.** Now asserts `not any(p.anchor_id == ids["A"] ...)`.

49 tests green (was 47).

## Verify specifically

- Are the new regexes correct and free of *new* false positives/negatives? Consider: a legitimate product literally named "V8 Juice" or "Vitamin V12"; a title using an en-dash or no spaces around the separator (`A-B` vs `A - B`) — does `_SEGMENT_SPLIT_RE` handle the real separator variants in this catalog?
- Is `_is_title_variant`'s prefix rule too aggressive? Could it reject a *legitimate* cross-sell — e.g. two genuinely different products that happen to share a long brand prefix ("Pre-Workout Gummies - Beast Mode" vs "Pre-Workout Gummies - Mushroom+" do NOT share a prefix, but is there a catalog shape where it misfires)? Is `_PREFIX_MIN_LEN = 8` well-chosen?
- Does the `product_clusters` fallback introduce a query/N+1 or correctness problem? It loads one row per product — is the dict build safe when a product has multiple cluster rows (does it silently pick an arbitrary one, and does that matter)?
- Are the preserved invariants still intact: fail-closed, tenant isolation (both new queries filter `tenant_id`), flag default-OFF, `_MAX_PER_FAMILY` cap, semantic-never-evicts-co-order?
- Do the 2 new unit tests actually prove what they claim?

Report `[Blocker]` / `[Should]` / `[Nit]` / `[Pass]` with `file:line`, then a **Verdict** (Approved | Changes requested | Blocked).
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer (agy)
- **[Blocker]** `_is_retired` regexes (`app/recommendations/semantic_cross_sell.py:41` and `44`) have false positives/negatives. `\bv\d+\b` will falsely retire legitimate products like "V8 Juice", "Vitamin V12", or "Yeezy V2". Additionally, `\s+[-|]\s+` requires surrounding spaces, meaning a tight separator like "Product-OLD" won't be split correctly and thus won't be retired.
  - *Fix:* Restrict the version regex (e.g., requiring separators or end of string) and allow tight separators in the split regex (e.g., `\s*[-|]\s*`).
- **[Blocker]** `_family` dict build (`app/recommendations/semantic_cross_sell.py:163`) silently overwrites values when a product has multiple clusters. The dict comprehension `clusters = {pid: cluster for pid, cluster in db.execute(...)}` is non-deterministic if the DB returns multiple cluster rows for one product.
  - *Fix:* Ensure the query returns one row per product (e.g., using a subquery, window function, or aggregating).
- **[Should]** `_is_title_variant` (`app/recommendations/semantic_cross_sell.py:79`) prefix check is too aggressive. `x.startswith(y)` will reject "Creatine Gummies" when the anchor is "Creatine" (length 8 >= `_PREFIX_MIN_LEN`), missing a legitimate cross-category bridge.
  - *Fix:* Require a boundary character (like a space or dash) after the prefix to confirm it's a true variant (e.g., `x.startswith(y + " ")`).
- **[Pass]** Weak exclusion assertion fixed. The new assertion `assert not any(p.anchor_id == ids["A"] for p in excluded)` at `tests/test_semantic_cross_sell.py:214` properly verifies that no candidate for `A` is yielded once `D` is excluded.
- **[Pass]** Marker list leaking suffixes fixed. `tests/test_semantic_cross_sell.py:223` correctly asserts that `_is_retired` captures "V2 faire" by leveraging the regex.

**Verdict**: Changes requested

VERDICT: FAIL
Basis: Blockers found in _is_retired regex and _family cluster fetch

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
