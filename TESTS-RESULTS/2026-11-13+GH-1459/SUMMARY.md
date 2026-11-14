# GH-1459 Verification Summary — Daily Work Ledger GH Issue, Carryover, Checkout Calibration & Repo Modes

- **Issue:** [#1459](https://github.com/HiQS-Labs/XYZ-forge/issues/1459) (`rmi-01M7BT9JQP5FFRGC5RXDC30BGC`)
- **Target files modified:**
  - `skills/3-weekly/weekly-planner/scripts/planner_core.py`
  - `skills/2-daily/daily-planner/SKILL.md`
  - `skills/3-weekly/weekly-planner/SKILL.md`
  - `PROJECT/2-WORKING/GH-1459-DAILY-PLANNER-SHARED-DAILY.md`
- **Guardrails verified:**
  - Zero new files under `test/` or changes to `validate.sh` (`GH-831`, `AGENTS.md:162`).
  - Zero new `sqlite3.connect` calls or scripts (`GH-777`, `check_inventory_ratchet.py --check` exits 0).
  - Rebalance's `/daily` skill remains untouched.

## Verification & Red/Green Controls Executed (`35 PASS / 0 FAIL`)

1. **Pre-fix Red Control (`red-control-0`):**
   - Extracted `origin/development:skills/3-weekly/weekly-planner/scripts/planner_core.py` into `$TMPDIR` and invoked `--mode ledger`; exited `2` with `invalid choice: 'ledger'`.
2. **AC1 — Complete Ledger Discovery, Unconditional Pagination on Full Pages, `min(number)` Tie-Break & Cross-Device Carryover:**
   - **Mixed-page duplicate & backfill control:** Stubbed a 100-row initial search page (`1 today` issue `#201` + `99 yesterday` duplicates `#101..#199`) where canonical today `#200`, canonical yesterday `#100`, a backfilled older ledger (`2026-10-01` created more recently than yesterday), and a non-ledger issue (`"Fix Daily Work Ledger — 2026-11-12 bug"`) reside on page 2. Verified unconditional pagination (`gh api --paginate --slurp repos/<slug>/issues?state=all&per_page=100`), selection of `#200` (`min(number)`) for today with comments merged across `[200, 201]`, and selection of `2026-11-12` `#100` (`min(number)`) for `previous_ledger`.
   - **Cross-device carryover control:** Verified comment by `noelsaw1` on `laptop-a` from `2026-11-12` citing `#101` (closed), `#102` (open), `PR #55` (merged), and `PR #56` (open) carried `#102` and `PR #56` forward when running on `studio-b`, while moving `#101` and `PR #55` to `completed_since_last_ledger`.
   - **Fail-closed discovery red controls (`disc_fail`, `disc_trunc`):** Verified `--publish-ledger` exits `3` without calling `gh issue create` when discovery fails or pagination is truncated.
3. **AC2 — First-Line Marker Ingestion, Authorship Verification (`[P1]`), Earliest Starter, Linked Worktrees & Canonical `tick claims --json`:**
   - Verified forged first-line comment (`comment.user.login="mallory"`, marker `"alice"`, `07:00Z`, `#998`) and quoted line-2 marker (`#997`) are rejected from carryover and `verified-ledger-claim`, while `bob`'s verified comment (`08:00Z`, `#999` and `#102`) is selected as `earliest_starter` and triggers collision detection on `#102`.
   - Verified clean tracked linked git worktree (`feat/gh-996-clean`, 0 dirty, 0 ahead) and live `.tick` claim (`gh-995`, read via `TICK_REPO_ROOT=<root> tick claims --json`) surface as `local-device-only` and flag collisions.
   - **Corrupt `.tick/events` red control:** Injected invalid JSONL into `.tick/events/9999-corrupt.jsonl`, proving `tick claims --json` exits `3` and `coverage` reports `tick claims` as `"failed"` without falling back to a parallel Python interpreter.
4. **AC3 — Assigned Issues, `reviewRequests`, GraphQL `reviewThreads`, `open_prs >= 300` Truncation & `POST`/`PATCH` Authorship:**
   - Verified `prs_awaiting_review` (`PR #58`) and `prs_needing_remediation` (`PR #56` with `isResolved == false`, excluding `PR #57` with `isResolved == true`).
   - Verified `len(prs) >= 300` marks `coverage["open PRs"]["status"] == "truncated"`.
   - Verified first-time `--publish-ledger` `POST`s comment (`created_count == 1`) and second same-day run `PATCH`es (`patched_count == 1`) while preserving `started:`.
   - **Authorship red controls:** Mismatched `--operator != auth_login` on `POST` exits `3`; forged comment (`comment.user.login != auth_login`) on `PATCH` exits `3`.
5. **AC4 — `--repo-mode {auto,forge,vendored,gh-only}` Precedence & Baseline-Free Execution:**
   - Verified auto-detection and baseline-free execution across `gh-only`, `vendored` (`.xyz/`), and `forge` (`releases.db` + `utils/hq/hq.sh`), plus precedence `--repo-mode` CLI > `XYZ_DAILY_LEDGER_MODE` env > `device_config.json` > `auto`.
6. **AC5 — Skill Docs, Live Read-Only Run & Gates:**
   - Executed live read-only `planner_core.py --mode ledger --repo-root . --gh-repo HiQS-Labs/XYZ-forge --repo-mode auto` (`live-run-DAILY-LEDGER.md`, `live-run-daily-ledger.json`).
   - Verified `check_inventory_ratchet.py --check` (`clean`), `test_python_layer.py` (`21 passed`), and `pdda.sh run` (`0 errors`).
