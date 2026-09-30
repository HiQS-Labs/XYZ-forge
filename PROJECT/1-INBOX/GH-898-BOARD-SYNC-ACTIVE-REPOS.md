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
- Python `sqlite3.connect("file:<url-encoded path>?mode=ro", uri=True, timeout=2)` opens and queries the live DB (measured 2026-09-30, 0.0 s). `immutable=1` is NOT used: SQLite disables change detection for it, which is unsafe against the concurrently-writing launchd sync (relay r1 F1). The earlier CLI failure was the `sqlite3 -readonly` shell call, not the database.
- `rebalance` is not importable from the Forge (`ModuleNotFoundError`), so no package import.
- Ledger evidence is loaded from ONE root (`load_work_evidence(Path(root)/"releases.db")`, [:1115](../../utils/py/board_sync.py)). Widening the allow-list gives the planner other repos' cards and GitHub state, including GitHub-authoritative moves (see Mutation eligibility); ledger-dependent Ready/start decisions for unlinked OPEN issues still need a per-repo ledger root (out of scope, see Non-goals).
- `touch`/default paths use `cfg["repos"][0]` ([:736](../../utils/py/board_sync.py), [:802](../../utils/py/board_sync.py), [:902](../../utils/py/board_sync.py)) — pinned repos must stay first.
- Untraced: `work_connectors/github_board.py` only calls `resolve_selection_policy(required=False)` ([:126](../../utils/py/work_connectors/github_board.py)); I did not trace its repo handling beyond that call.

## Requirements

1. New optional policy key `repos_source` in `github_board_selection_policy`: `{"type": "rebalance_active", "top_n": 8, "since_days": 7}`. Absent key = today's behavior, byte for byte.
2. When set, `policy["repos"]` = pinned repos (`repo`/`repos`, order kept, first) followed by the active repos not already present (case-insensitive dedupe), capped at `top_n` added.
3. DB path: `REBALANCE_DB` env → macOS Application Support → XDG → none. Open with `mode=ro` (URL-encoded path), 2 s timeout, close the handle; stdlib `sqlite3` only. No `immutable`, no retry-with-immutable.
4. Failure degrades, never blocks: DB missing, `sqlite3.Error`/`OSError`, `github_activity` table absent, or a zero-row result → warn on stderr (distinct message for schema-absent vs zero-score), use the pinned list. If there is no pinned list either, the existing "selection policy missing repos" error stands.
5. Source metadata is diagnostic only and is NOT part of policy identity: `resolve_selection_policy` pops `repos_source` from the returned dict, so the dict's keys are exactly today's and only `repos` differs. The resolved list and a `repos_source` label (`explicit`, `explicit+rebalance_active`, or `explicit (rebalance_active fell back)`) appear in the `config` branch of `main()` ([board_sync.py](../../utils/py/board_sync.py), `if args.cmd == "config"`; there is no `cmd_config`). When `repos_source` is absent the policy dict and output are unchanged. `resolve_device_block` copies only keys declared in `POLICY_DEFAULTS` (`device_config.py:95-111`), so `repos_source` must be added to `POLICY_DEFAULTS` (default `None`) for the resolver to see it.
6. Invalid `repos_source` (unknown type, non-positive ints) is a `ValueError`, matching the other policy fields.

## Smallest surface / writer extended

One helper, one `POLICY_DEFAULTS` key, a few lines in `resolve_selection_policy`, and one label in the `config` branch — all in `utils/py/board_sync.py`. No new module, no new writer, no change to `policy-preview`/`policy-apply` logic. A preview/apply pair already refuses when the policy changed between them ([:1167](../../utils/py/board_sync.py)). Because the list is now computed live, any change — a repo entering/leaving the top N, an ordering-only change from a score tie, or a source outage falling back to the pinned list — makes apply refuse; the operator re-previews. Accepted single-operator behavior, documented in the user-facing note. The added query orders by score then `repo_full_name` so ties are deterministic.

**Restore drift (r1 F3).** `restore_policy_result` compares the whole resolved policy to the saved result ([:1244-1246](../../utils/py/board_sync.py)), so a changed active list also blocks `policy-restore` of an earlier apply, and deleting `repos_source` does not help. No code change here (an identity guard is not removed). Documented recovery (equality-preserving because source metadata is not in the dict): in the device config, remove `repos_source` AND remove the singular `repo` key (otherwise `repo`+widened `repos` trips "policy repo and repos disagree", [:125-128](../../utils/py/board_sync.py)), set `repos` to exactly the saved `policy.repos`, leave every other field as saved, and unset `XYZ_GITHUB_BOARD_POLICY` if it overrides any; run `policy-restore`; then revert the config. The clone proof (step 7) generates the saved policy through the real resolver and requires dict equality before restore readback, and requires a different board owner/number to still refuse.

**Mutation eligibility (r1 F2).** Adding repos widens more than visibility. The existing planner moves an allowed OPEN PR to In review with no ledger row ([:252-255](../../utils/py/board_sync.py)), follows closing links ([:262-279](../../utils/py/board_sync.py)) and handles CLOSED issues before the missing-ledger guard ([:309-329](../../utils/py/board_sync.py)); those flow to the existing writer ([:1217-1219](../../utils/py/board_sync.py)). Accepted and documented: GitHub-authoritative moves apply to added repos. Ledger-dependent Ready/start decisions for unlinked OPEN issues stay unresolved until a per-repo ledger root exists (the non-goal). An inaccessible added repo can fail the whole GitHub collection ([:1005-1006](../../utils/py/board_sync.py)); `top_n` bounds the exposure.

## Non-goals

- Per-repo ledger roots (follow-up): ledger-dependent Ready/start decisions for unlinked OPEN issues in added repos stay unresolved until they exist; needed before #897 Phase 2 can apply those across repos. GitHub-authoritative moves for added repos are in scope and accepted (see Mutation eligibility).
- Alias canonicalization beyond case-insensitive dedupe; rebalanceOS's rename table stays in rebalanceOS (#150 alias class). If the DB carries a mirror spelling, it passes through as-is.
- Fixing the `hq` default path (#899), editing rebalanceOS, importing `rebalance`, any new test file or registry entry (AGENTS.md *No new tests*, GH-831).

## Risks / rollback

- Wider list means `collect_github_state` makes more API calls per preview (one set per repo). Bounded by `top_n`; default 8.
- Rollback: delete `repos_source` from the device config, or revert the commit. Resolving the list writes nothing; a later `policy-apply` writes board fields exactly as today, for the wider repo set, and is undone with `policy-restore` (see restore drift above).

## Ordered implementation

1. Add `_rebalance_active_repos(source)` (path resolution, `mode=ro` query mirroring `top_active_repos`'s score and window, plus `repo_full_name` tie-break) and wire it into `resolve_selection_policy` after the singular-`repo` collapse. Verify: `python3 -c` call against the live DB returns owner/name rows; with `REBALANCE_DB=/nonexistent` it warns and returns the pinned list.
2. Validate `repos_source` fields. Verify: bad `top_n` (0, "x", true) raises `ValueError`.
3. Print resolved repos and `source` in `board_sync.py config`. Verify: output with and without `repos_source`.
4. Run existing suites in a **disposable full clone** (`AGENTS.md`; never this task clone): `bash test/gh402-board-sync.sh` and the GH-605 policy suites (`rg -l 'policy-preview|policy_preview' test/`). Then `policy-preview --out $SCRATCH/p.json` against the live device config with `repos_source` enabled; assert the preview's repo list is non-empty and starts with the pinned repo.
5. Manual matrix (recorded in `TESTS-RESULTS/2026-09-30+GH-898/` with `provenance.jsonl`), asserting each on extracted non-empty data:
   - absent `repos_source` → policy dict and `config` output byte-identical to base;
   - live DB → pinned first, no duplicates (case-insensitive), at most `top_n` added, order stable across two runs;
   - `since_days`/`top_n`/`type` invalid (0, "x", true, unknown type) → `ValueError`;
   - `REBALANCE_DB` → nonexistent path, empty SQLite file (schema-absent), and a DB with the table but zero in-window rows → each warns (schema-absent message differs from zero-score) and returns the non-empty pinned list;
   - label text correct on success and on fallback.
6. Red control: the helper's contract is to return `[]` when the source yields nothing (that is the correct fallback contribution), so mutating it would leave the assertion green. Instead, in the disposable clone, mutate the resolver's merge so the final resolved list drops the pinned repos on source failure, re-run the same fallback assertion (non-empty list equal to the pinned list) and require a nonzero exit; restore the file from a saved copy and require exit 0. Record the exact mutation and both exit codes.
7. Restore recovery proof (clone run, recorded): from a singular-`repo` + enabled-`repos_source` config, produce the saved policy with the real resolver (repos `[pinned, a]`), change active membership so the resolver now yields `[pinned, b]`, confirm `policy-restore` refuses, apply the documented recovery, assert the resolved dict is exactly equal to the saved `policy`, confirm readback proceeds, and confirm a changed board owner/number still refuses. A hand-built result is not accepted as evidence.
8. CHANGELOG entry; document `repos_source` where the `github_board_selection_policy` block is documented.

## Task rating (2026-09-30)

rated 55/25/50/75. Consequence: board visibility gap, no data loss or corruption. Recurrence: unknown trend — single observation from the operator's board review, no prior same-class issues found (`gh issue list` search "board repos"). Appeal neutral (50), no user score supplied. Effort 75: ~60 lines in one file.
