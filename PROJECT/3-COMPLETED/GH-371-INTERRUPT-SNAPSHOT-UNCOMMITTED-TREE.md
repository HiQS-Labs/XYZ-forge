---
gh_issue: 371
source: https://github.com/HiQS-Labs/XYZ-forge/issues/371
title: "Interrupted-phase record doesn't snapshot the uncommitted tree — a killed turn's edits stay in the main repo"
goal: >
  an interrupted phase must record the uncommitted tree state
status: Complete
# Staged 2026-09-01 by the LTVera marathon orchestrator alongside the marathon plan at
# PROJECT/2-WORKING/2026-09-01-xyz-harness-quickwins/ — commit to XYZ-forge when the
# marathon fires. Exempt from ROADMAP parking while it travels inside the plan bundle.
roadmap_exempt: true
created: 2026-09-01
updated: 2026-09-02
owner: unassigned
doc_type: capture
complexity: 2
risk: 2
effort: 2
ratings_provisional: true
related:
  - "all seven findings originate from one live run: the 2026-09-01 LTVera health-and-isolation marathon"
---

# GH-371 — Interrupted-phase record doesn't snapshot the uncommitted tree — a killed turn's edits stay in the main repo

## Status

| What was just completed | What's next |
|---|---|
| Capture doc authored with preflight contract. | Marathon phase execution. |

Capture of [XYZ-forge issue #371](https://github.com/HiQS-Labs/XYZ-forge/issues/371).

Observed 2026-09-01: a builder turn killed past its cap had "zero disk output" per
its worktree, but had modified 6 tracked files and written 3 new test files directly in
the MAIN repo (agent cwd was the repo root — worktree isolation was advisory).
PHASE-INTERRUPTED.md recorded only the exit code; the next gate run then silently
collected the killed turn's untracked test files.

## Remediation

On the interrupted-phase path, append `git status --porcelain` of the main repo
(and the turn worktree, if distinct) to the interrupted-phase record, so recovery is
deterministic and the next run's Step 0 can warn about an unexpectedly dirty tree.

The fix MUST leave a `GH-371` marker comment at the primary change site — the
preflight probe below keys on it.

## Swarm Preflight Contract

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
      "path": "utils/py/marathon_drive.py",
      "pattern": "GH-371"
    }
  ],
  "artifacts":   ["utils/py/marathon_drive.py"],
  "remediation": {
    "source": "issue#371",
    "criteria": "Interrupted-phase record doesn't snapshot the uncommitted tree \u2014 a killed turn's edits stay in the main repo"
  },
  "lanes": {
    "agy_safe": [
      "utils/py/marathon_drive.py"
    ],
    "orchestrator_only": []
  }
}
```

## Lessons Learned (For Future Agents)

- When a phase or turn is interrupted, recording only the exit code leaves uncommitted working tree modifications untracked. Capturing `git status --porcelain` into `PHASE-INTERRUPTED.md` ensures partial turn output is inspectable and prevents silent leakage into subsequent gate runs.
