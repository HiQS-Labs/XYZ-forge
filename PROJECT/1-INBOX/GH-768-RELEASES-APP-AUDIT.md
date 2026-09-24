---
title: "GH-768: releases_app.py audit (duplication, dead code, seams, performance, test gaps)"
status: Proposed (1-INBOX — not yet active)
gh_issue: 768
source: https://github.com/HiQS-Labs/XYZ-forge/issues/768
doc_type: feedback
created: 2026-09-23
updated: 2026-09-23
owner: Claude
---

# GH-768 — releases_app.py audit (research only)

Target: `utils/py/releases_app.py` (6,695 lines, 2026-09-23 working tree). No code was changed.
System position (from `ARCHITECTURE/ledger-diagram.json`, `system-diagram.json`): node `releases-cli`
("releases_app.py verbs"). It is the only business writer to `releases.db` and `releases.sql` through
`perform_write` (WriterLock, intent journal, receipts). Callers: operator skills, `hq park`,
`wave_reconcile.py` (roadmap and check verbs), the routed pre-push/CI releases suites, and
`jog_run.py` (jog lease/status helpers). Readers: planner, Flightdeck (`load_work_evidence`), and
`export_timeline.py` / `leaderboard.sh`, which `refresh_preview` runs after every write.

## Summary

The core write protocol is sound and well documented. The file's weight comes from four things:
(a) 43 `_has_column(..., "updated_at")` forks that keep pre-migration-007 ledgers working, which
roughly doubles every INSERT/UPDATE;
(b) copy-pasted lookup and refusal blocks: issue-ref by token, the jog row selector, the roadmap
`--issue-num/--gid` selector, generation stamping and the stage/rename tail;
(c) three separate implementations of "origin remote → owner/repo" and two gh-binary env vars;
(d) per-row loops that each run the whole write protocol (`work backfill`, the review-ready scan),
where every write rebuilds a ~940 KB dump three times and runs `leaderboard.sh`.
One real bug turned up: `releases --root X jog resume|land|reconcile|retry-gate|retry-build N`
silently drops `--root` (verified on Python 3.9, 3.11 and 3.13). The file splits cleanly into
about 10 modules behind a `releases_app.py` facade. A refactor is only safe once `test/gh32-releases-app.sh`,
`gh549-work-events.sh` and `gh360-scoped-receipt-chain-rebuild.sh` are confirmed to cover
the dump byte format, and a golden-dump test pins `dump_text` output. Caller and coverage mapping
for rarely used verbs is marked **unverified**: the full cross-repo caller sweep had not
finished when this doc was written.

## Ranked findings

| id | category | file:line | evidence | proposed fix | also affects | effort | confidence |
|---|---|---|---|---|---|---|---|
| F1 | bug (argparse) | releases_app.py:6602-6630 (`--root` on jog resume/retry-gate/retry-build/land/reconcile) | Sub-parser `--root default=None` overwrites the top-level `--root`. `parse_args(['--root','/tmp/X','jog','resume','5']).root` → `None` on 3.9.6, 3.11.15 and 3.13.14. `jog list` keeps `/tmp/X`. The handlers at 4835 and 4856 then fall back to the CWD git toplevel. | Drop the per-subcommand `--root` args, or use `default=argparse.SUPPRESS`. | `jog_run.py` verbs, skills calling `releases --root … jog land` (unverified which) | S | verified |
| F2 | perf | 5019-5087, 5131-5189, 1616-1722 | `work backfill` calls `_emit_work_event` → `perform_write` once per roadmap row (295 rows in the live DB). Each write takes the lock, writes a journal, runs `business_digest` twice (~7 ms each) plus one `dump_text` (~13 ms, 939 KB) with fsync, then `refresh_preview`, which runs `bash utils/leaderboard.sh` (~110 ms measured) in this repo because `LEADERBOARD.md` is adopted, then `_dispatch_work_connectors`. The review-ready scan does the same once per linked issue. | Add a batch path: one `perform_write` with `work_events=[...]` (already supported, 1675), with the `_AlreadyRecorded` check done per event inside one mutate. | `LEADERBOARD.md` churn, connector dispatch count, writer-lock hold time | M | verified (timings on scratch copy) |
| F3 | perf | 1650, 1669, 1698 (and 1783, 1807, 1825) | Every write serialises the whole DB three times: the digest before, the digest after, and the dump. Cost grows with ledger size, not change size. | Reuse the after-state text: compute `dump_text(include_receipts=False)` once for `digest_after` and assemble the full dump from it. A longer-term option is per-table digests. | `check`'s receipt chain semantics must not change | M | verified |
| F4 | duplication (internal) | 43 sites, e.g. 1104-1229, 1657, 1795, 2020, 2135-2148, 2160, 2190, 2298-2317, 2321, 2360-2381, 2414, 2482, 2541, 2611, 2657, 2713, 2778, 2872, 2900, 3779, 5879-6023, 6126, 6305, 6312 | `if _has_column(conn, T, "updated_at"): <SQL with updated_at> else: <same SQL without>`. The live DB has migrations 1-8, and 007 added the column. | Add one helper, `_ins(conn, table, **cols)` / `_upd(...)`, that drops `updated_at` when the column is absent. Alternatively, require `releases migrate` to 007 and delete the else-branches. That second option is a policy decision: ledgers in other repos may be older (unverified). | dump/rebuild paths, every cmd_* | M | verified |
| F5 | duplication (internal) | 1657-1668, 1795-1806, 6126-6139; tail 1698-1707 vs 1825-1832 | The generation-stamp block is written out three times, and the stage/rename/crash-boundary tail twice (`perform_write` vs `perform_migration`). | Extract `_stamp_generation(conn, gen)` and `_finish_write(root, lock, paths, gen)`. | crash-injection suites (5 boundaries) | S | verified |
| F6 | duplication (internal) | 2651-2655, 2690-2694, 2770-2776, 2822-2826 (+2014-2017) | The "issue_refs row by (kind,value) or refuse unknown-issue" lookup is copied four times. `manifest cut` uses a differently shaped if/else for the same query. | Add `_find_issue_ref(conn, token)`. | manifest ship/marathon/cut/unship | S | verified |
| F7 | duplication (internal) | 2584-2595 vs 2856-2865 | The "dialed-in elsewhere" exclusivity query and its refusal are duplicated between `manifest dial-in` and `unship`. | Add `_refuse_if_dialed_elsewhere(conn, ref, rel)`. | GH-111 exclusivity rule | S | verified |
| F8 | duplication (internal) | 4382-4387, 4541-4548, 4583-4590, 4623-4630, 4704-4713, 4734-4741 | The jog row selector (`WHERE gh_number=? LIMIT 2`, not-found, multi-repo refusal) appears 6 times. `jog bump` (4504-4510) instead scopes to the first repo, which is inconsistent with the others. | Add `_jog_row(conn, gh_num, cols)`. Decide whether `bump` should follow the multi-repo rule. | `jog_run.py` via `jog_set_status` / `jog_acquire_lease` | S | verified |
| F9 | duplication (internal) | 3656-3670 vs 3856-3875; dry-run rating print 3578-3584, 3692-3696, 3899-3905 | The roadmap `--issue-num/--gid` selector and the "rating: / ovr:" dry-run output are copy-pasted. | Add `_resolve_roadmap_row(conn, args, cols)` and `_print_rating(rating)`. | roadmap add/rate/update/move | S | verified |
| F10 | duplication (internal) | 1444-1453 vs 4997-5016 | `_live_roadmap_event` and `_backfill_event_for` share the same section/marker classifier. They differ only in Deferred → `"deferred"` versus `None`. | Keep one classifier, and let backfill map `deferred` → skip. | work_events vocabulary, Flightdeck | S | verified |
| F11 | dead logic | 5367-5373 vs 5199-5212 | Inside `load_work_evidence`, `explicit_transition` recomputes exactly the START-event predicate of `_is_lifecycle_event`. `latest_lifecycle` was already selected by that predicate, so `explicit_transition` is always True. | Delete the recomputation. | `test/flightdeck/test_work_status.py` | S | verified |
| F12 | duplication (internal) | 2033-2041, 5104-5112, 5243-5252 | Three origin-remote → `owner/repo` resolvers, using two different regexes (`github\.com[/:]…` vs `[:/]([^/:]+/[^/]+?)`). | Add one `_origin_slug(root)`. | `tracking_token_to_url`, the review-ready scan, `load_work_evidence` | S | verified |
| F13 | duplication / inconsistency | 237-266 (`RELEASES_GH_BIN`), 3978-3981 (inline gh subprocess, `RELEASES_GH_BIN`), 5152 (`XYZ_BOARD_SYNC_GH_BIN`) | gh is run three ways, under two env overrides. `reconcile-state` reimplements `_gh_json` inline. | Add one `_gh(argv, *, json=True, env_key=...)`. Document which override applies. | tests that mock gh | S | verified |
| F14 | perf (N+1 subprocess) | 3967-4001 | `roadmap reconcile-state` runs one `gh issue view` subprocess per non-terminal row, each with a 30 s timeout. | Batch per repo with `gh issue list --state all --json number,state,stateReason`, or one GraphQL query. | `wave_reconcile.py` (if it calls reconcile-state: unverified) | M | verified |
| F15 | perf (N+1 subprocess) | 3131-3207 | `project sync --apply` makes 10 `gh project item-edit` calls per release (3204-3205), serially. | Use a GraphQL batch mutation, or skip unchanged fields by diffing against `item-list` values. | GitHub rate limits | M | verified |
| F16 | perf (N+1 query) | 6215-6217 | `dashboard` runs two COUNT queries per release. | One grouped query. | none | S | verified |
| F17 | correctness | 6231-6257, 6189 | `dashboard` interpolates DB text (codename, exit criterion, title) into HTML without escaping. Its read-only URI does not quote the path, unlike `load_work_evidence` (5286). It also queries `roadmap_items` without checking that the table exists. | `html.escape`, and reuse one read-only-connect helper. | anyone opening the output | S | verified |
| F18 | duplication (cross-file) | releases_app.py:4336-4341 vs utils/timeline/export_timeline.py:57-64 | `roadmap list` derives `calc` and override-wins itself. `leaderboard.sh` states "ONE SCORER, NEVER TWO", and export_timeline says it applies the rule "once, here". | Import the scorer from one module. | LEADERBOARD.md, roadmap list | S | verified |
| F19 | duplication (cross-file) | releases_app.py:3354-3358, 3425-3494 vs utils/py/_marathon_plan.py:497-556 | The ROADMAP.md ledger parser has a twin, and the in-code comments say so (3214-3218, _marathon_plan.py:494). | Move to a shared `roadmap_markdown` module, or retire both if legacy mode is gone (unverified). | marathon planner | M | verified (both exist) |
| F20 | dead/near-dead | 4044-4057, 3425-3494, 1933-1978, 2170-2338, 4863-4865 | `roadmap sync` is a documented no-op in releases-mode (this repo's `.pdda-mode`), but `wave_reconcile.py` "calls sync unconditionally" (4048). `import` is one-shot legacy. `gen` only refuses. That is roughly 600 lines kept for legacy/non-releases-mode repos. | Decide whether legacy mode is still supported downstream. If not, move this code to `releases/legacy.py` and consider retiring it. | vendored installs (`gh105`, `gh349` tests) | M | unverified (downstream usage) |
| F21 | dead/stale doc | 4975-4977 | The `cmd_work_emit` docstring cites `_extract_none`, which exists nowhere. `work-emit` is in `NON_EVENT_OPS` (1412). | Fix the docstring. | none | S | verified |
| F22 | forward-compat branch | 5327-5331 | `status_label` requires schema ≥ 9, but the `MIGRATIONS` registry stops at 8 (1016-1025). Only hand-built fixtures in `test/flightdeck/test_work_status.py` reach it. | Keep it, but add a comment naming the owning issue. | Flightdeck | S | verified |
| F23 | hygiene | 1605, 4825, 4833, 4854, 5096, 5424, 5456 | `sys.path.insert(0, …)` runs on every call. `_dispatch_work_connectors` runs once per write, so `sys.path` grows during loops (F2). | Insert once at module import, guarded. | none | S | verified |
| F24 | duplication (internal) | 44 × `resolve_root(args.root)`, 46 × `connect(...)`, 30 × `perform_write(root` | Each command repeats the same root/connect/try/finally/close scaffold. | Add a `@with_conn(write=True)` decorator or a context manager. | all cmd_* | M | verified |
| F25 | import-time work | module top | `python -X importtime`: 17.6 ms cumulative; the only module-level work is regex compiles and `MIGRATION_001.format`. | None needed. | n/a | - | verified (no issue) |
| F26 | dead-verb candidates | parser 6332-6645 | A rough grep outside `PROJECT/` and `relay-system/` found 0 non-self references for `marathon list`, `manifest unship`, `roadmap sections`, `work backfill`, `settings get`, `list --all-repos`, `reconcile --map`. Tests often call through a variable (`"$APP" …`), so the grep undercounts. | Confirm each verb with a variable-aware sweep before retiring anything. None is proposed for deletion yet. | skills/, tests | S | **unverified** |

## Test coverage (what exercises this file)

Files that reference `releases_app`, by reference count: `test/gh549-work-events.sh` (45),
`gh568-releases-md-retired.sh` (20), `gh280-jog-marathon-adapter.sh` (18),
`gh360-scoped-receipt-chain-rebuild.sh` (15), `gh32-releases-app.sh` (12),
`gh358-wave-reconcile-vendored-paths.sh` (10), `gh645`, `gh238`, `gh269`, `gh197`, `gh567`,
`gh353`, `test_gh605_board_policy.py`, `gh534_phase_b_tests.py`, `jog-queue.sh`,
`test_gh605_work_state.py`, `flightdeck/test_work_status.py`, `gh423-roadmap-render.sh`,
`gh527-issue-url-repair.sh`, `gh75-dashboard.sh`, and about 20 more with 1-3 references.

Gaps that make a refactor unsafe (unverified until a per-verb coverage map exists):
- No known golden test pins `dump_text` byte output across schema versions (pre-004, pre-007).
  F3 and F4 both touch it, and `check` compares dumps byte for byte.
- The pre-007 (`updated_at`-absent) branches of F4 need a fixture ledger at schema ≤ 6. Whether
  one exists is unverified.
- No test was found for `--root` combined with jog sub-verbs; that is why F1 went unnoticed.
- `project sync` depends on gh; whether a mocked-gh test covers `--apply` is unverified.
- `roadmap reconcile-state` has gh mocking via `RELEASES_GH_BIN` (the test file is unverified).

## Proposed split (keep `utils/py/releases_app.py` as a facade)

External code imports symbols from `releases_app` (for example `jog_run.py` uses `jog_set_status`,
`jog_acquire_lease` and `jog_reconcile_orphan_leases`, and Flightdeck uses `load_work_evidence`). So
the file stays as a thin CLI that re-exports those symbols, and its source-scanning test
(`gh549` derives op inventory "from this source file", 1386) is repointed.

| module | current lines | contents |
|---|---|---|
| `releases/core.py` | 72-300, 1066-1073, 2116 | constants, `now_iso`, gid/ulid, `refuse`/`warn`, small helpers |
| `releases/gh.py` | 237-266, 2033-2041, 5090-5113, 5243-5252 | one gh runner and one origin-slug resolver (F12, F13) |
| `releases/store.py` | 301-475, 1306-1328 | root/lock/journal paths, WriterLock, connect, settings, atomic write |
| `releases/schema.py` | 477-1055 | DDL and the migration registry |
| `releases/dump.py` | 1057-1302, 5721-6178 | dump_text/digest, parse/validate/load, `_rebuild` |
| `releases/protocol.py` | 1330-1913 | work-event registry, `perform_write`, `perform_migration`, recovery, refresh_preview |
| `releases/release_cmds.py` | 1985-2118, 2122-3098, 6280-6327 | releases, manifest, marathon, readers, `reconcile --map` |
| `releases/roadmap.py` | 3212-4346 | rating grammar, roadmap verbs (legacy markdown parser split into `legacy.py`) |
| `releases/jog.py` | 4349-4858 | queue verbs, lease helpers, jog_run delegation |
| `releases/work.py` | 4870-5488 | emit/backfill/reconcile/status, `load_work_evidence` |
| `releases/check.py` | 5490-5718 | `check` |
| `releases/views.py` | 3101-3209, 6180-6277 | project sync, dashboard |
| `releases/legacy.py` | 1915-1978, 2159-2338, 3425-3494, 4044-4209, 4863 | import, roadmap sync, gen stub (F20) |

## Suggested follow-up issue order

1. F1: fix the `--root` bug for the jog sub-verbs and add a regression test (S, standalone).
2. Test pinning: a golden dump test across schema fixtures (v2, v6, v8) plus a per-verb coverage map
   that closes F26. This is the precondition for everything below.
3. Small DRY extractions with no behaviour change: F5, F6, F7, F8, F9, F10, F11, F12, F13, F21, F23.
4. F2 (batch backfill / review-ready) and F3 (a single serialisation per write). These are the measurable perf wins.
5. F4: `updated_at` helper, or a minimum-schema policy decision (needs an operator call on older downstream ledgers).
6. F14, F15, F16, F17: gh batching, dashboard fixes.
7. F18, F19: shared scorer and roadmap parser across modules.
8. The module split behind the facade, then F20 (legacy retirement) once downstream usage is confirmed.

## Appendix A: Caller and test sweep (resolves the "unverified" items above)

This sweep finished after the main doc was written. It covers the whole repo except `relay-system/`, `PROJECT/`, `marathon-system/`, `TESTS-RESULTS/`, `.tick/orphan-backups` and `__pycache__`.

### A1. New defects found in callers

| id | where | defect |
|---|---|---|
| A1-1 | `skills/3-weekly/10days/SKILL.md:206,231` | Calls `releases_app.py roadmap show <N>`, which does not exist (the roadmap subparsers are at `releases_app.py:6489-6561`). At :206 the failure is hidden by `2>/dev/null \|\| true`. |
| A1-2 | `skills/1-hourly/standup/collect.sh:971,1010` | Suggests `releases_app.py ship {v}`. `ship` requires `--gid` and takes no positional argument (`releases_app.py:6375-6379`), so the suggested command fails with a usage error. |
| A1-3 | `skills/2-daily/marathon-triage/SKILL.md:283` | Cites `releases_app.py:4901` for `marathon add --tracking-issue`; the definition is now at `:6420`. |
| A1-4 | `utils/py/jog_run.py:1247` | Hardcodes the `utils/py/releases_app.py` path for `roadmap repoint`, so it breaks on vendored installs. The file already imports `resolve_tool` (:36). |
| A1-5 | `utils/py/jog_run.py:1612` (`--dry-run`), `:1666` | Runs `_ensure_jog_schema` (DDL plus `INSERT INTO schema_migrations`, `releases_app.py:965-972`) outside `perform_write`. Whether this persists anything is unverified. Related to #552. |
| A1-6 | `utils/pdda/pdda.sh:847` | Runs `list` with no `--root` and no `cd`, so it relies on the caller's cwd. Unverified whether that always matches `PDDA_REPO_ROOT`. |

### A2. Verbs with no executable caller outside tests

`migrate`, `baseline`, `manifest add` (alias), `manifest marathon`, `manifest unship`, `marathon list`, `gen` (retired), `dashboard`, `settings list/get/set`, `work status`, `roadmap sections`, `roadmap render` (as a CLI verb; `_marathon_plan.py:34` imports the function), `roadmap move`, `project sync`, `list --all-repos` / `RELEASES_APP_EXTRA_DBS`.

**No caller and no test at all:** `marathon list`, `settings list`, `settings get`, `work status` (via the CLI; its backend `load_work_evidence` is covered by `test_gh605_work_state.py`).

"No caller" does not mean safe to delete. `migrate`, `baseline`, `settings`, `roadmap move` and `work status` are operator verbs documented in `RELEASES-DB-FAQS.md`, `ROUTER.md` and `SOP.md`. Candidates for removal are `manifest add` (alias), `gen` (already refuses) and `marathon list`, and only after an operator decision.

Single-caller verbs, all in `relay-automation/xyz-releases-onboard.sh`: `init` (:101), `import` (:102), `reconcile --map` (:218).

### A3. Python importers (the public-API surface a split must preserve)

- `jog_run.py:39-45`: `_ensure_jog_schema`, `_table_exists`, `jog_acquire_lease`, `jog_set_status`, `jog_reconcile_orphan_leases`
- `board_sync.py:1115` (lazy) and `releases_cycle.py:47-56` (isolated `python -I` subprocess): `load_work_evidence`
- `_marathon_plan.py:34`: `roadmap_render`
- Tests import, among others: `connect`, `dump_text`, `load_dump`, `parse_dump`, `get_generation`, `business_digest`, `MIGRATIONS`, `MIGRATION_*`, `apply_migrations`, `perform_migration`, `perform_write`, `_migration_004`, `_has_column`, `cmd_init`, `cmd_roadmap_add`, `new_gid`, `now_iso`, `parse_rating`, `issue_ref_for_token`, `registry_versions`, `artifact_paths`, `roadmap_render`, `parse_roadmap_ledger`, `_is_ledger_bullet`, `_latest_event`, `_scan_review_ready`, `extractor_for`, `_extract_roadmap_update`, `_live_roadmap_event`, `refresh_preview`, `_dispatch_work_connectors`, `jog_acquire_lease`, `jog_reconcile_orphan_leases`, `main`.

A split must re-export all of these from `releases_app` or update the importers in the same change.

### A4. Test routing gap (refactor blocker)

`utils/ci-route.sh:24-26` `SUBSYSTEM_TESTS_releases` lists 23 suites. These suites exercise `releases_app` and are registered in `validate.sh`, but are **not** in that list, so a change to `releases_app.py` alone runs tier 2 without them:

`jog-queue`, `gh280`, `gh351`, `gh349`, `gh423`, `gh424`, `gh491`, `gh492`, `gh527`, `gh75-dashboard`, `gh360` (both), `gh454`, `gh525`, `gh418`, `gh421`, `gh238`, `gh239`, `gh290`, `gh291`, `gh197`, `gh605-*`.

Not wired into `validate.sh` or CI at all: `test/gh534_phase_b_tests.py` (it also misses pytest's `test_*.py` pattern) and `test/flightdeck/test_work_status.py`.

Largest suites: `gh32-releases-app.sh` (~120 invocations), `gh69-roadmap-shadow.sh` (~47), `gh549-work-events.sh` (~45), `gh280` and `jog-queue` (~35 each).

**Recommendation:** fix `SUBSYSTEM_TESTS_releases` before any extraction work. Otherwise a refactor PR can pass tier 2 while breaking about 25 suites.

### A5. Logic duplicated across the repo

- **GitHub slug from origin:** 3 copies inside `releases_app` (:2033, :5090/5105, :5243), plus at least 15 elsewhere: `harness_paths.py:130` (the documented twin), `swarm_preflight.py:787`, `backfill_source_url.py:39`, `rtl.py:616`, `marathon_drive.py:168,1584,1635,1872`, `merge_cleanup.py:239`, `scan_clones.py:341,356`, `hq-lib.sh:576`, `pdda-lib.sh:411`, `relay-turn-lib.sh:165`, `xyz-releases-onboard.sh:106-108`, `find-xyz.sh:95`, `marathon-drive.sh:345`.
- **`gh` wrappers:** `releases_app._gh_json`/`_gh_run` (:237, :256) plus `board_sync.py:520`, `express.py:162`, `hosted_lane_report.py:44`, `jog_run.py:858` (and raw calls at :1446, :1460, :1496), `_marathon_plan.py:435,462`, `merge_cleanup.py:66,70`, `scan_clones.py:337`. Each uses its own env-var override.
- **Atomic writes:** `releases_app._atomic_write` (:1325, plus inline `os.replace` at :1702, :1828, :6170) plus `board_sync.py:552,1082`, `jog_run.py:334-341`, `express.py:133,145`, `attempt_record.py:122`, `agent_chorus.py:868`, `intake.py:79,94`.
- **Repo root / `git_common_dir` / tool-path resolvers:** repeated across `harness_paths`, `rtl.py`, `harness_app.py`, `marathon_drive.py`, `relay_drive.py`, `agent_chorus.py`, `relay_attest.py`, and six shell scripts. Hardcoded app paths remain in `express.py:170`, `jog_run.py:1247` and `pdda.sh:845`.
- **UTC timestamps:** `releases_app.now_iso` (:175, mockable via `RELEASES_APP_NOW`) versus `express.py:85` (millisecond format, not mockable), `agent_chorus.py:77`, `flightdeck/contract.py:18`, `attempt_record.py:92`, `marathon_drive.py:1431`, plus inline `timezone.utc` in `jog_run.py`, `board_sync.py`, `wave_reconcile.py`, `releases_cycle.py` and `export_timeline.py`.
- **Roadmap section vocabulary:** `ROADMAP_SECTIONS` (:78) is re-declared in `_marathon_plan.py:37` (leaves out "Queue"), `marathon-plan.sh:232`, `site_build.py:50`, and as literals in `wave_reconcile.py`, `pdda.sh`, `ledger_merge.py`, `collect.sh`, `export_timeline.py` and `pdda-install.sh`.
- **Ledger bullet parser:** mirrored in `marathon-plan.sh:468-473` and `_marathon_plan.py:489-494`.
- **Direct `sqlite3` reads of `releases.db`, bypassing the app:** at least 13 sites, including `wave_reconcile.py`, `_marathon_plan.py`, `site_build.py`, `board_sync.py`, `export_timeline.py`, `hq-lib.sh`, `pdda.sh`, `release-lanes.sh`, `collect.sh` and `tools/vscode-cockpit`. These are schema coupling points a migration must account for.
- **No duplicate found:** the `rated N/N/N/N` parser (`ledger_merge.py:280` and `express.py:687` only build the token) and ULID/gid generation.

## Merge evidence

- PR #776 merged 2026-09-24 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
