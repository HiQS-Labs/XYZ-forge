---
gh_issue: 898
source: https://github.com/HiQS-Labs/XYZ-forge/issues/898
title: "board_sync: source the repo allow-list from the rebalanceOS active-repos signal"
status: Proposed (1-INBOX — plan awaiting QA)
created: 2026-09-30
doc_type: feature
effort: 2
complexity: 2
risk: 1
phases: 1
---

# GH-898: board_sync repo allow-list from the rebalanceOS active-repos signal

## Why

`resolve_selection_policy()` ([utils/py/board_sync.py:119](../../utils/py/board_sync.py)) builds `policy["repos"]` from the device config, and the singular `repo` key collapses it to one entry. Everything downstream scopes to that list: observations ([:204](../../utils/py/board_sync.py)), the planner's `allowed` set ([:224](../../utils/py/board_sync.py), [:1256](../../utils/py/board_sync.py)), GitHub state collection ([:986](../../utils/py/board_sync.py)). Other repos on the board are therefore opaque. A hand-kept list drifts from what the operator is working on; rebalanceOS already computes that signal.

Parent thread: #897 (hourly board review), #402, GH-605.

## Recon (base c42044d2, 2026-09-30)

- Signal: `top_active_repos()` in rebalanceOS `src/rebalance/ingest/db/github.py` — 7-day score over `github_activity`, full `owner/name`. Org-rename aliases are collapsed by `canonical_github_repo_name` (`get_watched_repos`, `index_ops.py:977`; #147). The live DB is 4.9 GB with `scan_date` current (2026-09-30); top rows: rebalance-git-pulse, XYZ-forge, rebalanceOS, LTVera-Pandas, ...
- DB path: rebalanceOS `paths.resolve_database_path` — `REBALANCE_DB` env, then `~/Library/Application Support/rebalance-os/rebalance.db` (macOS) or `$XDG_DATA_HOME`/`~/.local/share`. `~/.config/rebalance-os/rebalance.db` is a 0-byte stub.
- Precedent for a cross-repo read: `utils/hq/hq-lib.sh` reads the DB read-only with `sqlite3`. Its default path is stale — filed as #899, not fixed here.
- A plain `sqlite3` open fails on the live DB (WAL sidecars); `file:...?immutable=1` with `uri=True` works.
- `rebalance` is not importable from the Forge (`ModuleNotFoundError`), so no package import.
- Ledger evidence is loaded from ONE root (`load_work_evidence(Path(root)/"releases.db")`, [:1115](../../utils/py/board_sync.py)). Widening the allow-list gives visibility of other repos' cards and GitHub state; card moves for those repos still need a per-repo ledger root (out of scope, see Non-goals).
- `touch`/default paths use `cfg["repos"][0]` ([:736](../../utils/py/board_sync.py), [:802](../../utils/py/board_sync.py), [:902](../../utils/py/board_sync.py)) — pinned repos must stay first.
- Untraced: `work_connectors/github_board.py` only calls `resolve_selection_policy(required=False)` ([:126](../../utils/py/work_connectors/github_board.py)); I did not trace its repo handling beyond that call.

## Requirements

1. New optional policy key `repos_source` in `github_board_selection_policy`: `{"type": "rebalance_active", "top_n": 8, "since_days": 7}`. Absent key = today's behavior, byte for byte.
2. When set, `policy["repos"]` = pinned repos (`repo`/`repos`, order kept, first) followed by the active repos not already present (case-insensitive dedupe), capped at `top_n` added.
3. DB path: `REBALANCE_DB` env → macOS Application Support → XDG → none. Open read-only and immutable; stdlib `sqlite3` only.
4. Failure degrades, never blocks: DB missing/unreadable/empty result → warn on stderr, use the pinned list. If there is no pinned list either, the existing "selection policy missing repos" error stands.
5. `source: "explicit"|"explicit+rebalance_active"` and the resolved list appear in `board_sync.py config` output so the operator can see what was resolved.
6. Invalid `repos_source` (unknown type, non-positive ints) is a `ValueError`, matching the other policy fields.

## Smallest surface / writer extended

One helper plus a few lines in `resolve_selection_policy` in `utils/py/board_sync.py`; one line in `cmd_config`. No new module, no new writer, no change to `policy-preview`/`policy-apply` logic. A preview/apply pair already refuses when the policy changed between them ([:1167](../../utils/py/board_sync.py)) — if the active set shifts inside the 15-minute window, apply refuses and the operator re-previews. That is the intended safe failure.

## Non-goals

- Per-repo ledger roots / moving cards for non-Forge repos (follow-up; needed before #897 Phase 2 can apply across repos).
- Alias canonicalization beyond case-insensitive dedupe; rebalanceOS's rename table stays in rebalanceOS (#150 alias class). If the DB carries a mirror spelling, it passes through as-is.
- Fixing the `hq` default path (#899), editing rebalanceOS, importing `rebalance`, any new test file or registry entry (AGENTS.md *No new tests*, GH-831).

## Risks / rollback

- Wider list means `collect_github_state` makes more API calls per preview (one set per repo). Bounded by `top_n`; default 8.
- Rollback: delete `repos_source` from the device config, or revert the commit. No data written anywhere.

## Ordered implementation

1. Add `_rebalance_active_repos(source)` (path resolution, immutable read-only query mirroring `top_active_repos`'s score and window) and wire it into `resolve_selection_policy` after the singular-`repo` collapse. Verify: `python3 -c` call against the live DB returns owner/name rows; with `REBALANCE_DB=/nonexistent` it warns and returns the pinned list.
2. Validate `repos_source` fields. Verify: bad `top_n` (0, "x", true) raises `ValueError`.
3. Print resolved repos and `source` in `board_sync.py config`. Verify: output with and without `repos_source`.
4. Run existing suites: `bash test/gh402-board-sync.sh` and the GH-605 policy tests (find via `rg -l policy-preview test/`), then `python3 utils/py/board_sync.py policy-preview --out $SCRATCH/p.json` against the live device config with `repos_source` enabled. Record under `TESTS-RESULTS/2026-09-30+GH-898/`.
5. Red control (manual, recorded): with `REBALANCE_DB` pointing at an empty SQLite file, resolution must fall back with a warning, not return an empty allow-list and not crash.
6. CHANGELOG entry; document `repos_source` where the `github_board_selection_policy` block is documented.

## Task rating (2026-09-30)

rated 55/25/50/75. Consequence: board visibility gap, no data loss or corruption. Recurrence: unknown trend — single observation from the operator's board review, no prior same-class issues found (`gh issue list` search "board repos"). Appeal neutral (50), no user score supplied. Effort 75: ~60 lines in one file.
