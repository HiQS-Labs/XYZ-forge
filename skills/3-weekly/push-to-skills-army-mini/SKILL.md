---
name: push-to-skills-army-mini
description: >-
  RETIRED 2026-10-01 — do not run. XYZ-skills-army-mini is now the upstream for Skills Army HQ, and
  publishing from XYZ Forge would overwrite it. Formerly published the Skills Army HQ package from
  XYZ Forge into HiQS-Labs/XYZ-skills-army-mini.
---

# Push to XYZ Skills Army mini — RETIRED

> **Retired 2026-10-01 (#882; decision record: XYZ-skills-army-mini#2).** `HiQS-Labs/XYZ-skills-army-mini`
> is the upstream for Skills Army HQ. XYZ Forge keeps only a vendored copy (see
> `skills/3-weekly/skills-army-hq/UPSTREAM.md`). Do not run this publisher; it would overwrite upstream
> changes. Its own history check already refuses once mini carries a commit the publisher did not make.
> This skill and `test/gh620-skills-army-mini-sync.sh` are removed after the #854 freeze via the
> 2026-10-08 suite audit. The text below is kept for history only.

XYZ Forge is authoritative; the child is generated. Run from a clean landed `development` checkout
with a clean `main` checkout of `HiQS-Labs/XYZ-skills-army-mini` at the sibling path or at
`$XYZ_SKILLS_ARMY_MINI_REPO`.

1. Preview: `python3 utils/py/xyz_mini_sync.py --target skills-army-mini`.
2. Read the copy/delete plan. Refusals must be fixed at the source or destination; never hand-edit
   managed child files.
3. With operator authorization, publish and verify:
   `python3 utils/py/xyz_mini_sync.py --target skills-army-mini --push`.
4. Read back child `origin/main`, `MANIFEST.txt`, and `.xyz-forge-revision`; report the child SHA.

The publisher refuses dirty source/destination state, a destination branch other than `main`, and
unrelated ahead/behind/divergent history. It permits an unborn `main`, an exact origin/main checkout,
or one exact retained publisher commit so a failed push can be retried. It never force-pushes or
schedules itself. See `docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md` for the reusable recipe.
