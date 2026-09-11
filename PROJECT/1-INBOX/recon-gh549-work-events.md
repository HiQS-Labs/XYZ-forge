# Recon Map — the ledger write seam, the config surface, and the two PR emitters

Commit: `52938679` (task clone `~/task-clones/xyzforge-gh549-work-events`, branch
`feat/gh549-work-events-connectors`) · Mode: grep + full-file reads, three read-only sub-agent lanes ·
Lanes: **B** (ledger write seam and schema), **C** (config surface and the GitHub connector),
**A/D** (PR emitters, test and gate conventions).

This map extends `recon-projects-board-sync.md`, which answered "what writes to the board today"
against commit `7464fbbb`. That map's verdict still holds at `52938679`: a complete board
reader/writer exists, has run live, and **nothing invokes it automatically**. This map answers the
different question GH-549 actually needs — *where does a work event come from, what config carries a
connector, and where do PR events originate.*

## Subject and change class

**Subject:** the transaction inside `perform_write()`, the `device_config` resolution path, and the
push/merge boundaries.
**Change class:** state/authority change — a new append-only table joins a receipt-protected ledger,
and a new dispatch path leaves the process.

## The seams — where a change here escapes its file

| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| The one write transaction | `utils/py/releases_app.py:1352` (BEGIN) → `:1388` (commit) | every ledger verb | an insert lands outside it, or changes `business_digest` |
| The receipt chain | `releases_app.py:1351` / `:1381` digests, `:1382-1386` receipt, verified `:4659-4704` | every future write | any table in the business dump is mutated without a receipt |
| Schema registry | `releases_app.py:966-974` `MIGRATIONS` | every clone and vendored ledger | a version is added without dump + load_dump support |
| Nested config block | `utils/py/device_config.py:34-43` + the in-module merge idiom | every connector | anyone routes a dict through `resolve_device_setting` |
| Board mutations | `board_sync.py:397-401`, `:453-458`, `:489-490` | repo → live ProjectV2 | dispatch is not backgrounded and rc-ignored |
| Push boundary | `githooks/pre-push:275`, `:292`, `:309` | repo → event | an emitter blocks or hangs the push |
| Merge boundary | `skills/merge-cleanup/scripts/merge_cleanup.py:369-370` | repo → event | emitted above line 58 (the dry-run arm returns True) |

## Call paths in

```
28 ledger verbs (releases_app.py) ─┐
                                   ├─► perform_write(root, conn, op, target_gid, mutate)  :1317
                                   │      WriterLock :1331 · journal :1344 · digest_before :1351
                                   │      BEGIN IMMEDIATE :1352 · mutate(conn) :1354
                                   │      generation stamp :1368 · digest_after :1381
                                   │      op_receipts INSERT :1382 · commit :1388
                                   │      dump + generated view :1391 · atomic rename :1398
git push  ──► githooks/pre-push ───┴─► (green exits :275 / :292 / :309)
gh pr merge ─► merge_cleanup.py:57-64 ──► if merged: :369
```

`perform_write` is at **`releases_app.py:1317`**. The issue body cites `:1382`; that is the
`op_receipts` INSERT inside it, not the function. Corrected here.

All 28 callers live in `releases_app.py` and nowhere else. Their `op` strings are literals except
`jog_set_status` (`:4417`, writes at `:4440`), which computes `f"jog-{status}"` — **any event mapping
keyed on `op` must handle that dynamic prefix, not a fixed list.**

## State

**Read sites** are many and mostly `mode=ro` — `board_sync.py:181`, `wave_reconcile.py:581`,
`site_build.py:108`, `express.py:499`, `_marathon_plan.py:770`, `releases_cycle.py:43`,
`export_timeline.py:566`.

**Write sites.** `perform_write` is the single write path for domain verbs, with four deliberate
exceptions, all inside `releases_app.py`: `cmd_init` (`:1937-1970`, genesis, no receipt),
`perform_migration` (`:1411-1531`, own receipt at `:1496`), `_rebuild` (`:5141`, `merge-rebuild`
receipt at `:5232`), and `load_dump` (`:4950`, restore).

**One real bypass, outside `releases_app.py`:** `utils/py/jog_run.py:1638` and `:1692` call
`_ensure_jog_schema(conn)` (`releases_app.py:915-922`, `stamp=True` by default) on a bare
`sqlite3.connect`. The line immediately above the first call reads *"Hermetic --dry-run: zero
mutations, zero locks, zero DB writes"* (`jog_run.py:1633`) — and `CREATE TABLE` is autocommitted by
Python's sqlite3 in legacy isolation mode, so on a pre-006 ledger `--dry-run` does write. Filed
separately; not GH-549's job to fix, but GH-549 must not add a second one.

## Contracts

| Contract | Consumer | Breaking if | Declared at |
|---|---|---|---|
| `op_receipts` is append-only | `check` chain walk | a trigger is dropped | `releases_app.py:618-621` |
| `business_digest` covers business state only | every subsequent write | a mutable table enters the dump | `releases_app.py:1224-1226` |
| `resolve_device_setting` is top-level scalars | every config consumer | a dict is routed through it | `board_sync.py:90-92` |
| board is a projection; failure degrades | adapters (none exist) | dispatch blocks a host command | `board_sync.py:22-24` |
| suites registered in two places | `test/gh35-test-tiers.sh:133` | `ci-route.sh` lists a suite `validate.sh` does not | `utils/ci-route.sh:20-23` |

## Build, failure and rollback today

A new suite is registered in `validate.sh`'s `TESTS` array (`:55-608`) and, for Tier-2 routing, in
`utils/ci-route.sh` as a three-part act — `SUBSYSTEMS` (`:24`), `SUBSYSTEM_TESTS_<name>` (`:25-33`),
`subsystem_of()` (`:35-47`). `test/gh35-test-tiers.sh:133-142` fails if the pair drifts.
`githooks/pre-push` and `skills/merge-cleanup/*` are unmapped in `subsystem_of()`, so touching either
forces the full tier-3 gate.

Rollback for a schema change is `check --rebuild` plus the merge driver; both depend on the new tables
being present in **both** `dump_text` and `load_dump`, or the rebuild fails.

## What this changes about the plan — five findings

**1. `connector_cursors` must be excluded from `business_digest`, or every ledger write fails
`check`.** A cursor advances *after* the transaction, from the dispatcher. If the table is in the
business dump, the next `perform_write`'s `digest_before` (`:1351`) will not equal the previous
`digest_after` (`:1381`), and `cmd_check`'s chain walk (`:4659-4681`) reports a broken chain on every
single write. `work_events` should follow `op_receipts` exactly: emitted in the dump under the
`include_receipts` guard (`:1214-1220`), excluded from the digest. That also fixes the insert
placement — beside the receipt at `:1382`, not before `digest_after`.

**2. `device_config` cannot carry `work_connectors` through its generic resolver.** It handles
top-level scalars only; the env tier produces strings and there is no deep merge. The shipped idiom
for a nested block is `board_sync.py:89-119` `resolve_settings()` (defaults dict → file block →
per-key `XYZ_BOARD_SYNC_<KEY>` env with int and list coercion). `profile_resolve.py:189-207` is the
second instance, and it re-opens the config file itself because `load_local_device_config()`
(`device_config.py:34-43`) collapses "file absent" and "file unparseable" into the same `{}`. GH-549
needs that distinction: absent is a silent no-op, unparseable must warn.

**3. Removing the personal defaults breaks six existing assertions.** `test/gh405-mock-board-harness.sh`
legs 4-6 (`:105`, `:114`, `:126`, `:136`, `:143`, `:158`) run `board_sync touch --write` against the
mock while setting only the three `XYZ_BOARD_SYNC_GH_BIN` / `_MOCK_BOARD_STATE` / `_STATE_PATH` vars.
They pass today only because `board_sync.py:63-64` and `mock_gh_board.py:31-32` both hardcode
`noelsaw1` / `3` and therefore agree by coincidence. Acceptance criterion 2 deletes one side of that
coincidence, so those legs must be given explicit owner/number config in the same change.
`test/gh402-board-sync.sh:124-125` survives a changed literal but not a removed **key** — its env-tier
override iterates `DEFAULTS` and int-coerces on `isinstance(DEFAULTS[key], int)` (`board_sync.py:98-109`).

**4. `pre-push` cannot say "opened a PR", and does not know the PR number.** It reads the local ref
name at `:67` and immediately discards it (`:73` keeps only the SHA pair); there is no `gh` call
anywhere in `githooks/`. It also runs *before* the push is accepted, so the honest event is "a
reviewed branch is being pushed", not "a PR exists". Blind spots that only `reconcile` can close:
`git push --no-verify` (`:34`) skips the hook entirely, `XYZ_SKIP_PREPUSH` (`:82-86`) short-circuits
it, and a delete-only push exits at `:77-80`. The safe emit points are the three green exits (`:275`,
`:292`, `:309`), backgrounded — the file runs `set -uo pipefail` with **no `-e`**, so a failing
emitter would not abort the push, but a hanging one would stall it, the same hazard `:157-161` already
guards with a timeout.

**5. The offline mock has no affordance for acceptance criterion 8.** `mock_gh_board.py` implements
exactly one fault, `stale_option_once` (`:210-221`), and has no token, scope, or
`INSUFFICIENT_SCOPES` concept. It also never paginates (`:161-164` always returns
`hasNextPage: false`), so `board_sync`'s pagination loops (`:358-373`, `:468-481`) are unexercised.
Criterion 8 needs a new fault added to the mock; the pagination gap is noted and left alone.

## Unknowns

| Unknown | Why it matters | What would settle it |
|---|---|---|
| Whether `githooks/install.sh`'s fallback stub would skip a new emitter on stale checkouts | Silent absence on older clones | read `githooks/install.sh` |
| Whether `--reconcile-pr` should emit a merged event | It never verifies merge state, so emitting there could lie | operator/reviewer call during plan QA |
| Whether the mock's lack of pagination hides a real `board_sync` paging bug | Out of scope here, but it is unexercised code | add a >100-item mock fixture and run `reconcile` |

### Resolved while writing this map

- **The `gh` token really does lack `read:project`.** Run unsandboxed: `Token scopes: 'gist',
  'read:org', 'repo', 'workflow'`. Criterion 8's premise is verified, and GH-402's Phase 0 finding
  that the ambient token can mutate a user project is confirmed invalid.
- **No event-emitter helper exists to reuse.** `git grep -ln 'work_event|emit_event|work-event' --
  '*.py' '*.sh'` returns nothing, so `work_events` is a new mechanism rather than a second one.
- **This host's `device_config.json` has no `board_sync` block at all** (`load_local_device_config()
  .get("board_sync")` → `None`). So `gh405` legs 4-6 pass today because the key is absent, not
  because they are isolated — the host-dependency in finding 3 is real but currently dormant. Pin
  `XYZ_DEVICE_CONFIG_PATH` in those legs as part of this work.

## Current-state radius, one line

Every ledger verb in `releases_app.py` and its receipt chain; the `releases.db` schema registry and
every clone or vendored ledger that must migrate; `device_config.json` and its four consumers;
`board_sync.py` and the two suites that pin it; `mock_gh_board.py`; `githooks/pre-push` and every
developer's push latency; `merge-cleanup`'s merge path; and `validate.sh` + `utils/ci-route.sh`
registration, which decides whether a push runs the 30-second gate or the ten-minute one.
