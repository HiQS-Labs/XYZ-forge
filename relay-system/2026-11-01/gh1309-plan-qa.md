---
Goal: Plan QA for GH-1309 (skills-army-hq --migrate-legacy)
Date: 2026-11-01
---

NEXT: codex
STATUS: Approved

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
4. Is allowing content that differs from the managed copy acceptable here, given the verified ZIP, retained staging, explicit flags and preview-first default? Or must the plan require something more (say what, and why a smaller control would not do)?  [Unverified — no citation]
5. Is the verification plan sufficient and falsifiable without a new test file or registry entry: existing suites plus the manual matrix with red controls? Is the gate selection right (tier-2 skills-army-hq subsystem, including the publisher suites)?
6. Is the persisted rating (45/30/50/60) consistent with the evidence?

Each `[Blocker]` or `[Should]` must carry `Observed input:`, `Affected scope:` and `Falsifier:` lines. Cite file:line.

Write your verdict below. Set STATUS to Approved if the plan can proceed as written (minor notes allowed). Otherwise hand back with changes requested.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->


# Codex review — 2026-11-01

**Approved for implementation.** No Blocker or Should findings. This is plan approval, not implementation or runtime verification. The opt-in archive-and-stage approach is commensurate with the single-user local CLI envelope. Reversibility remains Costly, with the retained directory and verified ZIP as the rollback copies.

1. **Grounding and consumers — Pass, with a minor citation correction.** The recon table matches the cited source: `link_text` refuses real entries (`skills/3-weekly/skills-army-hq/scripts/intake.py:367-371`), reconciliation records those conflicts (`scripts/sync.py:253-283`), and the existing retirement producer, action handler and validator have the described name restrictions (`scripts/sync.py:287-323`, `scripts/intake.py:537-568`; script paths in this paragraph share the skill prefix). A repository source search for `retire-directory`, `skills-sync-trinity` and `Invalid retirement` found the cited runtime sites and a10 coverage, with no additional runtime consumer in the searched Python/Bash/JavaScript/JSON files. Graph tools were unavailable; this is source-search evidence, not a graph completeness claim. Minor: the plan's line 93 attributes “ask before archiving a real legacy app directory” to hard rule 2, but that exact text is in `skills/3-weekly/skills-army-hq/SKILL.md:164-167`. Hard rule 2 (`:21-23`) separately requires specific approval to override refusals with migration flags. Both support the intended approval requirement.

2. **Guard widening and coexistence — Pass.** A safe skill name plus membership in the receipt's validated skills map (retaining the explicit trinity exception) and the full collection-overlap exclusion is sufficient for the stated envelope. “Outside” here excludes equality and both ancestor directions, as already stated by the plan's reference to the link overlap rule (`skills/3-weekly/skills-army-hq/scripts/intake.py:253-272,574-583`). Keep the new check specific to retirement: collection-root manager links remain legitimate. New non-trinity pending receipts are **not backward replay compatible**: the old validator rejects them as `Invalid retirement` (`:568`) before `finish` starts applying actions (`:590-594`). This is a safe refusal, not silent misapplication to trinity. Minor operational note for recovery docs: finish/recover a new migration with the updated manager before downgrading it; an old manager cannot recover that pending operation. No versioned protocol or rolling-upgrade machinery is warranted here.

3. **Replay and ordering — Pass.** `finish` applies actions in list order on every attempt (`skills/3-weekly/skills-army-hq/scripts/intake.py:590-603`). Retirement immediately before the corresponding link, as required by plan lines 89-91, gives the link an absent pre-state. Checking the retained directory's digest before accepting an absent or symlink leaf makes retirement replay safe after either the rename or the link creation. The following link action already accepts the expected destination idempotently and refuses an externally retargeted link (`:511-514`); the retirement replay shortcut therefore does not grant ownership of an arbitrary symlink. A real directory that reappears remains on the guarded digest/staging-occupied path. No sorting or grouping may reorder the planned retirement/link pair.

4. **Different content — Pass.** Content equality would defeat the stated stale-folder use case. Explicit skill selection, a valid matching skill identity, specific operator approval, preview of the mismatch, the existing verified archive, retained staging and same-filesystem check provide proportionate controls. `archive` verifies CRC/count, permissions, bytes, link text and an unchanged source snapshot (`skills/3-weekly/skills-army-hq/scripts/intake.py:326-360`). Its snapshot rules also reject unsafe internal links and special files (`:147-192`), so “internal symlink” in the main manual case means one accepted by those existing rules. No broader acceptance of arbitrary folder contents is implied.

5. **Verification — Pass as a plan; [Unverified — needs clone run].** The existing wrapper invokes `test/test_deploy_skills.py`; a10 covers explicit trinity retirement and archival (`test/test_deploy_skills.py:531-547`). The selected subsystem is correct and includes the publisher consumers: `skills-army-hq.sh`, `gh620-skills-army-mini-sync.sh`, `gh589-xyz-mini-sync.sh`, `gh589-consult-no-tick.sh`, and `gh589-skill-viewer.sh` (`utils/ci-route.sh:33,50`). The manual matrix covers stale and matching content, refusal paths, repeated action replay and forged receipt guards, without introducing a new suite or registry. Red control A demonstrates the missing base feature; B/C exercise the newly widened guard. As required by the repository, the later manual receipt must record actual commands/results, nonempty artifacts and observed red outcomes; these are planned checks, not checks witnessed in this review. The wrapper can report SKIPPED when pytest is absent (`test/skills-army-hq.sh:10-15`), which is not completed runtime coverage. No test suite, executable fixture, network call or git command ran during this turn.

6. **Rating — Pass.** The tracked roadmap dump persists `45/30/50/60` (`releases.sql:958`), matching plan lines 120-123. A stale copy in one app with a status conflict supports modest severity; operator demand supports the priority; neutral appeal and moderately cheap effort are reasonable. Recurrence on other devices remains a hypothesis, correctly labeled unknown rather than measured incidence. The Mac Studio observations and prior-art search are supplied context, not independently reproduced in this offline review.

Only this relay file was edited. Implementation and the specified disposable-clone/manual verification remain outstanding.
