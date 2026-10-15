---
gh_issue: 1064
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1064
title: "merge-cleanup: script-owned batch issue (planned sequence) and enforced post-merge QA for batches of 2+ PRs"
status: "Proposed (1-INBOX - not yet active)"
created: 2026-10-14
updated: 2026-10-14
owner: operator
doc_type: feature
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/944
---

# GH-1064 — script-owned merge-batch issue and recorded post-merge QA

## Status

| What was just completed | What's next |
|---|---|
| Intake, rating, recon, plan drafted; operator scoped it (below). | Codex plan QA. |

## Operator decisions (2026-10-14)

1. **Script records, agent runs.** The script owns the batch issue, the run record, the sweep
   *inputs*, and the verdict *record*. It does **not** run the regression suite. The agent still runs
   it in a throwaway clone, as today. Reason: GH-831 forbids new gate machinery ("guards, lanes,
   runners"), and #944 kept the protocol in prose for the same reason.
2. **Exit code 4 = "landed, QA pending".** A batch that landed PRs but has no recorded sweep verdict
   ends with exit 4, not 0.
3. **Threshold is 2+ PRs** (was 3+), for both the issue and the sweep record. Single-PR runs are unchanged.

## Rating — 45/40/50/45 (pri/sev/appeal/effort), 2026-10-14

- **Severity 40:** a process/record gap with no data loss. A batch can land with a missing or
  inconsistent record, and post-merge QA can be skipped silently.
- **Priority 45:** the operator set it as medium priority.
- **Appeal 50:** neutral.
- **Effort 45:** about four script/test files plus SKILL.md, with an existing stub and helpers to extend.
- **Recurrence (2026-09-24..2026-10-15):** 6 batch issues exist (#791, #957, #1003, #1012, #1030,
  #1063), each with a different title and format. #1030 is a hand-rolled "merge record + post-merge
  review" with a 2-PR queue that the 3+ protocol does not cover. Days with several merges and no
  batch issue also exist (e.g. 2026-10-06, 4 merges). Coverage is limited to the 60 most recent
  merged PRs.

## Recon (base dbce58af)

All paths are under `skills/2-daily/merge-cleanup/scripts/` unless given as repo paths.

- **Driver:** `merge_cleanup.py` `main()` :1230; argparse :1242-1258.
  - Phase 4 runs `toposort_prs()` :1378 into `ordered_prs`.
  - Phase 5 runs `land_prs()` :902-1212. The loop is :928-1188 and the merge call `execute_pr_merge` is :1162.
  - The summary is :1189-1207. Exits are 0, 2 (hard stop) and 3 (queue done, something did not land).
- **Sequencing:** `toposort_prs.py` :85-192.
  - Hard edges come from body regexes (:52-70); soft edges from file overlap (:115-149).
  - Each PR carries `_hard_deps`/`_soft_deps`. The overlap *files* exist only in free-text warnings
    (:147-148), which `main()` discards, but `pr["files"]` is kept.
- **Outcomes:** only the `failed` dict (:925) is kept. Successful landings and merge commit oids are
  not recorded; `execute_pr_merge` returns a bool.
- **Records:** per-PR only, in `attempt_record.py`. Path `.tick/merge-cleanup/<slug>/pr-N.json`, with
  `RecordLock` + atomic `save` and `conflict_files[]`. There is no run-level record, and `--resume`
  has no batch state.
- **gh:** `scan_clones._gh()` :70 (it never raises; failures come back as rc 127, with the binary set by
  `MERGE_CLEANUP_GH_BIN`); `post_issue_marker` :315. There is no issue create/edit helper.
- **Tier selection to reuse:** `utils/py/wave_reconcile.py` `select_qualification_gate(clone, metas, env)` :593.
  It classifies the union diff of `mergeCommit.oid`s via `utils/ci-route.sh push`.
- **Tests/guards:**
  - `test/gh436-merge-cleanup.sh` → `gh534_phase_{a,b,c}_tests.py`.
  - `GH_STUB` in `gh534_phase_b_tests.py` exits 9 on any unknown gh verb.
  - The parity guard (`gh534_phase_c_tests.py` :527-605) pins the capability-table owners and requires a real
    `TestClass.method` for every `script` row. The SKILL.md options line must match argparse.
  - `TestGh623DriveLoopDocContract` (:880-929) pins exact Drive-loop and Done-rule phrases.
- **Routing:** `skills/*/merge-cleanup/*` routes as non-docs (`utils/ci-route.sh`:67); SKILL.md forces the full gate.
- **Callers of `merge_cleanup.py`:** SKILL.md and `PAGES/skills.html` usage examples only. No code
  depends on its exit codes.

## Preflight bet check

- **Outcome sought:** every 2+ PR landing leaves one consistent GitHub record of the *planned* order
  and its results. Missing post-merge QA becomes visible in the exit code instead of resting on the
  agent's reading of the Done rule.
- **Smallest viable bet:** a small run-record module plus hooks at three points in `land_prs`, one new
  flag, and one new exit code. No new runner, suite, guard, label scheme or daemon.
- **Alternative rejected:** prose-only (the #944 approach, tightened). Rejected because it is the
  status quo that produced 6 inconsistent records and an unenforceable Done rule. A script-run suite
  was rejected by the operator under GH-831.
- **Rollback:** revert the commit. Run records live under the gitignored `.tick/`, and issues already
  created stay as plain GitHub issues.

## Non-goals

- The script running any test suite, or blocking a merge on QA.
- Auto-closing batch issues, executing post-deploy items, or automating the carry-over transcription
  (that stays caller-owned).
- Any change to single-PR runs, Phase 4 ordering logic, merge policy, or teardown.
- New `test/` files, `validate.sh` entries, or guards (GH-831).

## Plan (ordered; verification inline)

1. **Keep soft-edge reasons as data** (`toposort_prs.py`, about 5 lines). Where soft edges are
   computed, also set `pr["_soft_reasons"] = {dep_number: sorted(overlap_files)}`. Ordering is unchanged.
   *Verify:* the existing ordering tests stay green.
2. **New `batch_record.py`** (about 150 lines). It reuses `attempt_record.repo_slug`, `RecordLock` and
   atomic `save`, and `scan_clones._gh`, so there is no second lock or gh wrapper.
   - **Record:** `.tick/merge-cleanup/<slug>/batch-<key>.json` holding `{schema:1, integration, issue,
     issue_error, planned:[{pos, pr, title, hard:[..], soft:{pr:[files]}}], outcomes:{pr:{outcome,
     merge_oid}}, sweep_inputs, verdict}`.
   - `open_or_resume(primary, slug, integration, ordered, resume)`. With `--resume`, it finds the
     newest local record whose PR list overlaps and whose verdict is unset, and reuses its issue.
     Otherwise it runs `gh label create merge-batch --force` and then `gh issue create --label
     merge-batch --body-file`. The body is rendered from the record, with a hidden marker
     `<!-- merge-batch integration=<b> prs=<n,…> -->`. Any gh failure sets `issue_error` and returns;
     it never raises.
   - `render_body(rec)` produces the GH-944 template: Merge sequence (planned order with dependency
     reasons, then the outcome per row), Problems, Ad-hoc fixes & pivots, Findings, Regression sweep,
     and Post-deployment carry-overs. The caller-owned sections are kept as placeholders for the agent.
   - `update(rec)` saves locally and runs `gh issue edit <n> --body-file`. A failure is recorded and does not block.
   - `record_sweep_inputs(rec, …)` and `record_verdict(rec, path)`.
3. **Hook into `merge_cleanup.py`:**
   - **Before the loop in `land_prs`:** when not dry-run and `len(ordered_prs) >= 2`, call
     `batch = batch_record.open_or_resume(...)`. This is the pre-first-merge point, :913-927.
   - **Per PR:** on landing, read `gh pr view N --json mergeCommit` for the oid. On each `failed[N]`
     entry, record its reason. Then call `batch_record.update`.
   - **After the loop**, if any PR landed, record the sweep inputs:
     - the merged range (first..last merge oid);
     - files touched by 2+ landed PRs (from `pr["files"]`);
     - the repaired conflict sites from each landed PR's `pr-N.json` `conflict_files`;
     - the tier from `select_qualification_gate`, imported through the same harness-tool resolution
       the reconcile step uses. If the import fails, record "tier unknown — run full".
     Then print the exact suite command for a `git clone --no-local` throwaway clone:
     `validate.sh --sequential --subsystem small` for tier 1, `validate.sh --sequential` otherwise.
   - **Exit:** when a batch exists, landed ≥1 PR, has no verdict, and the run would otherwise exit 0,
     print `STATUS: landed, QA pending — record a verdict with --record-sweep <file>` and return 4.
     Precedence is 2 > 3 > 4 > 0.
   - **New flag `--record-sweep PATH`** (standalone: it needs `--primary`, merges nothing, scans nothing).
     It loads the newest batch record that has no verdict. The first line of `PATH` must be
     `verdict: clean|findings|deferred`. Clean must name what ran (a non-empty body). Findings need at
     least one `- [ ]`. Deferred needs a reason. On success it stores the verdict, updates the issue
     and exits 0; malformed or empty input exits 2 and stores nothing.
   - *Verify:* the step 5 tests.
4. **SKILL.md:**
   - Change the threshold from 3 to 2 everywhere (recite item 6, Execute step, protocol trigger).
   - Rewrite the protocol bullets to say what the script does and what is still the caller's job:
     the analysis, running the suite, writing the verdict file, and carry-overs.
   - Add exit 4 and `--record-sweep` to the Drive loop and the Done rule by *adding* sentences, not
     rewording the pinned phrases.
   - Capability table: `batch-issue-threshold` and `batch-issue-resume-append` become `script`; add
     `batch-sweep-record` as `script`; `batch-regression-sweep` and `post-deploy-carryover-dual-sink`
     stay `caller`. Add `--record-sweep` to the options line.
5. **Keep the existing suite truthful** (`gh534_phase_b_tests.py`, `gh534_phase_c_tests.py`; no new file
   or registry entry). The parity guard *requires* a real test method for each `script` row, so this is
   the GH-831 "edit an existing suite to keep it truthful" case.
   - Extend `GH_STUB` with `label create`, `issue create` (records the body and prints a URL) and `issue edit`.
   - Add `TestBatchIssue`, with three methods:
     - **(a)** A 2-PR queue opens the issue *before* the first `pr merge` (checked in the stub's call
       log), with the planned order and soft-edge files. Outcomes are updated, and the run exits 4 with
       no verdict. A 1-PR queue creates no issue.
     - **(b)** `--resume` reuses the open record's issue: no second `issue create`.
     - **(c)** `--record-sweep` stores a valid verdict and exits 0. Empty or malformed input exits 2 and stores nothing.
   - Update `REQUIRED_CAPABILITIES` to match the new owners and the new row.
   - **Red controls:** set the threshold to 3, and (a) must fail. Make `--record-sweep` accept an
     empty body, and (c) must fail. Witness both and record them under `TESTS-RESULTS/2026-10-14+GH-1064/`.
6. **Gates:** iterate with `bash test/gh436-merge-cleanup.sh`. The classified route is the full gate (the
   SKILL.md path). Run it once on the final approved commit in a disposable `<folder>-gate` clone.
7. **CHANGELOG + doc status.**

## Risks

- **Exit 4 is new.** The only consumers are the SKILL.md drive loop and docs, and both are updated.
  A caller that treats non-zero as failure sees exit 4 as "not done", which is the intent.
- **Issue churn:** one `gh issue edit` per PR in the batch. Batches are small, so this is negligible.
- **Pinned doc phrases:** handled by adding text only. The suite will catch any slip.
