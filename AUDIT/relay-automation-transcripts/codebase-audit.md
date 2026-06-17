# RELAY · LTVera-Pandas codebase audit — GCP/scale review

NEXT: Done
STATUS: Approved
ROUND: 2 / 5

## Setup
- Artifact under review: `PROJECT/2-WORKING/CODEBASE-AUDIT-2026-06-14.md`
- Definition of Done: The audit's findings are technically sound, correctly located (`file:line`), and correctly prioritized — with **special scrutiny on the GCP / scale items** where the Reviewer's GCP depth is most additive — and the new **XYZ Recon/Verify 3-way plan** (top section) is sound and runnable. Nothing overstated; any wrong call, wrong venue, or mis-prioritization flagged with evidence.
- Producer: **Claude-A (maintainer, window A)**   ·   Reviewer: **Gemini (window B)**   <!-- IDENTITY LOCK: each holds ONE role for the whole relay; stamp your label in every turn header. A nudge for the other label is not yours (ground rule 2). -->
- Handoff: manual nudge
- Started: 2026-06-14
- Why Gemini: the stack is GCP (BigQuery, GCE, impersonated creds) — Gemini is a genuinely independent model with deep GCP training, so it pressure-tests the BQ-vs-Postgres calls a second Claude pass would share blind spots on.

## Ground rules
1. This file is the single source of truth. If it isn't written here, assume the other agent doesn't know it. The two agents are different tools (Claude and Gemini) and never share memory.
2. **Wrong-window guard — take a turn only if ALL hold, else STOP and write nothing:** (a) `NEXT` names the role you were asked to take; (b) **you are the agent bound to that role** — Setup names it (`Claude-A`=Producer, `Gemini`=Reviewer) and prior `Round N · <Role> · <agent>` headers show that role authored by *you*; (c) you have **not** authored the *other* role's turns; (d) the most recent turn block is **not** your own role. On any mismatch reply `STOP — wrong window: <which check failed>. Nudge the <correct role> window.`
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns. Then update `NEXT`, `STATUS`, `ROUND` at the top. (Only exception: right after committing, fill the hash into your own just-written turn's `Commit:` line.)
4. Stay tight. Findings are graded bullets with `file:line` evidence, not essays.
5. **The Reviewer never edits the artifact.** It proposes graded findings with concrete suggested fixes. The Producer (with the operator) decides each and implements — logging a disposition (Implemented / Modified / Declined + reason) for every one.
6. Grade every finding:  `[Blocker]` must fix to ship · `[Should]` strong recommendation · `[Nit]` optional. Use `[Pass]` for a thing you checked and found sound (evidence it's checked, not assumed).
7. The Reviewer posts a Verdict every turn (and its **Basis**: behaviorally proven vs textual-only — for an audit doc, "textual review of findings against cited code" is expected; flag anything you actually ran). The relay ends on **Approved**. If max `ROUND` ends without it, set `STATUS: Escalated`.
8. End your turn by committing it: `relay(codebase-audit): <role> r<N>`, then fill the hash into your `Commit:` line. If your turn touched no tracked files, write `Commit: none (comments only)`.
9. **One window at a time, clean tree at every handoff.** Both agents share one working tree; the `NEXT` pointer is honor-system, not a lock. Never start while the other window may be editing; never flip `NEXT` with uncommitted changes — commit or stash first.

## Roles
- **Producer (Claude-A)** — wrote the audit; requests review, decides + implements proposals, updates the doc.
- **Reviewer (Gemini)** — reviews against the DoD, proposes graded findings with fixes, sets a verdict. Never edits the artifact.

---
## Log

### Round 1 · Producer · Claude-A · 2026-06-14 15:14 PDT
**Did:** The audit (`CODEBASE-AUDIT-2026-06-14.md`, committed `61a2c2f`) is a full read of `app/` (~17.9K LOC) across 5 dimensions, plus a top **XYZ Recon/Verify 3-way plan**. It was produced by parallel **Claude** reviewers — so a second Claude would share blind spots; you (Gemini) are the independent GCP-savvy second model.
**Review this (against the DoD) — lean into your GCP depth:**
1. **Compute-venue calls (C1).** The audit routes behavioral-signal SQL (basket-affinity self-join, escalation cross-join, percentile windows) from Postgres to **BigQuery** for BQ-mirrored tenants (~1.37M orders), keeping Postgres for small Shopify-only tenants. Is that the right venue split? Are those query shapes genuinely BQ-appropriate and Postgres-hostile at that scale? Is the "17-hour cross-join saturates the GCE VM" failure mode credible?
2. **Whole-table pandas in Celery workers (C2/C3).** `select(Order)` with no LIMIT → DataFrame, and BQ client `SELECT *` → pandas ×7/analysis. Are the proposed fixes GCP-idiomatic (bounded/aggregated queries, column projection, row caps, `create_bqstorage_client=True`, `query_rows` path)? Anything better?
3. **BQ security/correctness (S8).** `project_id/dataset/table` from `connection_config` f-string-interpolated into BQ SQL — is the injection/quoting risk + the Pydantic-validator fix right for BigQuery specifically?
4. **Concurrency (CC1/CC2/CC3).** AnalysisJob off the FSM (at-least-once Celery double-run), transaction-across-HTTP, no in-flight guard — sound? Right severities?
5. **Prioritization** (P0/P1/P2 in §6) and the **recon plan** (top section): is the 3-way lane split runnable, and is the P0/P1/P2 ordering defensible?
**Open questions:** (a) Any GCP-native option the audit missed (BQ scheduled queries, materialized views, BQ BI Engine, Dataflow)? (b) Is "BQ for mirrored / Postgres for small" the right dividing line, or should everything analytical go to BQ?
**Commit:** 4c90bf4 (relay log; audit at 61a2c2f)


### Round 1 · Reviewer · Gemini · 2026-06-14
**Verdict:** Approved (with findings to implement).
**Basis:** Textual review of findings against cited code (`app/signals/compute.py`, `app/etl/bq_warehouse/client.py`, `app/ai/service.py`), leveraging GCP architectural patterns.

**Findings:**
- `[Blocker]` **C1 (Compute Venue):** The 17-hour GCE saturation failure mode is highly credible; Postgres will thrash and lock up on a ~4M row self-join (basket affinity). The fix (route to BQ) is correct. *However*, managing two SQL dialects is a maintainability drag. Consider moving *all* analytical compute to BQ (via scheduled queries or BI Engine), as latency overhead is negligible for async Celery tasks.
- `[Blocker]` **C2/C3 (Pandas/Celery RAM):** `app/etl/bq_warehouse/client.py:160-172` explicitly passes `create_bqstorage_client=False` and does an unbounded `SELECT *`. This will OOM the worker. The proposed fixes (`create_bqstorage_client=True`, bounded queries, and pushing aggregation to BQ) are the exact GCP-idiomatic solutions.
- `[Should]` **S8 (BQ Injection):** `app/etl/bq_warehouse/client.py:157-169`. BigQuery does not support parameterization for identifiers, so f-strings are required. The proposed Pydantic validator (`^[A-Za-z0-9_-]+$`) is correct and necessary to prevent backtick (\`) escaping.
- `[Pass]` **CC1/CC2/CC3 (Concurrency):** The assessment of the FSM bypass in `AnalysisJob` is correct. Adopting the FSM pattern from `SyncJob` is the right architectural model.
- `[Pass]` **Recon Plan & Prioritization:** The 3-way recon plan is safe and runnable due to its strictly read-only and isolated output design. The P0/P1/P2 priorities correctly elevate security/correctness (Phase 12) above DRY refactoring.

**Commit:** 0df1750

### Round 2 · Producer · Claude-A · 2026-06-14 15:26 PDT
**Verified every Gemini claim against live `app/` before deciding** (falsify-first; cited file:line):
- C3/C2 anchor `client.py:160-172` — **confirmed exact:** `SELECT *` @ `client.py:169`, `to_dataframe(create_bqstorage_client=False)` @ `client.py:172` (the only `create_bqstorage_client` occurrence in `app/`). Unbounded whole-table read into pandas as charged.
- S8 anchor `client.py:157-169` — **confirmed:** `_qualified()` @ `client.py:157-158` f-string-interpolates `` `project.dataset.table` ``; bounded `query_rows` path the C3 fix cites exists @ `client.py:188`.
- C1 shapes — **confirmed:** `_BASKET_AFFINITY_SQL` self-join @ `compute.py:33-94`, `_ESCALATION_SQL` cross-join @ `compute.py:269`, `PERCENTILE_CONT` windows @ `compute.py:157-159,317`; the fix's "`decisioning_warehouse.py` adapter already exists" is **true** (file present, 8.6KB).

**Decisions on proposals:** (operator-approved)
- [Blocker] C1 (venue) — **Modified** → operator chose "fold as alternative." Kept the mirrored/small split as the near-term call; added Gemini's all-to-BQ (scheduled queries / MV / BI Engine) as the documented forward-looking end-state + explicit answer to open-question (b), with the verified precondition that small Shopify-only tenants have **no BQ dataset today** so all-to-BQ needs a small-tenant mirror path first. Audit `…AUDIT-2026-06-14.md` C1 fix block. · Proof: textual only (non-executable doc).
- [Blocker] C2/C3 (pandas/RAM) — **Implemented (confirm-only)** → finding matched code exactly; existing audit fixes (`create_bqstorage_client=True`, bounded/aggregated `query_rows`, projection, row caps) already correct, no doc change needed beyond the verified anchors. · Proof: code read @ `client.py:160-172`.
- [Should] S8 (BQ identifier injection) — **Implemented** → enriched the fix rationale per Gemini: BQ has no parameter binding for *identifiers* (values only), so the `_qualified` f-string is structurally unavoidable and the `^[A-Za-z0-9_-]+$` validator (which rejects the backtick) is the sole defense. Audit S8 fix block. · Proof: textual only.
- [Pass] CC1/CC2/CC3 — **Accepted as-is** (Gemini confirmed FSM-bypass assessment; no change). · Proof: matches audit §3.
- [Pass] Recon plan & P0/P1/P2 — **Accepted as-is** (Gemini confirmed read-only/runnable + priority ordering). · Proof: matches audit top section & §6.
**Did:** Two surgical doc edits only (C1 alternative paragraph; S8 rationale). No `app/` code touched — relay edits the audit doc only.
**Verification:** N/A — non-executable artifact (Markdown audit doc). Code claims verified by read at the file:line above; no test/run applicable.
**Re-review this:** Confirm (a) the C1 "fold as alternative" framing faithfully captures your proposal without overstating it (I kept mirrored/small as primary, all-to-BQ as target end-state behind a mirror precondition), and (b) the S8 "no identifier parameterization → validator is sole defense" rationale is accurate for BigQuery. If both land, this is a clean Approved.
**Commit:** 190b8d0


### Round 2 · Reviewer · Gemini · 2026-06-14
**Verdict:** Approved.
**Basis:** Textual review of Claude's modifications to `PROJECT/2-WORKING/CODEBASE-AUDIT-2026-06-14.md` against GCP limitations and the prior proposal.

**Findings:**
- `[Pass]` **C1 (Compute Venue):** The "fold as alternative" framing is accurate. Retaining the mirrored/small split near-term while establishing all-to-BQ as the strategic end-state (contingent on small-tenant BQ provisioning) perfectly balances architectural vision with current infra reality.
- `[Pass]` **S8 (BQ Injection):** The updated rationale correctly identifies BigQuery's limitation regarding identifier parameterization. The Pydantic validator is indeed the required defense.

**Commit:** afcc002

<!-- ↓↓↓  NEXT TURN GOES ABOVE THIS LINE — keep this marker last  ↓↓↓ -->
