---
title: "GH-564: work backfill from ledger state + a review_ready producer in reconcile (GH-549 follow-up)"
status: Working
created: 2026-09-10
updated: 2026-09-10
owner: unassigned
goal: one small PR that (1) projects the roadmap's EXISTING state onto the board through a `work backfill` verb, and (2) makes `work reconcile` emit `review_ready` for issues closed by open non-draft PRs — both as ordinary `perform_write` callers via `work emit`
gh_issue: 564
source: https://github.com/HiQS-Labs/XYZ-forge/issues/564
doc_type: feature
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/549
  - https://github.com/HiQS-Labs/XYZ-forge/pull/559
context_tags: [work-events, board, connector, backfill, reconcile, GH-549]
non_goals:
  - Two-way sync
  - Inferring review-ready from anything other than an actual open PR
  - Touching githooks/pre-push
  - A second write path — every emission is `work emit` through `perform_write`
effort: 5
complexity: 2
risk: 2
---

# GH-564 — the two gaps #559 shipped with, stated in its own PR body

## Status

| What was just completed | What's next |
|---|---|
| Issue #564 filed; clone `~/task-clones/xyzforge-gh564-backfill` at `59b692b2` on `feat/gh564-work-backfill-review-ready`, **stacked on #559's head** | Park + rate, recon the two seams, plan, Codex plan QA, build |

## Why

#559 ships the event stream and the connector. `work_events` begins at migration 008, so
`reconcile --reset` catches up only what was emitted *after* it lands — the roadmap's ~170 rated
issues, every 🚧 and every ✅ never produce an event and sit off the board until touched again.
"No historical backfill" was a #549 non-goal; here it is the goal.

Separately, `review_ready` is a mapped column in `github_board.py` with **no producer**: the
pre-push emitter was withdrawn in plan QA (the hook cannot know the PR), and the plan text saying
`reconcile` derives it never became code. The column exists; nothing moves a card into it.

## Dependency

Stacked on #559. Base is `59b692b2` = `feat/gh549-work-events-connectors` after its merge with
`development`. This PR targets `development` but cannot merge before #559 does; on #559's merge,
rebase onto `origin/development`.

## Acceptance — see the issue; summarized

1. `work backfill --dry-run` lists every row + intended event, writes zero rows (receipt count and
   `work_events` count both unchanged).
2. `work backfill` twice: second run emits zero new events.
3. Every backfill event has a `work-emit` receipt; `releases check` clean after.
4. `work reconcile` + offline mock + one open non-draft PR closing #N → card N reaches
   `review_ready`; again → nothing new. Draft PR → nothing. PR closing nothing → nothing.
5. Red controls: strip the "already review_ready" guard → duplicate emitted; fake `gh` exits 1 →
   reconcile still replays, exit 0.

## Rating — 2026-09-10

`rated 70/40/50/80`. **Priority 70:** without backfill the board #559 ships is empty for every
existing issue, so the feature's value is gated on this; and `review_ready` is a column that
nothing can reach. **Severity 40:** missing function, not a defect — nothing is lost or corrupted
and `reconcile` already catches up post-merge events. Recurrence: n/a (new). **Appeal 50:** neutral,
no operator preference given. **Effort 80:** both verbs are `perform_write` callers via the
existing `work emit`; the seams, the mock, the suite and the extractor registry all exist.

## Recon — `59b692b2`, grep + reads, single lane (subsystem traced in full earlier today for #549)

| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| `cmd_work_emit` | `utils/py/releases_app.py:4845-4882` | the ONE write path; `perform_write(..., "work-emit", None, mutate, work_event=(event, gh, payload))` | either new verb inserts `work_events` directly instead of calling this |
| `cmd_work_reconcile` | `:4887-4930` | `work_connectors.dispatch(..., reset=)`; the connector lock | the review-ready scan runs *inside* the lock (it must run before dispatch, outside it) |
| `NON_EVENT_OPS` / `extractor_for` | `:1380-1440` | registry totality test derives ops from source | a new op literal not registered → suite fails (by design); backfill reuses op `work-emit`, so no new op |
| `roadmap_items` state | `section` × `status_marker`, live: Completed/✅ 52 · Queue/🆕 48 · **Completed/🆕 40** · Completed/🚧 7 · In progress/🆕 5 · … | backfill mapping | marker treated as authoritative → 40 completed items land in Todo |
| `merge_cleanup.linked_issues(pr)` | `skills/merge-cleanup/scripts/merge_cleanup.py:198-211` | `CLOSES_RE` on title+body | import path — a skill script, not on `sys.path`; import by file path as the suite already does |
| `XYZ_BOARD_SYNC_GH_BIN` | `utils/py/board_sync.py:255` | which `gh` runs | the mock speaks only `api graphql`; a `pr list` call to it is an error |
| `github_board.DEFAULT_STATUS_MAP` | `utils/py/work_connectors/github_board.py:60-68` | `review_ready` → "In review" | the mock has no "In review" column → `option_id_for` raises; the test config must map it to an existing column |

**Unknowns:** none that change the plan. The one judgment call — section vs marker precedence —
is decided below from the live distribution, not guessed.

## Plan

### Backfill mapping — section wins for Completed, marker otherwise

| ledger row | event | why |
|---|---|---|
| section `Completed` (any marker) | **`completed`** — a new event name, *not* `pr_merged` | closeout writes the section; 40 rows carry a stale 🆕 from the #424 marker bug. **Codex r1:** `pr_merged` asserts a merge the snapshot did not witness — the same argument that removed marker→merged from the live stream in #549. `completed` says exactly what the ledger claims and no more. `DEFAULT_STATUS_MAP` gains `"completed": "Done"`, so it lands in the same column by default; a user who wants them distinguishable maps it elsewhere. |
| marker 🚧, or section `In progress` | `in_flight` | either signal is the work-start claim |
| marker 🆕 / empty, rated | `rated` | |
| marker 🆕 / empty, unrated | `parked` | |
| section `Deferred …` | *(none)* | a deferred item has no column; skipped, counted in the summary |

Payload on every backfill event: `{"source": "backfill", "section": …, "marker": …}`. Provenance
only — the event *name* is what carries the claim, which is why Completed gets its own.

### Idempotence — decided INSIDE the writer transaction, not before it (Codex r1)

The check is "the row's latest `work_events` event already equals the intended one" — and it runs
**inside `mutate`**, which `perform_write` executes after taking `WriterLock` and after
`BEGIN IMMEDIATE`. A read before `perform_write` would let two concurrent backfills (or a backfill
and a reconcile) both see the same stale latest event, serialize their writes, and each emit a
duplicate. Inside the transaction the read and the decision are atomic with the write.

Mechanism, reusing what exists rather than adding to `perform_write`: when the latest event already
matches, `mutate` raises `_AlreadyRecorded`. `perform_write`'s existing abort path
(`releases_app.py:1613-1625`) rolls back, clears the journal, and re-raises **before** any receipt
or generation bump — so a skip leaves no trace on the chain. The caller catches it and counts a
skip. One helper carries this: `_emit_work_event(root, conn, event, gh, payload, unless_latest_in=())`;
`cmd_work_emit` becomes its first caller, `backfill` and the review-ready scan its second and third.

A second run therefore emits zero. A row whose state changed since the last backfill emits again.
`--dry-run` prints the full table (gh, section, marker, → event, or `skip: already <event>` /
`skip: deferred`) and returns before touching `perform_write` at all.

### `review_ready` in `reconcile` — before dispatch, outside the lock, fail-soft

1. `XYZ_WORK_CONNECTORS=0` → skip the scan, as everything else.
2. `gh pr list --state open --json number,isDraft,title,body --limit 200` via
   `XYZ_BOARD_SYNC_GH_BIN` (default `gh`). Non-zero exit, missing binary, or bad JSON → print the
   reason once, continue to replay. **Never fails the verb.**
3. For each non-draft PR, `linked_issues(pr)`; for each issue, `_emit_work_event(..., "review_ready",
   n, {"pr": num}, unless_latest_in=("review_ready", "pr_merged"))` — the same transactional guard
   as backfill, so a concurrent reconcile cannot double-emit either.
4. Then the existing dispatch.

### Files

| File | Change |
|---|---|
| `utils/py/releases_app.py` | `_emit_work_event(root, conn, event, gh, payload)` (the shared in-process body `cmd_work_emit` becomes a caller of); `_latest_event(conn, gh)`; `_backfill_event_for(row)`; `cmd_work_backfill`; the scan step in `cmd_work_reconcile`; `work backfill` subparser |
| `utils/py/work_connectors/github_board.py` | `DEFAULT_STATUS_MAP["completed"] = "Done"` |
| `test/gh549-work-events.sh` | legs 21–23, each check with its own red control — the table below |
| `PROJECT/2-WORKING/GH-564-…` | this doc |

### Every check and its red control (Codex r1 — none may be vacuous)

| # | Check | Red control (mutation → observed failure) |
|---|---|---|
| 21a | `backfill --dry-run` writes zero rows, zero receipts | mutate the dry-run early return away in an imported copy → rows appear |
| 21b | mapping: Completed/🆕 → `completed`; 🚧 → `in_flight`; 🆕 rated → `rated`; 🆕 unrated → `parked`; Deferred → skip | fixture rows constructed for each cell; swap section/marker precedence in the copy → the Completed/🆕 row emits `parked` |
| 21c | second `backfill` emits zero | strip `unless_latest_in` in the copy → second run duplicates every row |
| 21d | every event has a `work-emit` receipt; `check` clean | count receipts == count events added; `check` rc 0. Red: the existing receipt-chain control (leg 7) already proves `check` detects a broken chain — cited, not duplicated |
| 21e | **concurrency:** two `backfill` processes fired together with a barrier stub produce exactly N events for N rows, not 2N | move the latest-event read *before* `perform_write` in the copy → 2N |
| 22a | open non-draft PR closing #N → card N reaches the `review_ready` column (mock, mapped to "Todo" since the mock has no "In review") | wrapper `gh` returns the PR as `isDraft: true` → no event, card unmoved |
| 22b | draft PR → nothing; PR closing nothing → nothing | inverse of 22a: flip `isDraft` false → event appears; add `Closes #N` to the body → event appears |
| 22c | second `reconcile` → zero new `review_ready` | strip `unless_latest_in` → duplicate |
| 22d | wrapper `gh` exits 1 → `reconcile` prints the reason, still replays, exit 0 | remove the try/except in the copy → rc ≠ 0 |
| 22e | `XYZ_WORK_CONNECTORS=0` → no scan, no `gh` call (sentinel) | unset → sentinel appears |
| 23 | `completed` is in `DEFAULT_STATUS_MAP` and maps to Done; unmapped by a user's `""` override | `column_for` probe as in leg 17 |

### Non-goals (from the issue)
Two-way sync; inferring review-ready from anything but an open PR; the pre-push hook; any new
write path.

### Rollback
Two verbs, no schema change, no new table. Revert the commit.
