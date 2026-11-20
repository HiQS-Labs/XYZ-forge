# GH-1475 Phase 1 — verification receipts

Tested commit: `fb38cc5db2a43bbba1a6433cc28280d4f8e4f7e3` (implementation). Red control: base
`5967bde25` (`origin/development` at branch cut), extracted with `git archive` into a scratch dir.
No new tests or suites (GH-831); the drivers below are manual-check scripts, kept as `.txt`.

| Item | Driver | New | Red control (base) |
|---|---|---|---|
| P1.1 fetch race | `manual-p11.sh.txt` — scratch origin with `development` advanced, held `refs/remotes/origin/development.lock` (released after 1.5 s) and a two-branch `FETCH_HEAD` | succeeds after 2 ref-lock retries; HEAD = origin. A non-lock error (missing branch) still dies with code 2 | `cannot lock ref`, `ReconcileError`, HEAD not advanced |
| P1.2 live log | `manual-p12.sh.txt` — real `merge_cleanup.py` with `MERGE_CLEANUP_GH_BIN` pointing at a stub that sleeps 20 s | process alive at 5 s, 25 log lines (Phase 0 present) | process alive at 5 s, 0 lines |
| P1.3 workdir | `manual-p13.py.txt` — `_land_prs_loop` dry run, clean (empty queue) and stopped (PR read fails, rc 2) | clean: removed, 0 left; stopped: kept | kept in both |

Note on P1.3 workdir: the driver and log call the second case `deferred`, but its stub error does not match `TRANSIENT_RE`. The run therefore stops with exit 2 rather than deferring with exit 3, which is what the row above states ("stopped ... rc 2"). It shows the workdir is kept after a non-zero exit. The network-deferral path keeps it by the same `rc == 0` predicate but was not run separately (CodeRabbit, PR #1478).
| P1.3 keep guard | `manual-p13b.py.txt` — real `_land_prs_loop` (execute) where B1 resolves, the repaired-head push meets a draft refusal (sets `keep_workdir`, run returns 0); plus `_remove_own_scratch` on a symlink, a dir outside the temp root and a wrong prefix with `rmtree` replaced by an observer | rc 0, workdir and B1 result kept; each refusal returns False without calling `rmtree` | mutant (only `not keep_workdir` removed): the same run deletes the workdir and B1 result |
| P1.4 recovery | `manual-p14.py.txt` — `main()` `--reconcile-pr 11 --execute` (stubs: PR read, reconcile, push, `_gh`), dry run, failed reconcile, failed push; `record_sweep` hints | row `merged/ok`, `continuable` false, issue edited; the three negative cases leave the row unchanged; hints name `--reconcile-pr 11 --execute`, plus `--resume` only with an open row | row unchanged; hint always `--resume --execute` |
| P1.6 warnings | `manual-p16.py.txt` — `_land_prs_loop` dry run with 2 PRs and stubbed `required_checks_state`; `preflight_warnings()` with stub `pmset`/`pgrep` on PATH, nested `TMPDIR`, `disk_usage` forced to 5 GB | F6 line once for "no required checks", none for a named passing check, 0 `gh` calls; each forced probe fires; clean env prints none | no PRE-FLIGHT lines; no `preflight_warnings` |
| P1.5 doc | read from the drive-loop entry point; `test/gh534_phase_c_tests.py` doc contracts run inside `test/gh436-merge-cleanup.sh` | see `existing-suite-summary.txt` | old `:476` text contradicted `merge_cleanup.py` exit-4 path |

Note: the scratch primary in P1.4 is made dirty by the batch record's untracked `.tick/`, so the
driver passes `--allow-unready-primary`; Phase 0 is unchanged by this PR.

Output: `manual-check-run.log` (scratch paths shown as `<scratch>`). Existing suites:
`existing-suite-summary.txt`. Smoke: `smoke.log`.
