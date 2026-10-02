---
gh_issue: 882
source: https://github.com/HiQS-Labs/XYZ-forge/issues/882
title: "GH-882: Pointer — Skills Army HQ upstream is XYZ-skills-army-mini; forge keeps a vendored copy"
status: Active (2-WORKING — phase 1 complete; phase 2 scheduled for the 2026-10-08 audit after the #854 freeze)
created: 2026-10-01
updated: 2026-10-01
owner: noelsaw1
goal: XYZ Forge consumes Skills Army HQ from XYZ-skills-army-mini, with a clear pointer and no republisher
doc_type: feedback
effort: 1
complexity: 1
risk: 1
phases: 2
---

# GH-882 — Skills Army HQ upstream is XYZ-skills-army-mini

## Status

| What was just completed | What's next |
|---|---|
| Phase 1: `UPSTREAM.md` added, `push-to-skills-army-mini` marked retired, #506 ledger row and doc retired | Phase 2 after 2026-10-07: remove the republisher and its suite through the 2026-10-08 audit |

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
