# RELAY · GH-907 batch-drain code review (QA + does-it-fix)
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
6. **Commit only the relay file** (`relay(gh-907-code-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- **Artifacts under review (read them at these ABSOLUTE paths — working tree, uncommitted):**
  1. Plugin batch-drain (primary): `/Users/noelsaw/Documents/GH Repos/LTVera-Pandas/wordpress-plugins/wpdbtk-buffer-bridge/wpdbtk-buffer-bridge.php` (v0.2.1)
  2. Buffer-server batch ingest: `/Users/noelsaw/Documents/GH Repos/WP-DB-Toolkit/buffer-server/buffer_server/main.py` (`_ingest_woo_batch`, batch branch in `ingest_woo_events`)
  3. Buffer-server tests: `/Users/noelsaw/Documents/GH Repos/WP-DB-Toolkit/buffer-server/tests/test_ingress_guards.py` (`TestBatchIngest`)
  4. The plan for context: `/Users/noelsaw/Documents/GH Repos/LTVera-Pandas/PROJECT/2-WORKING/GH-907-BUFFER-BRIDGE-FLOOD.md`
  5. Original issue thread for the problem statement: `/Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/relay-system/2026-07-02/gh-907-plan-review.md` (embedded plan + Codex's prior findings)
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-07-02
- **Tie-break rule:** if the Reviewer and Producer disagree on a finding, the deciding authority is
  `/Users/noelsaw/Documents/GH Repos/LTVera-Pandas/AGENTS.md` (this session's governing repo; the
  buffer-server piece is additionally governed by `/Users/noelsaw/Documents/GH Repos/WP-DB-Toolkit/AGENTS.md`).
  Cite the specific AGENTS.md rule when it settles a tie.
- Definition of Done — grade on:
  1. **Does it fix GH-907?** The flood was one Action-Scheduler job + one blocking POST per order event,
     plus a self-amplifying sweep/rate-limiter. Confirm the new design actually removes that: per-event
     enqueue gone, one recurring batch-drain, sweep no longer re-enqueues per row.
  2. **Correctness of the atomic claim-with-lease** (`claim_due_rows`): is the `UPDATE … ORDER BY id LIMIT`
     + token select genuinely race-free across concurrent drains? Can any row be sent twice or stranded?
     Is the lease/reclaim (`status IN ('pending','retry','claimed') AND next_attempt_gmt <= now`) correct?
  3. **Coalesce-by-order_id** settlement: are superseded same-order rows always settled with their
     representative (never stranded, never double-counted)? Is the "not itemized ⇒ mark sent" fallback safe
     given server-side `(event_id, store_id)` dedup?
  4. **Backpressure**: does the 429 drain-pause actually stop the flood (release without bumping attempts,
     no new per-row actions), and resume correctly?
  5. **Server batch endpoint**: per-event isolation (one bad envelope doesn't fail the batch), dedup,
     whole-batch overload 429, single-event path untouched. HMAC over the batch body correct?
  6. **QA**: SQL-injection safety of the interpolated `IN (...)`/`LIMIT` (are they `$wpdb->prepare`d?),
     error handling, DB migration safety (`maybe_upgrade_schema`), no data-contract change to payloads.
  Grade each `[Blocker]`/`[Should]`/`[Nit]`/`[Pass]` with a concrete, code-anchored fix. Verdict =
  Approved only if it fixes GH-907 and is safe to stage. Do NOT edit any artifact — findings only.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
