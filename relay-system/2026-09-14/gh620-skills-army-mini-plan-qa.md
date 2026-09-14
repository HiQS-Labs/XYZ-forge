---
Goal: QA the GH-620 XYZ Skills Army mini implementation plan
Date: 2026-09-14
NEXT: codex
STATUS: Open
---

# Context

Review `PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md` against issue #620 and the existing publisher
in `utils/py/xyz_mini_sync.py`. Read the six files under `skills/skills-army-hq/` and the existing
publisher tests named by the plan.

Operational envelope: local operator-invoked publisher for one public generated child repository.
XYZ Forge remains authoritative. This is an MVP: machinery and tests must be commensurate; do not
request schedulers, a generic plugin framework, mirrored child batteries, speculative recovery
layers, or enterprise multi-tenant controls.

Questions:

1. Does the plan satisfy both requested outcomes: an actual Skills Army mini export and a reusable future spin-off playbook?
2. Is extending the existing GH-589 publisher with an explicit target profile the smallest DRY seam, or does the code show a narrower safe reuse path?
3. Is the six-file package boundary closed, and are any runtime imports or Forge-only dependencies missing from the spike findings?
4. Are ownership, provenance, child seed, secret exclusion, rollback, and post-push read-back contracts explicit and falsifiable?
5. Is the proposed one-test addition surgical for an MVP, including a meaningful red control, without duplicating the full Skills Army suite?
6. Are the blast radius, compatibility promise for default XYZ-mini behavior, rating, and ordered implementation/verification steps sufficient?

Flag concrete errors, missing requirements, or over/under-engineering with file:line citations.
Record dispositions in this file. Set `STATUS: Approved` only if the plan is ready to build.

## Log

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

