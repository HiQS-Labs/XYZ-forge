---
gh_issue: 1475
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1475
title: "merge-cleanup: 3-phase remediation from a 13-PR batch post-mortem (Phase 1)"
status: Active
created: 2026-11-14
updated: 2026-11-14
owner: Claude
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
non_goals:
  - Phase 2 and Phase 3 items (P2.1–P2.8, P3.1–P3.6)
  - pruning merge-check-* clones or per-PR clones on exit 3 (P2.3)
  - any refusal, lock file or new gh call in the dry run
  - new tests, suites or gate machinery (GH-831)
goal: >
  Ship the six Phase 1 quick wins from issue 1475 as one small, reversible PR
---

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# merge-cleanup remediation — Phase 1 quick wins

## Status

| What was just completed | What's next |
|---|---|
| Plan QA of the 3-phase issue plan by agy Gemini 4 Argon High: Approved r2 ([comment](https://github.com/HiQS-Labs/XYZ-forge/issues/1475#issuecomment-6889783329)); recon and this Phase 1 plan | Codex plan QA of this doc, then implementation |

## Table of contents
- [Problem](#problem)
- [Recon map](#recon-map)
- [Preflight bet check](#preflight-bet-check)
- [Phase 1 plan](#phase-1-plan)
- [Verification](#verification)
- [QA gate](#qa-gate)
- [Rating](#rating)
- [Lessons Learned](#lessons-learned)

## Problem
A real 13-PR `/merge-cleanup` batch (post-mortem:
https://github.com/BinoidCBD/LTVera-Pandas/issues/1095#issuecomment-6889598174) hit failure modes that
six small script/doc changes address: F5 (git pull races a concurrent fetch in the primary), F12
(buffered logs look like a hang), F1 (every landing workdir kept; disk filled), F8 (`--reconcile-pr`
recoveries invisible to the batch record), F7 (SKILL.md says single-PR runs never exit 4; a wrapper
mis-handled exit 4), and F1/F2/F6/F10 (no early warning about disk, battery, harness TMPDIR, a
concurrent landing, or absent required checks). The canonical three-phase plan is the issue body.

## Recon map
Base: `origin/development` `5967bde25`. All paths repo-relative.

| Item | Entry point → state written | Observation |
|---|---|---|
| P1.1 | `utils/py/wave_reconcile.py` `pull_upstream` (`:302-307`), called once at `:2456` unless `--skip-pull`/`--dry-run`/`--offline` | `git pull --ff-only origin <branch>` in the primary; any error `die()`s. `pull` = fetch (writes shared `.git/FETCH_HEAD`, takes `refs/remotes/origin/<b>.lock`) + merge of FETCH_HEAD. `merge_cleanup.py` already uses `fetch` then `merge --ff-only origin/<b>` (`:1223-1228`, `:1961-1966`). `TRANSIENT_RE` (`merge_cleanup.py:128-131`) feeds `_retry_call`; it has no ref-lock pattern. Suites invoke wave_reconcile with `--skip-pull`, so no suite drives `pull_upstream`. Vendored to consumers under `.xyz/utils/py/`. |
| P1.2 | `merge_cleanup.py` `main()` `:2130` | `log`/`log_err` use plain `print`; no flush, no reconfigure. |
| P1.3 | `_land_prs_loop` `:1629` `workdir = mkdtemp(prefix="merge-cleanup-")`; `finally` `:2063-2067` | `keep_workdir` is set True on every handoff/stop path (`:1744`…`:1879`) but never read; the `finally` always logs "retained". Only one `return 0` (`:2062`); the dry-run B1 early return (`:1813`) already sets `keep_workdir`. `run_isolated_check` (`:217-230`) `merge-check-*` retention is pinned by `test/gh436-merge-cleanup.py` takeover tests and `SKILL.md:80` → untouched. Existing operator-clone removal goes to Trash (`:1425-1440`); that rule is for operator checkouts, not this run's own `mkdtemp` scratch, and Trash on the same volume would not free disk (F1). |
| P1.4 | `main()` `--reconcile-pr` branch `:2348-2370` → `run_post_merge_reconcile` → `commit_and_push_phase5_writes` | Verifies MERGED + merge OID, reconciles, pushes; writes nothing to the batch record. `batch_record.continuable` (`batch_record.py:250-257`) treats a PR done only when `status=="merged"` and `reconcile=="ok"`. `_record_batch_outcomes` (`merge_cleanup.py:1590-1614`) ends with `finalize_sweep_inputs` + `batch_record.update` (issue refresh). `record_sweep` (`:2765-2787`) prints "Planned PRs remain: continue with --resume --execute." whenever `continuable`. |
| P1.5 | `SKILL.md:476` | Says single-PR runs have no exit 4. `merge_cleanup.py:2634-2663`: any `--execute` that finds a QA-pending batch (adopted or not) returns 4. Exits used: 0, 1 (`--retire-published-pr`, `:2127`), 2, 3, 4, 5 (`:79`). `test/gh534_phase_c_tests.py` pins SKILL.md substrings (`## Drive loop`, `Done rule`, `exit 4 is never Done`). |
| P1.6 | dry-run branch `:2424-2440` (forecast, pin, `jog_primary_precondition` warning) and `required_checks_state` (`:732-745`, called in the loop at `:1893`) | Precedent for a read-only dry-run warning: `jog_primary_precondition` → `log_warn`. `required_checks_state` already returns `("ok", "no required checks")` with no extra call. |

Untraced: hosted CI behaviour of these paths (none run them); Windows/Linux `pgrep`/`pmset` variants (probes are silent on any error).

## Preflight bet check
- **Outcome sought:** the next unattended batch does not fail on a fetch race, shows live progress,
  does not fill the disk with clean-run workdirs, ends with an accurate batch record after a
  recovery, and warns about known environment hazards before it starts.
- **Smallest viable bet:** six local edits in two Python files and one doc; no new module, flag,
  config key, state file or gh call. Not built: retention policy, locks, heartbeats, re-pin (Phase 2/3).
- **Alternatives rejected:** documenting the pre-flight list only (already in the post-mortem; it was
  not followed under pressure); moving workdirs to Trash (keeps the bytes on disk, so F1 is unfixed);
  an `fcntl.flock` lock (adds state to `--execute`; P3.6).
- **Rollback / containment:** one revert of the PR restores the code. Deleted scratch is not
  restored by a revert; P1.3 deletes only this run's own `mkdtemp` workdir after a clean 0 return,
  never a kept or failed one.

## Phase 1 plan
Ordered; verification inline. Existing writers extended: `batch_record.set_outcome` / `update`,
`log_warn`, `_retry_call`/`TRANSIENT_RE`.

1. **P1.2** `main()`: at entry, `sys.stdout.reconfigure(line_buffering=True)` and the same for stderr
   (guarded with `getattr`, so a replaced stream in tests is left alone).
2. **P1.1** `wave_reconcile.py` `pull_upstream`: up to 3 attempts of `git fetch origin <branch>` then
   `git merge --ff-only origin/<branch>`; retry (sleep 1 s, then 2 s) only when stderr matches
   `cannot lock ref|Unable to create .*\.lock|unable to update local ref`; otherwise `die()` with the
   stderr as today. Add `cannot lock ref|unable to create .*\.lock` to `merge_cleanup.py`
   `TRANSIENT_RE`.
3. **P1.3** `_land_prs_loop`: initialise `clean = False` before the `try`, set `clean = True` immediately before the single `return 0`; in the
   `finally`, when `clean and not keep_workdir and not deferred_sync_pending`, remove `workdir` with
   `shutil.rmtree` after proving it is a resolved, non-symlink directory whose parent is the resolved
   `tempfile.gettempdir()` and whose name starts with `merge-cleanup-`; log the removal. Otherwise keep
   the existing "retained" log. A removal error is logged as a warning and never changes the exit code.
4. **P1.4** extract the tail of `_record_batch_outcomes` (policy lookup, `finalize_sweep_inputs`,
   `update`, issue-error warning) into `_sync_batch(batch, primary_repo)` and call it from both
   places. In the `--reconcile-pr` branch, after `commit_and_push_phase5_writes` succeeds and only
   when not a dry run: `batch_record.find_unfinished(primary, origin, branch, [N])`; if found,
   `set_outcome(batch, N, status="merged", merge_oid=<GitHub merge OID>, reconcile="ok")` then
   `_sync_batch`. In `record_sweep`, replace the single hint with: for each planned row not done
   (per `continuable`'s rule), a row with `status=="merged"` → `--reconcile-pr N --execute`; any
   other → counted as possibly open; print `--resume --execute` only when that count is non-zero.
   (No gh query: the record already holds positive MERGED evidence for landed rows; GH-1140 records
   out-of-run merges on the next resume.)
5. **P1.5** `SKILL.md`: correct the `:476` sentence; add a 6-row exit-code table for wrapper scripts
   next to the drive loop, keeping every substring the doc-contract tests pin.
6. **P1.6** add `preflight_warnings(primary_repo) -> List[str]` (disk under the temp root < 20 GB;
   macOS on battery via `pmset -g batt`; `TMPDIR` set and resolving outside `/tmp` and the OS default
   `/var/folders`; another `merge_cleanup.py … --execute` from `pgrep -f`, excluding this PID). Each
   probe is wrapped so any error is silent; `pmset`/`pgrep` run with a 5 s timeout and only a zero
   exit with text output is parsed; `_gh` is not touched. Call it in the merging dry run next to the Jog warning and
   print each as `PRE-FLIGHT: …` via `log_warn`. In `_land_prs_loop`, when `dry_run` and
   `required_checks_state` returns `"no required checks"`, print the F6 `PRE-FLIGHT:` warning once.

## Verification
No new tests (GH-831). Focused during work: `bash test/gh436-merge-cleanup.sh` (runs the
merge-cleanup Python suites including `gh436`/`gh534_*`), `bash test/gh202-wave-reconcile-issue-state.sh`,
`bash test/gh168-wave-reconcile-scope.sh`. Final gate: the classifier routes `merge_cleanup.py`,
`wave_reconcile.py` and `skills/*/merge-cleanup/SKILL.md` to the full gate, run once on the final
commit in a disposable full clone (and again by the pre-push hook). Manual checks with red controls,
recorded under `TESTS-RESULTS/2026-11-14+GH-1475/` with commands, revision, exit statuses, outputs and `provenance.jsonl` (GH-430):

| Item | Check | Red control (unchanged tree) |
|---|---|---|
| P1.1 | Scratch repo with origin whose `<b>` has advanced (so the fetch must update the ref): hold `refs/remotes/origin/<b>.lock` ~1.5 s and write a two-branch `FETCH_HEAD`, run `pull_upstream`: succeeds after retry; non-lock error still dies | old `git pull --ff-only` fails under the same setup |
| P1.2 | Run `merge_cleanup.py --primary <scratch> > log` with a `gh` stub (`GH_BIN`) that sleeps 20 s on its first call, so the process is held after Phase 0; at ~5 s assert the process is still alive and the log already has a Phase 0 line | same input on the base: process alive, no Phase 0 line yet |
| P1.3 | Drive `_land_prs_loop` on a clean dry run in a scratch primary: no `merge-cleanup-*` left; a forced stop (`keep_workdir`) leaves it | old code leaves it in both cases |
| P1.4 | Scratch primary + batch record with one merged, reconcile-failed row; call `main()` with `--reconcile-pr N --execute`, stubbing only `refresh_pr_with_retry` (MERGED + OID), `run_post_merge_reconcile` and `commit_and_push_phase5_writes` (True) and `_gh`; reload the persisted record: row is `merged`/`reconcile: ok`, the issue update ran, `record_sweep` prints no `--resume` hint. Same with the dry run, and with the reconcile or push stub returning False: row unchanged. A merged-unreconciled row prints `--reconcile-pr N --execute`; a closed row prints nothing | base tree: reloaded row still reconcile-failed, hint `--resume --execute` |
| P1.5 | Doc read from the drive-loop entry point; doc-contract suite green | old `:476` text contradicts `:2634-2663` |
| P1.6 | Dry run with `required_checks_state` stubbed to `("ok", "no required checks")`: exactly one F6 `PRE-FLIGHT` line, `_gh` call count unchanged; with a named passing check: none. Force each other condition (a `TMPDIR` override to a nested scratch dir, stub `pmset`/`pgrep` on PATH, low threshold via monkeypatched `shutil.disk_usage`): each warning fires; clean env prints none | old dry run prints none |

Smoke (disposable clone): main path — a real `--prs` dry run of this repo against a scratch primary
showing live log, PRE-FLIGHT block and no leftover workdir; adjacent path — `--record-sweep` /
`--reconcile-pr` dry run (no writes) on a scratch record.

## QA gate
Phase 1 passes when: Codex plan QA Approved; focused suites green; full gate green once on the final
commit; each manual check above passes with its red control observed; Codex final QA Approved.

## Rating
2026-11-14 · `rated 60/65/50/75` (pri/sev/appeal/effort). Severity 65: work-blocking failures
(disk full, failed reconcile, stopped wrapper) that cost hours in the observed batch but lost no data
and were recoverable. Priority 60: tracks severity; operator asked for Phase 1 now. Appeal 50
neutral (no operator value). Effort 75: six local edits, no new subsystem. Recurrence: one batch
produced the observed incidents (one incident each, not a rising trend); `merge-cleanup` in-title
issues opened 2026-10-31..11-14: 6 vs 2026-10-17..10-30: 13 (all classes; trend for these specific
failure modes unknown).

## Lessons Learned
_To be filled at handoff._
