---
gh_issue: 944
source: https://github.com/HiQS-Labs/XYZ-forge/issues/944
title: "merge-cleanup: batch-issue protocol for multi-PR landings (>=3)"
status: Proposed
created: 2026-10-02
updated: 2026-10-02
owner: operator
goal: "Landing batches of three or more PRs leave a durable GitHub record — sequence, problems, fixes, regression sweep, post-deployment carry-overs — instead of living only in the run transcript."
complexity: 2
risk: 1
effort: 2
phases: 1
---

## Status

| What was just completed | What's next |
|---|---|
| Design locked with operator (threshold >=3; issue opened before first merge; tier-sized debug-mantra sweep; carry-overs dual-sink). SKILL.md protocol added on PR #943. | Dogfood the protocol on the first real >=3 batch; tune the issue template from that run. |

## Locked design decisions (operator, 2026-10-02)

1. **Threshold:** more than two PRs (>=3) in the sequenced queue. Deferred/parked/handed-off PRs are named but do not count.
2. **Timing:** issue created **before the first merge** and appended as the run progresses; survives mid-batch stops.
3. **Regression sweep:** `/debug-mantra` review over the merged range + tier-appropriate suite in a **disposable full clone** (GH-564 rail); findings become checklist items; a clean sweep records what ran.
4. **Post-deployment carry-overs (dual sink):** transcribed verbatim + attributed + unchecked into the issue checklist **and echoed at the end of the run's chat summary** (operator refinement, mid-implementation). Transcribe only — never executed.

## Implementation shape

Caller-owned, `skills/2-daily/merge-cleanup/SKILL.md` only — no script changes (GH-831 no-new-tests rail; the parity guard pins script-owned rows to tests). Recite block item 6, drive-loop step 3 pointer, "Batch issue protocol (GH-944)" section with issue template, four caller-owned capability rows, description mention. Reuses the previously orphaned `merge-batch` label; idempotent on `--resume` (match open `merge-batch` issues on integration branch + overlapping PR set — the title date is a label, never the key); posting is non-blocking (record, not a gate); merge-cleanup never auto-closes the issue.

## Merge evidence

- PR #943 merged 2026-10-03 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
