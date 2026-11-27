---
gh_issue: 1626
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1626
title: "merge-cleanup: a landing dry run no longer deletes retained scratch clones"
status: "Prepared 2026-11-27 (1-INBOX, held: not enqueued, not started)"
created: 2026-11-27
updated: 2026-11-27
owner: Conveyor preparation (Day 3 Flywheel proving-arc candidate; ledger #1611)
doc_type: bugfix
ratings_provisional: true
non_goals:
  - "#1578 (pruning does not check for unpushed commits): separate issue, same function, not in this scope"
  - Any change to keep counts, the one-hour age floor, tool-shape matching or lsof checks
  - Reporting a "would remove" list in dry run (allowed but not required)
  - A new test suite or gate machinery (GH-831)
goal: >
  A merge_cleanup.py landing run without --execute must not delete any folder: the
  end-of-loop retained-scratch pruning runs only on an executing run, while an executing run
  keeps pruning exactly as today.
---

# GH-1626 · Landing dry run keeps retained scratch clones

## Status

| What was just completed | What's next |
|---|---|
| Recon, capture, Preflight Contract, probe proof (unfixed / simulated fix / comment-only edit), both-consumer validation and PRS rating prepared 2026-11-27. No implementation, no queue admission. | Independent preparation review, publication of this preparation PR, then an explicit `/jog 1626` or `/start-task 1626` by the operator. |

## Acceptance

- [ ] A `merge_cleanup.py` landing run without `--execute` (dry run) removes no retained `merge-cleanup-*` / `merge-check-*` folder: `prune_retained_scratch` is skipped or reports only.
- [ ] An executing landing run still prunes old retained scratch folders exactly as today (same keep count, age floor, tool-shape and lsof checks).
- [ ] The existing `test/gh436-merge-cleanup.sh` suite stays green; a manual check under `TESTS-RESULTS/` records both cases (GH-831: no new tests).

## Acceptance — deviations from the issue

The issue has no `## Acceptance` heading (its fix is stated under "Suggested fix"), so Preflight reports acceptance fidelity as advisory. All three criteria above are declared here.

- [added] A `merge_cleanup.py` landing run without `--execute` (dry run) removes no retained `merge-cleanup-*` / `merge-check-*` folder: `prune_retained_scratch` is skipped or reports only. — reason: restates the issue's "Suggested fix (smallest)" as a checkable criterion; either named shape is accepted.
- [added] An executing landing run still prunes old retained scratch folders exactly as today (same keep count, age floor, tool-shape and lsof checks). — reason: the issue is silent; the probe's positive control requires it so that disabling pruning entirely cannot read as fixed.
- [added] The existing `test/gh436-merge-cleanup.sh` suite stays green; a manual check under `TESTS-RESULTS/` records both cases (GH-831: no new tests). — reason: the issue names `test/gh436-merge-cleanup.py` plus a manual check; `test/gh436-merge-cleanup.sh` is that suite's gate entry.

## Recon note (parent-only)

The operator's brief for this run asked for capture, contract, preflight and one independent review. The parent read the whole seam itself, so no separate research child was dispatched. Time budget: this preparation session; attempts consumed: 0.

- **Baseline:** `origin/development` at `cf04c03b4586ad46a5fa1143648e86a6c28b4f4e` (2026-11-27; seam files identical to `76808a53b`, where the reproduction first ran).
- **Observed (reproduced):** `TESTS-RESULTS/2026-11-27+GH-1626/readiness_probe.py` calls the real `land_prs([], …, dry_run=True)` with an old, tool-shaped folder planted under a fixture temp root; the folder is removed and `Scratch pruning: removed 1 old retained clone folder(s)` is logged (exit 1, unfixed).
- **Call path:** `main` calls `land_prs(ordered_prs, primary_repo, args, dry_run, batch=batch)` whenever PRs are queued and not `--teardown-only` (`skills/2-daily/merge-cleanup/scripts/merge_cleanup.py:3093-3097`) → `_land_prs_loop` (`:2013`) → its `finally` calls `prune_retained_scratch(workdir)` unconditionally (`:2545`) → `prune_retained_scratch` (`:387-430`) takes no dry-run argument and calls `_remove_own_scratch` (`:333`) on older folders under `tempfile.gettempdir()`.
- **State writer:** `_remove_own_scratch` (`shutil.rmtree`), the only deleter. **Consumer/retry boundary:** none downstream; deletion is not reversible, which is the harm.
- **Smallest plan:** gate the `:2545` call on `not dry_run` (or pass `dry_run` and log "would remove" without deleting). One function, one file.
- **Dependencies / overlap:** open PR #1607 edits `merge_cleanup.py` only inside `main()` / `_primary_blocks` (hunks at `:36`, `:2699-3062`), not `:333-430` or `:2545`; no textual overlap with this fix. Related open #1578 (unpushed-commit check in the same pruning) is a separate issue. #1625/PR #1629 (merged) only moved the suite's temp dir.
- **Discriminating check:** the probe exits 0 only if the dry run keeps the folder **and** an executing run (`dry_run=False`) still prunes it. It stubs only lookups that are not the seam: merge policy, origin URL, the `pgrep` "another run" check, and lsof. Simulated fix (`if not dry_run:` before the `:2545` call): exit 0. Comment-only edit: still exit 1.
- **Foreseeable approvals/runtime:** none beyond the normal gate; the probe and gate need no network or `gh`.
- **Unknowns:** none blocking. Whether dry run should print a "would remove" list is left to the builder (either passes).
- **Next owner:** the operator (explicit `/jog 1626` or `/start-task 1626`).

## Attempt and retry history (read 2026-11-27, nothing reset)

- `jog_queue` (primary ledger, read-only, and this clone): no row for #1626. `roadmap_items`: no row before this preparation. `work_events`: none.
- Branches and PRs: none for #1626. No prior capture doc, no `relay-system/` receipts, no issue comments.
- Attempts consumed: 0 queue, 0 native.

## Rating rationale

`rated 70/65/50/90` (sum 275), written through `roadmap pickup` on 2026-11-27; `ratings_provisional` stays true until the operator confirms.

- Severity 65: a documented-safe dry run deletes folders irreversibly, including clones a failed run kept on purpose; with #1578 it can remove unpushed repair work.
- Priority 70: severity-led; observed once (2026-11-25, 95 folders removed in one dry run, #1625). Coverage limit: issue evidence only.
- Appeal 50: neutral (no operator preference supplied).
- Effort 90: one conditional in one function.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash test/gh436-merge-cleanup.sh",
  "round_cap": 2,
  "artifacts": [
    "skills/2-daily/merge-cleanup/scripts/merge_cleanup.py",
    "TESTS-RESULTS/2026-11-27+GH-1626/"
  ],
  "fix_probes": [
    {
      "type": "command",
      "cmd": "python3 TESTS-RESULTS/2026-11-27+GH-1626/readiness_probe.py",
      "expect_nonzero": true
    }
  ],
  "remediation": {
    "source": "issue#1626",
    "criteria": "A merge_cleanup.py landing dry run (no --execute) removes no retained merge-cleanup-*/merge-check-* folder; an executing run still prunes exactly as today. Gate prune_retained_scratch on dry_run in _land_prs_loop (or make it report-only in dry run). Existing gh436 suite only; manual check under TESTS-RESULTS. No new suite."
  }
}
```

The probe is a retained manual check, not a suite: it exits 0 only when the fixed behavior is observed, and `expect_nonzero: true` makes any crash read as unfixed. Probe evidence and both consumers' exit codes are in `TESTS-RESULTS/2026-11-27+GH-1626/`.
