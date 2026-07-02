# RELAY · GH-907 Buffer Bridge flood plan review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-02.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 4

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
6. **Commit only the relay file** (`relay(gh-907-plan-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **GH-907-BUFFER-BRIDGE-FLOOD.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-02

### Artifact — GH-907-BUFFER-BRIDGE-FLOOD.md
```
---
title: "Buffer Bridge floods Action Scheduler & drives server into critical load"
gh_issue: 907
source: https://github.com/BinoidCBD/universal-child-theme-oct-2024/issues/907
status: "Proposed (1-INBOX — not yet active)"
created: 2026-07-02
updated: 2026-07-02
doc_type: bugfix
effort: medium
complexity: medium
risk: medium
phases: 1
related:
  - PROJECT/2-WORKING/P1-BUFFER-SERVER.md
---

<!-- 1-INBOX capture per PDDA issue-first SOP (PROJECT/PDDA.md "GitHub issue intake").
     Foreign-repo issue: it lives in BinoidCBD/universal-child-theme-oct-2024, NOT origin
     (BinoidCBD/LTVera-Pandas), so `source:` disambiguates the bare GH-907. This doc is the
     in-repo CAPTURE, not the active-work doc — no `## Status` table while it sits in 1-INBOX.
     The canonical, prod-matching plugin source (v0.2.0) is git-tracked IN THIS repo under
     wordpress-plugins/; a stale v0.1.1 fork also sits in Hypercart-Dev-Tools/WP-DB-Toolkit. -->

# GH-907 — WPDBTK Buffer Bridge floods Action Scheduler

## Where this lives (cross-repo)

- **Filed in:** `BinoidCBD/universal-child-theme-oct-2024#907` (the theme team's catch-all tracker).
  `wpdbtk_*` has **zero hits** in that theme tree — the flood is not theme code.
- **Owning code (two diverged copies — reconcile before fixing):**
  - `LTVera-Pandas/wordpress-plugins/wpdbtk-buffer-bridge/wpdbtk-buffer-bridge.php` — **v0.2.0**
    (`const VERSION = '0.2.1'`), **git-tracked in THIS repo**, matches the production source #907
    reviewed. This is the copy to fix.
  - `Hypercart-Dev-Tools/WP-DB-Toolkit` (Plugin URI) → same path — **v0.1.1**, stale fork, behind prod.
  - The Buffer Server is our project (`PROJECT/2-WORKING/P1-BUFFER-SERVER.md`) and this plugin is its
    WooCommerce feeder, so the fix lands here in LTVera-Pandas; WP-DB-Toolkit should then be re-synced.
- **Impact:** single biggest driver of Bloomz server overload — **~38–41% of all delayed background
  jobs** on Jul 1–2 2026, peaking in the worst load windows. Up to **102 jobs queued in one second**;
  peak DB queue depth **1,231**. Self-perpetuating under backpressure (see below).

## The ask (actionable substance from #907)

Rework the plugin's outbound path so it **batches** and **backs off** instead of spraying one
blocking HTTP POST per order event. No change to *what* data is sent — outbound payload stays a full
order snapshot; only the *scheduling* changes. Five concrete fixes requested:

1. **Batch drain.** Replace per-event `as_enqueue_async_action` with a **single recurring drain
   action** that claims N due rows and POSTs them as **one** request to `/ingest/woo/events` (the
   endpoint is plural — appears built for batches). Collapses thousands of tiny jobs into a handful.
2. **Coalesce event types per `order_id`** before sending — each payload is already a full snapshot,
   so `order_created` / `order_updated` / `order_status_changed` for the same order send once.
3. **Atomic row-claim** in the processor to prevent duplicate sends.
4. **Make the sweep claim rows** (advance next-attempt / set a claimed state) so it can't re-enqueue
   duplicate jobs during a backlog.
5. **Load-aware pause** — back off while server load is `elevated`/`critical` instead of forcing
   flushes through at the worst possible moment.

### Acceptance criteria
- Order-write bursts no longer produce 1 Action-Scheduler job per event (batched drain visible).
- Sweep + rate-limiter no longer *increase* job count under backpressure (no duplicate enqueues).
- Outbound data contract to the buffer server is unchanged (byte-for-byte snapshot).

## Code review — confirmed against the v0.2.0 source (this repo)

Reviewed `wordpress-plugins/wpdbtk-buffer-bridge/wpdbtk-buffer-bridge.php` **in LTVera-Pandas**
(v0.2.0 = production). Line refs below are that file. Every claim in #907 holds:

| Claim in #907 | Confirmed in v0.2.0 source |
|---|---|
| One row + one async action per event, no batching | `flush_pending_events` → `queue_event_for_order` → `insert_queue_row` + `schedule_queue_item($id, 0)` → `as_enqueue_async_action` per row |
| One blocking HTTP POST per row | `process_event` → `send_payload_to_buffer` → `wp_remote_post(... '/ingest/woo/events')`; endpoint plural ✓ |
| `woocommerce_update_order` is the volume driver | hooked → `handle_updated_order`; `wp_after_insert_post` on `shop_order` also emits |
| Sweep re-enqueues without claiming | `sweep_due_events` (line ~320) SELECTs due `pending`/`retry` rows (LIMIT 25) and calls `schedule_queue_item` **without advancing `next_attempt_gmt` or claiming** → duplicate jobs. **Byte-identical to v0.1.1 — the bug survived the upgrade.** |
| Self-amplification under throttle (#907 detail #2) | **present in v0.2.0**: `process_event` → `check_outbound_rate_limit()` → `defer_queue_row()` *reschedules a new async action* instead of pausing (`schedule_queue_item` at end of `defer_queue_row`) |
| No **server-load**-aware pause | Confirmed absent. v0.2.0 added a *client* rate limiter (count/interval per minute), but nothing keys off server load `elevated`/`critical` — so it still forces flushes through under DB stress |
| Within-request de-dup exists (partial mitigation) | `mark_pending_event` coalesces by `event_type:order_id` **within one request** — but concurrent requests each still flush independently on `shutdown`, which is the 102/sec dogpile mechanism |

## What v0.2.0 already added (and what it did *not* fix)

v0.2.0 is a substantial upgrade over v0.1.1 — admin page, WP-CLI, metrics counters, WC logging,
`/order-stats` endpoint, keyset-cursor reconciliation, and a **client-side outbound rate limiter**
(`check_outbound_rate_limit` / `defer_queue_row`, capped `WPDBTK_BUFFER_MAX_OUTBOUND_PER_MINUTE`,
default 30/min). **But none of the three flood roots were addressed:** still one job per event (no
batch drain), the sweep still can't claim rows, and the new rate limiter *reschedules* rather than
pauses — i.e. it is the very mechanism #907 calls self-amplifying. So all five fixes above still apply.

## ⚠️ Two-copy divergence — reconcile before acting

- `LTVera-Pandas/wordpress-plugins/…` = **v0.2.0** (`const VERSION = '0.2.1'`), git-tracked here,
  matches the production source #907 reviewed. **← fix this copy.**
- `Hypercart-Dev-Tools/WP-DB-Toolkit/…` = **v0.1.1**, stale fork, behind prod.
- Minor real bug in v0.2.0: header `Version: 0.2.0` but `const VERSION = '0.2.1'` — the emitted
  payload `plugin_version` reports `0.2.1` while the plugin list shows `0.2.0`. Align them.

## Suggested next steps (on promotion)

1. Fix against the **LTVera-Pandas v0.2.0** copy (canonical/prod), then re-sync the stale
   `WP-DB-Toolkit` v0.1.1 fork so the two stop diverging.
2. Open the fix issue where the code is driven from. #907 (theme repo) stays the cross-team
   back-reference.
3. Promote this doc to `PROJECT/2-WORKING/` if/when LTVera drives the plugin fix; otherwise keep it as
   an inbox tracker and close when the batch-drain fix ships.

## References
- Issue: https://github.com/BinoidCBD/universal-child-theme-oct-2024/issues/907
- Full plugin code review comment: https://github.com/BinoidCBD/universal-child-theme-oct-2024/issues/907#issuecomment-4870546590
- Buffer Server project doc: [P1-BUFFER-SERVER.md](../2-WORKING/P1-BUFFER-SERVER.md)
- Plugin source (canonical, v0.2.0): `wordpress-plugins/wpdbtk-buffer-bridge/wpdbtk-buffer-bridge.php` (this repo)
- Stale fork (v0.1.1): `Hypercart-Dev-Tools/WP-DB-Toolkit/wordpress-plugins/wpdbtk-buffer-bridge/…`
```
- Definition of Done — grade the embedded plan on these, **verifying against the real plugin source**
  at absolute path `/Users/noelsaw/Documents/GH Repos/LTVera-Pandas/wordpress-plugins/wpdbtk-buffer-bridge/wpdbtk-buffer-bridge.php`
  (v0.2.0, `const VERSION='0.2.1'`, ~1577 lines — read it directly):
  1. **Root-cause accuracy** — does the "one row + one async action + one blocking POST per event, no
     batching" diagnosis actually match the code paths (`flush_pending_events` → `queue_event_for_order`
     → `schedule_queue_item(...,0)`; `process_event` → `send_payload_to_buffer`)? Flag any overstatement.
  2. **Sweep claim** — confirm/deny `sweep_due_events` re-enqueues without claiming/advancing
     `next_attempt_gmt` (duplicate-job risk). Is the "byte-identical to v0.1.1" claim safe to assert?
  3. **Self-amplification** — is `check_outbound_rate_limit()` → `defer_queue_row()` truly
     self-amplifying (reschedules rather than pauses), or is the deferral bounded/safe in practice?
  4. **The five proposed fixes** — are they correct, sufficient, and safe? Any that would break the
     data contract, miss a hook (`woocommerce_update_order`, `wp_after_insert_post`, refund `save()`),
     race under concurrency, or need an index/migration the plan omits? Anything MISSING from the five?
  5. **Two-copy divergence + version-string bug** (header `0.2.0` vs `const '0.2.1'`) — accurate and
     material? Is "fix LTVera copy, re-sync WP-DB-Toolkit" the right call given Plugin URI points at
     WP-DB-Toolkit?
  Verdict = Approved only if the plan is technically sound and safe to promote as-is; else Changes
  requested with concrete, code-anchored fixes. Do NOT edit the plugin or the plan — findings only.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
