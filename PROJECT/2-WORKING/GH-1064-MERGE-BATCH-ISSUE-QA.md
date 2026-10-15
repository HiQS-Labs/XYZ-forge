---
gh_issue: 1064
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1064
title: "merge-cleanup: script-owned batch issue (planned sequence) and enforced post-merge QA for batches of 2+ PRs"
status: In Progress
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
| Implemented per the approved plan; gh436 green (185); 3 red controls recorded. | Full gate in a disposable clone, then final Codex QA and PR. |

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
  - Each PR carries `_hard_deps`/`_soft_deps`. The soft-edge warning carries only the overlap
    *count* (:147-148), and `main()` prints it (:1388-1391). The overlapping filenames are not kept
    anywhere; they have to be recomputed from `pr["files"]`.
- **Outcomes:** only the `failed` dict (:925) is kept, and it is incomplete:
  - hold-label and non-OPEN skips never enter it (:973-979);
  - drafts are removed from it (:1197);
  - a remote merge can succeed and then exit 2 during fetch, fast-forward, reconcile or durability
    (:1162-1188).
  Successful landings and merge oids are not recorded, and `execute_pr_merge` returns a bool.
  Discovery returns OPEN PRs only (`toposort_prs.py`:34), so a `--resume` queue shrinks as PRs land.
  An empty queue skips `land_prs` entirely (:1443).
- **Phase 5 → 6 dispatch:** `main` returns any non-zero `land_prs` rc before Phase 6 (:1448-1450).
- **Records:** per-PR only, in `attempt_record.py`. Path `.tick/merge-cleanup/<slug>/pr-N.json`, with
  `RecordLock` + atomic `save` and `conflict_files[]`. There is no run-level record, and `--resume`
  has no batch state.
- **gh:** `merge_cleanup._gh()` :70 (it never raises; failures come back as rc 127, with the binary
  set via `scan_clones._gh_bin`); `post_issue_marker` :315. There is no issue create/edit helper.
- **Tier selection to reuse:** `utils/py/wave_reconcile.py` `select_qualification_gate(clone, metas, env)`
  :593. It classifies the union diff of each `mergeCommit.oid` against its parent (:603) via
  `utils/ci-route.sh push` and returns `(gate, expected_small_list|None, reason)`.
- **Existing exit-0 expectations for 2-PR success:** `gh534_phase_b_tests.py`:379/388 and
  `gh534_phase_c_tests.py`:282.
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
2. **New `batch_record.py`** (about 180 lines). It reuses `attempt_record.repo_slug`, `RecordLock`
   and the schema-neutral atomic `save`, but never `attempt_record.load`, which requires per-PR keys.
   GitHub calls take an injected `gh` callable (the driver passes `merge_cleanup._gh`), so there is no
   import of the CLI driver and no second gh wrapper (R1).
   - **Record:** `.tick/merge-cleanup/<slug>/batch-<utc>.json` holding `{schema:1, integration,
     issue, issue_error, planned:[{pos, pr, title, files:[paths], hard:[..], soft:{pr:[files]}}],
     outcomes:{pr:{status, merge_oid, reconcile}}, sweep_inputs, verdict:{value, covers:[prs], body}}`.
     Every planned row starts with status `unattempted`. Each row keeps its normalized file list
     (R7), so a later process can compute cross-PR overlap even for hard-dependency pairs, which
     have no soft reason (`toposort_prs.py`:126-129).
   - **Two separate predicates (R2/R3):**
     - `qa_pending(rec)`: the record has at least one landing, and its set of landed PRs differs from
       `verdict.covers`. It is independent of held, draft, handed-off or unattempted rows, so a landed
       subset still needs QA, and a new landing invalidates an earlier verdict.
     - `continuable(rec)`: some planned PR is not terminal (merged-and-reconciled, or closed). This
       is used only to decide whether a resume continues the batch.
     A record is *unfinished* when either predicate holds.
   - `find_unfinished(primary, slug, integration, prs)` returns the newest unfinished record for this
     repo and integration branch. When `prs` is non-empty it must overlap the record's planned PRs.
     When `prs` is empty (OPEN-only discovery after everything landed), it matches on
     repo + integration alone.
   - `create(primary, slug, integration, ordered, gh)`: `gh label create merge-batch --force`, then
     `gh issue create --label merge-batch --body-file`. Any gh failure sets `issue_error`, saves
     locally, and never raises.
   - **Issue body ownership (R5):** the script owns only a marked block,
     `<!-- merge-batch:script:start -->` … `<!-- merge-batch:script:end -->`. That block holds the
     Merge sequence table (the planned order with hard deps and soft-edge files, then status, merge oid
     and reconcile result per row), the Sweep inputs, and the Sweep verdict. The caller sections
     (Problems, Ad-hoc fixes & pivots, Findings, Regression sweep analysis, Post-deployment
     carry-overs) sit outside the markers and are rendered as placeholders only at creation.
   - `update(rec, gh)` saves locally, reads the live body (`gh issue view <n> --json body`), replaces
     only the marked block, and runs `gh issue edit <n> --body-file`. If the read fails or the
     markers are missing, it does **not** edit; it records `issue_error`, so a body it cannot parse is
     never overwritten.
   - `set_outcome(rec, pr, status, merge_oid=None, reconcile=None)`, `finalize_sweep_inputs(rec, …)`,
     `record_verdict(rec, path)`.
3. **Hook into `merge_cleanup.py`:**
   - **Batch selection, before the first merge (R2).** In `main`, after Phase 4:
     - with `--resume`: `batch = find_unfinished(...)`, regardless of the current queue size (it may
       be 1 or 0); a found batch keeps its original issue;
     - then, if there is still no batch, the run is executing, and `len(ordered_prs) >= 2`:
       `batch = create(...)`. This covers fresh runs **and** `--resume` runs that have per-PR attempt
       records but no batch record (`gh534_phase_c_tests.py`:793-805);
     - otherwise there is no batch: single-PR runs without a matching record, fresh or resumed, are
       unchanged.
     `batch` is passed into `land_prs`; the issue exists before the loop (:928), so before any `gh pr merge`.
   - **Outcomes at the real branches (R4), all inside `land_prs`:**
     - **Remote merge:** immediately after `execute_pr_merge` returns true, read
       `gh pr view N --json mergeCommit` and call `set_outcome(N, "merged", oid)`, before
       fetch/ff/reconcile.
     - After reconcile + durability, record `reconcile="ok"`, or the failure reason on the exit-2 paths
       (:1171/:1181 and their neighbours).
     - `skipped: hold-label`, `skipped: not open` (:973-979), `skipped: draft`, and every `failed[N]`
       reason (`blocked by`, `deferred`, `parked`, `handoff`).
     - **Pre-merge hard stops (R4):** every `return 2` inside the loop body records
       `stopped: <diagnostic>` for the PR being processed first, through a small local `_stop(N, msg)`
       that also prints the existing error. Known sites: unknown mergeability (:997-999), gate red
       (:1137-1142), and the other in-loop returns at :968/:1011/:1163/:1171/:1181. Implementation
       greps every in-loop `return 2` to confirm none is missed. Later PRs keep `unattempted`.
       Repair policy and exit codes are unchanged.
     - A `try/finally` around the loop runs `finalize_sweep_inputs` and `update` on any return,
       including exit 2 after a landing.
   - **Sweep inputs (R6),** computed over **all** landings retained in the record, including earlier
     resumed runs:
     - `range = <first landing>^1..<last landing>`, in landing order; there is no range when nothing landed;
     - files touched by 2+ landed PRs, from the **stored** per-PR `files` lists (R7), each attributed to its PRs;
     - repaired conflict sites from each landed PR's `pr-N.json` `conflict_files`;
     - the gate from `select_qualification_gate(primary, metas, env)`, using its `(gate, expected,
       reason)` contract. The module is imported through the reconcile step's harness-tool
       resolution; on import failure the gate is full (`validate.sh --sequential`) with the reason recorded.
     Then print the exact command: `git clone --no-local <primary> <tmp> && cd <tmp> && bash <gate>`.
   - **Exit (R3):** `land_prs` returns its rc unchanged (0/2/3). `main` keeps the existing early return
     for 2 and 3, so Phase 6 still runs after a successful landing. After Phase 6, if
     `qa_pending(batch)`, `main` prints
     `STATUS: landed, QA pending — record a verdict with --record-sweep <file>` and returns 4. This
     holds whether or not other planned PRs are still held, draft or handed off.
     Precedence: 2 (including any Phase 6 failure) > 3 > 4 > 0.
     **QA-only continuation:** a `--resume` run whose queue is empty matches the batch by
     repo + integration (above), runs Phase 6, and returns 4 while `qa_pending`, or 0 once covered.
   - **New flag `--record-sweep PATH`.** It is dispatched right after primary-path resolution, before
     Phase 0, and runs no discovery, merge or teardown.
     - It loads the newest unfinished batch for the primary's repo.
     - The first line of `PATH` must be `verdict: clean|findings|deferred`. Clean needs a non-empty
       body naming what ran; findings need at least one `- [ ]`; deferred needs a reason.
     - On success it sets `verdict.covers` to the currently landed PRs, updates the issue's script
       block and exits 0. Malformed or empty input exits 2 and stores nothing.
     - Drive loop afterwards: if the batch still has non-terminal PRs, continue with
       `--resume --execute`; otherwise the run is complete.
   - *Verify:* step 5.
4. **SKILL.md:**
   - Change the threshold from 3 to 2 everywhere (recite item 6, the Execute step, the protocol trigger).
   - Rewrite the protocol bullets: what the script does (issue, script block, outcomes, sweep inputs,
     printed command, verdict record, exit 4) and what stays with the caller (the analysis, running
     the suite, writing the verdict file, carry-overs and the other caller sections).
   - Add exit 4, `--record-sweep` and the QA-only continuation to the Drive loop and the Done rule by
     *adding* sentences; the pinned phrases are not reworded.
   - Capability table: `batch-issue-threshold` and `batch-issue-resume-append` become `script`; add
     `batch-sweep-record` as `script`; `batch-regression-sweep` and `post-deploy-carryover-dual-sink`
     stay `caller`. Add `--record-sweep` to the options line.
5. **Keep the existing suite truthful** (`gh534_phase_b_tests.py`, `gh534_phase_c_tests.py`; no new file
   or registry entry). The parity guard requires a real method for each `script` row (GH-831's
   "keep an existing suite truthful" case).
   - **Existing expectations (R3):** every existing gh534 assertion whose queue has 2+ PRs and at
     least 1 landing moves from exit 0 to exit **4**, keeping its landing, durability and pruning
     assertions (which prove Phase 6 ran). Known sites: `phase_b`:379/388, :491-498 (held PR 1,
     PR 2 lands), :693; `phase_c`:282, :451, :803. Implementation greps both files for every
     `rc == 0` / exit-0 assertion and checks each against this rule.
   - **Extend `GH_STUB`:** `label create`; `issue create` (records the body and prints a URL);
     `issue view --json body`; `issue edit` (records the body); and a call log so ordering can be
     asserted. **Parity import:** `TestBatchIssue` lives in `phase_b` and is imported into
     `phase_c`'s globals following the existing pattern at :34, so the guard can resolve it.
   - **Add `TestBatchIssue`** (five methods, reusing existing fixtures):
     - **(a) Creation, skips and exit 4.** A 2-PR queue creates the issue before the first
       `pr merge`, with the planned order, file lists and soft-edge files. A clean run records
       `reconcile=ok` for both and exits 4 after Phase 6. The held-PR case (:491) records
       `skipped: hold-label` for PR 1, PR 2 merged, exit 4. A fresh 1-PR run creates no issue.
     - **(b) Resume continuity, R7 and verdict coverage.** A hard-dependency pair: PR 1 and PR 2
       both touch `shared.txt`, and PR 2 says `Depends on #1`.
       1. Run 1: PR 1 lands, PR 2 hands off (the :543 shape), exit 3.
       2. Record a partial verdict.
       3. Repair PR 2 and run `--resume`: same issue (no second create), both oids, range
          `<PR1>^1..<PR2>`, `shared.txt` attributed to both, and exit 4 (the new landing
          invalidated the earlier verdict).
       4. Empty-queue `--resume`: same issue, exit 4.
       5. Record a verdict, then another empty-queue `--resume`: exit 0. A file touched by only one PR
          is never listed as shared.
     - **(c) Stops.** In a 2-PR queue:
       - gate red on PR 1 (the :674 injection): `stopped: releases check: FAIL: rule=synthetic`,
         PR 2 `unattempted`, no merge, exit 2;
       - failed reconcile (:510): PR 1 merged with the reconcile failure recorded, PR 2 unattempted,
         exit 2;
       - an ordinary handoff still exits 3.
     - **(d) Body ownership and the verdict flag (R5).** Before an update, put
       `- [ ] #1: operator verification` in Post-deployment carry-overs and text in Findings. After
       the update both are byte-identical and the script block has changed. `--record-sweep` stores a
       valid verdict and exits 0; empty or malformed input exits 2 and stores nothing.
     - **(e) Resume with no batch record.** The :793-shaped run (2 open PRs, an existing per-PR
       record, `--resume`, no batch record) creates exactly one issue before either merge and exits 4.
       A 1-PR resume with no record creates none.
   - Update `REQUIRED_CAPABILITIES` for the new owners and the new row.
   - **Red controls,** witnessed on this suite and recorded with commands, outcomes and
     `provenance.jsonl` under `TESTS-RESULTS/2026-10-14+GH-1064/`:
     - threshold set to 3 → (a) fails;
     - `--record-sweep` accepting an empty body → (d) fails;
     - `update` overwriting the whole body → (d) fails.
6. **Gates:** iterate with `bash test/gh436-merge-cleanup.sh`. The classified route is the full gate (the
   SKILL.md path). Run it once on the final approved commit in a disposable `<folder>-gate` clone.
7. **CHANGELOG + doc status.**

## Risks

- **Exit 4 is new.** The only consumers are the SKILL.md drive loop and docs, and both are updated.
  A caller that treats non-zero as failure sees exit 4 as "not done", which is the intent.
- **Issue churn:** one `gh issue edit` per PR in the batch. Batches are small, so this is negligible.
- **Pinned doc phrases:** handled by adding text only. The suite will catch any slip.

## Implementation notes (2026-10-14)

- **Hard stops (R4):** instead of editing all 22 in-loop `return 2` sites, `land_prs` is a thin
  wrapper around the unchanged loop (now `_land_prs_loop`). `log_err` feeds the current PR's error
  lines to the wrapper, and the wrapper's `finally` records `stopped: <errors>` for the PR in hand,
  which covers every site, including :935 (before `p_num`). The parity guard's AST pins move to
  `_land_prs_loop`.
- **Landing order:** kept as `landed_order` in the record (append on merge), not derived from keys.
- **Verification:**
  - `bash test/gh436-merge-cleanup.sh`: 185 tests OK.
  - Red controls (each mutation restored byte for byte): `TESTS-RESULTS/2026-10-14+GH-1064/provenance.jsonl`.
