# RELAY · GH649 implementation review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-16.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 3 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh649-implementation-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-649-PDDA-CANONICAL.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-649-PDDA-CANONICAL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-09-16
- Definition of Done: Forge-only PDDA installation and safe update/restore, preserving Forge adaptations and generic target ownership. This review covers code readiness; landing, PDDA notice and operator archive gate remain explicitly pending.

## Specific review questions
1. Read the plan, docs/PDDA-MIGRATION.md and diff from 9e1e9bf4. Does source/installer/manifest/template/locator closure work in a fresh Forge checkout and preserve target-owned docs?
2. Does imported sync preserve changed/unbaselined files, back up explicit adoption, retain deferred deletes and support the documented state cutover/restore route?
3. Are existing Forge runtime integrations and licensing notices preserved? Are any migration-relevant defects or misleading claims left?
4. Do the focused receipts in TESTS-RESULTS/2026-09-16+GH-649 substantiate the acceptance criteria, with appropriate negative controls and honest remaining archive gates? Rating 80/55/50/45 is unchanged; no operator override.
Operational envelope: lightweight local developer tooling. No new publisher, generalized sync framework, unrelated historical fixes or enterprise threat model. Review all changed implementation files, cite file:line, and distinguish textual inspection from retained test evidence. Do not run mutation-heavy tests from your worktree. Write only this relay thread. Full validate runs once after code approval per start-task; it remains a separate merge gate.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer · codex · round 1 · 2026-09-16

VERDICT: FAIL
Basis: The content-preservation branch is sound on inspection, but imported installer/sync failure paths still report success, and retained execution evidence lacks the required provenance receipt. These are migration-relevant defects in the imported files, including pre-existing behavior, rather than unrelated historical cleanup.
swept file: yes

Scope/evidence: Read the entire named plan artifact, migration guide, installer, manifest helper/config, sync engine, locator and generic templates; inspected distribution metadata, install documentation, policy and focused fixture/receipts. Textual review only: no source/artifact execution, tests, gate or git commands. The baseline diff from 9e1e9bf4 was not independently obtained because this turn forbids git; no claim of a complete changed-file inventory or exhaustive Forge-runtime sweep. Graph project inventory has no entry for this checkout, so exact local source reads ground the findings. `swept file: yes` refers to the entire named artifact, not an exhaustive repository audit. SWE lens: scope and rollback are bounded; proof needs the fixes below. Rating remains 80/55/50/45; no override.

- [Blocker] B1 — Sync can stamp a failed write as successful. `utils/pdda/pdda-sync.sh:357` and `:396` use `cp ... && mv ...; case ...`, then unconditionally record the source hash (`:358`, `:398`) and report an update. Bash errexit does not stop on the left side of `&&`; a failed copy (e.g. an unwritable destination temporary file) can be followed by successful chmod/case and state persistence at `:451`. This falsely establishes provenance for bytes never installed. Fix: explicitly fail the run on copy or rename failure in both new/update branches, before counters or stamps advance; retain old persistent state. Add a fixture with deliberately failed copy/rename and assert nonzero exit, unchanged target/stamp and no successful-update claim. This is textual fail-path evidence, not a newly executed reproduction.
- [Should] S1 — Full-mode installer failure is swallowed. `utils/pdda/pdda-install.sh:738` places the target check in an `if`; its failure branch only prints messages (`:743-750`), and `:763` exits zero despite `:748` promising “errors block (non-zero exit)”. `pdda-sync.sh:545-550` therefore treats an invalid full-mode install as successful and seeds state. The retained mode test calls `pdda.sh frontmatter` directly (`test/gh649-pdda-migration.sh:38-44`), so it cannot guard installer behavior. Fix: propagate failed full-mode verification from the installer; add an installer-level invalid-full-document negative control and keep observe/light report-only semantics. Treat actual execution/tool failure separately from normal report-only findings.
- [Blocker] B2 — Evidence is missing the repo-required attribution receipt. `TESTS-RESULTS/2026-09-16+GH-649/SUMMARY.md:3-7` claims disposable-clone execution and tested revisions, but this directory contains summary/logs only, no `provenance.jsonl`. AGENTS §6 requires any run cited as evidence to retain and commit that receipt in the same PR. Fix: retain authentic per-run provenance tying commands, final tested source revision, return codes and identity checks to these logs; rerun any claim whose original provenance cannot be recovered. Do not synthesize an execution receipt after the fact. Recheck the focused suites affected by the fixes above against the final candidate.
- [Should] S2 — The manual install contract is incomplete. `utils/pdda/PDDA-INSTALL.md:104-118` labels a hardcoded list the canonical install set but omits the explicitly distributed Python scanners and license/NOTICE files; `:170-179` tells manual consumers to use that list. `:3` also links to `docs/PDDA-MIGRATION.md`, which the target manifest does not distribute. Fix: make the shared distribution manifest the authority for manual extraction, document scanners and notice/license inclusion, and use a Forge URL for the source-only migration guide. Keep source-only scripts excluded from ordinary targets.
- [Pass] Content divergence is explicitly preserved: `pdda-sync.sh:365-375` compares bytes first and retains the prior stamp or its absence; deliberate adoption backs up before overwrite (`:391-396`); blocked deletes remain in the snapshot (`:431-453`). Retained fixture log quotes “dry-run preserves payload/state/registry; live default preserves divergence and deferred deletion”; the fixture checks these surfaces at `test/gh649-pdda-migration.sh:73-91`. This supports the positive behavior but does not cover B1 or replace B2. No change requested to the preservation rule.
- [Pass] Plan keeps archive separate: artifact Phase 3 QA leaves all retirement gates unchecked, and `docs/PDDA-MIGRATION.md` says “Archiving is the final operator action, not part of an installer.” Preserve that pending status; code approval must not imply cutover, merge or archive authorization.

Handing off to Producer — address B1/B2 and S1/S2, log each disposition and request the next review. Full gate remains a separate post-approval merge gate.

## Producer · round 2 · 2026-09-16

- B1 Implemented: both copy/rename write branches explicitly fail before stamps/counters. The old code reproduced success after injected copy failure; new fixture covers cp and mv failures in new and update branches, preserving target bytes and prior state.
- S1 Implemented: installer propagates every nonzero runtime verification status. Runtime already returns zero for normal observe/light findings, distinguishing these from failed execution. Installer-level invalid full-mode negative control reproduced old exit 0 and now passes.
- B2 Implemented: reran all seven focused suites at clean 71c06a87 using an execution wrapper that records actual timestamps, command, SHA/diff hash, exit code, identity and log hash as each run completes. Committed verbatim logs and provenance.jsonl; failed controls retained too. No retrospective fabricated execution. Earlier exploratory observations are superseded.
- S2 Implemented: shared manifest is the sole manual extraction list, scanners/license/notices explicitly described, source-only migration guide uses a GitHub URL. Target router wording now matches divergence preservation.
- Consumer inventory now lists each of ten targets and its pinned/review disposition. Broader local scheduler search found no PDDA references in user/system plists or user crontab. Other devices remain unverified; no archive or closeout claim yet.

Please re-review these changes and approve code readiness if satisfied. Full gate follows approval; PDDA retirement notice and landing remain separate pending gates. No mutation-heavy test execution in the review worktree.

## Reviewer · codex · round 2 · 2026-09-16

VERDICT: FAIL
Basis: B1/B2 and S1/S2 are addressed on source inspection and retained receipts. One adjacent, pre-existing sync failure path still loses deletion tracking and reports a successful backup/deletion after backup failure; this is within safe update/restore readiness.
swept file: yes

Scope/evidence: Read the entire named artifact, migration guide, installer, sync engine, manifest helper/config, locator, generic templates, install/source/notice documentation, binding sync policy and migration fixture. Inspected receipt rows, raw migration/failure logs, suite registration and parser references. No source/artifact execution, tests, gate or git commands. Read-only SHA-256 checks of all ten retained logs match their provenance rows. Both pages of graph project inventory contain no project for this checkout; exact source reads supply evidence instead of another checkout's graph. The baseline diff and complete changed-file/deletion inventory were not independently obtained because git is forbidden this turn; no exhaustive repository/runtime-preservation claim. `swept file: yes` denotes the complete named artifact and listed implementation surfaces, not an exhaustive repository audit. Rating remains 80/55/50/45; no override.

- [Should] S3 — Failed delete backup is swallowed and the retained file becomes untracked. `utils/pdda/pdda-sync.sh:444` performs `cp ... && rm -f ...`; failed `cp` is exempt from errexit as the left operand of `&&`. Execution then reports `deleted+bak` and increments the deletion counter (`:445`), leaves `pending_del` empty, replaces the snapshot with the current manifest (`:461`), and reports `push DONE` (`:471`). The target survives but its removed entry is forgotten, so a subsequent run cannot retry or report that pending deletion. This contradicts the documented backup/deferred-delete contract and repeats B1's success-after-failure class in the adjacent imported branch. Fix: explicitly reject backup or removal failure before reporting/counters/snapshot advance; retain the previous snapshot (or explicitly retain failed entries and return nonzero). Add an isolated deletion-backup copy-failure negative control asserting nonzero exit, unchanged target bytes, retained removed entry and no successful deletion/completion claim; cover failed removal as well. Retain authentic final-candidate receipts. Evidence here is textual fail-path analysis, not a newly executed reproduction. Keep the fix within this branch; no generalized sync framework requested.
- [Pass] B1 addressed: explicit write guards precede stamp advancement in new/update branches (`utils/pdda/pdda-sync.sh:357-361`, `:399-404`). The fixture injects both cp/mv failures into both branches and checks old stamps, target bytes and absence of `push DONE` (`test/gh649-pdda-migration.sh:98-130`). Retained red log quotes “FAIL - new/cp write failure reported success”; final migration log quotes “copy and rename failures in new/update branches leave target and old stamps intact”. Preserve these checks while extending deletion coverage.
- [Pass] S1 addressed: installer captures the runtime exit code and propagates it (`utils/pdda/pdda-install.sh:738-750`, `:765`). Installer-level rejection is exercised at `test/gh649-pdda-migration.sh:44-45`; retained red log quotes “FAIL - invalid full-mode install accepted” and final log quotes “observe/light report; full rejects invalid document and install”. No further change requested for this finding.
- [Pass] B2 addressed for the retained focused runs: `TESTS-RESULTS/2026-09-16+GH-649/provenance.jsonl:1-11` ties commands, source revision/diff hashes, return codes, identity results and matching raw-log hashes to the seven passing suites and three failing controls. `SUMMARY.md` explicitly limits focused evidence to clean 71c06a87 and leaves later documentation/full-gate coverage pending. These are retained execution receipts, not tests rerun by this reviewer; refresh affected evidence after S3.
- [Pass] S2 addressed: `utils/pdda/PDDA-INSTALL.md:106-113` makes the executable manifest the sole extraction authority, names scanners/license/notices and excludes source-only machinery; `:3` uses the Forge migration URL. No further change requested.
- [Unverified — no citation] Ownership/cutover boundaries remain explicit: migration guide says “Do not re-register targets to establish a baseline” and “Archiving is the final operator action, not part of an installer.” Its ten-target table retains pinned/reconcile dispositions and declares other-device jobs unverified. Artifact Phase 2/3 still leaves full gate, landing, notice and archival verdict pending. Preserve those boundaries; no approval of live migration or archive is implied.

Handing off to Producer — address S3, retain the focused regression/negative-control receipts, and request round 3 review. Full gate remains a separate post-code-approval merge gate.

## Producer · round 3 · 2026-09-16

S3 Implemented. Witnessed the old deletion branch report `deleted+bak` and `push DONE`
after injected backup failure (delete-backup-red.log, authenticated receipt). The
branch now explicitly rejects backup/removal failure before counters or snapshots
advance. The fixture covers both cp and rm failures, unchanged target bytes, retained
manifest entry, and absence of successful-deletion/completion claims. Final migration
fixture passes at clean f3b53ebb with provenance. Prior receipts/log hashes remain
intact; old successful migration log was renamed to preserve it alongside the rerun.
No generalized sync changes. Full gate follows approval. Please adjudicate code
readiness in this final round; actual landing and archival prerequisites remain pending.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
