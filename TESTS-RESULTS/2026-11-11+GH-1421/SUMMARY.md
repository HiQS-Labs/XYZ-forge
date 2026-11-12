# GH-1421 verification summary (2026-11-11)

Commit under test: 49b9895bd. Run in the disposable full clone `XYZ-forge-gh1421-board-sync-repos-source-2026-11-11-verify`
(sibling of the task clone, `git clone --no-local`); HEAD, origin and `core.bare` were the same before and after.
No new suite or registry entry (GH-831); `manual_matrix.py` is an evidence script modelled on GH-898's.

| Check | Result |
|---|---|
| Manual matrix `manual_matrix.py --live`: key-off identity vs base 046b41538 (resolver + `config` stdout), key-on merge/order/cap, missing table, malformed agent table, validation, no-sidecar WAL fixture with writer-held control, live DB | 29 PASS, 0 FAIL (`matrix-pass-live.log`) |
| Red control (F2): agent-query error routed to the outer fallback (mutation in the verify clone) | 4 FAIL, rc=1 (`redcontrol-agent-error-outer.log`); restored: ALL PASS, rc=0 (`redcontrol-restored.log`) |
| Red controls built into the matrix | key on changes the list; key off omits the agent-only repo; base reader's generic warning on the WAL fixture and on the live DB |
| Live DB | `mode=ro` fails on the first SELECT (no `-wal`/`-shm`); the new warning names the likely cause; `?mode=ro&immutable=1` reads 25 `agent_session_activity` rows (the recorded working mode, not used by the reader) |
| Existing suites | gh402 34/0, gh405 19/0, gh549 125/0, gh777-inventory-ratchet PASS, gh605-board-policy OK (`suites/`) |
| Smoke (main + adjacent) | PASS (`smoke.md`) |

One annotated `sqlite3.connect` site in `_rebalance_active_repos`, by inspection (`grep -n "sqlite3.connect" utils/py/board_sync.py`: line 159 here, and line 542 is the unrelated pre-existing `releases.db` scan).
The routed push gate runs on the final commit; its result is recorded in the PR.
