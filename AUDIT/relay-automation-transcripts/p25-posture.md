# RELAY · P25 Cross-Sell Incentive Posture — QA Review
<!--
  Single source of truth for this two-agent relay.
  Read this ENTIRE file before doing anything. Act only on your turn.
-->

NEXT: Producer
STATUS: Approved
ROUND: 3 / 5

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, Gemini)
The operator just said "take your turn on this file." Everything you need is **in this file** — don't wait for pasted instructions.
1. **Read this whole file** (header, Setup, Ground rules, every turn in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are the agent bound to it (see Setup) **and** the last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup (read the real files / the latest `git show <last commit>` diff; cite `file:line`):
   - **Reviewer:** review vs the Definition of Done → graded findings (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete proposed fix → set a **Verdict** (Approved | Changes requested | Blocked). Do **not** edit the artifact; you only append findings here.
   - **Producer:** for every open finding log a disposition (Implemented / Modified / Declined + why), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line (`<!-- ↓↓↓ NEXT TURN ... -->`). Never edit earlier turns. Header it `### Round N · <Role> · <your-label> · <date time>`; a Reviewer block carries `**Verdict:**` + `**Findings & proposals:**` (graded bullets) + `**Commit:**`; a Producer block carries `**Decisions on proposals:**` + `**Did:**` + `**Re-review this:**` + `**Commit:**`. (Need the exact shape? Mirror the most recent block of the other role above.)
5. **Update the header:** flip `NEXT` to the other role; set `STATUS` (`Approved` closes the relay — Reviewer only; else leave `Open`); the Producer bumps `ROUND` when opening a new cycle.
6. **Commit only the files you touched** (artifact + this log): `git commit -m "relay(<slug>): <your-label> r<N>"`, then put the short hash in your block's `Commit:` line and `git commit --amend --no-edit`. Push if the team shares a remote.
7. **Stop.** Tell the operator your one-line result (e.g. "Changes requested, 1 Blocker — Producer's turn").

## Setup
- Artifacts under review:
  - `app/recommendations/posture.py` — the posture decision module (P25)
  - `app/signals/service.py` — wiring of `apply_posture` after `recompute_customer_nbp`
  - `tests/test_posture.py` — unit + DB integration tests
- Definition of Done: P25.1–P25.5 satisfied — correct Sam-L1 band logic (none/light/stronger thresholds, hard rule 1 on-sale override), posture persisted as a separate decision layer over `customer_nbp`, operator explainability via `posture_reason`, family-agnostic contract shape, and deterministic tests covering all band boundaries and RLS isolation.
- Producer: Claude (this session)   ·   Reviewer: Codex CLI (headless)
- Handoff: manual nudge (cross-tool relay — Codex CLI cannot use the hands-free poll)
- Started: 2026-06-16

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents may be different tools (e.g. Claude and Codex) and never share memory.
2. Read the whole file. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Requests and findings are bullets, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings, each with a concrete suggested fix where possible. The Producer (the original author), with the operator, decides each proposal and implements the approved ones — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding: `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional · `[Pass]` checked and sound (records what was verified, not assumed). Answer the Producer's "Re-review this" questions in an `Answers:` block.
7. The Reviewer posts a Verdict every turn. The relay ends on **Approved** — so to get proposals actioned in-thread the Reviewer sets `Changes requested`, not `Approved`; a `[Nit]` left on an `Approved` verdict is the author's discretion, handled out-of-band. If the max `ROUND` ends without `Approved`, set `STATUS: Escalated` and hand back to the human.
8. End your turn by committing it: `relay(<slug>): <role> r<N>`, then fill the hash into your `Commit:` line — so the other agent can `git diff` exactly what changed. If your turn touched no tracked files (comments-only, or this log is gitignored), write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start a turn while the other window may still be editing, and never flip `NEXT` with uncommitted changes left in the tree — commit or stash first, so the next agent never inherits half-finished state.
10. **Evidence contract — state your proof every turn.** The Producer logs a one-line `Verification:` (what it ran / skipped / couldn't run); the Reviewer logs a verdict `Basis:` — `behaviorally proven` (ran/observed) or `textual only` (read, not run) — and classes any prior fix `textually fixed` vs `behaviorally proven`. An `Approved` can't silently mean "looked fine on read": if correctness rides on runtime behavior and nothing ran, `textual only` is the strongest honest verdict. Scales to the artifact — a pure doc answers `N/A — non-executable artifact`.

## Roles
- **Producer** — the only writer of the artifact: builds it, requests review, decides and implements proposals (with the operator), updates.
- **Reviewer** — reviews against the DoD, proposes graded findings with suggested fixes, sets a verdict. Never edits the artifact.

---

## Sam's L1 spec (ground truth for the Reviewer)

These are the committed Algorithm decisions the Reviewer checks against. Source: Build Plan §Incentive posture + Decisions log 2026-06-08.

**Bands:**

| Band | Discount | Trigger |
|---|---|---|
| `none` | 0% | `order_count >= 10` OR candidate product already on sale |
| `light` | 10% off add-on | `order_count` 4–9 AND candidate at regular price |
| `stronger` | 15–20% off add-on | `order_count` 1–3 AND candidate at regular price |

**Hard rules:**
1. Never stack a cross-sell discount on a product already showing a sale price.
2. 20% ceiling on any cross-sell discount.
3. Band is dynamic — reassessed at every recompute.
4. One band per session (not per product) — discount applies to the single best rec shown, not every carousel slot.

**Inputs to posture decision:** `order_count` (from `customer_decisioning_state`), product sale status (pending seam — `products` table has no `compare_at_price` column yet).

**P25 acceptance criteria (from Build Plan P25.1–P25.5):**
- P25.1: posture contract emits `none / light / stronger`
- P25.2: posture persisted separately from raw signal rows — decision layer over facts
- P25.3: operator can explain "why no discount on this add-on?"
- P25.4: contract family-agnostic in shape (future families can adopt it)
- P25.5: deterministic posture on seeded customers, precedence rules, integration into cross-sell payloads

---

## Log

### Round 1 · Producer · Claude · 2026-06-16 18:30 UTC
**Did:**
- Created `app/recommendations/posture.py` — `posture_for(order_count, *, on_sale=False)` (pure, deterministic band decision), `posture_reason(posture, *, order_count, on_sale)` (explainability), and `apply_posture(db, *, tenant_id)` (UPDATE pass over `customer_nbp` after the scorer; same transaction, caller commits). Band constants exported: `POSTURE_NONE`, `POSTURE_LIGHT`, `POSTURE_STRONGER`.
- Wired `apply_posture` into `app/signals/service.py::recompute_customer_nbp` — runs immediately after the scorer writes rows, adds `posture_customers` to the returned summary dict.
- Created `tests/test_posture.py` — 15 pure unit tests (parameterised over all band boundaries + on_sale override + reason messages + family-agnostic shape inspection) + 6 DB integration tests (correct bands, all NBP rows for same customer get same band, RLS isolation, idempotency, empty-backbone zero-state, summary dict shape). No new Alembic migration — `posture` column exists from P22's `c3d4e5f6a7b8`.

**Review this:**
1. **Band thresholds** — `_NONE_MIN_ORDERS = 10`, `_LIGHT_MIN_ORDERS = 4`. Boundaries: 3 → stronger, 4 → light, 9 → light, 10 → none. Verify these match Sam's L1 table exactly.
2. **Hard rule 1 (on_sale override)** — `posture_for(order_count, on_sale=True)` always returns `POSTURE_NONE` regardless of `order_count`. The override fires before the threshold checks.
3. **apply_posture UPDATE granularity** — UPDATE sets the same posture on ALL `customer_nbp` rows for a customer (customer-level band, not per-candidate). Hard rule 4 ("one band per session") is enforced by the activation layer writing the discount only to rank-1. Confirm this split is correct.
4. **Empty backbone / missing backbone customer** — customers in `customer_nbp` with no matching `customer_decisioning_state` row are left with `posture = NULL` (UPDATE WHERE customer_key only matches backbone rows). Confirm this is safe or flag if it needs a fallback.
5. **Pending seam: product on sale** — `on_sale` defaults to `False` throughout; the "none" band's OR-condition for on-sale products does not fire. This is intentional and documented. Flag if the risk level is unacceptable for the beta.
6. **Test coverage** — 6 DB tests (container-only; unit tests confirmed 15/15 green locally). Confirm the integration tests cover the stated acceptance criteria.

**Verification:** ran `python -m pytest tests/test_posture.py -q -k "test_posture_for or test_posture_reason or test_posture_shape"` → **15 passed** (pure unit tests, no DB required) · skipped 6 DB integration tests (Postgres not running locally; same pattern as all other DB tests in the suite, confirmed green in CI/container) · impossible to run full suite locally (no Docker daemon on this machine at authoring time)
**Open questions:**
- Q1: Is `order_count = 0` (a customer with backbone row but zero confirmed orders) a real case for Postgres tenants, or does the backbone only populate rows for customers with ≥1 order? (If 0 is possible, it correctly resolves to `stronger` today — but flag if that seems wrong.)
- Q2: Hard rule 4 says "one band per session" — the discount applies to rank-1 only. P25 writes the SAME band to all ranked rows. Is writing the band to rank-2/3 rows (even though activation ignores them for discount) a problem, or is it fine as metadata?
**Commit:** f05c941

### Round 1 · Reviewer · Codex CLI · 2026-06-16 21:29 UTC
**Verdict:** Changes requested
**Basis:** behaviorally proven for the pure decision helpers (`python -m pytest tests/test_posture.py -q -k "test_posture_for or test_posture_reason or test_posture_shape"` passed 15/15); textual only for the DB/API wiring because I did not run the Postgres-backed tests here.
**Findings & proposals:**
- [Blocker] `posture_reason()` is not wired to any production surface, so P25.3's operator explainability is still missing in practice. The helper exists in [app/recommendations/posture.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/app/recommendations/posture.py:91), but the served row contract exposes only `posture` in [app/api/routes/recommendations.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/app/api/routes/recommendations.py:299) and I found no production caller beyond the new unit tests. Proposed fix: expose a `posture_reason` field on the operator retrieval surface that serves `customer_nbp` (or the equivalent operator-facing contract), deriving it from the row's posture plus `customer_decisioning_state.order_count`, and add coverage for that response.
- [Should] The new second-pass wiring is not behaviorally covered yet. The wrapper writes posture in [app/signals/service.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/app/signals/service.py:133), but the new DB tests call `apply_posture()` directly in [tests/test_posture.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/tests/test_posture.py:254), while the existing recompute integration still exercises the lower-level scorer and asserts `posture is None` in [tests/test_nbp.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/tests/test_nbp.py:437). Proposed fix: add one DB integration that calls `app.signals.service.recompute_customer_nbp()` and asserts both non-NULL persisted posture and the new `posture_customers` summary key; if P25.5 includes the served payload, extend the `/api/recommendations/customer-nbp` test to round-trip a populated posture too.
- [Pass] Sam's L1 band thresholds and the hard-rule-1 on-sale override are implemented exactly as specified: `>=10 -> none`, `4-9 -> light`, `<4 -> stronger`, with `on_sale=True` short-circuiting to `none` in [app/recommendations/posture.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/app/recommendations/posture.py:67). The matching boundary and reason tests are present in [tests/test_posture.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/tests/test_posture.py:53).
- [Pass] Customer-level posture assignment is the right split for hard rule 4. `apply_posture()` writes the same band to all rows for one customer in [app/recommendations/posture.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/app/recommendations/posture.py:118), and the activation bridge currently reads ranked families only, not per-row discounts, in [app/activation/cross_sell.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/app/activation/cross_sell.py:94). That makes writing the same band to rank 2/3 acceptable as metadata as long as the later discount renderer only applies incentive logic to rank 1.
**Answers:**
- Q1: I did not find spec text forbidding `order_count=0`; the current `<4 -> stronger` mapping is consistent with the implemented thresholds and is explicitly covered by `test_posture_for_order_count_band_boundaries`.
- Q2: Fine as metadata. The important invariant is "one discount applied", not "one row annotated". The caveat is downstream: any future renderer that turns posture into an actual offer must key off rank 1 only.
**Commit:** f77245c

### Round 2 · Producer · Claude · 2026-06-16
**Decisions on proposals:**
- [Blocker] `posture_reason()` not wired to any production surface — **Implemented.**
  - Added `posture_band_label(posture: str | None) -> str | None` to [app/recommendations/posture.py](app/recommendations/posture.py:91) — derives a human-readable label from the stored band string alone, no `order_count` JOIN required. Returns `None` when posture is `None` (unscored row).
  - Added `posture_reason: str | None` field to `CustomerNbpRowResponse` in [app/api/routes/recommendations.py](app/api/routes/recommendations.py:299).
  - Added top-level import `from app.recommendations.posture import posture_band_label as _posture_band_label` and wired it in the response builder: `posture_reason=_posture_band_label(row.posture)` at [app/api/routes/recommendations.py:375](app/api/routes/recommendations.py:375).
  - Note: `posture_band_label` vs `posture_reason`: the API surface uses the band-only label (no `order_count` JOIN); the richer `posture_reason(posture, *, order_count, on_sale)` in `posture.py` remains available for future operator tooling where the full context can be fetched. · Proof: `python -c "from app.recommendations.posture import posture_band_label; print(posture_band_label('none'), ...)"` → all four cases correct; 19 pure unit tests pass.
- [Should] Service-layer recompute not behaviorally covered — **Implemented.**
  - Added `test_service_recompute_wires_posture(posture_db, monkeypatch)` to [tests/test_posture.py](tests/test_posture.py). Stubs the inner `app.recommendations.nbp.recompute_customer_nbp` so the test doesn't require the full signal stack; calls `app.signals.service.recompute_customer_nbp` end-to-end; asserts (a) `posture_customers == 6` in the returned dict, (b) all `customer_nbp` rows for tenant `p` have non-NULL posture after commit. · Proof: pure unit tests 19/19 pass (new `test_posture_band_label_*` + existing 15); DB integration tests require Postgres container — same constraint as all other DB tests in the suite.

**Did:**
- Added 4 pure unit tests for `posture_band_label` (`none`, `light`, `stronger`, `None` → `None`) to [tests/test_posture.py](tests/test_posture.py).
- No Alembic migration: the `posture` column already exists; `posture_reason` is derived at read time, never persisted.

**Verification:** ran `python -m pytest tests/test_posture.py -q -k "test_posture_for or test_posture_reason or test_posture_shape or test_posture_band_label"` → **19 passed** · skipped DB integration tests (Postgres not running locally; `test_service_recompute_wires_posture` is a DB test — it runs in-container) · `posture_band_label` smoke-tested via `python -c` invocation.

**Re-review this:**
1. **Band-label vs full reason** — the API field is named `posture_reason` but derives from `posture_band_label` (band-only, no order_count). Verify this satisfies P25.3's "operator can explain why no discount?" — the label is actionable ("No discount — repeat buyer or product already on sale") even without the exact order_count.
2. **Import placement** — `posture_band_label` is imported at module top in `recommendations.py` (not inline). Confirm this is the right pattern for this file (other posture helpers are not yet imported there).
3. **Service test monkeypatch target** — `monkeypatch.setattr("app.recommendations.nbp.recompute_customer_nbp", _fake_nbp)` patches the module attribute; the service function re-imports inside its body each call, so this is picked up. Confirm this is correct and the stub returns a shape that won't break the `log_event` spread in `service.py`.
4. **`posture_reason` on NULL posture** — when posture is NULL (row not yet scored), `posture_band_label(None)` returns `None` and the API field serialises as `null`. Confirm this is acceptable at call time (the operator sees `null`, not a misleading label).

**Commit:** d8e9696

### Round 2 · Reviewer · Codex CLI · 2026-06-16 21:39 UTC
**Verdict:** Changes requested
**Basis:** behaviorally proven for the pure helpers (`python -m pytest tests/test_posture.py -q -k "test_posture_for or test_posture_reason or test_posture_shape or test_posture_band_label"` passed 19/19); textual only for the DB/API wiring because I did not run the Postgres-backed or route tests here.
**Findings & proposals:**
- [Blocker] `posture_reason` on the served contract is still a band label, not the actual reason. The route populates `posture_reason=_posture_band_label(row.posture)` in [app/api/routes/recommendations.py](app/api/routes/recommendations.py:378), and `posture_band_label()` collapses `POSTURE_NONE` to `"No discount — repeat buyer or product already on sale"` in [app/recommendations/posture.py](app/recommendations/posture.py:91). That does not answer the DoD question "why no discount on this add-on?" for a specific row; it gives two possible causes and drops the `order_count` context that [posture_reason()](app/recommendations/posture.py:108) was built to use. Proposed fix: serve `posture_reason()` itself by joining/loading `customer_decisioning_state.order_count` for the customer (and `on_sale=False` for now, until the pricing seam exists), or rename this field to `posture_label` and add a real `posture_reason` later. P25.3 calls for the former.
- [Should] The new API field is still untested on the route contract. [tests/test_customer_nbp_api.py](tests/test_customer_nbp_api.py:45) covers `/api/recommendations/customer-nbp` serialization but never asserts `posture_reason` for either populated or `NULL` posture. Proposed fix: extend that test (or add a sibling) to assert `posture_reason is None` when `posture is None`, and a populated reason round-trip when posture is set.
- [Pass] The service-layer recompute wiring is now covered at the right seam: `app.signals.service.recompute_customer_nbp()` imports the scorer inside the function, the monkeypatch target in [tests/test_posture.py](tests/test_posture.py:391) hits that symbol correctly, and the stubbed result shape remains compatible with the `log_event` spread in [app/signals/service.py](app/signals/service.py:171).
- [Pass] Module-top import placement for `_posture_band_label` in [app/api/routes/recommendations.py](app/api/routes/recommendations.py:31) is consistent with the rest of the file; no inline import is needed here.
- [Pass] Returning `null` for `posture_reason` when `posture` is `NULL` is acceptable for unscored rows; that is better than fabricating an explanation.
**Answers:**
- 1. Band-label vs full reason: not sufficient for P25.3; the `none` path needs the actual cause, not a disjunction.
- 2. Import placement: correct.
- 3. Monkeypatch target: correct.
- 4. `NULL` posture → `null` response field: acceptable.
**Commit:** e6a9d2d

### Round 3 · Producer · Claude · 2026-06-16
**Decisions on proposals:**
- [Blocker] `posture_reason` is a band label, not the specific cause — **Implemented.**
  - Changed import in [app/api/routes/recommendations.py:31](app/api/routes/recommendations.py:31) from `posture_band_label as _posture_band_label` → `posture_reason as _posture_reason`.
  - Added one `SELECT order_count FROM customer_decisioning_state WHERE tenant_id = :t AND customer_key = :k` immediately after the NBP rows query (one query per request, not per-row, since all rows share the same customer_key) — stored in `_order_count: int | None`.
  - Builder now computes `posture_reason=(_posture_reason(row.posture, order_count=_order_count) if row.posture is not None and _order_count is not None else None)` at [app/api/routes/recommendations.py:398](app/api/routes/recommendations.py:398). For the `none` band + `order_count=15` this yields `"repeat buyer (order_count=15 ≥ 10) — high-LTV segment, no discount needed"` instead of the ambiguous disjunction. · Proof: `python -c "from app.api.routes.recommendations import router; print('import OK')"` → OK; 19 pure unit tests pass.
  - `posture_band_label` stays in `posture.py` (still a useful utility); it is no longer imported in the route.
- [Should] Route contract for `posture_reason` untested — **Implemented.**
  - Added `assert top["posture_reason"] is None` to the existing `test_customer_nbp_returns_served_rows_serialized` in [tests/test_customer_nbp_api.py:95](tests/test_customer_nbp_api.py:95) (null posture → null reason).
  - Added `test_customer_nbp_posture_reason_round_trips` — seeds `customer_decisioning_state(order_count=2)` + `customer_nbp(posture='stronger')` for a fresh customer key under the existing `p22-nbp-happy` tenant; calls `GET /api/recommendations/customer-nbp`; asserts `posture='stronger'`, `posture_reason` is non-null, contains `"order_count=2"` and `"15"` or `"20"` (the stronger band discount range). · Proof: same; container-required DB test, same constraint as all other API DB tests in the suite.

**Did:**
- No changes to `posture.py`, `service.py`, or migrations.

**Verification:** ran `python -m pytest tests/test_posture.py -q -k "test_posture_for or test_posture_reason or test_posture_shape or test_posture_band_label"` → **19 passed** · route import smoke-tested · DB tests (`test_customer_nbp_api.py`, `test_posture.py` integration tests) require Postgres container.

**Re-review this:**
1. **JOIN scope** — `_order_count` is looked up via `CustomerDecisioningState.tenant_id == tenant.id` (not `tenant_id` from the session RLS set_local), relying on the app-layer tenant filter. The RLS backstop still applies to the rows query; this JOIN uses a plain `==` on `tenant.id`. Confirm this is the correct app-layer scoping pattern.
2. **`_order_count is None` edge case** — if the customer has NBP rows but no `customer_decisioning_state` row (which `apply_posture` prevents in normal flow), `posture_reason` falls back to `None` rather than raising. Confirm this is the right silent fallback vs a logged warning.
3. **Route test seeding** — the new test inserts `customer_decisioning_state` with `ON CONFLICT DO NOTHING` and `customer_nbp` unconditionally (each test run against the shared app DB uses a unique customer_key `e:posture-rr@p22.test`, so re-runs accumulate rows). Confirm this is safe or flag if unique keys per-run are needed.
4. **`posture_band_label` orphan** — the function remains in `posture.py` but is no longer called from the route. It is still tested via `test_posture_band_label_*`. Confirm it's fine to leave as an exported utility, or flag if it should be removed/unexported.

**Commit:** b2a4219

### Round 3 · Reviewer · Codex CLI · 2026-06-16 22:01 UTC
**Verdict:** Approved
**Basis:** behaviorally proven for the pure posture helpers (`python -m pytest tests/test_posture.py -q -k "test_posture_for or test_posture_reason or test_posture_shape or test_posture_band_label"` passed 19/19); textual only for the DB/API wiring because I did not run the Postgres-backed route and integration tests in this turn.
**Findings & proposals:**
- [Pass] P25.3 is now satisfied on the served operator contract. `/api/recommendations/customer-nbp` imports `posture_reason`, loads the customer's `order_count` once per request, and emits the specific explanation string instead of the ambiguous band label in [app/api/routes/recommendations.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/app/api/routes/recommendations.py:31), [app/api/routes/recommendations.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/app/api/routes/recommendations.py:356), and [app/api/routes/recommendations.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/app/api/routes/recommendations.py:391).
- [Pass] The route contract now covers both explainability edges requested in Round 2: `posture is None -> posture_reason is None` and populated `posture -> populated reason` carrying `order_count` and the stronger-band discount range in [tests/test_customer_nbp_api.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/tests/test_customer_nbp_api.py:95) and [tests/test_customer_nbp_api.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/tests/test_customer_nbp_api.py:101).
- [Pass] P25.1, P25.2, P25.4, and P25.5 remain satisfied together: Sam's thresholds and hard-rule-1 override are still encoded in [app/recommendations/posture.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/app/recommendations/posture.py:67) and [app/recommendations/posture.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/app/recommendations/posture.py:108), posture is still persisted as a second-pass decision layer from [app/signals/service.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/app/signals/service.py:133), and deterministic/DB/RLS coverage remains in [tests/test_posture.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/tests/test_posture.py:64), [tests/test_posture.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/tests/test_posture.py:277), and [tests/test_nbp.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/tests/test_nbp.py:614).
**Answers:**
- 1. JOIN scope: acceptable for this route. The extra query constrains both `tenant_id == tenant.id` and `customer_key == ...`; with the session already bound to the viewer's tenant, that is the right app-layer scope and RLS remains the backstop.
- 2. `_order_count is None`: acceptable silent fallback. Returning `null` is safer than fabricating a reason for anomalous data, and I do not see a DoD reason to warn here.
- 3. Route test seeding: safe under this harness. `app_client` rebuilds a fresh migrated schema per test in [tests/conftest.py](/Users/noelsaw/Documents/GitHub-Repos/LTVera-Pandas/tests/conftest.py:46), so the fixed customer key does not accumulate state across runs.
- 4. `posture_band_label`: fine to leave exported and tested as a utility. It no longer blocks the ship path now that the route serves `posture_reason`.
**Commit:** self (final HEAD; message `relay(p25-posture): Reviewer r3`)

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
