---
title: tick log is exempt from the foreign-cwd guard — the verb that seeds every run, plus the whole marathon.* namespace
status: Proposed (1-INBOX — not yet active)
created: 2026-09-03
owner: noelsaw1
gh_issue: 411
source: https://github.com/HiQS-Labs/XYZ-forge/issues/411
doc_type: bug
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Guarding cost.* — the exemption exists for auxiliary cost capture and that reason is sound.
  - Guarding task.* only, which leaves marathon.* exempt and preserves the defect one namespace over.
related:
  - GH-406 (umbrella — external review by Russ K.)
  - GH-12 (the original foreign-cwd foot-gun this reproduces)
  - GH-396 (harness root resolution — landed on origin; sequence after it)
goal: >
  Move the foreign-cwd guard decision from verb to verb + event-type prefix so every tick log
  type except cost.* is guarded, ending an exemption whose safety currently depends on every
  caller remembering to pin TICK_REPO_ROOT.
---

# GH-411: `tick log` outside the foreign-cwd guard

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

## Why this is R2

`tick log task.created` is how every run gets seeded, and it is the one seeding verb outside
`MUTATING_GUARD_VERBS`. `assertResolvedRoot` returns early on the **verb**, not the event type,
so the widest-blast-radius call inherits an exemption written for the narrowest one.

E1, re-executed at HEAD from a plain dir with `TICK_REPO_ROOT` unset:

| Call | Result |
|---|---|
| `tick claim T1 --agent s --paths 'x/**'` | refused, rc 1 — guard works |
| `tick log task.created T9 --agent s --paths 'x/**'` | **rc 0**, creates `<cwd>/.tick/events/…jsonl` |
| same, `TICK_REPO_ROOT` pinned | rc 0, event only in the intended root |

## Scope correction that makes this worth doing once

`marathon.*` is equally unguarded and equally written through `tick log` — `marathon.phase.start`,
`.approved`, `.escalated` from the marathon driver and `marathon.complete` from the runner. The
driven path survives only because those callers pin the root. Guard **everything except `cost.*`**.

## Phase

Single phase: one condition change in `bin/tick`, plus a red control covering a non-`task.*` type
and a green control confirming `cost.*` still succeeds unpinned. Both halves, or the change has
only been proven to break something.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "bin/tick", "pattern": "GUARDED_LOG_PREFIXES" } ],
  "artifacts":   [
    "bin/tick",
    "test/gh411-tick-log-foreign-cwd.sh",
    "test/baselines/GH-411-negative-control.md"
  ],
  "remediation": { "source": "issue#411", "criteria": "every tick log event type except cost.* is refused from an unpinned foreign cwd, and cost.* still succeeds" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
