---
gh_issue: 882
source: https://github.com/HiQS-Labs/XYZ-forge/issues/882
title: "GH-882: Pointer — Skills Army HQ upstream is XYZ-skills-army-mini; forge keeps a vendored copy"
status: Reversed by GH-955 (2026-10-03) — closes when #882 is closed as reversed after GH-955 merges
created: 2026-10-01
updated: 2026-10-03
owner: noelsaw1
goal: XYZ Forge consumes Skills Army HQ from XYZ-skills-army-mini, with a clear pointer and no republisher
doc_type: feedback
effort: 1
complexity: 1
risk: 1
phases: 2
---

# GH-882 — Skills Army HQ upstream is XYZ-skills-army-mini

> **Reversed (2026-10-03, operator, [GH-955](https://github.com/HiQS-Labs/XYZ-forge/issues/955)).** XYZ-forge is the
> upstream for every standalone child repo again, published by one central publisher
> (`utils/py/xyz_mini_sync.py`, skill `push-downstream`). XYZ-skills-army-mini never diverged after this
> decision: its only commit since was a forge sync. The record below is kept as history.

## Status

| What was just completed | What's next |
|---|---|
| **Reversed 2026-10-03 by [GH-955](https://github.com/HiQS-Labs/XYZ-forge/issues/955):** XYZ-forge is the Skills Army HQ upstream again. `UPSTREAM.md` deleted; the republisher is un-retired and folded into `push-downstream`; gh620 kept. Phase 2 below is **cancelled**. | Close #882 as reversed; transfer mini #4–#7 back to the forge (GH-955 closing actions) |

The canonical plan and decision record live upstream on
[XYZ-skills-army-mini#2](https://github.com/HiQS-Labs/XYZ-skills-army-mini/issues/2). This doc tracks the
forge side only.

## Decision (operator, 2026-10-01)

- XYZ-skills-army-mini is the canonical upstream for Skills Army HQ.
- XYZ Forge keeps a vendored copy at `skills/3-weekly/skills-army-hq/`. A forge-only `UPSTREAM.md` points
  upstream. Refreshes are ad-hoc vendor PRs from a tagged mini release, with no freshness guarantee.
- `push-to-skills-army-mini` is retired now and deleted later.
- Forge issues #506, #676, #837 and #881 moved to mini as #4, #5, #6 and #7.

## Forge-side phases

1. **Now (this doc's first PR):**
   - add `UPSTREAM.md`;
   - mark `push-to-skills-army-mini` retired;
   - retire the forge ledger row and capture doc of transferred #506.
2. **After the #854 freeze (2026-10-07), via the 2026-10-08 suite audit:**
   - delete `skills/3-weekly/push-to-skills-army-mini/` and `test/gh620-skills-army-mini-sync.sh`;
   - drop the `skills-army-mini` package from `utils/py/xyz_mini_sync.py`;
   - retire `test/skills-army-hq.sh` and `test/test_deploy_skills.py`, which are ported to mini.

## Rating (2026-10-01): `rated 60/35/50/85`

- **sev 35:** a stale vendored copy or an accidental republish could overwrite or confuse upstream. No data loss.
- **pri 60:** it closes the loop on the operator's pivot.
- **appeal 50:** neutral.
- **effort 85:** docs and ledger only.
- **Recurrence:** none; this is a one-off pivot.

## Merge evidence

- PR #936 merged 2026-10-02 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #939 merged 2026-10-03 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Merge evidence

- PR #950 merged 2026-10-03 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
