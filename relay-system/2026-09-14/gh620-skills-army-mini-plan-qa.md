---
Goal: QA the GH-620 XYZ Skills Army mini implementation plan
Date: 2026-09-14
NEXT: claude-a
STATUS: Approved
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

## Codex re-review — approved

VERDICT: PASS
Basis: the revision resolves every blocking finding without expanding the MVP envelope

**Review result: Approved.** The plan is ready to build. Extending the existing publisher with one
fixed target profile remains the smallest DRY seam, and the revised contracts are explicit enough
to implement and falsify.

### Graded dispositions

1. **Both outcomes — pass.** The generated child flow is carried through land, publish, remote
   read-back, and issue linkage (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:120-131`); the reusable
   playbook now has an exact path and the issue-defined seven-section contract
   (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:94`).
2. **Reuse seam and compatibility — pass.** The profile owns only manifest, identity, environment,
   and default checkout, while no-target behavior must retain the existing XYZ-mini values and
   output (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:82-84`). This directly bounds the currently
   hard-coded seams in `utils/py/xyz_mini_sync.py:29-60`, `utils/py/xyz_mini_sync.py:78-79`,
   `utils/py/xyz_mini_sync.py:110-124`, and `utils/py/xyz_mini_sync.py:171-173` without inventing a
   plugin layer.
3. **Package boundary — pass.** The nine payload destinations are enumerated exactly, with the six
   package files, child gitignore, and two licenses all managed (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:68-80`).
   The only runtime-relative import remains `sync.py` to sibling `intake.py`; the README's current
   Forge-specific quick start (`skills/skills-army-hq/README.md:56-65`) is now an explicit child-valid
   Phase 1 edit (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:95`).
4. **Ownership, provenance, seed, exclusions, rollback — pass.** The child slug, environment/default
   destination, zero-seed policy, publisher-owned control files, excluded state, authority, and Easy
   rollback are explicit (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:30-42`). Managed bytes/modes,
   manifest, revision marker, local/remote equality, and excluded-state read-back form a falsifiable
   post-push contract (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:122-131`).
5. **Test scope — pass.** One GH-620 test uses an expected destination set independent of the
   profile, witnesses that oracle fail after dropping an entry, checks preview/apply containment and
   detached catalog/link read-through, and adds the divergence negative case
   (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:106-118`). Reusing the existing throwaway-clone shape
   while retaining `test/gh589-xyz-mini-sync.sh` and `test/skills-army-hq.sh` is surgical rather than
   a mirrored child battery (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:133-137`).
6. **Blast radius, rating, and execution order — pass.** The compatibility failure mode is named,
   rollback is Easy, four phases match frontmatter, every phase has an observable QA gate, and the
   rating is justified (`PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:30-36`,
   `PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:44-49`, `PROJECT/1-INBOX/GH-620-SKILLS-ARMY-MINI.md:139-143`).

### Implementation watchpoint (non-blocking)

For the Phase 1 divergence guard, resolve `origin/main` from the remote (or fetch immediately before
comparison); do not treat a possibly stale local remote-tracking ref as proof. The negative test
should advance the bare remote independently so this distinction is exercised. This is the natural
pre-write counterpart to the publisher's existing `ls-remote` post-push read-back
(`utils/py/xyz_mini_sync.py:178-188`).

### Producer implementation correction — 2026-09-14

The first runtime-level check falsified the reviewed root-package destination: `intake.py init`
derives its manager folder from the script and `skill_info()` requires that folder's basename to
equal frontmatter name `skills-army-hq`. Exporting `SKILL.md` and `scripts/` at the child root would
therefore make a clone named `XYZ-Skills-Army-mini` fail initialization. The ownership map now keeps
the six-file package under child `skills-army-hq/` and adds a separate managed root landing README.
This preserves existing manager semantics and remains inside the issue's intended boundary; no new
code path or abstraction was added.
