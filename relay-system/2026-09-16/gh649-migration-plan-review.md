# RELAY · GH649 migration plan review
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-16.
-->

NEXT: Producer
STATUS: Open
ROUND: 1 / 3

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
6. **Commit only the relay file** (`relay(gh649-migration-plan-review): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **.relay-artifacts/GH-649-PDDA-CANONICAL.md** — the read-only path that
  `relay-drive.sh --artifact-file PROJECT/2-WORKING/GH-649-PDDA-CANONICAL.md` seeds into the isolated worktree (read it there; do NOT edit it).
- Reviewer: codex   ·   Producer: claude-a
- Started: 2026-09-16
- Definition of Done: A minimal, executable ownership migration preserving Forge runtime improvements, generic target templates, existing consumers and explicit archival prerequisites. Scope is lightweight local developer tooling; no enterprise framework.

## Specific review questions
1. Does the plan cover the actual installer/manifest/template/locator closure without copying Forge governance into targets?
2. Are unique upstream and Forge behaviors preserved, and are old/new sync writers and rollback addressed?
3. Is any acceptance criterion missing for safe retirement, or any unnecessary component proposed?
4. Are the test scope, rating and license-pending gate honest and proportionate?
Read the committed plan and the cited source files; upstream snapshot is available read-only at the sibling pdda checkout if needed. No tests or implementation edits in this review. Output file:line findings and textual-only basis. Do not require unrelated historical PDDA bugs to be fixed unless migration introduces or depends on them.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

## Reviewer — codex — round 1 — 2026-09-16

VERDICT: FAIL
Basis: Ownership consolidation and the narrow reuse approach are sound, but the target contract boundary and first sync after moving source-local state are not executable enough to meet the preservation Definition of Done. Textual review only; no tests, implementation, artifact edits or git commands run.
swept file: yes

- [Should] **Generic contract closure:** `.relay-artifacts/GH-649-PDDA-CANONICAL.md:64-66` maps generic startup templates but leaves the manifest shipping Forge's `PROJECT/PDDA.md` verbatim. Upstream `utils/pdda/pdda-sync-manifest.conf:17-18` includes that path; Forge `PROJECT/PDDA.md:627-628` says RELEASES.md is retired “in this repository” for releases.db/release tooling. This becomes misleading governance in an ordinary target. **Fix:** explicitly choose one generic distributable PDDA contract and keep Forge-only adoption notes outside its managed payload (or name a minimal source-to-target mapping shared by install and sync). Add a fixture assertion that installed contract/startup docs contain no Forge-only retirement/authority rules and all named executable paths resolve. Review imported AGENTS wording too: upstream `AGENTS.md` calls its recipient “the standalone PDDA source-of-truth repo”; targets are leaf consumers.
- [Should] **Source-state cutover and rollback proof:** `.relay-artifacts/GH-649-PDDA-CANONICAL.md:56,78,90` retains backups and says not to empty old state, but does not choose how old state reaches the replacement writer. Upstream `utils/pdda/pdda-sync.sh:27-32` puts hashes, manifest snapshots, backups and lock under the source checkout's temp directory; relocation changes that directory. With no previous stamp, `:359-373` replaces unequal target content without the divergence backup branch; re-registering first installs and then seeds state (`:204-218`), so it is not a preservation migration. **Fix:** specify stop/quiesce old writers before the first replacement write, snapshot payload + registry + per-target hashes/manifests/backups, and explicitly reuse/migrate the old state or block unbaselined targets pending reviewed adoption. Add one isolated old-source→Forge fixture with a locally modified managed file and a removed manifest entry; require preservation or explicit reviewed disposition, retained deletion tracking, dry-run leaving target/state unchanged, and rollback restoring payload plus state before resuming exactly one writer. Make this fixture a cutover prerequisite; “fix or contain #59” alone does not choose a safe route.
- [Pass] **Runtime preservation and modest scope:** `.relay-artifacts/GH-649-PDDA-CANONICAL.md:51-56,64-65` explicitly retains Forge checks/scanners, leaves root install.sh intact, and rejects a child publisher/framework. The upstream changelog improvement is concrete: PDDA `utils/pdda/pdda.sh:405-406` handles unbracketed version headings and extracts the trailing date; Forge `utils/pdda/pdda.sh:425-426` still uses the older expressions. Keep the proposed targeted port and focused regression coverage.
- [Pass] **Honest evidence and retirement boundary:** `.relay-artifacts/GH-649-PDDA-CANONICAL.md:58,60,79,90-99` marks license confirmation pending, separates historical incidents from an unknown recent trend, requires disposable-clone validation and committed provenance, inventories consumers/backlog, and reserves archive mode for the operator. Keep these gates; this review does not establish license approval, consumer inventory completeness or passing tests.
- [Nit] `.relay-artifacts/GH-649-PDDA-CANONICAL.md:60` gives four unlabeled rating numbers. **Fix:** label the four dimensions so the rating can be read without consulting issue history.

Whole artifact reviewed, including recon, all three phases and follow-up lanes. The source sweep found the pre-existing generic-payload wording and missing-stamp sync behavior above because the migration depends on them; no unrelated historical defect is requested for repair. Graph project XYZ-forge is a different checkout with generation 2026-09-01T15:54:30Z; coverage metadata is stale for relevant paths, so direct source reads supplied the textual evidence. No exhaustive upstream/runtime parity claim.

Handing off to producer — address both Should findings, log each disposition, and reopen the next review round.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
