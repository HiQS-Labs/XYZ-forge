---
Goal: QA the GH-620 XYZ Skills Army mini implementation plan
Date: 2026-09-14
NEXT: claude-a
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

## Codex review — changes requested

VERDICT: FAIL
Basis: exact ownership, divergence, playbook destination, detached assertions, and phase gates were missing

**Review result: Changes requested.** The existing-publisher/profile direction is the smallest DRY seam, and the six
runtime files are a closed Python import set, but the plan is not ready to build because it treats a
required divergence guard as already present, does not declare the new profile's exact ownership
map, and leaves the detached-package and red-control assertions ambiguous.

### Graded dispositions

1. **Both outcomes — not yet.** The actual post-merge publication is present
   (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:55-62`), but the reusable playbook is only named in
   step 1; it has no destination path or checkable mapping to the issue's qualify/manifest/bootstrap/
   test/land/maintain/rollback recipe (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:57`).
2. **Reuse seam — yes, with a missing contract.** A named profile over the existing engine is leaner
   than a second publisher, but the plan must enumerate the profile-owned values. The implementation
   currently hard-codes the manifest, log/CLI identity, environment/default destination, and commit
   identity/message (`utils/py/xyz_mini_sync.py:29-60`, `utils/py/xyz_mini_sync.py:78-79`,
   `utils/py/xyz_mini_sync.py:110-124`, `utils/py/xyz_mini_sync.py:171-173`). Preserve the no-target
   XYZ-mini behavior byte-for-byte and make only those values data-driven; do not grow a plugin API.
3. **Package boundary — runtime-closed, distribution docs not yet closed.** `sync.py` imports only its
   sibling `intake.py` (`skills/skills-army-hq/scripts/sync.py:13-15`), and `intake.py`'s imports are
   standard-library (`skills/skills-army-hq/scripts/intake.py:3-18`). However, the shipped README's
   standalone quick start still names an XYZ-forge checkout
   (`skills/skills-army-hq/README.md:58-64`), while the plan calls Forge assumptions merely
   explanatory and schedules no edit to the six-file package (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:42-46`).
   Require the package's child-facing command/path wording to work from the child clone; retaining
   upstream attribution is fine.
4. **Ownership/provenance/seed/exclusion — incomplete.** The plan lists source files but never states
   their destination paths and `managed`/`seed` modes, nor whether v1 deliberately has zero seed
   paths (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:42`,
   `PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:57-60`). It also omits the final repository slug and
   therefore cannot pin the profile's default checkout/env contract. Add one exact source ->
   destination -> ownership table covering the six files, landing README, gitignore, both licenses,
   manifest, and revision marker; name the public child repo; state the secret/machine-state
   exclusions and the seed policy explicitly.
5. **Test scope — right-sized, not yet falsifiable.** One profile E2E plus the existing package suite
   is appropriate, but “removes one manifest item and must fail” does not name an independent oracle
   (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:60`). Pin a literal expected destination set outside
   the profile, mutate/drop one required profile entry, and require the test process to go red against
   that fixed set. Also spell out the detached smoke assertions: init preview leaves the empty root
   untouched; apply initializes it; add/target/sync preview leaves collection and target unchanged;
   apply changes only the temporary roots; final catalog/link read-through succeeds. “Fresh cycle”
   alone does not prove those acceptance clauses.
6. **Blast/rating/order — directionally sufficient, readiness structure is not.** Easy rollback,
   authority, default-profile compatibility, bounded MVP scope, and post-push byte/mode/revision
   read-back are stated (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:30-36`,
   `PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:55-74`). But the plan's claim that the current
   publisher already owns divergent-state refusal is false
   (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:45`): it checks dirty worktrees, then writes/commits,
   and only discovers a non-fast-forward at push time, retaining the local commit
   (`utils/py/xyz_mini_sync.py:123-133`, `utils/py/xyz_mini_sync.py:155-182`). Add a pre-write
   destination branch/upstream-divergence refusal and a negative test. Also reconcile `phases: 4`
   with the body: PDDA requires a multi-phase plan to expose its phases/TOC and observable QA gates
   (`PROJECT/PDDA.md:803-811`, `PROJECT/PDDA.md:1052-1065`), while this document has only Phase 0 plus
   an unphased ordered list.

### Cheapest revision

- [ ] Add the exact child repo/profile/manifest ownership table and define the small profile data
      seam, including the unchanged default.
- [ ] Add divergence preflight + its negative assertion to the existing publisher contract; keep one
      separate GH-620 detached-package smoke with a fixed expected-file oracle and witnessed mutant.
- [ ] Make the shipped package README's quick start child-valid, name the playbook artifact and its
      seven required sections, then reshape the four declared phases with observable QA gates.

### Producer disposition — 2026-09-14

All six findings are accepted and implemented in the revised plan. The plan now names the public
child slug and environment/default checkout, provides the exact source/destination/ownership table,
declares zero v1 seeds and explicit exclusions, scopes the profile data seam, corrects the divergence
overclaim, requires the bounded pre-write guard and negative test, pins an independent literal-set
oracle and its mutant, expands the detached workflow assertions, names
`docs/SPIN-OFF-REPOSITORY-PLAYBOOK.md`, and exposes four phases with QA gates. The README quick-start
edit is now an explicit Phase 1 item. No speculative machinery was added.

Handing back to Codex for plan re-review.
