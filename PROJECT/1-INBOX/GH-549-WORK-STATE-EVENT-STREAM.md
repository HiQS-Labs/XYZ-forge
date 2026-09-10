---
title: "GH-549: work-state event stream with concurrent connectors — GitHub Kanban first, HQ and Flightdeck next"
status: Parked
created: 2026-09-10
updated: 2026-09-10
owner: unassigned
goal: emit one normalized work-state event from the single ledger write seam and let multiple thin connectors project it concurrently, so a user can see what is ready to be worked, in flight, ready for review, and merged — without any connector becoming authoritative
gh_issue: 549
source: https://github.com/HiQS-Labs/XYZ-forge/issues/549
doc_type: feature
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/402
  - https://github.com/HiQS-Labs/XYZ-forge/issues/405
  - https://github.com/HiQS-Labs/XYZ-forge/issues/39
  - https://github.com/HiQS-Labs/XYZ-forge/issues/424
  - https://github.com/HiQS-Labs/XYZ-forge/issues/494
context_tags: [board-sync, connectors, event-stream, releases-ledger, device-config, projectv2]
non_goals:
  - Two-way sync, or any connector writing back into the ledger
  - Dynamic or entry-point plugin discovery; connectors are vendored modules enabled by name
  - Creating or renaming board columns, fields, or the board itself
  - Making any connector authoritative — PDDA and the RELEASES DB stay the source of truth
  - Building the HQ or Flightdeck connectors in this issue
  - Retiring `releases_app.py project sync` (the separate GH-39 draft-card projector)
  - Backfilling historical issues onto any board
effort: 6
complexity: 4
risk: 3
phases: 4
---

# GH-549 — a board writer nothing calls, hardcoded to one person, next to three private definitions of "in flight"

## Status

| What was just completed | What's next |
|---|---|
| Intake captured from the operator-approved design on the issue; recon map already exists at `PROJECT/1-INBOX/recon-projects-board-sync.md` | Park + rate, then task clone, plan, Codex plan QA |

## Problem

Three gaps, each confirmed by the recon map rather than inferred.

**1. Nothing invokes the board writer.** `utils/py/board_sync.py` works and has run live, but no hook,
workflow, cron, skill or script calls it. Both CI workflows were read in full; every git hook, all 52
repo skills, every globally installed skill including `start-task`, `package.json`, `crontab` and the
launchd hourly scan are clean. Its only callers are two test suites, both redirecting `gh` to the
offline mock. `PROJECT/2-WORKING/GH-402-BOARD-SYNC.md:54` records Phase 2 as unchecked.

**2. The board identity is hardcoded to one person.** `utils/py/board_sync.py:63-64` ships
`"project_owner": "noelsaw1"` and `"project_number": 3` as defaults requiring no config, and `:67`
defaults `repos` to `HiQS-Labs/XYZ-forge`. Any other user of this harness writes to someone else's
board.

**3. Each consumer re-derives "what is happening" for itself.** `board_sync.py` reads
`roadmap_items.status_marker` and `jog_queue.status`; HQ (`utils/hq/rollup.sh`) walks `ROADMAP.md`
per repo; Flightdeck (GH-494) reads its own extract. Three definitions of "in flight", drifting
independently, and a fourth arrives with any new surface.

## Requested outcome

One normalized work-state event stream, with **multiple connectors consuming it concurrently** — the
GitHub Kanban board first, HQ and Flightdeck as in-house connectors after.

## Design, as settled with the operator

Full design is on the issue. The load-bearing decisions:

- **The stream is the product; connectors are thin.** The core emits rich domain events — parked,
  rated, running, PR opened, merged, escalated — never a board's column vocabulary. Each connector
  maps to its own presentation. The core does not inherit GitHub's column model.
- **Same database, same transaction, one seam.** `perform_write()` at `utils/py/releases_app.py:1382`
  is the single function every ledger mutation passes through, and it already writes its `op_receipts`
  row inside the transaction. The work event is written there, so it is atomic with the ledger write.
- **Sibling tables, not wider `op_receipts`.** This is a deliberate refinement of the operator's
  "extend `op_receipts`" answer, made after reading the schema at `releases_app.py:603-620`.
  `op_receipts` is append-only via `op_no_update` / `op_no_delete` triggers and carries a
  `state_digest_before` / `after` chain that `check` verifies, with the business-state digest
  deliberately excluding itself. Widening it means migrating a trigger-protected, self-verifying
  audit chain to carry a payload that is not an audit record — and connector cursors must be mutable,
  which an append-only table forbids outright. So: `work_events` (append-only, mirroring the receipt
  discipline) and `connector_cursors` (mutable by design), both in the same DB and the same
  transaction.
- **Connectors are vendored modules enabled by name in config**, resolved through the existing
  `device_config.py` 3-tier resolver (`XYZ_<KEY>` env > `device_config` key > defaults, per GH-174).
  No new config system, no dynamic discovery, no loading code the harness did not vendor. Adding a
  connector is a PR, not a runtime install.
- **Write-only; the ledger is truth.** Connectors project outward and never read back. A hand-dragged
  card is overwritten on the next event. There is no conflict-resolution model to design and no
  remote system that can mutate governance state.
- **Independent per-connector failure, never blocking.** The ledger write commits first, then dispatch
  happens detached with a timeout and an ignored exit code. This preserves `board_sync.py`'s existing
  documented adapter contract — "network failure warns and degrades, never blocks a host operation".
  A governance writer must never depend on the network.
- **Cursor plus `reconcile`, no queue.** A failed connector does not advance its cursor; `reconcile`
  replays everything after it. No queue to corrupt, duplicate, or wedge — and the same command repairs
  a hand-edited board.
- **Unconfigured is a silent no-op.** No `work_connectors` config means ledger writes behave exactly
  as today. `XYZ_BOARD_SYNC=0` remains a kill switch.

## What recon changed about the plan

Two findings from `PROJECT/1-INBOX/recon-projects-board-sync.md` that the design had to absorb:

1. **The ambient `gh` token cannot mutate a user project.** It carries `gist, read:org, repo, workflow`
   and not `read:project`, so every board call fails today with `INSUFFICIENT_SCOPES`. This
   **invalidates GH-402's Phase 0 finding** that the ambient token suffices. The connector must detect
   the missing scope and print the exact `gh auth refresh -s read:project,project` command rather than
   running an auth command on anyone's behalf.
2. **A prior answer in this repo's own session log said nothing updates the board. That was wrong** —
   an empty search result was read as a negative without confirming the search had matched anything.
   `board_sync.py`, `mock_gh_board.py` and two test suites exist. The correction is recorded in the
   recon map so the wrong answer does not get cited later.

## Sequencing risk — GH-424 is now live

GH-424's `--status-marker` writer **has landed** on `development` (`utils/py/releases_app.py:5608`).
Its own recon (`PROJECT/1-INBOX/recon-gh424-status-marker.md:61`) recorded that `board_sync.py`'s `🚧`
query was inert only because nothing wrote `🚧`. That premise is gone: rows can be flipped to `🚧`
today. What still keeps it inert is gap 1 above — nothing calls the writer. **This issue removes that
protection**, so the unconfigured-is-a-no-op acceptance criterion is not a nicety; it is the guard
that stops the first ledger write after this lands from creating live cards on somebody's board.

## Acceptance criteria

Every criterion names the red control that proves the check can fail.

1. A fresh checkout with no `work_connectors` config performs zero network calls and zero connector
   writes on every ledger verb. **Red control:** with config present and a stub connector, the same
   verbs do dispatch.
2. `board_sync.py` `DEFAULTS` contains no personal owner, project number or repo. **Red control:** a
   test asserts the literals `noelsaw1` and `3` are absent from the module.
3. The work event and the ledger row are written in one transaction. **Red control:** inject a crash
   between them and assert neither is present — no event without its ledger row, no ledger row without
   its event.
4. A connector that raises or times out leaves the ledger write committed, the host command's exit
   code unchanged, and its own cursor un-advanced. **Red control:** inject a failing connector and
   assert the ledger verb still exits 0, the row is present, and the cursor did not move.
5. Two connectors enabled, one failing and one succeeding — the succeeding one still advances.
6. `reconcile` replays exactly the events after a connector's cursor, and is idempotent when run twice.
7. A configured state whose option label is missing on the board reports and writes nothing; the
   board's schema is never mutated.
8. Missing `read:project` produces the named remediation command, not a traceback.
9. Each of the four states is reachable end-to-end against `mock_gh_board.py` (GH-405).

## Phases

| Phase | Scope |
|---|---|
| 1 | `work_events` + `connector_cursors` schema and migration; emission from `perform_write()` |
| 2 | Connector registry, `work_connectors` config through `device_config.py`, detached dispatch |
| 3 | GitHub connector rebuilt from `board_sync.py` with the personal defaults removed; scope detection |
| 4 | `reconcile` verb; PR-open emitter in `githooks/pre-push`; PR-merged emitter in `merge-cleanup` |

## Known gap, accepted by the operator

A merge performed in the GitHub UI is missed until `reconcile` runs. No new CI workflow and no new
secret is introduced to close it.
