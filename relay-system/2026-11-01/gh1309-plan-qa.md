---
Goal: Plan QA for GH-1309 (skills-army-hq --migrate-legacy)
Date: 2026-11-01
---

NEXT: codex
STATUS: In review

# Context

Review the plan in PROJECT/2-WORKING/GH-1309-SA-MIGRATE-LEGACY.md before any code is written. Issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1309.

Operational envelope: a small, opt-in change to the Skills Army HQ scripts (skills/3-weekly/skills-army-hq/scripts/intake.py and sync.py) plus docs. Grade against the stated requirement and commensurate complexity. No new test file or registry entry (AGENTS.md "No new tests", GH-831). Do not ask for enterprise multi-user threat models; the tool already states it is not a security boundary against a hostile process with write access to the same user's files. Review only: edit nothing except this relay file. No network calls.

Read the plan and the code it cites:
- skills/3-weekly/skills-army-hq/scripts/sync.py (reconcile, retirement, main)
- skills/3-weekly/skills-army-hq/scripts/intake.py (link_text, archive, action_apply "retire-directory", validate_receipt, finish, transact)
- skills/3-weekly/skills-army-hq/references/recovery.md and SKILL.md (hard rules, migration text)
- test/skills-army-hq.sh, test/test_deploy_skills.py (a10), utils/ci-route.sh:24-50

Questions:

1. Are the plan's claims grounded at the cited file:line? Is anything misquoted? Any other consumer of the "retire-directory" action or of the "skills-sync-trinity" constant that the plan misses?
2. Is widening the retire-directory guard (name in receipt state skills, plus a new root-outside-collection check) sufficient and safe? Does it change rollout coexistence (a pending receipt written by the new manager and replayed by an older one)?
3. Is the replay change correct (return when the path is absent or now a symlink, after checking the staged copy's digest)? Any ordering problem between the retire-directory action and the link action for the same path inside finish()?
4. Is allowing content that differs from the managed copy acceptable here, given the verified ZIP, retained staging, explicit flags and preview-first default? Or must the plan require something more (say what, and why a smaller control would not do)?
5. Is the verification plan sufficient and falsifiable without a new test file or registry entry: existing suites plus the manual matrix with red controls? Is the gate selection right (tier-2 skills-army-hq subsystem, including the publisher suites)?
6. Is the persisted rating (45/30/50/60) consistent with the evidence?

Each `[Blocker]` or `[Should]` must carry `Observed input:`, `Affected scope:` and `Falsifier:` lines. Cite file:line.

Write your verdict below. Set STATUS to Approved if the plan can proceed as written (minor notes allowed). Otherwise hand back with changes requested.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

