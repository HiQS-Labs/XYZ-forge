---
gh_issue: 649
source: https://github.com/HiQS-Labs/XYZ-forge/issues/649
title: PDDA canonical source migration
status: In progress
created: 2026-09-16
updated: 2026-09-16
doc_type: project
owner: Noel Saw
goal: Make Forge the sole PDDA development authority and define a verified archival gate.
effort: 3
complexity: 3
risk: 3
phases: 3
ratings_provisional: false
---

# PDDA canonical source migration

## Quad Concepts
- Two development authorities drift → reconcile PDDA into Forge while preserving unique behavior.
- Separate-clone onboarding blocks retirement → ship the governance installer from Forge.
- Existing consumers outlive repository ownership → inventory and migrate distribution before archive.
- Standalone demand is unproven → no generated child or independent roadmap.

Canonical requirements and research: https://github.com/HiQS-Labs/XYZ-forge/issues/649
Operator requested execution and evidence-based closeout on 2026-09-16. Archive remains an operator action after the documented gate.

## Status

| What was just completed | What's next |
|---|---|
| Plan and implementation relays approved; full gate passed | Land migration, publish retirement notice, then record archive verdict |

## Table of contents

- [Recon and decision](#recon-and-decision)
- [Phase 1: import and onboarding](#phase-1-import-and-onboarding)
- [Phase 2: verification and review](#phase-2-verification-and-review)
- [Phase 3: cutover and archive gate](#phase-3-cutover-and-archive-gate)

## Recon and decision

Base: Forge 9e1e9bf4f1f2d2fef127da2f851acf8e5da273a7; PDDA b0c708660706f2a6359e85a2cb753564e59cba58.
Graph generation 2026-09-01 is stale; direct source reads ground these findings. No exhaustive graph claim.

- PDDA install.sh:22,28,577 reads the repo-root manifest; :588-594 seeds generic startup docs and the pdda skill; :723 registers target; :734 runs the target check suite.
- PDDA utils/pdda/pdda-sync.sh:17-30 resolves source root and source-local state; :365-382 is the divergence/backup problem recorded in pdda#59; register invokes root install.sh. No PDDA-named launchd plist or loaded PDDA job was found on this device. Other-device jobs remain unknown.
- PDDA utils/pdda/pdda-sync-manifest.conf:17-23 distributes runtime + contract, excluding the sync tools. Forge lacks those source-only tools.
- Forge skills/vendor-stack/find-pdda.sh:28 and SKILL.md:60-91 locate a separate clone and call its installer. Forge root install.sh is the tick installer and must remain unchanged.
- Forge pdda.sh:326 includes releases.db coverage and :664 DB issue-state checks; pdda-lib.sh:458 adds positional release fields. Preserve these, the comment scanners, timing support and local-check gates. The only removed core logic in the inspected upstream-to-Forge diff that needs porting is PDDA's two-line changelog heading/date fix (#65).
- Forge utils/py/pdda_gov_scan.py and pdda_comment_refs.py are optional stdlib scanners used by the Bash fallback-capable core; include them explicitly in the manifest to retain performance.
- PROJECT/PDDA-SYNC-POLICY.md protects local behavior after a destructive sync incident. Keep its deletion-classification protection, changing ownership language only.
- New import sources: PDDA install.sh, pdda-manifest.sh, pdda-sync.sh, pdda-sync-manifest.conf, templates/ROUTER.target.md, generic AGENTS.md/GUIDING-PRINCIPLES.md, .claude/skills/pdda/SKILL.md, license, and focused installer/changelog tests. Old repository history preserves unrelated Sentinel and retired/experimental skill work; archive does not delete it.

Assumption: consolidating ownership pays for the migration; no independent distribution promise is needed. Failure: existing consumers lose install/update behavior or local documents. Shield: explicit managed manifest, preserved templates/seeds, dry-run first, fixture install/upgrade and restore checks. Reversibility: Costly. Retain pinned original source/history and migration backups; stop replacement writer and restore previous payload/state on regression. No history rewriting, license conversion, generic plugin framework or child publisher.

License: preserve existing PDDA Apache-2.0 notices; Forge licensing unchanged. No relicensing is proposed. This is the conservative default stated to the operator; optional preference question remains available. Preserve upstream authorship/provenance in imported files and document which files are imported versus Forge additions.

Rating 2026-09-16: priority 80 / severity 55 / appeal 50 / effort-cheapness 45. User prioritizes consolidation; observed consequence is ownership/drift and unsafe update confusion, not a newly reproduced data-loss incident. Appeal neutral. Effort reflects cross-repo packaging/consumer review. Historical sync incident and pdda#59 are relevant examples, not evidence of a growing 14-day incident rate; recent recurrence trend unknown. No override.

## Phase 1: import and onboarding

1. Import the existing installer as utils/pdda/pdda-install.sh, resolving source root two levels up. Put generic templates under utils/pdda/templates and map them to target startup/skill paths. Remove standalone-source-repo claims from generic AGENTS; no Forge product rules ship in startup templates. Keep PROJECT/PDDA.md a generic contract: relocate its Forge-only RELEASES-retirement note into ROUTER.md (which already declares it), leaving shared legacy/release-mode rules in the contract. Preserve Forge root install.sh. Import manifest and sync helpers, repoint sync register to the renamed installer. New Bash imports carry per-file New-bash-exception trailers because this is preservation of existing tooling, not a rewrite.
2. Exclude source-only installer/templates/sync machinery from target payload. Include Forge's two Python scanners explicitly. Preserve Forge runtime, port PDDA#65 changelog parser and contract/test; retain all local checks untouched. Inventory every changed/deleted managed path.
3. Resolve PDDA to the owning Forge tree by default. Explicit source overrides must point at the new installer; no silent fallback to a retired clone. Update vendor-stack and source metadata, README/ROUTER ownership, install manifest contract, and sync policy without weakening guardrails.
4. Preserve license/provenance as decided. Record migration and archive checklist in one Forge-owned document; align PDDA's future retirement notice only after Forge lands.

### Phase 1 QA

- [x] Fresh Forge checkout contains the complete installer and template source set.
- [x] Runtime/contract differences reconciled; no Forge-local check removed.
- [x] Target manifest omits all source-only machinery; source paths and executable bits exist.
- [x] Existing license terms and provenance preserved without conversion.

## Phase 2: verification and review

5. Reuse the imported changelog and startup-doc tests, adapted only for source paths/templates. Add one focused migration contract test covering Forge resolver without sibling PDDA, fresh installation, user seed/doc preservation on upgrade, source-only exclusion, manifest failure, and restore from a saved payload. Assert installed contract/startup docs have no source-repo identity or Forge-only retirement rule. Include observe/light/full behavior and a negative control (missing installer / invalid full-mode document). Keep fixture registries/state isolated; never run a fixture against live operator targets.
6. Run focused suites and the relevant existing Forge PDDA suites from a disposable full test clone, then required validate.sh against the final candidate. Inspect test-clone identity before/after. Retain logs/provenance in committed TESTS-RESULTS. Run a Codex relay plan review before implementation and final review after validation; max 3 rounds each. Use debug-mantra for any failure; do not waive broken checks.
7. Open PR to development, verify checks and merge only once evidence permits. Reconcile ledger/docs with the shipped workflow. Preserve task clone until work is verified on origin; then use cleanup SOP.

### Phase 2 QA

- [x] Focused tests green, negative controls fail for the intended reason.
- [x] Required Forge gate run complete with retained evidence; Codex review approved.
- [ ] Landed origin commit contains imported assets, contract, templates and authority pointers.

## Phase 3: cutover and archive gate

8. Inventory each existing local registry target (10 found during research) and active distributors before any writes. Inspect local divergence; do not blind-push over user adaptations or empty the old state. No PDDA job was found on this machine; document the check rather than assuming every device is clean. Contain pdda#59 in the imported sync update branch: compare target/source first; any unequal target with no prior stamp or with a stamp unequal to target is reported as diverged and preserved unless explicit --force-resync is given. Forced overwrites always back up the unequal target before replacement, including missing-stamp cases. Normal source updates whose target still equals the prior stamp continue unchanged. Keep deferred deletion tracking and existing poisoning guards. This is required migration protection, not a general sync rewrite.

   The cutover route is explicit: quiesce the old writer, snapshot registry + target managed payload + old temp/pdda-sync-state, temp/pdda-sync-manifest and temp/pdda-sync-backups; invoke the Forge writer with PDDA_SYNC_TMP pointing at the old retained temp directory. Do not re-register targets to establish a baseline. Preview with --dry-run --no-delete; target bytes, hash state and manifest snapshots must not change (existing diagnostic logging/temporary lock is permitted). Targets with local changes remain pinned and documented until individually reviewed; no force-resync or delete is used for live migration. Rollback: stop Forge writer, restore payload plus registry/state snapshots, resume exactly the old writer. An isolated fixture must exercise a diverged file, an old removed manifest entry, preview, explicit backup-enabled adoption and full restore before any live write.
9. Give each open PDDA issue a disposition in the migration document (carried as a linked backlog item, already covered, or intentionally deferred). Existing URLs remain durable; no mass closure or invented completion. Use Forge issues only for new actionable work. Publish PDDA's top-level migration notice, preserving source/history and directing contributions to Forge.
10. Close #649 only with landed and consumer-cutover evidence, or explicitly keep it open with outstanding gates. Tell the operator to archive PDDA only after: Forge-only fresh install/upgrade verified; source authority pointers updated; old writers stopped/repointed; registered targets accounted for; backlog dispositions and notice published; rollback retained. Operator flips GitHub archive mode separately.

### Phase 3 QA

- [x] No competing active source writer remains among inspected devices; unknown devices called out.
- [x] Each registered target has a reviewed disposition and replacement update route.
- [ ] PDDA backlog and migration notice point at Forge, without discarded historical work.
- [ ] Explicit archival verdict cites evidence; #66 mirrors #649's actual state.

## Scheduled follow-up lanes

Review findings, fixture dogfood findings and conformance are sequential Phase 2 checkpoints in this single migration arc, not independent parallel projects. Escalate a finding to its own issue only if outside this migration's scope; no speculative framework or separate publisher.

## Execution evidence

Plan Codex relay approved round 2 (reviewed 4bf7c33f). Focused evidence is in
TESTS-RESULTS/2026-09-16+GH-649/SUMMARY.md. Imported sync uses upstream PR #61 with
the additional reviewed preservation rule; manifest handles Bash 3 empty arrays and
vendored sources outside their parent index. No live target or registry was written.

## Lessons learned

Imported regression suites must adopt Forge's fixture guards, pipeline conventions,
path-token classification and subsystem census before the full gate. Behavioral tests
alone missed these integration contracts. The first full run exposed six conformance
failures; focused fixes preserve the reviewed production implementation. Final full
validation is retained separately rather than relabeling the failed run.
