---
gh_issue: 1344
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1344
title: "GH-1340 item 1: finishing work (Tasks 10, 9, 8, 7)"
status: proposed
created: 2026-11-04
owner: unassigned
doc_type: feature
complexity: 4
risk: 3
effort: 4
phases: 1
non_goals:
  - no change to when ledger rows are created (that is #1345)
  - no new test or suite (GH-831)
  - no human review of the 55 #1333 candidates in this PR
related:
  - "#1340"
  - "#1333"
  - "#1339"
  - "#1332"
goal: >
  Docs are found by issue identity in every folder, one completion sweep files closed issues by
  stateReason without creating rows or closing issues, the sweep lists delivered-but-open
  candidates, and landing closes an issue only on a recorded whole-issue proof (G2, G3, G4).
updated: 2026-11-04
---

# GH-1340 item 1: finishing work (Tasks 10, 9, 8, 7)

## Status

| What was just completed | What's next |
|---|---|
| Split out of #1340 as Jog item 1 (operator, 2026-11-04). Task text and citations are in #1340 Tasks 10, 9, 8, 7 (Codex QA approved, head 2c0484c8). | Jog run: Codex builds, Agy reviews. |

## Plan

Build in #1340's order inside one PR. Extend existing code only; the citations below are from #1340 (re-check them at `development@6806c0d2`).

1. **Task 10, readers by issue identity.** Grow `find_active_doc_for_issue` (`utils/py/wave_reconcile.py`, around `:1070-1081`) to look up `gh_issue` frontmatter first, then the `GH-<n>-` prefix, across `1-INBOX`, `2-WORKING`, `3-COMPLETED` and `4-MISC`. Route the readers #1340 lists (`jog land`, the planner, `roadmap-coverage` in `utils/pdda/pdda.sh`, path integrity) through one resolver per language (Python and Bash), treating the stored `doc_path` as a cache. Decide whether #1339's 1-INBOX fallback (`pdda.sh` around `:382-393`) is subsumed; record the decision in the PR.
2. **Task 9, completion sweep.** Add a fix mode to `check_issue_doc_sync` (`pdda.sh:611`), reusing the `stateReason` that `releases roadmap reconcile-state` already fetches (`utils/py/releases_app.py`, around `:4100-4140`) and the mover and repoint in `wave_reconcile.py` (around `:1515-1583`, `:2381-2477`). `COMPLETED` goes to `3-COMPLETED`, `NOT_PLANNED` to `4-MISC`, anything else is reported. Repoint existing rows only; a missing row stays missing; never close an issue. Keep the component that writes `SHIPPED … (PR #N)`, which `jog land` checks (`jog_run.py` around `:1207-1228`).
3. **Task 8.** The sweep prints delivered-but-open candidates, from the census's delivered map, as a report mode. It closes nothing.
4. **Task 7, close at merge.** In the landing step (`jog land`, `jog_run.py` around `:1140`; the merge-cleanup batch), close only on (a) a recorded independent whole-issue coverage assertion, or (b) a non-empty Acceptance checklist that is fully checked. Otherwise post one comment, "delivered, left open because <reason>". `--lane-closes-issue` intent alone is not proof. Never write negated closing keywords.
5. Record each acceptance witness (red on base, green on PR) under `TESTS-RESULTS/2026-11-04+GH-1344/` with `provenance.jsonl`.

## Acceptance

- [ ] A doc moved between `PROJECT/` folders breaks none of the Task 10 readers (red on base, green on the PR), recorded.
- [ ] One sweep run on a disposable clone clears stranded docs and stale `doc_path` values (before/after recorded); a closed, never-started capture moves without gaining a row.
- [ ] A local Jog landing still finds its `SHIPPED … (PR #N)` badge after the sweep.
- [ ] The sweep lists delivered-but-open candidates and closes nothing.
- [ ] A one-phase partial delivery with neither proof stays open with one reason comment; either proof closes it (red/green).
- [ ] The gate suites below pass on the final commit. No new test (GH-831).

## Non-goals

Row creation timing (#1345), the human review of the 55 #1333 candidates, #1332 item 2, Task 13.

## Risk and rollback

Risk: the sweep moves docs wrongly when `stateReason` is missing. Mitigation: anything but the two named reasons stays put and is reported. Rollback: revert the PR; moved docs move back with `git revert`, since rows are only repointed.

## PRS proposal

pri 80 / sev 60 / appeal 50 / effort 35 (rationale on #1344).

## Preflight Contract

```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash test/pdda-roadmap-coverage.sh && bash test/gh492-roadmap-state-sweep.sh && bash test/wave-reconcile.sh && bash test/jog-queue.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "utils/pdda/pdda.sh", "pattern": "NOT_PLANNED",
      "note": "pre-fix: issue-doc-sync has no stateReason routing; landed when the sweep routes NOT_PLANNED to 4-MISC" }
  ],
  "artifacts": [ "utils/pdda/pdda.sh", "utils/py/wave_reconcile.py", "utils/py/jog_run.py", "utils/py/releases_app.py" ],
  "remediation": {
    "source": "issue#1344",
    "criteria": "#1340 Tasks 10, 9, 8, 7 as planned above: identity resolver across all four folders, stateReason sweep that repoints only and never closes, report of delivered-but-open, close-at-merge only on recorded proof. Extend existing code; no new test (GH-831)."
  }
}
```
