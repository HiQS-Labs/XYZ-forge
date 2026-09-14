---
title: "GH-620: XYZ Skills Army mini and reusable spin-off recipe"
status: Active implementation
created: 2026-09-14
updated: 2026-09-14
owner: Codex
goal: publish the closed Skills Army HQ package as a generated child repository while keeping XYZ Forge authoritative, and record the reusable minimum spin-off playbook
gh_issue: 620
source: https://github.com/HiQS-Labs/XYZ-forge/issues/620
doc_type: project
context_tags: [skills-army-hq, spin-off, publisher, xyz-mini]
non_goals:
  - publishing any deployed skill collection or machine-local state
  - automatic or scheduled publication
  - a second publisher engine or mirrored child regression suite
effort: 3
complexity: 2
risk: 2
phases: 4
---

# GH-620 — XYZ Skills Army mini

## Status

| What was just completed | What's next |
|---|---|
| Phase 0 confirmed the six tracked package files form a closed standard-library unit and the existing GH-589 publisher is the reusable seam. | Parameterize the existing publisher with a Skills Army target, add the minimum detached-package smoke, review, publish, and read back the generated child. |

## Goal and ownership

XYZ Forge remains authoritative. The child is a generated projection: managed changes land here
first and are republished; managed child files are never hand-patched. Child-only seed files remain
child-owned. The bet is that the existing GH-589 publisher can carry one additional explicit target
profile without becoming a general deployment framework. Failure mode: target-specific paths or
state leak across profiles. Rollback is Easy: revert the parent PR and the generated child commit.

## Phase 0 — Spike: qualify the split

### Findings

- The package boundary is exactly `skills/skills-army-hq/{SKILL.md,README.md,scripts/intake.py,scripts/sync.py,references/recovery.md,references/targets.md}` plus repository licenses and a child landing README/gitignore.
- `scripts/intake.py` uses only Python's standard library. `scripts/sync.py` imports only sibling `intake.py`; there are no Forge runtime imports.
- Forge-specific assumptions are explanatory rather than imports: the skill documents the operator's current Git Pulse collection authority. The child must describe itself as the distributable manager package and retain the separation from deployed collections and machine state.
- GH-589's `utils/py/xyz_mini_sync.py` already owns tracked-file expansion, preview/apply/push, managed deletion, seed preservation, secret scanning, commit provenance, and remote read-back. A second copied engine would create maintenance drift.
- The smallest seam is a named target profile in that publisher, defaulting to the current XYZ-mini behavior for compatibility. One target-specific wrapper skill may invoke the profile; no scheduler or new framework is needed.

### What this changes

The build will extend the existing publisher rather than add a parallel sync implementation. Tests
will retain the GH-589 end-to-end contract and add one narrow GH-620 detached-package smoke that
proves the profile exports only the intended boundary and the copied scripts work in a temporary
collection/target.

## Ordered implementation plan

1. Add the Skills Army child README/gitignore sources and the reusable spin-off playbook in Forge -> expect the ownership, qualification, publication, read-back, maintenance, and rollback contracts to be explicit.
2. Extend `utils/py/xyz_mini_sync.py` with an explicit Skills Army target profile while preserving the default XYZ-mini CLI contract -> expect existing GH-589 tests unchanged and green.
3. Add a small `/push-to-skills-army-mini` operator wrapper and register the new target in architecture/routing only where needed -> expect one canonical writer and no automation.
4. Extend existing test registration with one surgical GH-620 test -> expect exact inclusion-only payload, idempotence, provenance read-back, and a fresh temporary init/add/target/sync cycle; red control removes one manifest item and must fail.
5. Run focused tests and final qualifying gate once, review the committed result, then open a PR into `development` -> expect no unrelated files.
6. After merge, create/bootstrap the child from landed `development`, push, and verify origin/main payload bytes/modes, manifest, and `.xyz-forge-revision` -> expect no child hand-edits or parent/child managed drift.

## Test scope

- Existing `test/gh589-xyz-mini-sync.sh` remains the regression contract for the original profile.
- One new GH-620 shell test may reuse its throwaway-clone/bare-remote shape and invoke the package's existing scripts.
- No new framework, fixture subsystem, matrix, recovery campaign, fuzzing, or mirrored child suite.

## Rating rationale (2026-09-14)

`rated 65/25/50/45`: operator-ordered packaging feature; low severity because no defect is being
repaired; appeal held neutral; moderate/easy delivery because the closed package and publisher seam
already exist. Recurrence trend is not applicable to this feature. No rank override requested.

