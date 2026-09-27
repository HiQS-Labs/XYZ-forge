# GH-851 / GH-852 — evidence

Plan: `PROJECT/2-WORKING/GH-851-MERGE-CLEANUP-LANDING-RESILIENCE.md`. Base `030ab5ba`. Implementation `04fd21bf`.
There are no new tests (AGENTS.md). The witnesses are manual checks, and the focused suites are the existing ones.

## Witnesses (`witness.py.txt`, the same script at base and head)

Each case runs in its own process group under a 10 s outer watchdog. The results are in
`witness/base.jsonl` and `witness/head.jsonl`, and every case's log is `witness/<label>-<case>.log`.

| Case | Plan step | Base `030ab5ba` | Head `04fd21bf` |
|---|---|---|---|
| `w1_clone_stall` | F1 | BLOCKED at the 10 s watchdog | `(False, "second clone failed: timed out after 2s …")` at 2.4 s |
| `w2_timeouts` | F1 | `None` at all six sites | 180 / 180 / 180 / **3600** / 180 / 180 (`:316` clone, `:343` push, `:550` fetch, `:601` push, `:605` fetch, `scan_clones.py:437` fetch) |
| `w2a_scan_fetch_stall` (no `GIT_HTTP_LOW_SPEED_*`) | F1, QA D1 | BLOCKED at the watchdog | `failed_query: git fetch origin development: timed out after 2s` |
| `w3_env` | F1 | both variables unset | `1000` / `120` in both `main()`s; an operator's `LIMIT=5` is kept |
| `w4_transient` | F1, QA C1 | `Operation too slow` and `Connection reset` → False | both → True; `Repository not found` and `Authentication failed` stay False |
| `f2_merge_recovery` (merge rc 1, PR reads MERGED) | F2 | False, no re-query | True, with the warning `gh pr merge exited 1 but PR #42 reads MERGED as bbbbbbbbbb` |
| `f2_control_open` (merge rc 1, PR reads OPEN) | F2 | False | False |
| `f3_lookup` (active run on PR head H, wait exhausted) | F3, safety 3 | looks for the primary's HEAD, falls back, **local writer called** | waits on merge M and head H → `active_timeout`, local writer **0** |
| `f3_open_refused` | F3, safety 1 | reconciles (local writer called) | rc 2 `PR #42 is OPEN, not merged`, zero `run_post_merge_reconcile` calls |
| `f3_view_error` | F3, safety 2 | reconciles (local writer called) | rc 2 `cannot read its state`, zero calls |
| `f3_red_control` (local writer injected while the run on H is active) | F3, red control | — | local writer 1: the witness turns red, as required |
| `f4_regate` (old head CONFLICTING → new head UNKNOWN → MERGEABLE) | F4 | stops after the stale read; landing clone never built for the new head | waits for the pushed head, then reaches the landing clone at it |
| `f5_default` | F5 | `MERGE_CLEANUP_HOSTED_WAIT_S` default 1800 | 5400 |

## Focused suites and red control (commit `9319ea9a`, disposable full clone, identity unchanged)

| Check | Result |
|---|---|
| `test/gh436-merge-cleanup.sh` (includes `gh534_phase_{a,b,c}`) | 180 tests OK (239 s) |
| `test/gh674-merge-cleanup-hosted-lookup.sh` | 6 tests OK |
| `test/gh645-merge-cleanup-xyz-tools.sh` | 8 tests OK |
| Red control: `main` ignores `run_post_merge_reconcile`'s result | `test_reconcile_pr_failure_propagates` FAILS (`0 != 2`) |
| Restore control | passes; tree clean |

Logs are in `focused/`. There is no local full gate: the PR goes to `staging/stabilize-2026-10` under #854 D2 (operator, 2026-09-27).

## Final QA findings R1 / R2 (commit `fab979c4`)

Codex's one-round final QA (`relay-system/2026-09-27/gh851-852-final-qa.md`) found two defects. Both are fixed and witnessed.

| Case | Before (`04fd21bf`) | After (`fab979c4`) |
|---|---|---|
| `r1_head_moved_after_poll`: the pushed head reads UNKNOWN, then the poll returns another head | prepares the foreign head `eeee` | stops: `head moved to eeeeeeeeee after the pushed cccccccccc` |
| `r2_active_then_lookup_error`: the run on H is in flight, then the lookup fails | `fallback`, so the local writer would run | `active_timeout`: `refusing to start the local reconciler` |

The focused suites were re-run on `fab979c4` (`focused-fab979c4/`): gh436 180 OK, gh674 6 OK, gh645 8 OK. The red control still fails (`0 != 2`), and the restore passes.

## Landing-clone retry (commit `6555fc2e`), found on the #820 landing

| Case | Before (`9a7b9fb3`) | After (`6555fc2e`) |
|---|---|---|
| `r3_clone_retry_after_stall`: the first clone creates its directory and stalls past the bound | the retry fails with `destination path … already exists` | the retry clones, and the run proceeds |

The focused suites were re-run on `6555fc2e` (`focused-6555fc2e/`): gh436 180 OK, gh674 6 OK, gh645 8 OK. The red control fails, and the restore passes.
