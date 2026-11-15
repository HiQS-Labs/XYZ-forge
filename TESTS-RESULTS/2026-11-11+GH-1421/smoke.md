# GH-1421 smoke (GH-1088): `board_sync.py config` on the main path and one adjacent path

Commit 49b9895bd, disposable full clone. Device config and DB passed via `XYZ_DEVICE_CONFIG_PATH` / `REBALANCE_DB`.
Fixture: `github_activity` has HiQS-Labs/XYZ-forge; `agent_session_activity` has only noelsaw1/t3code-fork (runs 3).

| Path | Command | Observed `selection_policy_repos` | Verdict |
|---|---|---|---|
| Main, key on | `board_sync.py config` (fixture DB) | `["HiQS-Labs/XYZ-forge", "noelsaw1/t3code-fork"]`, `explicit+rebalance_active` | PASS: agent-only repo appended after the GitHub repo |
| Main, key off | same, `include_agent_sessions: false` | `["HiQS-Labs/XYZ-forge"]`, `explicit (rebalance_active fell back)` | PASS: no agent repo (only the pinned repo is GitHub-active, so nothing new to add) |
| Adjacent: second invocation against the live DB | key-on config, no `REBALANCE_DB` (default macOS path) | `["HiQS-Labs/XYZ-forge"]`, fell back; stderr in `smoke-live.err` names the WAL/no-sidecar cause | PASS: warns and falls back, no exception, DB untouched |

Not run: a live `policy-preview`. This device's real device config has no `github_board_selection_policy`,
so there is no live board policy to preview, and inventing one would change what is being tested.
The resolver behind `policy-preview` is exercised directly by the matrix (A1 to A5).
