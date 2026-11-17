---
gh_issue: 1517
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1517
title: "merge-cleanup batch protocol agrees with the GH-1383 auto-sweep"
status: Proposed (1-INBOX — not yet active; isolated trial capture, unpublished)
created: 2026-11-17
updated: 2026-11-17
owner: GH-1476 preparation trial (test sub-agent)
doc_type: bugfix
goal: "merge-cleanup batch protocol agrees with the GH-1383 auto-sweep"
---

# merge-cleanup batch protocol agrees with the GH-1383 auto-sweep

## Status

| What was just completed | What's next |
|---|---|
| RAW issue selected; one read-only medium research child returned SHA-pinned evidence at `2e22cce0` and live `development` `6000f3de`. | Independent preparation QA, publication through a docs PR, live preflight at the integration ref, then explicit `/start-task 1517` or `/jog 1517`. Not ready. |

## Research note (carried from the parent selection note)

Selected 2026-11-17T19:08Z under the GH-1476 trial; deadline 2026-11-17T19:50:24Z; research attempts 1 of 1 used; remaining 0. Receipt: `raw-1517/research-receipt.md` in the trial evidence.

## Recon

- Stale text: `skills/2-daily/merge-cleanup/SKILL.md:494-495` says the script "does not run any test suite (GH-831): the caller still runs the sweep and writes the verdict."
- Contradicted by the GH-1383 bullet at line 529 and lines 531-532.
- Real behavior: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py` flags `--record-sweep` (2470) and `--no-auto-sweep` (2471); trigger 2975-2985 runs `run_auto_sweep()` (3035) via `run_isolated_check()` only in `--execute`, with a declared non-deferred sweep that is not a `gh workflow run` dispatch; otherwise exit 4 "landed, QA pending — record a verdict with --record-sweep" (2986-2988). Verdict writer: `batch_record.record_verdict()` / `batch_record.update`; manual path `record_sweep()` (3090).
- Overlap: open PR #1516 edits this SKILL.md at line ~653 only (no textual conflict) and `merge_cleanup.py`; line numbers may shift if it lands first.

## Plan

1. Reword the batch-protocol sentence at lines 494-495 only: the script adds no new suite (GH-831); in `--execute` it runs the declared sweep at batch end (GH-1383); when `--no-auto-sweep` is passed, the sweep is deferred, the declared command is a full-gate `gh workflow run` dispatch, no command is declared or the run is not `--execute`, the caller runs the sweep and records the verdict with `--record-sweep`.
2. Leave the manual exit-4 steps (lines 418-422, 463-464) unless review finds them contradictory. Leave the historical `TESTS-RESULTS/2026-10-18+GH-1127/review-diff.patch.txt` copy unchanged.

Non-goals: no code change, no new suite or gate (GH-831), no change to sweep behavior. Rollback: revert the one paragraph.

## Acceptance
- [ ] The batch protocol sentence and the GH-1383 bullet agree.
- [ ] Docs-only change; no new tests (AGENTS.md *No new tests*). Note: this SKILL.md is a full-gate route surface.

## Gate classification

`utils/ci-route.sh pull_request` on this file: `docs_only=true full_required=true route=full tier=3` (kernel/gate surface, `utils/ci-route.sh:333-337`). Use the full gate, not the docs lane.

## Rating rationale

Proposed 30/30/50/90: low priority and severity (one contradictory sentence; may cause a duplicate manual sweep), neutral appeal 50 (no operator value), effort 90 = very cheap. Recurrence: one report (GH-1493 final QA nit); trend unknown. Provisional until written by the canonical writer.

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "artifacts": [
    "skills/2-daily/merge-cleanup/SKILL.md"
  ],
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "skills/2-daily/merge-cleanup/SKILL.md",
      "pattern": "any test suite \\(GH-831\\): the caller still runs the sweep"
    }
  ],
  "remediation": {
    "source": "issue#1517",
    "criteria": "Reword the batch-protocol sentence so it agrees with the GH-1383 auto-sweep and names when the caller records the verdict with --record-sweep; no code or suite changes."
  }
}
```
