# PDDA ownership migration

XYZ Forge is the development authority for PDDA. Governance remains optional for
Consult/Relay. There is no independently maintained PDDA distribution or generated child.
Historical source remains at https://github.com/Hypercart-Dev-Tools/pdda.
Decision and completion evidence: https://github.com/HiQS-Labs/XYZ-forge/issues/649.

## Install and update

From a clean Forge checkout: `bash utils/pdda/pdda-install.sh /path/to/target`.
The existing root install.sh remains Forge's tick installer. PDDA's installer uses the
single manifest beside it; generic startup templates are opt-in and create-only unless
explicitly forced. Target project documents remain target-owned.

Use `bash utils/pdda/pdda-sync.sh status` and `push --dry-run --no-delete` to review updates.
Changed or unbaselined target files are preserved and reported as DIVERGED.
`--force-resync` is deliberate adoption, with backup before replacement; it is not the
migration default. Deletions retain the existing poisoning checks and backup behavior.

## Existing distributor cutover

1. Stop/quiesce the old PDDA sync job on each device. Snapshot the target managed payloads,
   machine-local registry, and old source temp/pdda-sync-state, pdda-sync-manifest and
   pdda-sync-backups directories. Do not publish machine paths or registry contents.
2. Use the landed Forge source with `PDDA_SYNC_TMP` set to the retained old state directory.
   Do not re-register targets to establish a baseline: registration installs first.
3. Preview `push --dry-run --no-delete` with that override. Target files, stamps and manifest
   snapshots stay unchanged; diagnostic logs and temporary locks are allowed. Review each target.
4. Locally adapted targets may remain pinned. Their continuing runtime use does not require
   a writable old repository. Upgrade them individually after reconciling their changes; never
   force a mass update to make the inventory look current.
5. For rollback, stop the Forge writer, restore payload/registry/state snapshots and resume
   exactly the old writer. Keep backups until all consumers are accounted for.

No automated source switching, registry rewriting or mass target upgrade is performed by
installing this change. Existing local paths can remain until the operator has migrated jobs.

## Archive gate

Do not archive solely because the research was accepted. Archive when the Forge migration
is merged and verified, the old README/description point here, open work has a recorded
disposition, old distributor jobs are stopped/repointed, each known target is accounted for
(upgraded or intentionally pinned), and rollback source/state remain accessible.
Archiving is the final operator action, not part of an installer. It preserves history but
makes GitHub issues and comments read-only, so publish pointers before flipping it.

## Inventory at 2026-09-16

Ten local registry targets had an installed runtime and contract. Nine had a .xyz directory.
Six had local changes under managed PDDA paths; one registered directory was no longer a
Git checkout. All are retained/pinned pending individual update review. No PDDA reference was found in user/system launch-agent or launch-daemon plists,
loaded jobs, or the user crontab on this device. Other-device jobs are unverified.
This inventory proves an existing footprint, not independent product demand.

## Historical backlog disposition

All numbers below resolve to https://github.com/Hypercart-Dev-Tools/pdda/issues/.
They remain historical receipts; no claim of completion follows from repository retirement.

| PDDA issue | Disposition |
|---|---|
| #66 | Pointer to Forge #649; close only with migration outcome |
| #64 | Carry remaining roadmap-mode acceptance into Forge #169; existing DB support is not proof every requested case is done |
| #63 | Carry upstream contract requirement into existing Forge #26/#27 |
| #62 | Deferred WIP-limit proposal; reconsider in Forge when selected |
| #60 | Retire standalone positioning work; underlying unmet signal capabilities remain proposals |
| #59 / PR #61 | Incorporate sync protection in Forge #649; preserve PR provenance and review it before closing as superseded |
| #56 | Preserve explicit do-not-start hold on EOD redesign |
| #55 | Deferred legacy EOD-skill path defect; historical skill not imported as a new Forge product |
| #51 | Deferred cross-repo indexing proposal; no new index built by migration |
| #50 | Deferred 3-Eyes/Sentinel integration; preserve external-system ownership |
| #47 | Resolve project root in the imported orientation skill; verify destination path |
| #44 | Fresh startup installation is a migration acceptance check |
| #43 | Carry reporting concern as historical backlog; do not claim warnings absent |
| #42 | Deferred agents-builder proposal |
| #41 | Historical held-marathon triage; no old tasks auto-started |
| #40 | Deferred optional legacy release-version validation |
| #39 | Deferred cross-repo release rollup; relate to Forge RELEASES/HQ when selected |
| #38 | Deferred alternate Sentinel design; no daemon imported |
| #36 | Carry governance exemption defect for separate triage; not silently declared fixed |
| #14 | Preserve FD-exhaustion report; existing Forge scanner is not blanket proof of all fallback cases |
| #10 | Preserve Sentinel project/history; not part of the governance installer |
| #9 | Deferred progress-counter proposal |

Preserved source license and import provenance: utils/pdda/NOTICE.md.

### Local target dispositions

Identifiers below map to the retained machine-local inventory; registry names and paths
are not published. Each disposition follows the observed managed-path state.

| Local inventory identifier | Inspection | Disposition and update route |
|---|---|---|
| Target 01 | Managed paths clean | Retain pinned; use Forge preview with retained old sync state when selected |
| Target 02 | Managed paths clean | Retain pinned; same Forge preview route |
| Target 03 | Managed paths clean | Retain pinned; same Forge preview route |
| Target 04 | Managed paths modified | Preserve local work; reconcile diff before Forge adoption |
| Target 05 | Managed paths modified | Preserve local work; reconcile diff before Forge adoption |
| Target 06 | Managed paths modified | Preserve local work; reconcile diff before Forge adoption |
| Target 07 | Managed paths modified; no .xyz | Retain governance-only use; reconcile before Forge adoption; full harness is not required |
| Target 08 | Managed paths modified | Preserve local work; reconcile diff before Forge adoption |
| Target 09 | Managed paths modified | Preserve local work; reconcile diff before Forge adoption |
| Target 10 | Runtime present; registered directory is not a Git checkout | Preserve files; resolve the stale checkout identity before any update |

These are retained installs, not a commitment to an independent PDDA product. The
old checkout/state stays available for rollback; no registry or target was mutated.
