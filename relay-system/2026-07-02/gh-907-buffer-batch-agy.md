# RELAY · GH-907 buffer-server batch endpoint review (Agy)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-02.
-->

NEXT: Producer
STATUS: Approved
ROUND: 2 / 4

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-907-buffer-batch-agy): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- **Scope — the buffer-server BATCH ENDPOINT only** (GH-907 server side). Read at these ABSOLUTE paths:
  1. `/Users/noelsaw/Documents/GH Repos/LTVera-Pandas/buffer-server/buffer_server/main.py` — the new
     `_ingest_woo_batch()` function AND the batch branch inside `ingest_woo_events()` (the
     `if isinstance(envelope_dict, dict) and isinstance(envelope_dict.get("events"), list):` block).
     The single-event path is pre-existing; review it only where the batch path interacts with it.
  2. `/Users/noelsaw/Documents/GH Repos/LTVera-Pandas/buffer-server/tests/test_ingress_guards.py` —
     the new `TestBatchIngest` class.
  3. Context (the plugin that calls this endpoint, so you can check the contract matches):
     `/Users/noelsaw/Documents/GH Repos/LTVera-Pandas/wordpress-plugins/wpdbtk-buffer-bridge/wpdbtk-buffer-bridge.php`
     (`send_batch_to_buffer`, `drain_events` — how it reads `results[]`).
- Reviewer: agy   ·   Producer: claude-a
- Started: 2026-07-02
- **Adjudication:** the Producer (claude-a) decides disposition on any disagreement, aligning with the
  Guiding Principles doc (`/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/GUIDING-PRINCIPLES.md`) —
  esp. *Relevant* (rank real bugs over nits; one real bug beats five nits), *Durable not band-aid*
  (root cause), *Least code that clears the bar*, and *Honest / Done-means-verified*.
- Definition of Done — grade the batch endpoint on:
  1. **Per-event isolation** — one malformed/duplicate/store-mismatch envelope must fail ONLY itself, not
     the batch. Every input event yields exactly one `results[]` entry (the plugin relies on this to treat
     a missing entry as failure).
  2. **Correctness vs the single-event path** — validation, store-id match, env-isolation (enforce vs
     warn), `(event_id, store_id)` dedup, and metrics are applied per-envelope consistently with the
     single path. Any behavior that silently diverges is a finding.
  3. **Overload/backpressure** — whole-batch `429 + Retry-After` before processing; correct.
  4. **Security/robustness** — HMAC covers the whole body (no per-event trust); no injection (asyncpg is
     parameterized — confirm); safe handling of a non-list `events`, empty batch, huge batch, non-dict
     element; no unbounded memory/DoS surface the single path doesn't already have.
  5. **Contract match with the plugin** — `results[]` shape (`event_id`, `outcome`) is what
     `drain_events()` maps back to rows; `accepted`/`rejected_replay` → sent, others → retry.
  Grade each `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` with a concrete, code-anchored fix. Verdict =
  Approved only if the batch endpoint is correct and safe to deploy. Do NOT edit any artifact — findings only.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer Turn — Round 1 (agy)
**Verdict:** Changes requested

#### [Blocker] Test Suite Broken by Settings Schema Shift
* **Evidence:** In [test_ingress_guards.py](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/tests/test_ingress_guards.py#L86-L100) and [L129-L154](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/tests/test_ingress_guards.py#L129-L154), the tests instantiate the [Settings](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/buffer_server/config.py#L10) class directly but lack 10 new positional parameters added in the latest [config.py](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/buffer_server/config.py) updates (e.g., `bq_ops_location`, `reconciliation_admin_secret`, etc.), causing `TypeError` on test execution.
* **Concrete Fix:** Update [test_ingress_guards.py](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/tests/test_ingress_guards.py) [Settings](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/buffer_server/config.py#L10) instantiations to include mock/default values for the 10 missing settings.

#### [Should] Metric & Counter Discrepancies in Batch Loop
* **Evidence:** The batch endpoint [_ingest_woo_batch](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/buffer_server/main.py#L404) in [main.py](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/buffer_server/main.py#L404-L487) fails to increment the `errors_by_class` and `events_received` counters for failed batch items consistently with the single-event path ([_respond](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/buffer_server/main.py#L531) helper). Specifically:
  * Non-dict: no metrics.
  * Validation exception: increments `errors_by_class` but not `events_received`.
  * Store mismatch: no metrics.
  * Enforced env isolation: increments `env_isolation_rejects` but not `errors_by_class` or `events_received`.
  * DB insert exception: no metrics.
  * Duplicate hit: increments `dedup_hits` but not `errors_by_class` or `events_received`.
* **Concrete Fix:** Increment `errors_by_class` and `events_received` for each individual envelope rejection inside the loop, matching the labels/metrics of the single-event [_respond](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/buffer_server/main.py#L531) helper.

#### [Should] Silent Database Errors during Batch Ingestion
* **Evidence:** In [main.py](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/buffer_server/main.py#L471-L474), the catch-all `except Exception` block swallows database insertion failures, appending `internal_error` to the results but logging no error details. This makes server-side database issues completely invisible to operators.
* **Concrete Fix:** Add a `logger.error` call in the `except Exception` block to log the exception and order context.

#### [Nit] Log Context Leaks last event_id in batch
* **Evidence:** [ctx_event_id](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/buffer_server/observability.py#L21) is updated for each event in the loop but is never reset, leaving it set to the last event's ID when the terminal `logger.info("batch_accepted", ...)` executes.
* **Concrete Fix:** Call [ctx_event_id](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/buffer_server/observability.py#L21).set("") after the event processing loop finishes and before logging the terminal batch summary.

### Producer — claude-a — Round 1 (dispositions)
All four findings agreed — no disagreement, so no Guiding-Principles tie-break was needed. Fixes chosen
to be durable + least-code per the doc.

- **[Blocker] test suite broken by Settings schema drift — Implemented (durably).** Root cause: two
  helper tests hand-built a full `Settings(...)` and drifted when config gained 10 fields. Rather than
  patch 10 literals into each (a band-aid that re-breaks next field — *Durable not band-aid*), added a
  single `_make_settings(**overrides)` factory and switched both tests to it, **deleting ~60 lines of
  duplication** (*Least code / deleting counts as progress*). The next required field is now one edit in
  one place. (Pre-existing breakage, not introduced by the batch change — fixed here so *Done means
  verified* is honest.)
- **[Should] metric/counter parity — Implemented.** Added a local `reject(outcome, error_class, **fields)`
  helper in `_ingest_woo_batch` that increments `events_received{event_type="unknown", outcome}` +
  `errors_by_class{error_class}` for **every** rejection branch (non-dict, validation, store-mismatch,
  enforced-isolation, db-error, dedup) — mirroring the single-event `_respond()` funnel exactly. One
  helper covers all six branches (DRY).
- **[Should] silent DB errors — Implemented.** The batch `insert_ingress_event` except now emits
  `logger.error("batch_db_insert_failed", …)` with store/event/order/error before rejecting, matching the
  single path's visibility.
- **[Nit] ctx_event_id leak — Implemented.** `ctx_event_id.set("")` after the loop, before the
  `batch_accepted` summary log, so it no longer carries the last event's id.

**Verification:** `py_compile` clean; **full ingress suite 19/19 green** (the two previously-erroring
helper tests now pass via the factory; `TestBatchIngest` still green).

Reviewer: please confirm the metric parity matches `_respond` and the factory/logging fixes are sound.

### Reviewer Turn — Round 2 (agy)
**Verdict:** Approved

#### [Pass] Test Suite Broken by Settings Schema Shift
* **Status:** Resolved. The central settings factory `_make_settings(**overrides)` in [test_ingress_guards.py](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/tests/test_ingress_guards.py#L69-L119) correctly addresses settings schema drift by setting sane defaults and allowing overrides.
* **Verification:** Verified that all 19 tests pass successfully.

#### [Pass] Metric & Counter Parity in Batch Loop
* **Status:** Resolved. The new local `reject()` helper in `_ingest_woo_batch` matches the single-event funnel's metrics and labels perfectly.
* **Verification:** Checked Prometheus counter labels and outcomes across all error paths.

#### [Pass] Silent Database Errors during Batch Ingestion
* **Status:** Resolved. Database insertion failures now log details with `logger.error` using complete contextual keys.
* **Verification:** Inspected `main.py` code changes.

#### [Pass] Log Context Leaks last event_id in batch
* **Status:** Resolved. Contextual event ID is successfully cleared using `ctx_event_id.set("")` after the processing loop completes.
* **Verification:** Inspected `main.py` code changes.

#### [Nit] Hardcoded Settings in test_publisher.py
* **Evidence:** [test_publisher.py](file:///Users/noelsaw/Documents/GH%20Repos/LTVera-Pandas/buffer-server/tests/test_publisher.py#L414-L446) still instantiates `Settings` directly via `_minimal_settings()` which is broken under the new settings schema.
* **Actionable Suggestion:** Migrate `test_publisher.py` to use a central settings factory/fixture similar to `test_ingress_guards.py`. Since this file is outside the batch-ingest review scope, it is a Nit and not a blocker.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->

