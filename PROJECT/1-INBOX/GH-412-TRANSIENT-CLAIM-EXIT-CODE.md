---
title: A transient O_EXCL claim collision exits 1, identical to a durable loss — no retry channel under marathon load
status: Proposed (1-INBOX — not yet active)
created: 2026-09-03
owner: noelsaw1
gh_issue: 412
source: https://github.com/HiQS-Labs/XYZ-forge/issues/412
doc_type: bug
complexity: 2
risk: 3
effort: 3
phases: 2
ratings_provisional: true
non_goals:
  - Changing exit 1's meaning for the three durable causes GH-408 unified; that unification was correct.
  - Auto-reaping on a cap error — silently stealing a claim trades a loud stall for a race.
related:
  - GH-406 (umbrella — external review by Russ K.)
  - GH-408 (upstream, shipped — unified the durable lost: exits; never considered EEXIST)
goal: >
  Separate a transient lock collision from a durable claim loss with a distinct exit code (75 /
  EX_TEMPFAIL) that drivers retry on, and emit one --json result line per verb so callers stop
  parsing stderr prose.
---

# GH-412: transient claim collision is indistinguishable from a durable loss

> **1-INBOX capture**, not an active-work doc. On promotion, create the status table.

## Why this is R3

Its value scales with every lane added. Two lanes colliding on the O_EXCL lock for milliseconds
produce the same observable outcome as a genuinely lost task, and `rtl.py` fails the turn with no
retry. That is a flaky-turn generator that will be misdiagnosed as a model problem every time,
because the only signal is stderr prose nobody reads at 2am.

Chain, verified by read: `src/lock.js:44-52` throws a bare `Error` on `EEXIST` →
`bin/tick:463-465` maps every throw to exit 1 → `rtl.py` re-reads `tick info` and exits without
retrying.

## Relationship to GH-408

GH-408 deliberately **unified** the lost-claim exits, correctly, for three causes that are all
durable. `EEXIST` was never in that set. This is a follow-up to shipped work, not a gap in it —
which is a stronger footing than the umbrella originally claimed.

## Phases

1. Typed `EEXIST` error → exit 75; `rtl.py` bounded-backoff retry on 75 only.
2. `--json` result line per verb. Russ K.'s §2 note: this plus the distinct code makes GH-411 and
   this issue mechanical instead of best-effort, and makes both §13 red controls trivial.

Red control must reproduce a real concurrent collision pre-fix, not simulate one.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "src/lock.js", "pattern": "EX_TEMPFAIL" } ],
  "artifacts":   [
    "src/lock.js",
    "bin/tick",
    "utils/py/rtl.py",
    "test/gh412-transient-claim-exit.sh",
    "test/baselines/GH-412-negative-control.md"
  ],
  "remediation": { "source": "issue#412", "criteria": "a transient EEXIST collision exits 75 and is retried; durable losses still exit 1; an idempotent re-claim still exits 0" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
