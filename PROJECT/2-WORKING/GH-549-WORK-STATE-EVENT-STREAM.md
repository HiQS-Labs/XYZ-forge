---
title: "GH-549: work-state event stream with concurrent connectors — GitHub Kanban first, HQ and Flightdeck next"
status: 2-WORKING
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
effort: 5
complexity: 4
risk: 3
phases: 4
---

# GH-549 — a board writer nothing calls, hardcoded to one person, next to three private definitions of "in flight"

## Status

| What was just completed | What's next |
|---|---|
| Parked and rated 70/50/50/25; recon run over the ledger write seam, config surface and PR emitters (`PROJECT/1-INBOX/recon-gh549-work-events.md`); implementation plan written | Codex plan QA, then execute the ordered list |

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
- **Same database, same transaction, one seam.** `perform_write()` at `utils/py/releases_app.py:1317`
  is the single path for **domain verbs** — 28 callers — and it already writes its `op_receipts` row
  inside the transaction. The work event is written there, so it is atomic with the ledger write.
  It is not the only thing that can touch the file: `cmd_init`, `perform_migration`, `_rebuild` and
  `load_dump` are enumerated exceptions, and `jog_run.py:1638`/`:1692` is a bypass filed as #552.
  The accurate claim is "single domain-verb path with enumerated exceptions", not "every ledger
  mutation" (Codex r1).
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
- **Independent per-connector failure, bounded not zero (revised, Codex r1+r2).** The ledger write
  commits and `perform_write` releases its `WriterLock` **before** any dispatch. Connectors then launch
  **concurrently** and are joined under one total bounded window, so N connectors cost one window, not
  N timeouts. The host's exit code never changes. This preserves `board_sync.py`'s documented adapter
  contract — "network failure warns and degrades, never blocks a host operation" — and a governance
  writer never depends on the network. The earlier wording "detached with a timeout and an ignored
  exit code" was incoherent and is withdrawn: see Phase 3.1.
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
2. `board_sync.py` `DEFAULTS` contains no personal owner, project number or repo, and an unconfigured
   `board_sync scan` refuses while making zero `gh` calls. **Red control:** restore `project_owner` to
   `DEFAULTS` and the refusal assertion must stop firing. (The issue's original "assert the literal
   `3` is absent" is withdrawn — Codex r1 is right that a bare `3` occurs legitimately anywhere in a
   Python file. See Phase 4.2.)
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
| 1 | `work_events` + `connector_cursors` schema and migration, with append-only triggers on `work_events` |
| 2 | Emission from `perform_write()` via a total extractor registry |
| 3 | `resolve_device_block()` in `device_config.py`; connector registry; concurrent bounded dispatch |
| 4 | GitHub connector; scope detection; `work emit` as a `perform_write` caller; `pr_merged` emitter in `merge-cleanup`; `reconcile` |

**Withdrawn after Codex r2:** the PR-open emitter in `githooks/pre-push`. The hook keeps only
local/remote SHA pairs (`githooks/pre-push:61-76`), has no issue or PR lookup, and a green push may
target a branch with no PR at all — so mapping it to a review column can assert a review state that
does not exist. The alternative, a `gh pr view` call on every push, puts network latency inside a git
hook. "Ready for review" is therefore derived by `reconcile` from actual open PRs instead. Same state
delivered, not real-time.

## Known gap, accepted by the operator

A merge performed in the GitHub UI is missed until `reconcile` runs. No new CI workflow and no new
secret is introduced to close it.

---

# Implementation plan

Grounded in `PROJECT/1-INBOX/recon-gh549-work-events.md` at base `52938679`. Every step names the
existing subsystem it extends and the check that proves it.

## The observed problem, restated from evidence

`utils/py/board_sync.py` is a complete, working board writer that **nothing calls** — verified across
both CI workflows, every git hook, all repo skills, `package.json`, `crontab` and the launchd scan.
It ships another person's board as a zero-config default (`:63-64`, `:67`). And three surfaces each
compute "in flight" privately: `board_sync.py` from `roadmap_items.status_marker` + `jog_queue.status`,
HQ from `ROADMAP.md`, Flightdeck from its own extract.
## Smallest affected surface

| File | Change |
|---|---|
| `utils/py/releases_app.py` | migration 008; `work_events` in `dump_text` + `load_dump`; one insert in `perform_write`; `work emit` and `work reconcile` verbs |
| `utils/py/device_config.py` | one new `resolve_device_block()` + a loader that distinguishes absent from malformed |
| `utils/py/board_sync.py` | personal literals out of `DEFAULTS`; `resolve_settings` migrated onto `resolve_device_block` |
| `utils/py/work_connectors/__init__.py` | registry, config resolution, bounded dispatch |
| `utils/py/work_connectors/github_board.py` | the GitHub connector, built from `board_sync.py` |
| `utils/py/mock_gh_board.py` | one new fault: `insufficient_scopes` |
| `skills/merge-cleanup/scripts/merge_cleanup.py` | one emit inside `if merged:` |
| `test/gh549-work-events.sh` (new), `test/gh405-mock-board-harness.sh` | proof, and the six assertions that must stop depending on a coincidence |
| `validate.sh`, `utils/ci-route.sh` | registration |

## Non-goals

Carried verbatim from the issue: no two-way sync, no dynamic plugin discovery, no board schema
mutation, no connector becomes authoritative, no HQ or Flightdeck connector, `releases_app.py project
sync` stays, no historical backfill. Added after recon: **not** fixing the `jog_run.py` dry-run write
(#552), and **not** fixing the mock's missing pagination. Added after Codex r1: **no cross-clone
cursor history** — a cursor is device-local runtime state, and nothing in the acceptance criteria
needs it to survive a rebuild or travel between clones.

## Phase 1 — the tables

**1.1** Add `MIGRATION_008_DDL` beside `MIGRATION_006_DDL` (`releases_app.py:895-912`), two tables:

- `work_events` — `id`, `global_id` (`_gid_check("global_id", "wev-")`), `repo_id` -> `repos(id)`,
  `gh_number`, `txn_id`, `event`, `payload` (JSON text), `at`. Index on `gh_number`.
  **Plus append-only triggers, added after Codex r2** — the design called this table append-only and
  the field list did not enforce it. `work_events_no_update` / `work_events_no_delete` mirror
  `op_receipts`' pair at `releases_app.py:618-621`. Note `_ddl_statements()` **raises** on
  `CREATE TRIGGER` (`:667-668`), so the two triggers are issued as individual `conn.execute()` calls
  the way `_migration_004` does at `:885-892`, not through the DDL splitter.
  **Red control:** attempt an `UPDATE` and a `DELETE` on a `work_events` row and witness both refusals
  by name.
- `connector_cursors` — `connector` PRIMARY KEY, `last_event_id`, `last_attempt_at`, `last_error`,
  `updated_at`.

**1.2** `_migration_008(conn)` applying it statement-by-statement via `_ddl_statements()`
(`:659-679`) — **never `executescript()`**, which commits the open transaction (the warning at
`:711-715`). Register `8: {"apply": _migration_008, "txn_safe": True}` at `:966-974`.

**1.3 — corrected after Codex r1. The two tables are treated differently, and the reason is a check
I originally missed.**

My first plan put both tables in `dump_text` under the `include_receipts` guard, reasoning only about
`business_digest`. That reasoning was right as far as it went and **wrong overall**, because
`cmd_check` runs a second, stricter comparison:

```
utils/py/releases_app.py:4627
    elif dump_content != dump_text(conn, db_gen):
        ... fail("dump-divergence", ...)
```

That is a byte comparison of the committed `releases.sql` against the canonical dump of the DB, and it
includes receipts. `perform_write` writes the dump once, at `:1391-1402`, immediately after commit. A
cursor advances *after* that. So a `connector_cursors` row inside `dump_text` would put the file and
the database out of sync the moment any connector ran, and the next `releases check` — including the
one behind the pre-push gate — would fail `dump-divergence` on a healthy repo.

Corrected placement:

- **`work_events` -> in `dump_text` under the `include_receipts` guard (`:1214-1220`), excluded from
  `business_digest` (`:1224-1226`).** Safe because every row is written inside the transaction, before
  the dump is staged, so file and DB agree. Excluded from the digest because it is provenance, not
  business state.
- **`connector_cursors` -> not in `dump_text` at all.** It is device-local runtime state: two clones of
  the same repo legitimately hold different cursors, and a git-tracked cursor would reintroduce
  exactly the per-run merge churn GH-496 PR 1 just removed. `check --rebuild` therefore resets it and
  `work reconcile` replays from the start, which is idempotent by construction (4.4). This is also
  Codex's "cut that coupling" point in the same finding.

**1.4** `work_events` gets matching loaders in `load_dump` (`:5125-5133` pattern), parent-before-child.
`connector_cursors` deliberately gets none.

*Verification:* migrate a fixture 007 -> 008; assert both tables exist and `schema_migrations` carries
8; assert `check` is clean after a `roadmap add`.
**Red control A (digest):** move the `work_events` emit above the `include_receipts` guard; two
consecutive `roadmap add` calls must make `check` report `receipt-chain`.
**Red control B (divergence — the one Codex's blocker demands):** add `connector_cursors` to
`dump_text`, advance a cursor after a ledger write, assert `check` reports `dump-divergence`. Then in
the shipped configuration advance **both** `last_event_id` and `last_error` and assert `check` is
clean, and run two connector completions concurrently as the concurrency control.

## Phase 2 — emission at the one seam

**2.1** Inside `perform_write` (`:1317`), immediately after the `op_receipts` INSERT (`:1382-1386`)
and before `conn.commit()` (`:1388`), insert one `work_events` row.

**2.2 — the extractor contract, added after Codex r1.** `perform_write` receives only `root`, `conn`,
`op`, `target_gid` and `mutate`. It does **not** receive `gh_number`, and it cannot see the marker a
`roadmap-update` just wrote. So a bare `op` -> event table is not implementable, which the first draft
missed. Each mapped `op` instead names an **extractor**: a function run after `mutate(conn)` and
inside the transaction, given `(conn, op, target_gid)`, returning `(event, gh_number, payload)` or
`None`.

The registry is **total**. Every `op` string reachable from the 28 callers is either mapped to an
extractor or listed in an explicit `NON_EVENT_OPS` allowlist with a one-line reason. A coverage test
enumerates the `op` literals in `releases_app.py` — plus the `jog-` prefix family from
`jog_set_status` (`:4417`, writes at `:4440`) — and **fails when one is neither mapped nor
allowlisted**. That is what stops a new verb from silently dropping a state.

| `op` | event | extracted from |
|---|---|---|
| `roadmap-add` | `parked` | the inserted `roadmap_items` row |
| `roadmap-rate` | `rated` | the updated row's four axes |
| `roadmap-update` | `in_flight` / `updated` | re-read `status_marker` after `mutate` |
| `jog-lease` | `in_flight` | `jog_queue` row |
| `jog-<status>` (prefix) | `jog_<status>` | `jog_queue` row |
| everything else | — | `NON_EVENT_OPS`, with a reason |

**Codex is right that `roadmap-update` with a completed marker does not prove a PR merged**, and
neither does the generic `reconcile` op. Both are dropped from the `merged` mapping. The `merged`
board state is driven only by the merge emitter in 4.5, which witnesses an actual `gh pr merge`
exit 0.

**2.3** Dispatch happens after `conn.commit()` and after the dump/rename at `:1391-1402`, wrapped so
no exception escapes.

*Verification:* all 28 callers exit 0 with no config present; plus the coverage test above.
**Red control:** the existing `_crash("pre-commit")` hook at `:1387` — inject the crash and assert
neither the ledger row nor the event survives.

## Phase 3 — the connector layer

**3.1 — the dispatch contract, rewritten after Codex r1.** The first draft said "detached with a
timeout and an ignored exit code". Codex is right that this is not implementable as one thing: a
parent that waits enforces the timeout but blocks; a `Popen` nobody waits on enforces nothing, can
never observe success to advance a cursor, and makes the stated red control unable to fire.

**Revised again after Codex r2 on two counts: the dispatch was serial where the issue asks for
concurrent, and the cursor write had no lock boundary.** Both corrected here.

The contract:

> A ledger verb's added latency is **bounded and does not grow with the number of connectors**. All
> enabled connectors are launched **concurrently** — one `subprocess.Popen` each, every one started
> before any is joined — and collected under **one total deadline** (`CONNECTOR_WINDOW_S`, default
> 5s), not a per-connector timeout. Two connectors that each hang cost one window, not two. Any child
> still running at the deadline is terminated and reaped. The host's exit code never changes, and with
> no connectors configured the added latency is exactly zero, because dispatch returns before spawning.

**The lock boundary (Codex r2, blocker 2).** `perform_write` holds `WriterLock` until its `finally` at
`releases_app.py:1407-1408`, which runs *after* the return. My r1 revision put dispatch "after the
dump and rename at `:1391-1402`" — still inside `perform_write`, therefore **inside the governance
lock, across network time**. That was wrong. Corrected:

1. `perform_write` completes and releases its lock. It returns `txn_id` and dispatches nothing.
2. The **caller** — one shared helper each `cmd_*` invokes after `perform_write` returns — reads the
   pending events, launches every child, and joins them under the single window.
3. Cursor and error outcomes for **all** connectors are then persisted in **one short explicit
   transaction on a separate device-local connection**, taken after the join and never held across a
   child's lifetime.

Named explicitly, per Codex r1: the **process boundary** is one child per connector; the child holds
**no DB connection** — it receives its event batch as JSON on stdin and reports on stdout, and the
**parent is the sole writer of `connector_cursors`**; **kill/reap** is terminate-then-reap at the
deadline; **success acknowledgement** is child exit 0 plus a parseable `advanced_to: <id>` line.

*Verification:*
- **Concurrency (Codex r2's own test):** two connectors that each sleep 5s finish in about 5s
  together, not 10s. **Red control:** serialize the launch loop and assert elapsed time roughly doubles.
- **Lock release:** a second ledger writer proceeds while connectors are blocked. **Red control:** move
  dispatch back inside `perform_write` and assert the second writer now blocks.
- **Cursor durability:** two connectors complete concurrently; reopen the DB and assert both outcomes
  persisted.
- Bounded host latency, hung child killed, no zombie left, host rc unchanged, ledger row present,
  failing cursor un-advanced, succeeding cursor advanced.
**Red control (exception leakage):** remove the `try/except` and assert the host verb exits nonzero
when a **synchronous injected** dispatcher raises. Codex r1's point stands — this control must use the
injected synchronous path, since it cannot fire against a real child.

**3.2** `load_connectors()` reads the `work_connectors` block through the shared helper below. Absent
config is a silent no-op; malformed config warns and disables.

**3.3 — extend the config subsystem, do not copy it a third time (Codex r1, accepted).** Codex is
right that `device_config.resolve_device_setting` (`:46-66`) already returns arbitrary top-level JSON
values; what is genuinely missing is nested per-key env coercion and the ability to tell **absent**
from **malformed**, since `load_local_device_config()` (`:34-43`) collapses both to `{}`. So rather
than write a third private merge — after `board_sync.resolve_settings` and `profile_resolve` — add one
`resolve_device_block(block, defaults, env_prefix)` plus a diagnostic loader to `device_config.py`, and
migrate `board_sync.resolve_settings` onto it. That is a smaller net diff than a third copy and
removes one of the two existing ones. `device_config.py` is now in the affected-surface table, which
it should have been from the start.

*Verification:* `board_sync config` output is byte-identical before and after the migration.
**Red control:** a malformed `work_connectors` block must warn and disable, not raise and not look
like absent config.

## Phase 4 — the GitHub connector, `reconcile`, and the PR emitters

**4.1** `github_board.py` wraps `board_sync.py`'s existing resolve/add/set-status functions. Personal
literals leave `DEFAULTS` (`:63-64`, `:67`); owner and number become **required** config with no
default, so an unconfigured connector cannot write anywhere.

**4.2 — criterion 2's check, rewritten after Codex r1.** The issue proposes asserting the literals
`noelsaw1` and `3` are absent from the module. Codex is right that this is unsound: `3` occurs
legitimately all over any Python file. Replaced with semantic assertions:

- `DEFAULTS` contains no `project_owner`, `project_number` or `repos` key at all.
- With no config, `board_sync scan` **refuses** with a named error and makes zero `gh` calls — asserted
  by pointing `XYZ_BOARD_SYNC_GH_BIN` at a script that writes a sentinel file, then asserting the
  sentinel does not exist.
- A grep for the string `noelsaw1` stays: it is a name, not a number, so it is sound.

Then repair the six assertions this breaks. `test/gh405-mock-board-harness.sh` legs 4-6 (`:105`,
`:114`, `:126`, `:136`, `:143`, `:158`) pass today only because `board_sync.py:63-64` and
`mock_gh_board.py:31-32` hardcode the same values and agree by coincidence. Give those legs explicit
`XYZ_BOARD_SYNC_PROJECT_OWNER` / `_NUMBER` and pin `XYZ_DEVICE_CONFIG_PATH` — recon confirmed this host
has no `board_sync` block, so the legs read the real user config today and pass only because it
happens to be empty.

**4.3** Scope detection. `_gql` (`:242-267`) folds every GraphQL error into one opaque string at
`:265`. Classify `INSUFFICIENT_SCOPES` there and print `gh auth refresh -s read:project,project`.
Verified unsandboxed: this host's token is `gist, read:org, repo, workflow`. Add an
`insufficient_scopes` fault to `mock_gh_board.py` beside `stale_option_once` (`:210-221`).

**4.4** `work reconcile --connector <name>` replays every event after the cursor. Idempotent because
each board write is set-to-value, never an increment, and because replaying from zero is the rebuild
path by design (1.3).

**4.5 — the emitter write path, rewritten again after Codex r2.**

My r1 answer added a standalone `work emit` verb that took `WriterLock`, wrote the journal, the
receipt and the artifacts itself. Codex r2 is right that this **forks the write protocol** rather than
extending it, and that it is the second entry point the Definition of Done rules out. `perform_write`
already owns that protocol and already accepts an arbitrary `mutate` callback
(`releases_app.py:1317-1408`) — so the verb should be a *caller* of it, not a parallel copy of it.

Corrected: `releases work emit --event <name> --gh-number <N> [--payload-json <json>]` is an ordinary
`perform_write` caller, the 29th. It passes `op="work-emit"` and a `mutate` that inserts the
`work_events` row. Generation, `state_digest_before`/`after`, the receipt, the journal, the staged dump
and the atomic rename are all whatever `perform_write` already does — nothing is recomputed and there
is no second protocol to keep in step. `work-emit` is registered in the extractor table as
self-describing (its event is its argument), so the generic extractor does not double-emit.

*Verification:* a crash-boundary matrix — `_crash("pre-commit")` and `_crash("post-commit")` against
both `roadmap add` and `work emit` — must show identical recovery, generation, dump and receipt-chain
behaviour. That is the equivalence proof Codex asked for, and it is cheap precisely because there is
now only one implementation.

**The `pr_merged` emitter.** `merge_cleanup.py` shells out to `work emit` inside the `if merged:` block
at `:369-370`, gated on `not dry_run`. **Not** in `execute_pr_merge` above `:58`, where the dry-run arm
returns `True` without merging. `--reconcile-pr` (`:286-290`) never verifies merge state, so it does
not emit.

**The pre-push emitter is withdrawn (Codex r2, blocker 4).** I accept the finding and take the "cut it"
branch of the two remedies offered. The hook keeps only local/remote SHA pairs
(`githooks/pre-push:61-76`), makes no `gh` call anywhere in `githooks/`, and therefore cannot supply
the `--gh-number` the verb requires. Worse, a green push may target a branch with **no PR at all**, so
mapping `push_validated` to a review column would assert a state that does not exist. The other remedy
— fail-soft PR lookup inside the hook — puts a network round trip on every push, in the one place this
repo has been most careful to keep fast, and would still need the no-PR, multi-ref, draft and
lookup-failure cases handled.

So "ready for review" is derived by `reconcile` instead, from actually open, non-draft PRs. The state
is still delivered; it is no longer real-time. This is the same class of gap the operator already
accepted for a GitHub-UI merge, and it is now the second item on that list.

Accepted blind spots, closed only by `reconcile`: a merge performed in the GitHub UI, and the
review-ready transition, which is now reconciliation-derived by design rather than event-driven.

## Acceptance criteria and their red controls

Codex r1 was right that criteria 5-9 had happy-path checks only. One mutation each:

| # | Criterion | Witnessed red |
|---|---|---|
| 1 | unconfigured = zero network, zero writes | configure a stub connector; the same verbs must dispatch |
| 2 | no personal defaults | restore `project_owner` to `DEFAULTS`; the refusal assertion must stop firing |
| 3 | event and ledger row are one transaction | `_crash("pre-commit")`; neither may survive |
| 4 | a failing connector changes nothing | remove the `try/except`; host rc must go nonzero |
| 5 | two connectors, one failing | skip the second connector in the loop; its cursor must stop advancing |
| 6 | `reconcile` replays exactly, twice safely | advance the cursor one past the last event; replay must skip a real event and the test must catch it |
| 7 | missing option reports, never mutates schema | auto-create the missing option; the "never mutates schema" assertion must fail |
| 8 | missing scope names the remediation | suppress the `INSUFFICIENT_SCOPES` classification; the remediation line must disappear |
| 9 | four states reachable end-to-end | delete one event mapping; that state must become unreachable |

Every assertion checks a non-empty fixture first, so an empty result can never read as a pass.

## Registration

`test/gh549-work-events.sh` into `validate.sh`'s `TESTS` array, then the three-part act in
`utils/ci-route.sh` (`SUBSYSTEMS` `:24`, `SUBSYSTEM_TESTS_*` `:25-33`, `subsystem_of()` `:35-47`).
`test/gh35-test-tiers.sh:133-142` fails if the pair drifts. `skills/merge-cleanup/*` is unmapped in
`subsystem_of()`, so this branch runs the full tier-3 gate on every push — expected, not a defect.
`githooks/pre-push` is no longer touched at all, since its emitter was withdrawn.

## Risks and rollback

| Risk | Mitigation |
|---|---|
| A cursor write breaks the receipt chain | `work_events` outside `business_digest`; red control A |
| A cursor write breaks the dump comparison | `connector_cursors` outside `dump_text` entirely; red control B |
| Migration 008 lands without dump/load support | `check --rebuild` in the suite, which fails loudly |
| A connector delays a ledger verb | one 5s total window for all connectors, launched concurrently and measured; zero when unconfigured |
| Dispatch holds the governance lock across network time | dispatch runs in the caller, after `perform_write` releases `WriterLock`; red control moves it back and asserts a second writer blocks |
| `work emit` drifts from `perform_write`'s protocol | it *is* a `perform_write` caller; crash-boundary matrix proves equivalence |
| A connector changes a host exit code | `try/except BaseException`; red control 4 |
| The first write after merge creates live cards | no default owner or number; red control 2 |
| Vendored `.xyz/` ledgers migrate on next use | `perform_migration` handles it; `txn_safe`, idempotent |

**Rollback:** revert the branch. Migration 008 leaves two unused tables in any ledger that already
migrated; both are `IF NOT EXISTS`, `work_events` is append-only and empty, and `connector_cursors` was
never in the dump, so a reverted binary ignores both.

## Ordered implementation list

1. Migration 008 with append-only triggers on `work_events`; `work_events` in `dump_text` +
   `load_dump`; `connector_cursors` in neither. Red controls A (receipt-chain), B (dump-divergence)
   and the two witnessed trigger refusals.
2. `work_events` insert in `perform_write`; the extractor registry, `NON_EVENT_OPS` allowlist, and the
   coverage test that fails on an unclassified `op`. Crash red control.
3. `resolve_device_block()` + diagnostic loader in `device_config.py`; migrate
   `board_sync.resolve_settings` onto it and assert `board_sync config` is byte-identical.
4. Connector registry and **concurrent** bounded dispatch, launched only after `perform_write`
   releases its lock; concurrency-timing, lock-release, cursor-durability, kill/reap, zombie, rc and
   latency checks.
5. GitHub connector; personal literals out; semantic criterion-2 checks; repair `gh405` legs 4-6 and
   pin `XYZ_DEVICE_CONFIG_PATH`.
6. Scope classification + `insufficient_scopes` mock fault.
7. `work emit` as a `perform_write` caller, plus the crash-boundary equivalence matrix; then the
   `merge_cleanup` `pr_merged` caller. No pre-push emitter (withdrawn, Codex r2).
8. `work reconcile`; idempotency and the cursor-overshoot red control.
9. Register the suite in `validate.sh` and `utils/ci-route.sh`; full gate in a disposable clone.
