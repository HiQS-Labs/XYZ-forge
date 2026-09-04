---
title: The structural relay-block validator never runs on the driven path, and rejects the format real threads write
status: In Progress (2-WORKING — active)
created: 2026-09-03
updated: 2026-09-03
owner: noelsaw1
gh_issue: 410
source: https://github.com/HiQS-Labs/XYZ-forge/issues/410
doc_type: bug
complexity: 3
risk: 3
effort: 3
phases: 3
ratings_provisional: true
non_goals:
  - Writing a third STATUS parser; the fix extracts the tolerant one that already exists.
  - Wiring the validator into the two rtl_enforce backstop calls, which no-op on the healthy path.
related:
  - GH-406 (umbrella — external review by Russ K.)
  - GH-21 (validate-relay-block Phase 1 — this completes its driven-path wiring)
  - GH-92 (bold/backtick-tolerant NEXT/STATUS parsing)
  - GH-67 (Option A idempotent token handoff — why the backstop is the wrong seam)
goal: >
  Make §12's separated-grading guarantee true on the path the harness actually runs, without
  breaking every healthy turn: align the validator's STATUS parsing with the tolerant reader,
  call it from rtl_enforce before staging, and ship red and green controls together.
---

# GH-410: relay-block validator off the driven path

## Status

| What was just completed | What's next |
|---|---|
| Implemented tolerant STATUS parser in bin/validate-relay-block and relay-turn-lib.sh; wired validation into rtl_enforce before staging; shipped test/gh410-relay-block-driven-path.sh (20/20 pass) and test/baselines/GH-410-negative-control.md | Verify full test gate via validate.sh, push, and open PR |

## Why this is R1

Highest-impact item on the GH-406 umbrella. §12 sells separated grading as mechanically enforced
"before the lock releases"; on every marathon turn and every headless relay it is enforced only if
the model volunteers `--relay-file`, which the turn prompt never asks for.

## Three obstacles, all at HEAD

1. **Wrong seam.** `rtl_enforce`'s handoff is idempotent (GH-67 Option A) and no-ops on the normal
   path, so wiring the flag into the backstop gates only the forgot-to-release fallback.
2. **No landing zone for exit 8.** Both backstop calls run under `>/dev/null 2>&1` inside an `if`
   with a WARN-never-fail contract; exit 8 would join an ignored warning bucket.
3. **The validator rejects real format.** `bin/validate-relay-block:17` matches literal
   `^STATUS:`; the poll loop documents that real threads write `**STATUS:**` (GH-92). Naive wiring
   turns every healthy bold-STATUS handoff into a misdiagnosed WARN and an open token.

Coverage today: **zero**. No test feeds the validator a relay file — no red control, no green path.

## Phases

1. Extract the shared tolerant STATUS/NEXT parser; point the validator at it.
2. Call the validator from `rtl_enforce` before staging; define exit 8's meaning there.
3. Red control + paired green control (bold-format file) recorded in `test/baselines/`.

Acceptance criteria are enumerated on the issue and are the source of record.

## Lessons Learned (For Future Agents)

- Always extract and share existing robust parsing routines (like `rtl_relay_field`) rather than writing brittle duplicates in individual scripts.
- Guardrails must be placed at the right execution seam (`rtl_enforce` before staging/committing) to cover both standard and idempotent fallback paths.

## Swarm Preflight Contract

```json
{
  "target":      { "repo": ".", "ref": "development" },
  "gate":        "bash validate.sh",
  "fix_probes":  [ { "type": "grep_absent", "path": "relay-automation/relay-turn-lib.sh", "pattern": "validate-relay-block" } ],
  "artifacts":   [
    "bin/validate-relay-block",
    "relay-automation/relay-turn-lib.sh",
    "test/gh410-relay-block-driven-path.sh",
    "test/baselines/GH-410-negative-control.md"
  ],
  "remediation": { "source": "issue#410", "criteria": "the structural validator runs on the driven path AND accepts the bold STATUS format real threads write" },
  "lanes":       { "agy_safe": [], "orchestrator_only": [] }
}
```
