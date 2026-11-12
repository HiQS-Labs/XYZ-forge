# GH-1430 verification summary

Manual check matrix and live smoke. No new tests (AGENTS.md, GH-831). All runs use `/usr/bin/python3`
3.9.6 with Apple SQLite 3.54.0, the interpreter `board_sync.py`'s `#!/usr/bin/env python3` resolves to on
this Mac. Code under test: commit `37676605d` (base `0f21b761a`).

## Manual matrix (`manual_matrix.py`, `matrix.log`): 10/10 PASS

| Check | Result |
|---|---|
| Fixture: WAL mode, no `-wal`/`-shm` (written and closed by rebalanceOS's venv Python) | PASS |
| **Red control:** base `_rebalance_active_repos` on that fixture | `[]` + "unable to open database file" warning |
| New code on the same fixture shape | `['o/gh', 'o/agent-only']`, no warning |
| Fixture sha256 and mtime after the new read | unchanged (side files `-wal` (0 bytes) and `-shm` remain, as Apple SQLite leaves them) |
| Write on a `mode=rw` + `query_only` connection | `attempt to write a readonly database`; fixture unchanged |
| Missing `REBALANCE_DB` path | "not found" warning, `[]`, nothing created |
| `mode=rw` on a missing path | "unable to open database file", no file created |

## Live smoke (#87 step 7; `smoke.sh`, `smoke-live.log`)

Read-only. Policy: `project_owner`, `project_number` and `repos` through `XYZ_GITHUB_BOARD_POLICY_*` env.
`repos_source` (`rebalance_active`, `top_n` 3, `since_days` 7, `include_agent_sessions` on/off) came from a
scratch file through `XYZ_DEVICE_CONFIG_PATH`, because the env tier cannot carry an object
(`device_config.resolve_device_block` returns a string for a `None` default). No `~/.xyz/device_config.json`
exists before or after. Nothing was written to the board: `policy-preview` performs GraphQL reads only and
writes its `--out` file to scratch, and `policy-apply` was not run.

- **Main path, no side files:** the live DB had no `-wal`/`-shm` and no process holding it, which is exactly
  the failing condition. The first new-code read returned 17 GitHub-active repos (7-day window). Before this
  change it fell back to pinned repos.
- **Adjacent path, rerun:** `config` and `policy-preview` with the key on, then off (side files now present).
  Both resolve `explicit+rebalance_active` with
  `HiQS-Labs/XYZ-forge, Hypercart-Dev-Tools/rebalance-git-pulse, HiQS-Labs/rebalanceOS, BinoidCBD/LTVera-Pandas`.
  `policy-preview` exit 0, 164 proposed changes, no warnings. The `unresolved` list is elided in the receipt.
- **Live DB:** sha256 `585f1720e218bf8691684749cdbe1984c26c0161729997812b23289e9cd47378`, mtime `1794454706` and
  size `1375346688` taken before the first new-code read and again after the smoke and final QA: identical, so the
  main file's bytes did not change across every read this session. The reads left `rebalance.db-shm` (32 KB) and a
  0-byte `rebalance.db-wal` beside it, as Apple SQLite does; Rebalance's next connection uses them. (sha256 added after
  final QA, which noted its absence as non-blocking.)
- **Agent-only on/off: outstanding.** Key on and key off give the same set because no live repo is agent-only.
  `agent_session_activity` holds 3 repos (681 runs, 2026-10-13..2026-11-11), and all 3 also have
  `github_activity` rows. The on-minus-off diff is empty for windows of 1, 2, 3, 7, 14 and 30 days. Live data
  was not modified to manufacture one. The behaviour is shown on the fixture (`o/agent-only`), not live.
  Re-run `smoke.sh` once T3 has worked a repo with no GitHub activity.
