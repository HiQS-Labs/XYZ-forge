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
| `utils/py/releases_app.py` | migration 008; two tables in `dump_text` + `load_dump`; one insert in `perform_write`; `work reconcile` verb |
| `utils/py/work_connectors/__init__.py` | registry, config resolution, detached dispatch |
| `utils/py/work_connectors/github_board.py` | the GitHub connector, built from `board_sync.py` |
| `utils/py/board_sync.py` | personal literals out of `DEFAULTS` |
| `utils/py/mock_gh_board.py` | one new fault: `insufficient_scopes` |
| `githooks/pre-push` | one backgrounded emit before each green exit |
| `skills/merge-cleanup/scripts/merge_cleanup.py` | one emit inside `if merged:` |
| `test/gh549-work-events.sh` (new), `test/gh405-mock-board-harness.sh` | proof, and the six assertions that must stop depending on a coincidence |
| `validate.sh`, `utils/ci-route.sh` | registration |

## Non-goals

Carried verbatim from the issue: no two-way sync, no dynamic plugin discovery, no board schema
mutation, no connector becomes authoritative, no HQ or Flightdeck connector, `releases_app.py project
sync` stays, no historical backfill. Added after recon: **not** fixing the `jog_run.py` dry-run write
(filed separately), and **not** fixing the mock's missing pagination.

## Phase 1 — the tables

**1.1** Add `MIGRATION_008_DDL` beside `MIGRATION_006_DDL` (`releases_app.py:895-912`), two tables:

- `work_events` — `id`, `global_id` (`_gid_check("global_id", "wev-")`), `repo_id` -> `repos(id)`,
  `gh_number`, `txn_id`, `event`, `payload` (JSON text), `at`. Index on `gh_number`.
- `connector_cursors` — `connector` PRIMARY KEY, `last_event_id`, `last_attempt_at`, `last_error`,
  `updated_at`.

**1.2** `_migration_008(conn)` applying it statement-by-statement via `_ddl_statements()`
(`:659-679`) — **never `executescript()`**, which commits `perform_migration`'s open transaction
(the warning at `:711-715`). Register `8: {"apply": _migration_008, "txn_safe": True}` at `:966-974`.

**1.3** Emit both tables in `dump_text` **inside the `include_receipts` guard** (`:1214-1220`), beside
`op_receipts`. This is the load-bearing decision from recon finding 1: `connector_cursors` is mutated
after the transaction by the dispatcher, so if it entered `business_digest` (`:1224-1226`) the next
write's `digest_before` would not match the previous `digest_after` and `cmd_check`'s chain walk
(`:4659-4681`) would report a broken chain on **every** write. `work_events` follows the same
placement for symmetry and because it is provenance, not business state.

**1.4** Matching loaders in `load_dump` (`:5125-5133` pattern), parent-before-child, or
`check --rebuild` and the merge driver break.

*Verification:* migrate a fixture from 007 -> 008, assert both tables exist and `schema_migrations`
carries 8. **Red control:** with the `dump_text` emit moved *above* the `include_receipts` guard,
two consecutive `roadmap add` calls must make `releases check` report `receipt-chain` — proving the
placement is what protects the chain, not luck.

## Phase 2 — emission at the one seam

**2.1** Inside `perform_write` (`:1317`), immediately after the `op_receipts` INSERT (`:1382-1386`)
and before `conn.commit()` (`:1388`), insert one `work_events` row. `op`, `target_gid`, `txn_id`,
`session_id()` and `now` are all already in scope.

**2.2** Map `op` -> domain event through one table. The mapping must handle
`jog_set_status`'s computed `f"jog-{status}"` (`:4417`, writes at `:4440`) with a prefix rule, not a
fixed literal list. Unmapped ops emit nothing — a new verb must be added deliberately, not guessed.

| `op` | event |
|---|---|
| `roadmap-add` | `parked` |
| `roadmap-rate` | `rated` |
| `roadmap-update` (marker `🚧`) | `in_flight` |
| `roadmap-update` (marker `✅`), `reconcile` | `merged` |
| `jog-lease` | `in_flight` |
| `jog-completed` / `jog-failed` / `jog-parked` (prefix `jog-`) | `jog_<status>` |

**2.3** Dispatch happens **after** `conn.commit()`, not inside the transaction — the ledger write must
never depend on the network. `perform_write` calls the dispatcher once, after the dump and rename at
`:1391-1402`, wrapped so no exception can escape.

*Verification:* every one of the 28 callers still exits 0 with no config present. **Red control:**
inject a crash between the domain mutate and the commit and assert neither the ledger row nor the
event survives; the existing `_crash("pre-commit")` hook at `:1387` is the seam for it.

## Phase 3 — the connector layer

**3.1** `utils/py/work_connectors/__init__.py`:

- `load_connectors()` — reads the `work_connectors` block. **Copies `board_sync.py:89-119`'s
  `resolve_settings()` idiom**, because `device_config.resolve_device_setting` handles top-level
  scalars only and cannot carry a nested dict (stated in-source at `board_sync.py:90-92`). Follows
  `profile_resolve.py:201-207` in re-opening the config file to distinguish **absent** (silent no-op)
  from **unparseable** (warn), since `load_local_device_config()` collapses both to `{}`
  (`device_config.py:34-43`).
- `dispatch(events)` — for each enabled connector, run it detached with a timeout and an **ignored
  exit code**. This is the adapter contract `board_sync.py:22-24` declares and that no adapter has
  ever provided; `board_sync.py`'s own `touch`/`dedupe` exit nonzero on write failure *by design*, so
  the dispatcher is what makes it non-blocking.
- Cursor advance on success only; on failure record `last_error` and leave `last_event_id` alone.

**3.2** Registry is a literal dict of name -> module in that file. No entry points, no import by
string from config — a connector is added in a PR.

*Verification:* two stub connectors, one raising and one succeeding; assert the host verb exits 0,
the ledger row is present, the failing cursor did not move and the succeeding one did.
**Red control:** remove the `try` around dispatch and assert the host verb now exits nonzero.

## Phase 4 — the GitHub connector, `reconcile`, and the PR emitters

**4.1** `github_board.py` wraps `board_sync.py`'s existing resolve/add/set-status functions. Personal
literals leave `DEFAULTS` (`:63-64`, `:67`); owner and number become required config with **no
default**, so an unconfigured connector cannot write anywhere.

**4.2** Fix the six assertions this breaks. `test/gh405-mock-board-harness.sh` legs 4-6 (`:105`,
`:114`, `:126`, `:136`, `:143`, `:158`) pass today only because `board_sync.py:63-64` and
`mock_gh_board.py:31-32` hardcode the same values and agree by coincidence. Give those legs explicit
`XYZ_BOARD_SYNC_PROJECT_OWNER` / `_NUMBER`, and pin `XYZ_DEVICE_CONFIG_PATH` — recon confirmed this
host has no `board_sync` block, so the legs read the real user config today and pass only because it
is empty.

**4.3** Scope detection. `_gql` (`:242-267`) folds every GraphQL error into one opaque string at
`:265`. Detect `INSUFFICIENT_SCOPES` there and print `gh auth refresh -s read:project,project`. Verified
unsandboxed: this host's token is `gist, read:org, repo, workflow`. Add an `insufficient_scopes` fault
to `mock_gh_board.py` beside `stale_option_once` (`:210-221`) — criterion 8 has no mock affordance today.

**4.4** `work reconcile --connector <name>` replays events after the cursor. Idempotent because the
board write is a set-to-value, not an increment.

**4.5** PR emitters.

- `githooks/pre-push` — one backgrounded call before each of the three green exits (`:275`, `:292`,
  `:309`). **The honest event is `branch_pushed`, not `pr_opened`**: the hook discards the ref name at
  `:73`, makes no `gh` call anywhere in `githooks/`, and runs *before* the push is accepted. The
  connector maps `branch_pushed` to the review column. It must be backgrounded — the file runs
  `set -uo pipefail` with no `-e`, so a failing emitter cannot abort the push, but a hanging one would
  stall it, the hazard `:157-161` already guards against with a timeout.
- `merge_cleanup.py` — emit inside the `if merged:` block at `:369-370`, gated on `not dry_run`.
  **Not** in `execute_pr_merge` above `:58`, where the dry-run arm returns `True` without merging.
  `--reconcile-pr` (`:286-290`) never verifies merge state, so it does **not** emit; that path is
  covered by `reconcile`.

Accepted blind spots, closed only by `reconcile`: `git push --no-verify` (`:34`), `XYZ_SKIP_PREPUSH`
(`:82-86`), a merge performed in the GitHub UI.

## Registration

`test/gh549-work-events.sh` into `validate.sh`'s `TESTS` array, then the three-part act in
`utils/ci-route.sh` (`SUBSYSTEMS` `:24`, `SUBSYSTEM_TESTS_*` `:25-33`, `subsystem_of()` `:35-47`).
`test/gh35-test-tiers.sh:133-142` fails if the pair drifts. Note `githooks/pre-push` and
`skills/merge-cleanup/*` are unmapped in `subsystem_of()`, so this branch will run the full tier-3
gate on every push — expected, not a defect.

## Risks and rollback

| Risk | Mitigation |
|---|---|
| A cursor write breaks the receipt chain | Both tables excluded from `business_digest`; red control in 1.4 proves it |
| Migration 008 lands without dump/load support | `check --rebuild` in the suite, which fails loudly if either is missing |
| A connector blocks a ledger verb | Detached + timeout + ignored rc; red control removes the guard and asserts the failure |
| The first write after merge creates live cards on someone's board | No default owner or number; criterion-1 red control |
| Vendored `.xyz/` ledgers migrate on next use | `perform_migration` already handles this; migration is `txn_safe` and idempotent |

**Rollback:** revert the branch. Migration 008 leaves two unused tables in any ledger that already
migrated; both are `IF NOT EXISTS` and outside `business_digest`, so a reverted binary ignores them.

## Ordered implementation list

1. Migration 008 + `dump_text` + `load_dump`; migrate-a-fixture check and the chain red control.
2. `work_events` insert in `perform_write` + the `op` map; crash red control.
3. Connector registry, config resolution, detached dispatch; two-stub red control.
4. GitHub connector; personal literals out; repair `gh405` legs 4-6 and pin `XYZ_DEVICE_CONFIG_PATH`.
5. Scope detection + `insufficient_scopes` mock fault.
6. `work reconcile`; idempotency check.
7. `pre-push` and `merge_cleanup` emitters.
8. Register the suite in `validate.sh` and `utils/ci-route.sh`; full gate in a disposable clone.
