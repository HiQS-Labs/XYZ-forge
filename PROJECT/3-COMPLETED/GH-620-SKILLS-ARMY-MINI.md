---
title: "GH-620: XYZ Skills Army mini and reusable spin-off recipe"
status: Complete
created: 2026-09-14
updated: 2026-09-17
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
| Root projection is published and read back, focused gates are green, and the exact-head hosted vendored smoke passed. | Resolve or requalify the known unrelated GH-615 full-suite baseline before moving draft PR #622 toward merge readiness. |

## Goal and ownership

XYZ Forge remains authoritative. The child is a generated projection: managed changes land here
first and are republished; managed child files are never hand-patched. Child-only seed files remain
child-owned. The bet is that the existing GH-589 publisher can carry one additional explicit target
profile without becoming a general deployment framework. Failure mode: target-specific paths or
state leak across profiles. Rollback is Easy: revert the parent PR and the generated child commit.

The public child repository will be `HiQS-Labs/XYZ-skills-army-mini`. Profile `skills-army-mini`
uses `$XYZ_SKILLS_ARMY_MINI_REPO` or the sibling checkout `../XYZ-skills-army-mini`. Version 1 has
no seed paths: every exported file is parent-managed. `MANIFEST.txt` and `.xyz-forge-revision` are
publisher-managed control files. Deployed collections, receipts, targets, history, backups, secrets,
and machine-local paths are excluded.

## Table of contents

- [Phase 0 — Spike: qualify the split](#phase-0--spike-qualify-the-split)
- [Phase 1 — Parent contract and playbook](#phase-1--parent-contract-and-playbook)
- [Phase 2 — Surgical verification and review](#phase-2--surgical-verification-and-review)
- [Phase 3 — Land, publish, and read back](#phase-3--land-publish-and-read-back)
- [Phase 4 — Root-project the canonical package](#phase-4--root-project-the-canonical-package)

## Phase 0 — Spike: qualify the split

### Findings

- The package boundary is exactly `skills/skills-army-hq/{SKILL.md,README.md,scripts/intake.py,scripts/sync.py,references/recovery.md,references/targets.md}` plus repository licenses and a child landing README/gitignore.
- `scripts/intake.py` uses only Python's standard library. `scripts/sync.py` imports only sibling `intake.py`; there are no Forge runtime imports.
- Forge-specific assumptions are explanatory rather than imports, but the package README's quick start currently names an XYZ Forge checkout. It must become clone-relative while retaining upstream attribution and the separation from deployed collections and machine state.
- GH-589's `utils/py/xyz_mini_sync.py` already owns tracked-file expansion, preview/apply/push, managed deletion, seed preservation, secret scanning, commit provenance, and remote read-back. It does not yet preflight destination branch/upstream divergence; that issue requirement needs one bounded guard. A second copied engine would create maintenance drift.
- The smallest seam is a named target profile in that publisher, defaulting to the current XYZ-mini behavior for compatibility. One target-specific wrapper skill may invoke the profile; no scheduler or new framework is needed.

### What this changes

The build will extend the existing publisher rather than add a parallel sync implementation. Tests
will retain the GH-589 end-to-end contract and add one narrow GH-620 detached-package smoke that
proves the profile exports only the intended boundary and the copied scripts work in a temporary
collection/target.

### Exact managed ownership map

| XYZ Forge source | Child destination | Ownership |
|---|---|---|
| `skills/skills-army-hq/**` | `/**` (paths relative to the canonical folder) | managed / package and landing-page authority |
| `mini/skills-army-gitignore` | `.gitignore` | managed |
| `LICENSE` | `LICENSE` | managed |
| `LICENSE-COMMERCIAL.md` | `LICENSE-COMMERCIAL.md` | managed |

Profile-owned values are limited to manifest, display/commit identity, environment variable, and
default sibling checkout. Calling the CLI with no `--target` must retain XYZ-mini's existing values
and output. This is a fixed two-profile data seam, not a plugin API.

### Recon Map — Skills Army root projection

Commit: `ca1506778141` · Mode: graph + direct source fallback · Lanes: A–D serial in the driver

#### Subject and change class

Contract change: publish one canonical skill directory at a generated repository root without
changing the installed skill-folder identity or weakening ordinary import validation.

#### The seams

| Seam | Location | Crosses | Breaks if |
|---|---|---|---|
| Manifest expansion | `utils/py/xyz_mini_sync.py:110` | Forge paths → child paths | an empty destination becomes an empty/escaping file path |
| Source identity | `skills/skills-army-hq/scripts/intake.py:98`, `:134` | checkout folder → declared skill name | all folder/name mismatches are accepted instead of only generated roots |
| Payload hashing/copy | `skills/skills-army-hq/scripts/intake.py:147`, `:563` | generated checkout → installed manager | `.git`, licenses, or publisher controls enter the installed skill |
| Initialization/update | `skills/skills-army-hq/scripts/intake.py:200`, `:602` | root checkout → collection receipt/staging | init works but later manager update rejects the recorded source |

#### Call paths in and state

`xyz_mini_sync.main` → `expand` → managed copy/manifest/provenance writes. In the child,
`scripts/intake.py init` → `package_info` → filtered digest → `stage_payload` → transaction; later
`update skills-army-hq` returns through `source_record` and the same package filter. The publisher is
the single child writer; intake transactions remain the single collection writer.

#### Contracts, failure, and rollback

Normal skill folders still require `folder.name == frontmatter.name`. Only a repository root with
Forge provenance and a manifest containing the manager entry points may use the declared skill name
as its installed destination. The deterministic red control is the detached GH-620 test: before the
change it reports missing root payloads and cannot open `scripts/intake.py`. Runtime failures use the
debug-mantra sequence. Rollback is Easy: restore the nested destination mapping and republish.

#### Unknowns

None for the bounded v1 package. The graph excluded the manager scripts and playbook by design, so
their complete source was read directly and the limitation is recorded here.

#### Current-state radius

The Skills Army child layout, its clone-relative quick start, manager init/update receipts, generated
manifest/provenance, GH-620 regression, and future spin-offs following the canonical playbook.

### Phase 0 QA gate

- [x] Import closure and exact ownership map recorded.
- [x] Existing reuse seam and its missing divergence preflight identified.
- [x] Findings injected into this plan before implementation.

## Phase 1 — Parent contract and playbook

1. Add `docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md` with the seven issue-defined sections: qualify, manifest, bootstrap, minimum tests, land/publish, maintain, rollback -> expect a reusable checklist that names Forge as authority and generated children as projections.
2. Make the package README quick start work from the future child clone and add its ownership rule; add the child gitignore source -> expect no machine-specific path or published runtime state.
3. Extend `utils/py/xyz_mini_sync.py` with the fixed `skills-army-mini` profile while preserving no-target XYZ-mini behavior -> expect only the four profile-owned values to vary.
4. Before any write, require destination branch `main` and origin/main equality; also allow an unborn main or the exact one-commit publisher retry whose parent is origin/main and whose current profile/provenance matches -> expect arbitrary ahead, behind, or divergent histories to refuse without writes.
5. Add `/push-to-skills-army-mini` as the thin operator flow -> expect preview first, explicit push, and read-back through the same canonical publisher.

### Phase 1 QA gate

- Existing no-target GH-589 contract remains green.
- The new playbook maps all seven recipe sections and names no second authority.
- Diff contains one publisher engine and no scheduler, generic plugin layer, or duplicated package logic.

## Phase 2 — Surgical verification and review

1. Add one GH-620 shell test using a throwaway source clone and local bare child remote -> expect the literal destination set in the test (independent of the profile) to equal the ten managed payload files plus the two control files.
2. Witness the oracle fail by dropping one required profile entry while the literal expected set stays fixed, then restore the source -> expect nonzero test status before the final green run.
3. Exercise the detached package: init preview leaves an absent collection untouched; init apply creates only the temporary collection; add/target/sync previews leave collection and target unchanged; applies touch only those temporary roots; final catalog and target-link read-through identify the fixture skill.
4. Add one divergence negative case -> expect a destination commit not on origin/main to refuse before managed bytes change.
5. Run focused tests, commit, and complete Codex implementation QA -> expect Approved with all findings dispositioned against the MVP envelope.

### Phase 2 QA gate

- Literal payload oracle, red control, divergence refusal, idempotence, provenance, and detached workflow are green.
- Existing Skills Army suite and GH-589 publisher suite are green.
- No new framework, fixture subsystem, matrix, recovery campaign, fuzzing, or mirrored child suite.

## Phase 3 — Land, publish, and read back

1. Run the final qualifying gate once in a disposable full clone and open the PR into `development` -> expect exact-SHA evidence and no unrelated files.
2. After merge, create the public child if absent and publish from clean landed `development` -> expect `origin/main` to equal the publisher's local HEAD.
3. Compare all managed bytes/modes, `MANIFEST.txt`, and `.xyz-forge-revision` to the landed parent -> expect zero managed drift and no excluded state.
4. Link the parent PR and child commit in issue #620 -> expect a cold operator can find both the implementation and reusable playbook.

### Phase 3 QA gate

- Hosted origin CI is green for the landed parent SHA.
- Child origin/main and local HEAD match; all managed payloads and provenance read back exactly.
- Rollback remains a parent revert/republish or generated child commit revert, never a child hand-patch.

## Test scope

- Existing `test/gh589-xyz-mini-sync.sh` remains the regression contract for the original profile.
- One new GH-620 shell test may reuse its throwaway-clone/bare-remote shape and invoke the package's existing scripts; its expected file set is literal and independent of the publisher profile.
- No new framework, fixture subsystem, matrix, recovery campaign, fuzzing, or mirrored child suite.

## Phase 4 — Root-project the canonical package

**Goal:** The tracked contents of `skills/skills-army-hq/` appear directly at the child repository
root, while initialization and subsequent manager updates install only the canonical package under
the declared `skills-army-hq` collection folder.

- [x] Make an empty manifest destination preserve source-relative paths and refuse empty or escaping outputs.
- [x] Recognize a mismatched repository-root source only when Forge provenance and the publisher manifest prove the generated shape; keep ordinary `skill_info` callers strict.
- [x] Hash and stage the generated root without `.git`, `.gitignore`, licenses, manifest, or provenance so the installed manager remains the canonical package payload.
- [x] Update the canonical README, spin-off playbook, ownership map, and clone-relative links for the root layout.
- [x] Match the default sibling checkout's case to the public `XYZ-skills-army-mini` repository and cover the no-`--dest` path in the GH-620 regression.
- [x] Run the GH-620, GH-589, and Skills Army HQ focused suites from a disposable full clone.
- [x] Republish and read back the exact root payload bytes, executable modes, manifest, provenance, and idempotent retry.
- [x] Designate PR #622 as the immutable parent/child SHA receipt so publication updates do not create a self-referential project-doc republish loop.

### Phase 4 — QA checklist

- [x] Root payload oracle and detached init/update smoke pass after the witnessed pre-fix failure.
- [x] Ordinary mismatched skill folders remain rejected; the generated-root proof fails when provenance or required manifest entries are absent.
- [x] Existing XYZ-mini publisher behavior remains green.
- [x] Blast: **Easy** undo; shield is the existing generated-child profile plus strict projection recognition; tripwire is any payload-set, metadata-exclusion, init/update, or read-back failure before publication.
- [x] Status table reflects the verified publication; exact immutable SHAs are recorded in PR #622 to avoid creating a self-referential republish loop.

## Rating rationale (2026-09-14)

`rated 65/25/50/45`: operator-ordered packaging feature; low severity because no defect is being
repaired; appeal held neutral; moderate/easy delivery because the closed package and publisher seam
already exist. Recurrence trend is not applicable to this feature. No rank override requested.
