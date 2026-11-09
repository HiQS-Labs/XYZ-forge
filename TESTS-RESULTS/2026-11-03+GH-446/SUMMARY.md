# GH-446: marathon-plan writes its dated plan doc only when asked

- **Change:** a bare `marathon-plan.sh` / `marathon_plan.py` run now prints the report and writes nothing. `--write` saves `PROJECT/2-WORKING/MARATHON-PLAN-<today>.md`. `--dry-run` and `--check` are unchanged. Edited: `utils/py/marathon_plan.py` (authoritative), the frozen Bash twin `utils/marathon-plan.sh` (same contract, `Frozen-twin-exception` trailer on the commit), and the reconciler's live step in `utils/py/wave_reconcile.py`, which now passes `--write` so its committed plan docs are unchanged.
- **Manual check (before/after, no new test, GH-831):** `gh446-check-output.txt`. Same repo state, `QUEUE_PLAN_QUEUE_DIR` pointed at a throwaway directory so the repo was never written.

| Run | Code | Plan file written |
|---|---|---|
| bare | before (`origin/development`) | **YES** (the bug) |
| bare | after | no |
| `--write` | before | n/a (rc 2, unknown argument) |
| `--write` | after | YES |
| `--dry-run` | after | no |
| `--check` | after | no (rc 1: nothing to compare in the throwaway dir) |
| `--bogus` | after | no (rc 2) |

- **Existing suites, disposable clone, unsandboxed (GH-177):** with the change but no test edits, the main planner suite (`marathon-plan`) failed 39 of 72 and `gh418-planner-ledger-source` failed, because both ran the planner bare and asserted on the written doc (on `origin/development`: 70 passed, 0 failed, 2 skipped, and pass). The test helpers (`run_qp`, `run_qp_py`, `run_qp_sh`) and gh418's `plan()` now pass `--write`. After that: `marathon-plan` 70 passed / 0 failed / 2 skipped (same as base), `gh418` pass, `gh362` 9/0, `gh308` 38/0. Earlier, unchanged: `gh421` OK, `gh454` OK, `gh202` 40/0, `gh168` 7/0, `gh232` 13/0, `gh358` 8/0, `gh429` 15/0.
- **Not done / limits:** the issue's third ask (exit 2 on an empty invocation) was not taken: a bare run still prints the report, which is the useful "look at the plan" behaviour. Callers outside this repo that run the planner bare and expect the file (none found in this repo's skills, scripts or docs; `~/.claude` skills were not fully audited) must add `--write`. The check ran against one repo state.

## Takeover readiness correction
Independent Codex source review atcf799f0 confirmed originalneed remains on development1c2bd89e and found existing directmutatedBashinvocation omitted--write, potentially comparing stalePythonoutput. Added--write to that existing invocation only; no new suite/machinery. Existing suite70pass/0fail/2explicitlegacy-render skips, mutation detected. Normal exact-composition push gate pending.
