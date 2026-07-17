---
gh_issue: 222
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/222
title: "Marathon end-of-session hygiene gaps: no cost summary in marathon-drive.sh, no worktree cleanup in /10days"
status: "Fixed and verified 2026-07-17 via a marathon lane, merged to development."
created: 2026-07-17
updated: 2026-07-17
owner: noel
doc_type: bugfix
complexity: 2
risk: 1
effort: 2
phases: 2
ratings_provisional: true
non_goals:
  - Not building a new telemetry/cost system — reuse the existing `tick analyze --format human` render verbatim, same as relay-drive.sh's GH-152 pattern.
  - Not changing marathon-drive.sh's exit codes or health-record semantics (xyz_marathon_emit) — additive only.
related:
  - relay-automation/marathon-drive.sh
  - relay-automation/relay-drive.sh
  - skills/10days/SKILL.md
goal: >
  Give the Marathon harness a real end-of-run cost summary (marathon-drive.sh currently has none,
  unlike relay-drive.sh) and give the /10days skill an explicit worktree-cleanup step so parallel-lane
  runs don't leave orphaned worktrees behind.
---

## Status

| What was just completed | What's next |
|---|---|
| **Fixed and verified 2026-07-17** via a marathon lane (worktree-isolated Sonnet subagent). Added `xyz_marathon_cost_summary()` to `relay-automation/marathon-drive.sh`, mirroring `relay-drive.sh`'s GH-152 `xyz_relay_cost_summary()` verbatim, gated on a `MARATHON_DRIVE_STARTED` flag so `--help`/`--dry-run`/lock-contention exits never trigger it, wired into the EXIT trap so a failed `tick analyze` can't flip the real exit code; nested `relay-drive.sh` calls get `RELAY_COST_SUMMARY=0` to avoid a double-print. `skills/10days/SKILL.md` Step 7 now runs `git worktree remove` (fallback `--force`) per lane after merge; Step 8 gained a cleanup-failure report line. Independently re-verified on the marathon branch: `bash validate.sh` 113/114 (only the pre-existing, tracked `acorn-extract.sh` environmental red). | Closed out — nothing further for this lane. |

## Problem (confirmed in code/docs, not assumed)

Audited whether the Marathon skill/recipe has an end-of-session status update and cleanup function
(chat session, 2026-07-17). Status update exists but is incomplete; cleanup is narrow.

**1. `marathon-drive.sh` has no end-of-run cost summary.**
`relay-automation/relay-drive.sh` auto-prints a `tick analyze --format human` cost block at
end-of-run for a standalone `/relay` session (GH-152), wired into the same EXIT trap as its lock
cleanup (`xyz_relay_cost_summary()`, relay-drive.sh ~L130-160) so a failed/forced `tick analyze`
call can never flip the driven run's own exit code. That summary is intentionally silenced when the
relay runs nested inside a marathon phase (`XYZ_HARNESS_CONTEXT=marathon-phase`/`swarm`), on the
assumption the outer harness owns the whole-run record. But `marathon-drive.sh` never picks that
responsibility up — its terminal exit paths (`complete_phase_success`, and every branch of the
`case "$relay_exit"` escalation block) only call `xyz_marathon_emit` (a binary green/red health
record appended to `XYZ.json`), with no cost figure attached anywhere. A bare `marathon-drive.sh`
run or a full `marathon.sh` multi-phase chain therefore ends with no visible cost total unless the
operator manually runs `tick analyze` afterward.

**2. `/10days`'s parallel-lane execution has no worktree-cleanup step.**
`skills/10days/SKILL.md` Step 7 dispatches concurrent lane agents with `isolation: "worktree"` and
describes merging each lane's worktree commit(s) back onto the marathon branch one at a time, but
never instructs removing/pruning those worktrees afterward — no `git worktree remove`/`git worktree
prune` call anywhere in Step 7 or the Step 8 report. Left as-is, a run with several parallel lanes
accumulates orphaned worktree directories under the repo's git metadata across sessions.

## Remediation

1. Add an end-of-run cost summary to `marathon-drive.sh`, reusing the existing `tick analyze
   --format human` render verbatim (same DRY approach as relay-drive.sh — no new cost computation),
   wired into the same lock-cleanup EXIT trap so it can't change the driver's real exit code. Cover
   both a bare `marathon-drive.sh` phase run and a `marathon.sh` multi-phase chain (likely emitted
   once at the very end of the whole chain, not duplicated per-phase).
2. Add an explicit worktree-cleanup step to `/10days` Step 7 (after each wave's merges land,
   alongside the gate check) — `git worktree remove` each lane's worktree once its commits are
   merged onto the marathon branch — and surface any cleanup failures in the Step 8 report.

## Acceptance criteria

- A `marathon-drive.sh` run (standalone or via `marathon.sh`) prints a `tick analyze` cost block at
  its final exit, matching relay-drive.sh's existing render, without changing any existing exit code.
- `skills/10days/SKILL.md` Step 7 explicitly removes each lane's worktree after its commits are
  merged, and Step 8's report format includes a cleanup-failure line if any removal fails.

## Swarm Preflight Contract
```json
{
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [
    { "type": "grep_absent", "path": "relay-automation/marathon-drive.sh", "pattern": "tick analyze" },
    { "type": "grep_absent", "path": "skills/10days/SKILL.md", "pattern": "worktree remove" }
  ],
  "artifacts": [
    "relay-automation/marathon-drive.sh",
    "skills/10days/SKILL.md"
  ],
  "remediation": {
    "source": "issue#222",
    "criteria": "(1) marathon-drive.sh prints a tick analyze --format human cost block at its final exit (standalone or via marathon.sh), reusing relay-drive.sh's existing xyz_relay_cost_summary render verbatim, wired into the same EXIT-trap lock cleanup so a failed/forced tick analyze call can never change the driver's real exit code; silenced-when-nested precedent (XYZ_HARNESS_CONTEXT) is not violated — this is the outer harness picking up the responsibility relay-drive.sh explicitly defers to it. (2) skills/10days/SKILL.md Step 7 explicitly runs git worktree remove for each lane's worktree after its commits are merged onto the marathon branch, and Step 8's report format gains a cleanup-failure line if any removal fails. (3) bash validate.sh green, no worse than pre-existing environmental reds."
  },
  "lanes": { "agy_safe": [ "relay-automation/marathon-drive.sh", "skills/10days/SKILL.md" ], "orchestrator_only": [] }
}
```
