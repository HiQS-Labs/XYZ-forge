# Plan draft: #484 feat(skill): deploy-skills — durable local catalog and global symlink deployment

> draft; preflight and independent plan QA outstanding

- Request: `gh-484-e3a6d471a212` (tick `slot_096`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 72/58/50/55
- Capture doc: PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md (sha256 4fc5ebbd2c7a5961eff289b19e6e5b33e254ae876f5de5b1d444c3980fa0ee93)
- Issue sha256: e3a6d471a2121265ebe89be709e76b619d5ce3875ca5e24f0475fd9d939f9352 (updated 2026-10-30T18:28:21Z)
- Dependencies: none

## Scope

_Source: issue#484:L9 (Current scope)_

Write the grounded plan and perform the first plan QA through relay-xyz with Agy. No implementation or live deployment in this planning checkpoint. Subsequent delivery must include verification, final QA, PR on origin, and immediate safe task-clone teardown once all required evidence/state is pushed. No merge requested.

_Source: PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:L9 (frontmatter goal)_

Manage a durable copied skill collection and global app links through conversation.

## Acceptance criteria

_Source: PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:L195 (Acceptance evidence)_

Proposed focused suite: `python3 -m unittest discover -s test -p 'test_deploy_skills.py'`; validate its integration rather than assuming discovery. Use isolated temporary homes/repos/targets, no live app folders in automated tests. Commit nonempty results plus `provenance.jsonl` under `TESTS-RESULTS/2026-09-07+GH-484/`. Each receipt names command, artifact SHA, platform, actual exit status and evidence file. Red controls are **planned, not yet run**. Tests call real CLI paths, inspect filesystem bytes/links and compare independent expected outcomes; they do not merely check log wording.

| ID | Pass evidence | Red control and destination |
|---|---|---|
| A1 | Detached copied bundle initializes/list/catalog from alternate home and CWD; manager discovered via SKILL.md | Remove a required sibling resource; nonzero actionable result. `a1-portability.log` |
| A2 | Update/removal archive round-trip bytes/modes/internal links; two same-day updates yield distinct ZIPs; old state on failure | Inject archive write/copy failure and invalid CRC; compare old digest and link text. `a2-backups.log` |
| A3 | Strict read-only preview, valid nonempty intake, containment on source and targets | Empty/malformed SKILL.md, traversal/reserved/case names, denied scan, external symlink and cycle all refuse. `a3-containment.log` |
| A4 | Exact desired symlink set, no-op rerun, receipt-based deletion, disabled target cleanup | Retarget one owned link and place a real collision; both preserved, nonzero

## Open questions

_missing_

## Write set

- `ARCHITECTURE.md` (PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:L59)
- `skills/3-weekly/skills-army-hq/scripts/intake.py` (PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:L74)
- `skills/3-weekly/skills-army-hq/scripts/sync.py` (PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:L75)
- `test/test_python_layer.py` (PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:L111)
- `validate.sh` (PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:L111)
- `AGENTS.md` (PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:L121)
- `test/test_deploy_skills.py` (PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:L197)

## Unresolved file names

- `README.md` (PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:L59; 56 tracked files share this name)
- `SKILL.md` (PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:L59; 77 tracked files share this name)
- `install.sh` (PROJECT/2-WORKING/GH-484-DEPLOY-SKILLS.md:L59; 29 tracked files share this name)

## Contract probes

- none
