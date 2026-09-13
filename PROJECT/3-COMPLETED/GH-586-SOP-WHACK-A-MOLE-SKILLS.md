---
gh_issue: 586
source: https://github.com/HiQS-Labs/XYZ-forge/issues/586
title: "GH-586: add /sop and /whack-a-mole skills; route skill management to skills-army-hq; XYZ_SKILLS_ROOT"
status: Complete
created: 2026-09-12
updated: 2026-09-12
owner: orchestrator
doc_type: feature
effort: 1
complexity: 1
risk: 1
phases: 1
goal: >
  Land two prompt-only skills (sop, whack-a-mole) in skills/, make ROUTER.md name skills-army-hq as
  the system's skill-management mechanism, and keep the manager's docs repo-agnostic via an
  XYZ_SKILLS_ROOT env var.
---

# GH-586 · /sop + /whack-a-mole skills, skill-management routing

Born-complete capture: the work shipped on `feat/specialized-skills` in one motion and this doc
records it for the ledger. Issue: [#586](https://github.com/HiQS-Labs/XYZ-forge/issues/586).

## What landed

- `skills/sop/` — SOP / runbook / lessons-learned catch-up skill (recon → propose → confirm → apply;
  git read-only). Renamed from the imported `catchup` because that name collides with the
  `pdda.sh catchup` subcommand and is ambiguous.
- `skills/whack-a-mole/` — recurring-bug clustering by churn score; files one approved root-cause
  umbrella issue; read-only otherwise.
- Each skill: `SKILL.md` + `agents/openai.yaml`; rows in `ARCHITECTURE.md` → Skills Index.
- `ROUTER.md` routing hint: managing skills for the system = `skills-army-hq`. `skills/` is the
  authoring source; the durable collection lives at `$XYZ_SKILLS_ROOT` (machine-local); only
  `intake.py` / `sync.py` mutate it or app symlinks.
- `skills/skills-army-hq/scripts/{intake,sync}.py` honor `XYZ_SKILLS_ROOT` as the default `--root`.
- `intake.py remove` no longer deadlocks when two or more payloads have vanished (found while
  deploying — see [#585](https://github.com/HiQS-Labs/XYZ-forge/issues/585)); regression test
  `test_a5_two_missing_payloads_do_not_deadlock_remove`.

## Acceptance

- [x] Both `SKILL.md` files carry valid `name`/`description` frontmatter and manifests.
- [x] Skills Index rows and CHANGELOG entry present.
- [x] `test/skills-army-hq.sh` — 25 passed, 4 subtests (includes the new regression).
- [x] Deployed via skills-army-hq to all five enabled targets on the publisher machine and
      discoverable in Claude Code (2026-09-12).

## Out of scope (parked)

- Skills Index drift: 47 rows vs 55 folders in `skills/` before this change.
- `skills-army-hq` README/SKILL examples still spell a machine path instead of `$XYZ_SKILLS_ROOT`.
- The pulse writer pulling before it stages the collection (root cause in #585) — belongs to the
  Git Pulse tooling, not this repo.

## Reversibility

Easy — delete the two skill folders, revert the three doc edits and the two-line env-var change.
