---
Goal: QA Phase 1 Plan for Jog Skill and Serial Queue
Date: 2026-08-26
NEXT: Reviewer
STATUS: Open
---

# Context

Adjudicate the Phase 1 plan for the `jog` skill and serial execution engine in `PROJECT/1-INBOX/GH-259-JOG-SERIAL-QUEUE.md` against the existing harness architecture (`relay-automation/`, `bin/tick`, `utils/py/releases_app.py`, `utils/py/marathon_plan.py`).

Read in full:
- `PROJECT/1-INBOX/GH-259-JOG-SERIAL-QUEUE.md` (the plan)
- `skills/relay-xyz/SKILL.md` (driver lock matrix, single driver per clone invariant)
- `utils/py/rtl.py` or `relay-automation/driver-lock-lib.sh` (driver lock resolution)
- `relay-automation/relay-drive.sh` (single-phase execution path)
- `utils/py/releases_app.py` (roadmap & releases DB operations)

Questions:

1. **State representation:** Is storing jog entries directly as a ledger tier in SQLite (`releases.db`/`releases.sql`) with a `jog` marker and integer queue position sound, or does it risk schema/query conflicts with the roadmap and release manifests?
2. **Driver lock interaction:** The plan specifies holding the repository driver lock across the entire serial `jog run` loop. Does holding the driver lock across multiple consecutive task pop-and-drive iterations pose any deadlock, stale lock, or orphan worktree hazards?
3. **Preflight & already-landed probe:** Is calling `swarm-preflight --gh-issue <n>` at pop time sufficient to catch duplicate or landed tasks before dispatching the single-phase drive?
4. **Overlap check safety:** Is the assumption sound that for a strictly serial queue, write-set collision analysis is unnecessary for execution safety (and only valuable as an advisory sort hint and staleness flag)? Are there edge cases where serial tasks touching the same files could cause uncommitted git state conflicts or test contamination?
5. **Capture & Trigger ergonomics:** Are the proposed conversational triggers (`"jog GH-123"`, `"jog task above"`) and deferring full preflight contract verification to fire time aligned with the issue-first SOP and PDDA intake lifecycle?
6. **What is missing or over/under-engineered?** Flag any architectural gaps, missing error recovery paths, or unnecessary complexity in the Phase 1 specification.

Flag anything wrong, missing, incorrectly scoped, or over/under-engineered. Be concrete and cite file:line where you disagree with a specific claim.

Write your verdict below. Set `STATUS: Approved` if sound as written, or leave it Open with `**Verdict:** Changes requested` and say exactly what must change.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex review — 2026-08-26

**Grade:** F

**Verdict:** Changes requested

### Blocking findings

1. **The plan under review is absent, so this relay is not reviewable as assembled.** The thread
   requires the reviewer to read `PROJECT/1-INBOX/GH-259-JOG-SERIAL-QUEUE.md` in full
   (`relay-system/2026-08-26/gh259-jog-plan-qa.md:10-17`), but that path does not exist in this
   checkout (nor does any `PROJECT/**/GH-259-*` path). I cannot cite or approve claims in an
   unavailable artifact. Commit/seed the exact plan into the review worktree and rerun this QA.
   The remaining findings below grade only the architectural propositions stated in this relay;
   they do not substitute for the missing plan review.

2. **Do not encode an independent execution queue as another `roadmap_items` tier without first
   resolving the table's identity and lifecycle conflict.** `roadmap_items` permits only one row per
   `(repo_id, gh_number)` (`utils/py/releases_app.py:584-600`), defines `position` as ordering *within
   a roadmap section* (`utils/py/releases_app.py:590-592`), and defines `status_marker` as the
   entry's leading display marker, not an execution state (`utils/py/releases_app.py:592-598`). Thus
   GH-123 cannot simultaneously retain its canonical parked/active roadmap pointer and gain a
   second jog row. Moving the one row into a Jog section instead would make an execution action
   mutate PDDA portfolio state and would conflate queue state with `raw_text` display state. The dump
   and rebuild paths also enumerate this schema explicitly (`utils/py/releases_app.py:1023-1042`,
   `3686-3698`), so an informal marker is not a harmless extension. Phase 1 must either (preferred)
   add a separate `jog_queue` relation keyed to the canonical issue/roadmap identity, or specify a
   fully tested one-row transition model that preserves roadmap coverage and history. Release
   manifests are a separate relation; they are not the direct collision here.

3. **The queue needs durable claim/lease state; removing the head before driving loses work on a
   crash.** The DB already provides short, atomic writer transactions and crash-recovery journaling
   (`utils/py/releases_app.py:1146-1229`). Use that machinery for transitions such as
   `pending -> running -> succeeded|parked`, persisting attempt count plus the task/branch/PR identity.
   Never hold the RELEASES writer lock while preflight or a model turn runs. On restart, reconcile a
   `running` row before selecting another item; on every nonzero preflight/drive result, retain or
   park the row with the reason rather than silently popping it. The plan must define SIGINT/SIGTERM,
   crash, and resume behavior and an operator-visible retry/skip policy.

4. **Holding the repo driver lock for the whole serial run is viable only as an explicit outer-driver
   composition.** The established pattern acquires the shared lock, writes its PID, exports
   `RELAY_DRIVER_LOCKED=1`, and registers exit cleanup (`utils/py/marathon_drive.py:835-887`); nested
   `relay-drive` then inherits that environment. Without the export, the child sees the parent's
   live PID and refuses itself (`utils/py/relay_drive.py:420-479`). The plan must reuse
   `rtl.driver_lock_path`, own cleanup once, and invoke only nested drivers that honor this contract.
   It must also say that a long queue intentionally starves every other relay/marathon in that clone,
   and stop before the next item if a turn leaves an unresolved worktree/token/branch. The lock is
   not a queue lease and does not replace finding 3.

5. **`swarm-preflight --gh-issue N` is necessary but not sufficient as the sole duplicate/landed
   check.** It refuses an issue unless a matching capture has already been promoted to
   `PROJECT/2-WORKING` (`utils/py/swarm_preflight.py:1141-1152`), so a merely parked `1-INBOX` item
   will deterministically block at the head of the queue. Its `STALE` verdict is derived only from
   the capture's declared `fix_probes` (`utils/py/swarm_preflight.py:181-230`, `1542-1604`), while a
   CLOSED source issue is explicitly advisory (`utils/py/swarm_preflight.py:1663-1670`). It does not,
   by that call alone, prove that no equivalent open PR/branch or duplicate queued row exists. Keep
   the fresh pop-time preflight, but add deterministic queue deduplication, define the CLOSED/open-PR
   policy, validate probe presence/quality, and map every preflight exit to skip/park/halt behavior.

6. **Serial execution removes simultaneous write/write races, not dependency and integration
   hazards.** Write-set overlap can remain advisory for scheduling, but each item must preflight
   against the state produced by the prior *landed* item. If Jog merely opens several unmerged PRs,
   later same-file work is not based on earlier work and merge conflicts are deferred, not removed.
   Specify one of: land/re-anchor `development` between items, or an explicit stacked-branch strategy.
   Require a clean boundary and successful isolated-worktree cleanup before advancing; stop on
   containment failure. Also keep the repository rail that full gates run only in a separate full
   clone: serial worktrees share git state and do not prevent test contamination.

7. **The capture triggers need a deterministic issue identity and a two-stage validation contract.**
   `jog GH-123` is sound only after resolving the canonical repo, existing capture, and unique roadmap
   row. `jog task above` must echo the resolved issue/title for confirmation and, when no issue exists,
   perform issue-first capture plus immediate roadmap parking before enqueueing; conversational text
   is not durable queue identity. PDDA says an inbox capture is not active work and must be promoted
   when execution starts (`PROJECT/PDDA.md:264-278`). Therefore do cheap identity/lifecycle checks at
   enqueue time, then full freshness/probe preflight at fire time. Define how an unready head is
   parked or skipped so one rough capture cannot deadlock every later runnable item.

8. **The plan must state the per-item shipping boundary and final review.** Each task needs an owned
   branch/PR targeting `development`, recorded gate evidence for its final commit, and an outer
   reviewer check of base branch, diff size, and verification before the queue advances. Without
   that, “serial” describes dispatch order but not when an item is complete enough for the next item
   to consume its state.

### Exact changes required before re-review

1. Make the canonical GH-259 plan available in the relay worktree.
2. Separate roadmap identity from Jog runtime state (or fully specify and test a lossless one-row
   transition model), including dump/rebuild migration coverage.
3. Add durable pending/running/terminal transitions, crash recovery, retry/park/skip rules, and
   short DB-lock boundaries.
4. Specify outer driver-lock ownership plus `RELAY_DRIVER_LOCKED=1` nesting and cleanup.
5. Define promotion, dedupe, closed/open-PR, preflight-exit, branch/landing, re-anchor, and
   verification policies before advancing the queue.
