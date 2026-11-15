---
gh_issue: 1475
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1475
title: "merge-cleanup: 3-phase remediation from a 13-PR batch post-mortem (Phase 1, Phase 2A)"
status: Active
created: 2026-11-14
updated: 2026-11-14
owner: Claude
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 2
non_goals:
  - Phase 2B and Phase 3 items (P2.4–P2.7, P3.1–P3.6)
  - P2A.measure and P2A.decision (separate, after Phase 2A lands)
  - any refusal, lock file or new gh call in the dry run
  - new tests, suites or gate machinery (GH-831)
goal: >
  Ship the six Phase 1 quick wins (landed in PR 1478), then Phase 2A (P2.1, P2.2, P2.3, P2.8)
  as one small, reversible PR each
---

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# merge-cleanup remediation — Phase 1 quick wins

## Status

| What was just completed | What's next |
|---|---|
| Phase 1 landed (PR #1478); Phase 2A plan written (P2.1, P2.2, P2.3, P2.8) | Codex plan QA on the Phase 2A plan, then implementation |

## Table of contents
- [Problem](#problem)
- [Recon map](#recon-map)
- [Preflight bet check](#preflight-bet-check)
- [Phase 1 plan](#phase-1-plan)
- [Verification](#verification)
- [QA gate](#qa-gate)
- [Rating](#rating)
- [Phase 2A](#phase-2a)
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
| P1.2 | Run `merge_cleanup.py --primary <scratch> > log` with a `gh` stub (`MERGE_CLEANUP_GH_BIN`) that sleeps 20 s on its first call, so the process is held after Phase 0; at ~5 s assert the process is still alive and the log already has a Phase 0 line | same input on the base: process alive, no Phase 0 line yet |
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

## Phase 2A
Scope: P2.1, P2.2, P2.3, P2.8 of the issue body. P2A.measure and P2A.decision are not in this PR.
Base: `origin/development` `a9ece7fcf` (Phase 1 merged as `4306cba77`). Paths below are
`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` unless named; line numbers are at the base.

### Phase 2A recon
| Item | Entry point → state | Observation |
|---|---|---|
| P2.1 | `_land_prs_loop` B1 branch `:1812-1933` → `push_resolved_head` → re-fetch until GitHub reports `b1["commit"]` (`:1898-1915`) → re-gate clone → ledger gate `:1936` → pin check `:1947-1953` | After a successful repair the loop already proves GitHub reports exactly `b1["commit"]` (`:1907`, `:1912`) and re-gates it, then **always** defers at `:1948` because the head is not `args._pins[n]` (exit 3). The checks wait (`:1957-1982`) is never reached for a repaired head. The final eligibility re-read (`:1987-2016`) stops on a head change (`:2006`, rc 2) and refuses an unpinned head (`:2010`). Writers that hold the pin: `args._pins` (in memory, from `verify_selection` `:2320`), the selection file (single writer `pin_selection` `:509`, GH-1452, keeps the stored forecast only when passed back), and `batch_record.set_allowlist` (`batch_record.py:329`, latest pin wins). `required_checks_state` (`:750`) reads `gh pr checks <n> --required`, which reports the PR's current head; right after a push, checks may not be registered, and gh then answers "no required checks reported", which the function maps to `ok`. Tests pinning the deferral: `test/gh534_phase_b_tests.py:423-424` (`land_repaired` `:241-245`), `test/gh534_phase_c_tests.py:283-284, :392, :456-457, :664`. Forecast text: `merge_cleanup.py:676` and `ledger_merge.py:704` say a repair defers the PR; `SKILL.md:259`, `:287`, `:292`, `:473` say the same. |
| P2.2 | `resolve_merge_policy` `:270-311` (sole validator of `.merge-cleanup.json`), `required_checks_state` `:750-772`, the wait loop `:1962-1970`, the F6 dry-run warning `:1958-1961` | `qualification` accepts only `full_suite` (required), `sweep_command`, `canary_command`. The policy is re-read per PR in the loop (`:1717`), so `policy["qualification"]` is in scope where checks are read. Test stub (`gh534_phase_b_tests.py` GH_STUB `pr checks`) ignores `--required` and answers from `st["checks"][n]`, else "no required checks reported". Real gh without `--required` says "no checks reported" when none exist. |
| P2.3 | `_land_prs_loop` `finally` `:2132-2139`; `run_isolated_check` `:235-248` (`merge-check-*`, retained, pinned by `test/gh436-merge-cleanup.py` takeover tests and `SKILL.md:479`); `prepare_landing_clone` `:807` (`pr-<n>-<sha8>-*` under the workdir); `validate_head_in_second_clone` `:834` (also under the workdir) | Phase 1 removes the workdir only on a clean 0 return with no `keep_workdir`. Exit 3 from deferrals alone (`:2119-2129`) never sets `keep_workdir`, so the whole workdir, including landed PRs' clones, is kept. Nothing ever prunes older `merge-cleanup-*`/`merge-check-*`. Existing helpers: `_remove_own_scratch` (`:218`, proves prefix + direct child of the resolved temp root + not a symlink) and `scan_clones.inspect_open_handles` (`scan_clones.py:364`, `lsof +D`, three outcomes, fails closed: `verified` False on any doubt). Suites run fixtures under the real `$TMPDIR`, so any prune also runs during tests against the developer's temp root. |
| P2.8 | B1 branch `:1858-1877` | `resolve_ledger_conflict(execute=False)` (`ledger_merge.py:536-583`) returns `handoff=True` for every non-repairable case and otherwise `resolved=False` with reason `[DRY RUN] B1 would keep …` (`:581-583`). So in a dry run, a non-handoff result is always the B1 preview, and `:1872-1877` logs "B1 stopped", sets `keep_workdir`, and `return 0`, leaving later PRs unpreviewed. Confirmed in the Phase 1 smoke (`TESTS-RESULTS/2026-11-14+GH-1475/smoke.log`). |

### Phase 2A preflight bet check
- **Outcome sought:** a hub PR lands in one cycle when its repaired head goes green; a repo without
  branch protection can still make the script wait for named CI; retained clones stop filling the
  disk; a dry run previews the whole batch.
- **Smallest viable bet:** edits inside `_land_prs_loop`, `resolve_merge_policy`, one small checks
  helper, one prune helper reusing `_remove_own_scratch` + `inspect_open_handles`, wording in two
  forecast strings and `SKILL.md`, and truthful updates to the existing tests that pin the old
  deferral. No new module, state file, flag, or test.
  Not built: heartbeat, stacked-lane detection, forecast pass rules (2B), measurement (P2A.measure).
- **Alternatives rejected:** re-pin by running a fresh dry run inside the loop (re-plans the whole batch;
  more gh calls); a CLI flag for declared checks (the policy file is where the repo's merge policy
  already lives, so a per-run flag would drift); age-only pruning (cannot tell a live run's dir from an
  old one; the open-handle probe is the existing safety check).
- **Rollback / containment:** revert the PR. P2.1 only re-pins a head this run pushed and GitHub
  reports unchanged after its checks pass; anything else keeps today's deferral. Pruned scratch is not
  restored by a revert; pruning is limited to tool-named temp-root children, older than the newest N and
  older than one hour, with a verified-idle `lsof` result, skipped while another `merge_cleanup.py` runs.

### Phase 2A plan
Ordered; verification inline. Writers extended: `args._pins` + `pin_selection` + `batch_record.set_allowlist`
(P2.1), `resolve_merge_policy` (P2.2), `_remove_own_scratch` + `inspect_open_handles` (P2.3).

1. **P2.8** In the B1 branch, when `dry_run` and `not b1["handoff"]` (the preview case), log
   `[DRY RUN] PR #n: B1 would repair this ledger conflict (<reason>); --execute repairs it, waits for the new head's checks and re-pins` and `continue`
   with no `failed` entry, no `keep_workdir`, no return. Execute-mode "B1 stopped" stays as is (rc 2).
   *Check:* a two-hub dry run previews both PRs (each `[DRY RUN]` line present) and returns 0 with no
   kept workdir. *Red control:* base logs "B1 stopped" for the first hub and never mentions the second.
2. **P2.2** `resolve_merge_policy`: accept `qualification.wait_for_checks`, a non-empty list of non-empty
   strings (still requires `full_suite`, as every `qualification` does today). New
   `checks_state(p_num, repo, declared)`: calls `required_checks_state` unchanged; when `declared` is set,
   one more `gh pr checks <n> --json name,bucket` read, and per declared name: any `fail`/`cancel` →
   failing; absent ("not reported") or `pending`/unknown bucket → pending; all `pass`/`skipping` → ok.
   gh's "no checks reported" means every declared name is absent (pending); any other unreadable answer
   is `unknown` (defers, never merges). Combined result: when the required part is "no required checks",
   the declared result alone; otherwise worst of the two (failing > unknown > pending > ok). The loop's
   two `required_checks_state` calls (`:1957`, `:1970`) use `checks_state` with
   `(policy.get("qualification") or {}).get("wait_for_checks")`. The F6 warning fires only when no checks
   are declared. *Check:* policy validation accepts a list and refuses `[]`, `[""]`, a string; a fixture
   PR with no required checks and declared `ci` pending waits, then lands when `ci` passes, and defers when
   it stays pending past a short `MERGE_CLEANUP_CHECKS_WAIT_S`; a missing declared name defers. *Red control:*
   base merges the same PR at once ("no required checks") and refuses the policy key.
3. **P2.1** In the B1 success path (execute only), before `push_resolved_head`, read
   `required_checks_state` once on the old head and remember whether the repo reported any required checks
   (`had_required = detail != "no required checks"`; an unknown answer counts as having them). After the
   push and the existing proof that GitHub reports `b1["commit"]`, set `own_repair = b1["commit"]`. At the
   pin check (`:1947`): when the head is not the pin and equals `own_repair`, do not defer; go to the checks
   wait. If `had_required` and the new head still reads "no required checks", poll every
   `MERGE_CLEANUP_CHECKS_POLL_S` for up to `MERGE_CLEANUP_CHECKS_GRACE_S` (default 120 s) for them to
   register; still none → defer `required checks not registered on the repaired head`. The existing
   pending wait, failing and defer handling then apply. When checks are `ok`: one `refresh_pr_with_retry`;
   if the head is no longer `own_repair` → defer `head moved after this run's B1 repair`; else re-pin:
   `args._pins[n] = head`, `pin_selection(primary, branch, args._pins, <pins as open PRs>, forecast=<stored forecast>)`
   (single writer kept), `batch_record.set_allowlist(batch, {n: head})` when a batch exists, and log
   `PR #n: re-pinned to <sha> after this run's B1 repair (checks passed on that commit)`. The final
   eligibility checks (`:2006`, `:2010`) are unchanged and now pass for the re-pinned head. Any other
   off-pin head keeps today's deferral. Forecast wording (`merge_cleanup.py:676`, `ledger_merge.py:704`) and
   `SKILL.md` (`:259`, `:287`, `:292`, `:473`) say a repaired PR lands in the same run once its new head's
   checks pass, else defers. Update the pinned tests truthfully: `gh534_phase_b_tests.py:423-424` and
   `gh534_phase_c_tests.py:283-284, :392, :456-457, :664` expect the repaired PR to land in the first run
   (helper `land_repaired` becomes an assertion of the re-pin log line). *Check:* those suites green; manual:
   repaired head with a pending required check that turns green lands in one run (rc 0/4) and the selection
   file + batch allowlist hold the new head. *Red controls:* (a) base defers the repaired head (rc 3);
   (b) an external push after the repair (head ≠ `own_repair` at the post-check refresh) still defers;
   (c) a head moved off the pin before the run (`:1792`) still defers; (d) required checks that never
   register within the grace defer.
4. **P2.3** New `prune_retained_scratch(current)` called from the `finally`, after Phase 1's own-workdir
   decision: skipped entirely when `pgrep -f merge_cleanup\.py` reports another process (reuses
   `_probe_text`). For each prefix (`merge-cleanup-`, `merge-check-`): candidates are direct children of the
   resolved temp root with that prefix, real directories owned by this uid, not `current`; sort newest-first
   by mtime, keep the newest `MERGE_CLEANUP_KEEP_WORKDIRS` (default 3, invalid → 3), and also keep anything
   modified within the last hour. Each remaining candidate is removed with `_remove_own_scratch` only when
   `scan_clones.inspect_open_handles(path)` returns `verified` and not `active`; otherwise it is kept and
   named. One summary line: pruned N, kept M (reasons). Also in the `finally`: when the loop returned 3,
   `keep_workdir` is false and no deferred sync is pending, remove the clones of PRs merged in this run
   (`workdir/pr-<n>-*` for `n` in this run's merged set) with `_remove_own_scratch(path, f"pr-{n}-", root=workdir)`
   — `_remove_own_scratch` gains an optional `root` (default the temp root). The deferred PRs' clones stay.
   `SKILL.md:479` updated. *Check (manual, scratch `TMPDIR`):* five old `merge-cleanup-*` and five old
   `merge-check-*` → newest 3 of each kept, one held open by a `sleep` with cwd inside → kept, one under
   an hour old → kept, a symlink and a foreign-prefix dir → untouched; an exit-3 loop with one landed and one
   deferred PR leaves only the deferred PR's clone. Existing `gh436`/`gh534_*` suites green (takeover tests
   keep their `merge-check-*`: newest and under an hour). *Red control:* base leaves all ten dirs and both
   PR clones.
5. CHANGELOG entry; doc Status; receipts under `TESTS-RESULTS/2026-11-14+GH-1475-phase2a/`.

### Phase 2A verification
No new tests (GH-831). Focused: `bash test/gh436-merge-cleanup.sh` (collects `gh534_phase_a/b/c`). Final
gate: the route for `merge_cleanup.py`/`ledger_merge.py`/merge-cleanup `SKILL.md` is the full gate, run once
by the pre-push hook on the final commit. Manual checks above with their red controls, recorded with
commands, revision, exit codes and `provenance.jsonl`. Smoke in a disposable clone of this repo: main path
a real `--prs` dry run over open PRs (P2.8 shows every PR, PRE-FLIGHT respects declared checks); adjacent
path a second dry run (rerun) plus `--show-merge-policy` with a `wait_for_checks` policy.

### Phase 2A QA gate
Codex plan QA Approved; focused suite green; full gate green on the final commit; each manual check
passes and its red control is observed on the base; smoke recorded; Codex final QA Approved.

### Phase 2A rating
2026-11-14 · retained `rated 60/65/50/75` (one row per issue; read back from the ledger). Phase 2A
addresses the same observed batch (F13 two cycles per hub, F6 manual CI waits, F1 disk full twice); no new
incidents since Phase 1 landed (window 2026-11-14..15). Severity and priority unchanged; Phase 2A is a
little more work than Phase 1 but within the same cheapness band. Appeal 50 neutral.

## Lessons Learned
- An independent plan review caught a race the author missed: `merge --ff-only FETCH_HEAD` still
  reads the shared file a concurrent fetch rewrites; merge `origin/<branch>` instead.
- A cleanup predicate with several guards needs a control that reaches the success path with each
  guard tripped; the first P1.3 evidence never exercised `clean=True, keep=True`.
- Smoke on a real repo found every open PR conflicting, so dry runs still keep clones via the
  pre-existing B1 dry-run early return (P2.8); Phase 1 does not change that.

## Merge evidence

- PR #1478 merged 2026-11-15 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
