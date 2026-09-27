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

## Focused suites and red control

See `provenance.jsonl`. They are `test/gh436-merge-cleanup.sh`, `test/gh674-merge-cleanup-hosted-lookup.sh` and
`test/gh645-merge-cleanup-xyz-tools.sh`, run in a disposable full clone. There is also the Phase-B red control (`main`
ignoring `run_post_merge_reconcile`'s result must turn `test_reconcile_pr_failure_propagates` red).
