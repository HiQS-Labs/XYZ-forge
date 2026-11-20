# Manual Check — GH-1558 (KS-14: `build_queue.py --daily-goals <issue>`)

- **Issue:** #1558 (KS-14 from #1541)
- **Date:** 2026-11-20
- **Branch:** `feat/XYZ-forge-gh1558-ks14-daily-goals-2026-11-20`
- **Route:** `docs` (see `outputs/ci-route.txt`)

## Pre-Change Red Control
- `outputs/pre-change-red.txt` (3200 bytes): pre-change `build_queue.py --daily-goals 999` exited `2` (`unrecognized arguments: --daily-goals 999`).

## Post-Change Green Controls (`outputs/controls-green.txt`)
1. **Control 1 & 4 (`CONTROL_1_AND_4_DAILY_GOALS`, exit 0):** Parses `#102` (older than default cutoff, included via daily-goals), `HiQS-Labs/XYZ-forge#101`, `HiQS-Labs/XYZ-forge#103`, `#105`, `#106`, ignores checked/closed `#107`, ignores foreign `other/repo#123` (local `#123` NOT pulled), deduplicates `#102`, ignores self-ref `#999`, excludes non-goal `#104`, holds `#103` (`body HELD:`) and `#106` (`DECISION` without proceed) in `Needs the operator`, and queues `#101`, `#102`, and `#105` (`Operator decision: proceed`).
2. **Control 2 (`CONTROL_2_DEFAULT_MODE_UNCHANGED`, exit 0):** Without `--daily-goals`, default mode still includes open issue `#104`.
3. **Control 3a–3d & 3f (Fail-closed invalid/missing goals):** Closed goals issue (`#998`), empty goals issue (`#997`), number mismatch (`555` vs `999`), non-positive issue number (`0`), and missing referenced issue (`#404`) all exit nonzero.
4. **Control 3e (`CONTROL_3E_PARTIAL_OFFLINE_REPLAY_ZERO_SUBPROCESS`):** Passing `--daily-goals-json` without `--prs-json`/`--pr-meta-json`/`--issues-json` fails closed upfront with `subprocess_calls=0` (zero network/git subprocesses invoked).
5. **Control 4e (`CONTROL_4E_OUT_AND_OTHER_SESSION`, exit 0):** `--daily-goals` composes cleanly with `--other-session` and `--out`.

## Static Analysis & Governance
- `outputs/mypy.txt`: `mypy --allow-untyped-defs --allow-incomplete-defs skills/1-hourly/kickstart/scripts/build_queue.py` — 0 issues.
- `outputs/ci-route.txt`: `route=docs`.
- `outputs/pdda-run.log`: `./utils/pdda/pdda.sh run` — 0 errors.
- `outputs/code-and-docs.patch`: full `origin/development..HEAD` diff for `skills/1-hourly/kickstart/`.
- `provenance.jsonl`: exact SHA-256 and byte-size ledger for every evidence file.
