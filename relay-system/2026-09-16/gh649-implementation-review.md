# RELAY · GH649 implementation review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-16.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 2 / 3

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

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
