---
gh_issue: 1452
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1452
title: "merge-cleanup: plan-ahead landing forecast so direct-vs-group is decided with evidence at planning time"
status: Proposed (1-INBOX — not yet active)
created: 2026-11-13
owner: unassigned
doc_type: feedback
complexity: 3
risk: 2
effort: 3
phases: 1
ratings_provisional: true
non_goals:
  - change the explicit decision contract
  - group executor
  - exact repair prediction
related:
  - #1076
goal: >
  TODO: one-paragraph statement of what "done" looks like for this idea.
---

## Key concepts

- landing forecast
- git merge-tree
- selection pin snapshot
- GH-1158 explicit decision

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# merge-cleanup: plan-ahead landing forecast so direct-vs-group is decided with evidence at planning time

## Status

| What was just completed | What's next |
|---|---|
| Captured via HQ (`/hq park`) for project **XYZ-forge** → repo `XYZ-forge`. The GitHub issue is the signal stream; this doc is the in-repo capture and back-reference. | Fill in Why/Key Concepts, correct the provisional ratings above, and run a Phase 0 explore pass before promoting to `2-WORKING`. |

## Idea

## Observed

On 2026-11-13 an operator planned a 6-PR landing queue in a downstream repo through three planning stages. The dry run only showed at the very end that 5 of the 6 PRs conflict (in `releases.db`, `releases.sql`, `CHANGELOG.md` and `RELEASES-PREVIEW.html` only) and that landing them one at a time would probably burn the two-repair cap. The agent then recommended grouped landing, after the planning was finished. The "probably parks two PRs" projection was a hand estimate and was never proved in a run. The downstream repo is private, so the dry-run output is retained by the reporter rather than linked; every claim below is measured in this tree.

| Claim | Command | Observed |
|---|---|---|
| The direct/group decision is first forced at an early checkpoint during `--execute`, after planning is over | `sed -n 2000,2052p skills/2-daily/merge-cleanup/scripts/merge_cleanup.py`; `rg -n 'EXIT_LANDING_PLAN_REQUIRED = ' .../merge_cleanup.py` | the checkpoint starts at `merge_cleanup.py:2000`, validates the decision at `:2034` and returns exit `5` at `:2050`, before Phase 0, scanning and any mutation; the constant is at `:79`. A second, later refusal sits at `:2296` |
| The dry run offers only generic trade-off text for a 3+ PR queue, no computed evidence | `sed -n 2229,2240p .../merge_cleanup.py` | prints "Queue holds N PRs. GH-1066 requires an explicit decision" plus two generic bullets (`:2231-2240`) |
| The dry-run pin stores head SHAs only, and is the single writer of the selection file | `sed -n 491,512p .../merge_cleanup.py` | JSON keys `integration`, `pinned_at`, `prs` (`pin_selection`, `:491-512`); `verify_selection` (`:513`) reads only `["prs"]` |
| Each PR gets two repairs, whatever the head | `rg -n 'MAX_REPAIRS = ' .../attempt_record.py` | `attempt_record.py:31: MAX_REPAIRS = 2` |
| A repaired PR is deferred, because its new head is never the pin | `sed -n 1648,1652p .../merge_cleanup.py` | `if not dry_run and info.get("headRefOid") != pinned:` defers (`:1651`) |
| No tool simulates the queue's cross-PR conflicts before a merge starts | `rg -c 'merge-tree' skills/2-daily/merge-cleanup/scripts/` | zero matches (rc=1); the only landing simulation is per PR inside the execute loop: the merge itself runs in `prepare_landing_clone` (`merge_cleanup.py:587`, merge at `:1503`), and the semantic ledger check `pre_merge_ledger_gate` is called at `:1639` (defined `ledger_merge.py:658`) |
| B1 repairs only a defined path set and hands off the rest | `sed -n 543,547p .../ledger_merge.py` | `B1_EXCLUDED` paths hand off (`ledger_merge.py:543-547`) and policy applies after that |
| The dry run's pin is written before any queue ordering in that branch | `sed -n 2170,2178p .../merge_cleanup.py` | `pin_selection` called at `:2174` with the open-PR list; the early checkpoint orders the pinned PRs separately (`toposort_prs` at `:2017`) |

## Diagnosis / existing gap

Origin: GH-1066 / GH-1158 added a required direct-vs-group decision for 3+ PR queues but made it an `--execute`-time refusal. The fix site is the dry run, where the PR order (`toposort_prs`) and live heads are already known. Removes the class: the decision arrives with computed conflict evidence at planning time, so it can be reviewed (GH-1066 step 5) before the operator commits to a plan, instead of surfacing at the first `--execute`. Not a one-instance fix. The forecast is advice: the explicit GH-1158 decision stays the operator's.

## Plan

1. `ledger_merge.py`: add `landing_forecast(...)` beside `pre_merge_ledger_gate` (`:658`). It reuses B1's policy-aware path set (`B1_EXCLUDED`, `LEDGER_VIEWS` at `:37`, the policy lookup) and defines no constants of its own. The caller (`merge_cleanup.py`) owns the network side: in one disposable clone with no working-tree checkout (never the primary, GH-564) it freezes one base SHA, fetches each PR as `pull/<N>/head` (the same approach as `prepare_landing_clone`, `merge_cleanup.py:609`, reusing `_net_git` and `_retry_call`, not the whole function) and verifies every fetched object equals the pinned head, all bounded by timeouts. `landing_forecast` receives that clone, the base SHA and the verified heads and does only the `merge-tree` work, so `ledger_merge` never imports the main script back (`merge_cleanup.py:56` already imports `ledger_merge`). Any failed command, missing object or timeout is `unknown`, never `clean`; the clone is always cleaned up.
2. Simulation with `git merge-tree --write-tree`: (a) each PR alone against the frozen base; (b) each pair of queue members, to surface code overlap between PRs; (c) a cumulative fold in `toposort_prs` order that advances only through clean steps, using synthetic ancestry-preserving commits. At the first conflict the cumulative projection stops and later PRs are marked "conditional: not simulated after #N", because a conflicted `merge-tree` result carries conflict markers and is not a resolved landing.
3. Output per PR: `conflicts_alone`, `conflicts_in_sequence` (or "conditional"), paths split into "potentially B1-eligible" and "needs review (excluded, code or unknown)", repairs already consumed (read from `attempt_record`, not written), and a `churn_risk` band (low, medium, high) with its stated assumptions. It reports how many PRs would be deferred in the run that repairs them (a B1 repair pushes a new head that is never the pin, `merge_cleanup.py:1651`), and gives no CI-wait count, because the script waits only while required checks are pending (`:1660-1669`) and a repo may require none. It says plainly that reconcile commits after each landing can add conflicts the forecast cannot see. It does not claim an exact repair count, and reaching two repairs is not reported as parking (an already-repaired head that merges cleanly still lands, `merge_cleanup.py:1517`).
4. Recommendation rule, printed with the numbers behind it. First, any `unknown` result (failed fetch or merge command, missing object, head or base mismatch, timeout) takes precedence and withholds the recommendation: "none: forecast incomplete, #N unknown". A PR marked "conditional" because an earlier PR conflicted is a known conflict, not `unknown`. Otherwise: `group` when members conflict on code or unclassified paths, or 3 or more PRs conflict, or a PR that already used a repair conflicts again; otherwise `direct`.
5. `pin_selection` (`merge_cleanup.py:491`) stays the single writer: the dry run computes the forecast first and publishes one coherent snapshot (pins, ordered sequence, base SHA, assumptions, forecast) with a temp file and atomic replace, serialized by the existing `attempt_record` lock helper (`RecordLock`, `attempt_record.py:61-89`) taken only around the temp-write and the replace, never across fetch or simulation, with a lock timeout reported as a failure to publish. A concurrent dry run therefore cannot attach a forecast to another selection. Mode behavior: `--scan-only` returns before pinning (`:2148`), so no forecast; a dry-run `--prs-only` reaches pinning and sequencing (`:2246`), so it forecasts; a dry run without `--prs` writes nothing executable; inline `N@sha` pins are validated against the forecast's heads before use.
6. The dry run prints the exact recommended `--landing-plan direct|group --landing-reason "..."` command beside the forecast table (extending the block at `:2231-2240`). `--execute` keeps the GH-1158 contract unchanged: the caller passes `direct` or `group` and a non-blank reason at the early checkpoint (`:2000-2050`). The early checkpoint reads the stored forecast only to annotate, recording whether the decision matches the forecast or is an override of it. That extends the existing `batch_record.set_landing_plan` (`batch_record.py:310-319`, which today keeps only decision, reason, PRs and time) with one optional forecast-comparison argument (forecast identity, match, override, stale), so old callers are unchanged and the comparison survives save and resume. It also prints "forecast stale" when the sequence, heads or base differ. No new flag value.
7. `SKILL.md`: Drive loop step 1 and the GH-1066 section (`:251`) say to run the forecast and the 3+ PR independent sequence review when the PR set is chosen, not at `--execute`; material changes to membership, order or integration content reopen that review as the contract already says; add capability-table row `landing-forecast | 4 | script | manual check, TESTS-RESULTS/<date>+GH-<n>/` (the `batch-sweep-record` manual-check precedent).

## Blast radius

Recon `6c0c76bb5` (`git diff --quiet origin/development -- skills/2-daily/merge-cleanup` exits 0 in the primary checkout, so its merge-cleanup files equal `origin/development`; this task clone is cut from `6c0c76bb5`). Integration base stated separately: `development@6c0c76bb5`.

| Seam | Touch | Why |
|---|---|---|
| `skills/2-daily/merge-cleanup/scripts/ledger_merge.py` | add `landing_forecast` | reuses the B1 path set and sits beside `pre_merge_ledger_gate` |
| `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` | dry-run print, `pin_selection` snapshot, early-checkpoint annotation | the only writer of the pin and the owner of the `--landing-plan` checkpoint |
| `skills/2-daily/merge-cleanup/SKILL.md` | drive loop, GH-1066 section, capability row | caller-facing contract |
| `skills/2-daily/merge-cleanup/scripts/batch_record.py` | extend `set_landing_plan` with one optional forecast-comparison argument | the existing mutator owns the landing-plan record; old callers unchanged |
| `skills/2-daily/merge-cleanup/scripts/attempt_record.py`, `toposort_prs.py` | read only | `MAX_REPAIRS`, consumed repairs, `RecordLock` and the order are reused unchanged |
| `test/gh534_phase_a/b/c_tests.py` | none expected | existing suites must stay green; edit only if pinned behavior legitimately changes |
| `TESTS-RESULTS/<date>+GH-<n>/` | new evidence folder | manual cases and red controls (no new tests, GH-831) |
| `CHANGELOG.md`, RELEASES ledger | per-PR governance entry | normal PR rails |

Truthful write-set: four files under `skills/2-daily/merge-cleanup/` (`ledger_merge.py`, `merge_cleanup.py`, `batch_record.py`, `SKILL.md`), one `TESTS-RESULTS/` folder, the changelog and ledger. No new module and no new flag. Builder route: `/start-task` (Claude). Reviewer: Codex via the relay, a different model family from the author.

## Dependencies

None hard. Soft: #1076 (selective-CI and batch-qualification policy) is adjacent and not a duplicate; this change reads no CI policy. GH-1066, GH-1158 and GH-1226 are the shipped behavior being extended.

## Acceptance

- [ ] A dry run (`--prs`) over 3 or more PRs prints a Landing forecast with, per PR, conflicts alone, conflicts in sequence or "conditional", B1-eligible vs needs-review paths, consumed repairs, a churn-risk band, and the recommended `direct` or `group` with its numbers. Red control: on `development@6c0c76bb5` the same command prints no forecast and the `grep_absent` probe below passes.
- [ ] A disposable-clone queue of 3 PRs that each make a different edit to the same lines of `releases.sql` and `CHANGELOG.md` (shared paths alone do not conflict) forecasts `group`; 3 PRs with disjoint files forecast `direct`. Red control: break the classifier (treat every path as non-conflicting) and the first queue must stop forecasting `group`; a queue of fewer than 3 PRs prints no forecast.
- [ ] A conflict before the cumulative sequence ends stops the cumulative projection, and later PRs read "conditional". Red control: a queue whose first PR conflicts must not print a clean cumulative result for the PRs after it.
- [ ] A failed fetch, a missing fork object or a head that differs from its pin yields `unknown` for that PR, never `clean`. Red control: point one PR ref at a nonexistent object and the forecast must say `unknown` and print no recommendation: a three-PR queue with one failed fetch and two clean PRs must not recommend `direct`, while a complete disjoint queue still does.
- [ ] One pin snapshot holds pins and forecast together, written atomically, and a pin file from the old code (no forecast key) still passes `verify_selection`. Red control: run two dry runs with different `--prs` against one primary at once; the surviving file's forecast heads must equal its own pins.
- [ ] `--scan-only` writes no forecast, a dry run without `--prs` writes nothing executable, and a dry-run `--prs-only` forecasts. Red control: each mode checked against the unfixed tree and the fixed tree.
- [ ] `--execute` on 3 or more PRs without `--landing-plan` and `--landing-reason` still exits 5 at the early checkpoint before any ref, marker or batch-record change, and a decision that differs from the stored forecast is recorded as an override. Red control: capture refs, markers and batch records before and after the refused run, and require them unchanged.
- [ ] A decision recorded at the early checkpoint stores forecast match, override or stale metadata through `set_landing_plan`, it survives a save and reload of the batch record, and a caller that omits the new argument still records exactly decision, reason, PRs and time. Red control: record an override, reload the record and read it back; the unchanged function must not retain it.
- [ ] `SKILL.md` states that the forecast and the sequence review run at planning time and has the `landing-forecast` capability row. Red control: the `grep_absent` probe below fails on the fixed tree (it passes on the unfixed tree, which is its purpose).
- [ ] The existing suites `test/gh534_phase_a_tests.py`, `gh534_phase_b_tests.py` and `gh534_phase_c_tests.py` pass in a disposable full clone, with the result retained under `TESTS-RESULTS/`.

## Verification

No new tests (AGENTS.md *No new tests*, GH-831). Existing suites `gh534_phase_a/b/c_tests.py` run in a separate disposable full clone (never a linked worktree). Manual cases retained under `TESTS-RESULTS/<date>+GH-<n>/` with `provenance.jsonl`: (a) a throwaway repo with a fake `origin` and three PRs editing `releases.sql` and `CHANGELOG.md` shows the `group` forecast; (b) a disjoint three-PR queue shows `direct`; (c) wrong membership and order, stale heads, a conflict before the sequence ends, a missing fork object, command failure versus clean, and a PR with consumed repairs; (d) two concurrent dry runs, and the early-checkpoint refusal with before/after state captured; (e) a read-only dry run of the real 6-PR downstream queue from 2026-11-13 if its PRs are still open; (f) clone transfer size, disk use and runtime of the forecast measured on one representative large repository.

## Non-goals

- No change to the GH-1158 contract or exit 5: the operator still passes `direct` or `group` with a reason. The forecast is advice and never supplies the decision or the reason.
- No group executor: `group` still prints the GH-1066 checklist and exits 0.
- No exact repair or reconcile prediction: reconcile commits after each landing and B1 handoffs (`classify`, `ledger_merge.py:145`, policy, `B1_EXCLUDED`) are outside what a text-level forecast can see, and the output says so.
- No new test suite, no new flag or flag value, no relay automation, no repair automation.

## Risk and rollback

Code rollback is easy: the change adds printed output, one atomically written snapshot in an untracked `.tick/` file, and an annotation in the batch record; reverting the PR restores the old pin shape and old pin files stay readable because `verify_selection` reads only `prs`. The forecast alone performs no merge, but an operator who follows a mistaken `direct` recommendation authorizes sequential landing, and reverting this PR does not undo that; that is why the decision stays explicit and the forecast labels its blind spots.

## PRS proposal

- pri 55: a 3+ PR queue is a routine Day-1 landing, and the 2026-11-13 run lost a planning cycle to this late discovery.
- sev 40: no data loss or wrong merge; the cost is wasted planning time and a possible parked PR (parking was estimated by hand and never demonstrated), and the exit-5 gate already blocks unsafe landing.
- appeal 50: neutral default; the operator has not set an appeal score.
- effort 40: a cumulative simulation, a concurrent-safe pin snapshot and error handling in a 138K script, verified only by manual cases, is more work than a print change.

## Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_absent",
      "path": "skills/2-daily/merge-cleanup/scripts/ledger_merge.py",
      "pattern": "def landing_forecast",
      "note": "forecast helper must not exist yet"
    },
    {
      "type": "grep_absent",
      "path": "skills/2-daily/merge-cleanup/SKILL.md",
      "pattern": "landing-forecast",
      "note": "capability row and planning-time guidance must not exist yet"
    }
  ],
  "artifacts": [
    "skills/2-daily/merge-cleanup/scripts/ledger_merge.py",
    "skills/2-daily/merge-cleanup/scripts/merge_cleanup.py",
    "skills/2-daily/merge-cleanup/scripts/batch_record.py",
    "skills/2-daily/merge-cleanup/SKILL.md"
  ],
  "artifacts_new": []
}
```

Recon: 6c0c76bb5 · base: development@6c0c76bb5 · tier: standard · review: consult idea-forecast-100328 models=codex, degraded hash 91c6ae5cebded39ee78c763838ea7c3c97b374c19cfbab58d071b3b5f91cd779

## Plan QA revisions (start-task Step 6, relay `gh1452-plan-qa`, Codex)

Round 1 verdict FAIL on three bounded Shoulds, all adjudicated against the tree and accepted; the issue body above keeps its filed text and review hash, and this doc is the working plan.

- S1 (`set_landing_plan` cannot hold the annotation, `batch_record.py:310-319`): extend that existing mutator with one optional forecast-comparison argument; `batch_record.py` added to Blast radius, write-set and Preflight artifacts; new Acceptance item for save and reload.
- S2 (CI-wait lower bound unsupported, `merge_cleanup.py:1651-1669`): the forecast reports the number of PRs whose B1 repair would defer them, and no CI-wait count.
- S3 (failed simulation could fall through to `direct`): any `unknown` result withholds the recommendation; "conditional" is a known conflict and is named separately.
- Nits applied: repaired-head condition cited at `:1651`; per-PR merge simulation cited at `prepare_landing_clone` (`:1503`); conflicting-edit wording in the acceptance fixture; lock held only around temp-write and replace; the helper receives a prepared clone rather than importing the main script; severity rationale no longer treats parking as measured. Every red control is witnessed: the retained check must show the deliberately wrong output being rejected, not only that the input ran.

## Why

A 3+ PR landing queue forces the direct-vs-group decision only at --execute, so a 2026-11-13 operator planned three stages before the dry run's late conflict evidence pointed to grouped landing. A planning-time forecast puts that evidence where it can be reviewed first.

## Phase 0 — Explore & scope

### Checklist

- [ ] TODO: scope-specific checklist items for this idea's Phase 0 pass.

### QA checklist — Phase 0

- [ ] TODO: acceptance criteria for the Phase 0 pass above.
