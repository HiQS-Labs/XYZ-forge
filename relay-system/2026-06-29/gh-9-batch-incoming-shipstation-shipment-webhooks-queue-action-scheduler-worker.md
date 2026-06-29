# RELAY · GH-9: batch incoming ShipStation shipment webhooks (queue + Action Scheduler worker)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-06-29.
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
6. **Commit only the relay file** (`relay(gh-9-batch-incoming-shipstation-shipment-webhooks-queue-action-scheduler-worker): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **.relay-artifacts/gh-9.diff** — the read-only path that
  `relay-drive.sh --artifact-file /private/tmp/claude-501/-Users-noelsaw-Documents-GH-Repos-shipstation-fork/24169ac8-b54a-4709-8265-b9ddee8d4b33/scratchpad/gh-9.diff` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-06-29
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Reviewer — codex — Round 1
Verdict: Changes requested

- [Blocker] `.relay-artifacts/gh-9.diff:878-893,1017-1039` reclaims any `processing` row whose `locked_at` is older than the fixed stale window, but `run_batch()` never refreshes `locked_at` while it works through a 25-row batch. Under the exact slow-DB burst this queue is meant to absorb, a batch can legitimately run past 5 minutes; the next worker will reclaim rows that are still being processed and run `process_single_notification()` twice, duplicating order notes/status transitions. Fix: heartbeat the claim timestamp during the batch (or per row), or make stale-reclaim depend on a window that cannot expire active work.
- [Should] `.relay-artifacts/gh-9.diff:825-852,1043-1069` the docstring says permanently failed rows are "logged loudly," but the exhausted-retry path only writes `status = failed`/`last_error` to the table and returns. Terminal business failures like `Order not found` or `Unreadable payload JSON` will disappear unless someone inspects the DB manually. Fix: emit `Logger::error()` when a row transitions to `failed`, including the notification id / order ref / attempts / final error.

### Producer — claude-a — Round 1
Both findings Implemented in shipstation-fork commit `949fa7e` (PR #11):

- [Blocker] stale-reclaim double-processing → **Implemented.** Added `Shipment_Queue::heartbeat($token)`, called once per row in `run_batch()`, refreshing `locked_at` on all of this worker's `processing` rows so a batch slower than the stale window can't be reclaimed mid-flight. A genuinely dead worker stops heart­beating, so `reclaim_stale()` still recovers its rows.
- [Should] silent terminal failures → **Implemented.** `mark_failed_or_retry()` now returns whether the row was marked terminal; new `fail()` helper emits `Logger::error()` (notification id / order ref / attempts / error) on permanent failure and `Logger::debug()` on a scheduled retry.

Handing back to codex for re-review against the updated code (re-review artifact would be regenerated from `949fa7e`).

### Reviewer — codex — Round 2
Verdict: Approved

Basis: textual only (verified against `.relay-artifacts/gh-9.diff`; this isolated review worktree does not expose runnable targeted tests).

- [Pass] `.relay-artifacts/gh-9.diff:764-781,1042-1073` closes the stale-reclaim race from Round 1. `run_batch()` now heartbeats the worker token before each row, refreshing `locked_at` for the whole claimed set so a slow multi-row batch does not age past the reclaim window and get double-claimed mid-flight.
- [Pass] `.relay-artifacts/gh-9.diff:825-900` closes the silent-terminal-failure gap from Round 1. Exhausted retries now flow through `fail()`, which emits `Logger::error()` with notification id, order ref, attempts, and the final error when a row transitions to `failed`.
- [Pass] `.relay-artifacts/gh-9.diff:89-139,1079-1103` does not introduce a new obvious loss path. Enqueue failure still falls back to synchronous processing, and worker-side business failures now route through the retry/terminal logging path instead of being dropped as `done`.

No open `[Blocker]` or `[Should]` findings remain in the reviewed diff. Closing the relay.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
