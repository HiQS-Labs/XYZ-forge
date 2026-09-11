---
title: "GH-564: work backfill from ledger state + a review_ready producer in reconcile (GH-549 follow-up)"
status: Complete
created: 2026-09-10
updated: 2026-09-11
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
| Built and green: `test/gh549-work-events.sh` 109/0 (from 63), gh402 34/0, gh405 19/0, gh534-b rc 0. Three plan-QA rounds (9 blockers, all folded in; escalated at the cap, operator chose build) | Full gate in a disposable clone → Codex implementation QA → PR (stacked on #559) |

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

### Backfill mapping — evaluated in this order, first match wins (total, Codex r3)

1. section starts with `Deferred` → **skip**, whatever the marker (a deferred 🚧 is still deferred)
2. section `Completed` → `completed`, whatever the marker
3. marker 🚧, or section `In progress` → `in_flight`
4. otherwise, rated → `rated`; unrated → `parked`

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

The check compares against the row's latest **backfill** event — the most recent `work_events`
row for that issue whose payload carries `"source": "backfill"` — not its latest event of any
kind (Codex r3). With the global latest, `rated` (backfill) → `review_ready` (reconcile) →
backfill again would re-emit `rated`, and the next reconcile would re-emit `review_ready`: a
ping-pong between two honest observers. Comparing each producer against its own last projection
makes the two independent. The check runs
**inside `mutate`**, which `perform_write` executes after taking `WriterLock` and after
`BEGIN IMMEDIATE`. A read before `perform_write` would let two concurrent backfills (or a backfill
and a reconcile) both see the same stale latest event, serialize their writes, and each emit a
duplicate. Inside the transaction the read and the decision are atomic with the write.

Mechanism, reusing what exists rather than adding to `perform_write`: when the latest event already
matches, `mutate` raises `_AlreadyRecorded`. `perform_write`'s existing abort path
(`releases_app.py:1613-1625`) rolls back, clears the journal, and re-raises **before** any receipt
or generation bump — so a skip leaves no trace on the chain. The caller catches it and counts a
skip. One helper carries this: `_emit_work_event(root, conn, event, gh, payload, unless_latest_in=(), only_source=None)` — `only_source="backfill"` scopes the latest-event lookup to that producer's own rows;
`cmd_work_emit` becomes its first caller, `backfill` and the review-ready scan its second and third.

A second run therefore emits zero. A row whose state changed since the last backfill emits again.
`--dry-run` prints the full table (gh, section, marker, → event, or `skip: already <event>` /
`skip: deferred`) and returns before touching `perform_write` at all.

### `review_ready` in `reconcile` — before dispatch, outside the lock, fail-soft

1. `XYZ_WORK_CONNECTORS=0` → skip the scan, as everything else.
2. Resolve the repository **before** any call (Codex r3): `--repo <owner/name>` is taken from the
   first enabled connector's `repos[0]` (`work_connectors.load_connectors()`), falling back to
   `git -C <root> remote get-url origin` parsed to `owner/name`; if neither yields one, print
   "review-ready scan skipped: no repository identity" and go straight to replay. `work reconcile
   --root X` can run from any CWD and must never query the caller's unrelated remote.
   Then `gh pr list --repo <owner/name> --state open --json number,isDraft,title,body --limit 200`
   via `XYZ_BOARD_SYNC_GH_BIN` (default `gh`). Non-zero exit, missing binary, or bad JSON → print
   the reason once, continue to replay. **Never fails the verb.**
   **The offline seam (Codex r3):** `mock_gh_board.py` speaks only `api graphql`. The suite ships
   `test/lib/gh-prlist-wrapper.sh` — a named file, ~15 lines — which answers `pr list` from the
   JSON file `$GH549_PRLIST_JSON` (records every call's argv to `$GH549_PRLIST_CALLS` so the
   `--repo` control can read it back) and execs the mock for everything else. 22a runs against
   exactly that wrapper, so its success is the real branch and not the fail-soft one.
3. For each non-draft PR, `linked_issues(pr)`; for each issue, `_emit_work_event(..., "review_ready",
   n, {"pr": num}, unless_latest_in=("review_ready", "pr_merged", "completed"))` — `completed`
   in the suppression set (Codex r3) so an open PR against a Completed issue cannot pull its card
   back to In review — the same transactional guard
   as backfill, so a concurrent reconcile cannot double-emit either. **Each emission is its own
   fail-soft unit (Codex r2):** `_AlreadyRecorded` is a quiet skip; any *other* exception from
   `_emit_work_event` — a locked ledger, a refused write, a bad row — is caught, printed with the
   issue number, counted, and the scan continues to the next issue and then to dispatch. The verb
   exits 0 regardless. The one thing that must not be swallowed is an injected `_crash`, which uses
   `os._exit` and never reaches an `except` anyway.
4. Then the existing dispatch.

### Files

| File | Change |
|---|---|
| `utils/py/releases_app.py` | `_emit_work_event(root, conn, event, gh, payload)` (the shared in-process body `cmd_work_emit` becomes a caller of); `_latest_event(conn, gh)`; `_backfill_event_for(row)`; `cmd_work_backfill`; the scan step in `cmd_work_reconcile`; `work backfill` subparser |
| `utils/py/work_connectors/github_board.py` | `DEFAULT_STATUS_MAP["completed"] = "Done"` |
| `test/lib/gh-prlist-wrapper.sh` | new — answers `pr list` from a JSON fixture, records argv, execs the mock for `api graphql` |
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
| 22a | open non-draft PR closing #N → card N reaches the `review_ready` column (mock, mapped to "Todo" since the mock has no "In review") | **source mutation:** in the copied app, replace the `review_ready` event name in the scan with `updated` → the card does not reach the column |
| 22b | draft PR → nothing; PR closing nothing → nothing | **source mutations, one each:** remove the `isDraft` filter in the copy → the draft PR emits; replace `linked_issues(pr)` with `[pr["number"]]` in the copy → a PR closing nothing emits for its own number |
| 22f | one emission raises (not `_AlreadyRecorded`) → `reconcile` prints it, continues to the next issue, dispatches, exits 0 | copied app: make `_emit_work_event` raise `RuntimeError` for one specific issue number; assert the other issue's event still lands, dispatch ran (cursor moved), rc 0. **Red:** remove the per-emission `except` in the copy → rc ≠ 0 and no dispatch |
| 22c | second `reconcile` → zero new `review_ready` | strip `unless_latest_in` → duplicate |
| 22d | wrapper `gh` exits 1 → `reconcile` prints the reason, still replays, exit 0 | remove the try/except in the copy → rc ≠ 0 |
| 22e | `XYZ_WORK_CONNECTORS=0` → no scan, no `gh` call (sentinel) | unset → sentinel appears |
| 21f | interleave: backfill → reconcile emits `review_ready` → backfill again emits **nothing**; then a Completed issue with an open PR: reconcile emits **nothing** | copied app: (i) drop `only_source` → the second backfill re-emits `rated`; (ii) drop `completed` from the suppression set → the Completed card gets `review_ready` |
| 21g | Deferred + 🚧 → skip; Deferred + rated → skip | copied app: reorder so the Completed/marker branches run before the Deferred check → Deferred/🚧 emits `in_flight` |
| 22g | `--repo` is the connector's `repos[0]`, and from a no-git CWD the scan still names the ledger repo (read from `$GH549_PRLIST_CALLS`) | copied app: drop `--repo` → the wrapper records no `--repo` argv (and real `gh` would have used the CWD) |
| 23 | `completed` is in `DEFAULT_STATUS_MAP` and maps to Done; unmapped by a user's `""` override | **source mutation:** delete the `completed` key from the copied `DEFAULT_STATUS_MAP` → `column_for("completed", …)` is `None` and the mapping assertion fails |

### Non-goals (from the issue)
Two-way sync; inferring review-ready from anything but an open PR; the pre-push hook; any new
write path.

### Rollback
Two verbs, no schema change, no new table. Revert the commit.

## Implementation notes — what changed from the plan while building

- **The ping-pong had a second half the plan missed.** Scoping backfill to its own rows
  (`only_source="backfill"`) stopped backfill re-emitting after a `review_ready`, but reconcile
  still used the global latest, so a backfill `rated` let the next reconcile re-emit
  `review_ready` once. Fixed symmetrically: reconcile ignores backfill rows
  (`exclude_source="backfill"`). Leg 21f now proves both directions with a red control each.
- **A terminal claim must suppress regardless of producer.** `completed` only ever comes from
  backfill, so excluding backfill rows would have blinded reconcile to it. `_emit_work_event`
  gained `terminal=(...)`: the global latest in that set suppresses whoever made it. Reconcile
  passes `terminal=("completed", "pr_merged")`.
- **`_linked_issues` is inlined**, not imported from `merge_cleanup.py`: that is a skill script off
  `sys.path`, and a ledger verb must not depend on a skill's file layout. Same regex.
- **Test-authoring defects found by the controls themselves, disclosed:** 21a's first mutation
  anchored on `if args.dry_run:`, which has 12 occurrences — it mutated a different verb and the
  control passed vacuously; it now anchors on backfill's unique print. 21f first used #405, which
  is a Completed issue in the real ledger, so backfill emitted `completed` and terminal
  suppression hid the interleave; it now creates a fresh parked issue. 22b's draft control asserted
  on the linked issue while the same copy had `linked_issues` bypassed, so the draft emitted for its
  own number instead.

## Lessons Learned (For Future Agents)

- **Independent producer views prevent event ping-pong loops**: When multiple subsystems project onto a shared event stream (e.g., historical ledger backfill vs live PR reconciler), each producer must filter its latest-event checks against its own scoped source (`only_source` vs `exclude_source`) rather than comparing globally. Otherwise, interleaved emissions cause endless state re-announcements.
- **Fail-soft scanning with robust repository identity**: Best-effort external scans (such as querying `gh pr list`) should resolve repository identity strictly from ledger connector config or git origin rather than assuming current working directory, and must handle external CLI failures gracefully without crashing downstream dispatch.
