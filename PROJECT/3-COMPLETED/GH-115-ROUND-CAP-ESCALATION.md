---
title: "GH-115: marathon-drive prematurely escalates productive multi-round reviews at the fixed round cap (exit 4)"
status: active
created: 2026-08-22
updated: 2026-08-22
owner: orchestrator (Claude Code)
goal: let a relay that is demonstrably converging continue past the round cap, and make cap escalations distinguish stall from progress
gh_issue: 115
source: https://github.com/HiQS-Labs/XYZ-forge/issues/115
branch: gh-115/round-cap-escalation
doc_type: bugfix
effort: 1
complexity: 2
risk: 1
related:
  - "#113 — same marathon-drive seam; shared artifact utils/py/marathon_drive.py"
---

# GH-115 — premature round-cap escalation

## Status

| What was just completed | What's next |
|---|---|
| capture doc + preflight contract written (ready, exit 0); queued as Bulkhead wave 1 (2026-08-22, release 0.7.3 "Bulkhead", #179) | Operator fires the marathon lane per MARATHON-PLAN-2026-08-23.md; builder executes ## Plan, reviewer verifies ## Acceptance |


Release 0.7.3 "Bulkhead" manifest member. Radar 2026-08-22: headless-reliability class.
All four Daybreak waves ended in harness escalations, two of them this exact
`cap-or-close-mismatch` shape, while the underlying relays were productive (wave 4 closed
Approved on its own evidence).

## Bug

`marathon-drive.sh` defaults to `--round-cap 5` per fire. On phases where builder and
reviewer iterate productively past 5 rounds, the runner escalates
`cap/close-mismatch (relay-drive exit 4)` even though the lane is active and converging —
halting automated execution and requiring manual restart.

## Plan

1. Progress-aware extension in `utils/py/relay_drive.py` (authoritative Python lane; the Bash
   twin is FROZEN per GH-308) / `utils/py/marathon_drive.py`: at the cap, if the last round produced new commits or newly
   resolved review items, grant a bounded extension (one increment, hard ceiling 2× cap) and
   record it in the transcript; a round with no progress still escalates exit 4.
2. Per-phase cap override: honor a `round-cap:` key in the phase brief and a CLI flag.
3. Escalation record distinguishes `cap-stalled` from `cap-progressing-extended` so post-run
   triage stops re-litigating productive runs.
4. `test/gh115-round-cap.sh`: scripted relay hitting the cap while progressing → extended then
   approved; hitting the cap stalled → exit 4 unchanged. Register in validate.sh TESTS.

## Acceptance

- [ ] A relay that is converging (new commits or resolved review items each round) passes the round cap with a bounded, recorded extension instead of escalating.
- [ ] A relay that is stalled at the cap (no progress) still escalates exit 4, unchanged.
- [ ] `test/gh115-round-cap.sh` green and registered in validate.sh.

## Swarm Preflight Contract

```json
{
  "target":        { "repo": ".", "ref": "development" },
  "gate":          "bash validate.sh",
  "fix_probes":    [ { "type": "path_absent", "path": "test/gh115-round-cap.sh" } ],
  "artifacts":     [ "utils/py/relay_drive.py", "utils/py/marathon_drive.py", "test/gh115-round-cap.sh", "validate.sh" ],
  "artifacts_new": [ "test/gh115-round-cap.sh" ],
  "remediation":   { "source": "self#plan", "criteria": "cap with progress extends bounded and is recorded; cap without progress still escalates exit 4; gh115 suite green" },
  "lanes":         { "agy_safe": [ "test/gh115-round-cap.sh" ], "orchestrator_only": [ "relay-automation/" ] }
}
```

## Lessons Learned (For Future Agents)

Three durable lessons from this lane. (1) The reviewer caught a real producer/consumer root
mismatch in the new escalation-reason channel — relay_drive wrote under the harness root while
marathon_drive read under the marathon root, which silently degrades to the old generic reason in
the vendored layout; cross-process file channels need one explicitly shared root and an
integration assertion on the consumer side, not just the producer's stdout. (2) This lane's own
Test 5 initially set `MARATHON_ROOT="$ROOT"` (the real repo, not the `$A` fixture), committing a
live transcript onto the working clone during every gate run — the GH-195 incident. The
`marathon-root-audit.sh` guard missed it because it only recognizes `bash <driver>.sh`
invocations, not direct `python3 marathon_drive.py` calls. Fixture-scope every driver env var and
pass an explicit `--pre-advance-cmd` in tests. (3) Both this lane and GH-8 used phase-id `p1`,
so their `marathon-system/p1/` transcripts collided at merge time; the resolution (relocating one
lane's transcript to `p1-gh115/`) worked but cost a manual conflict pass — concurrent lanes need
distinct phase ids up front, per the run-hygiene note in relay-xyz.
