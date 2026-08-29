# Marathon Phase gh-222-releases-tracking-repoint
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-GH-222-RELEASES-TRACKING-REPOINT-TURN-3-4 builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-222-releases-tracking-repoint

- Generated: 2026-08-29T04:48:39Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/PROJECT/2-WORKING/GH-222-RELEASES-TRACKING-REPOINT.md 
- Target root: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222 (marathon/gh-222-releases-tracking-repoint-2026-08-28 @ 123d92493)
- Suggested branch: `marathon/gh-222-releases-tracking-repoint-2026-08-29` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 5435 LOC across 31 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/PROJECT/2-WORKING/GH-222-RELEASES-TRACKING-REPOINT.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #222 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] Decision recorded (immutability intentional vs. mutable) in RELEASES-DB-FAQS.md.
- [ ] If mutable: `releases update --gid <g> --tracking-issue <url>` re-points with a receipt;
      `releases check` stays clean; generated views show the new tracker.
- [ ] If intentional: FAQ names the sanctioned workaround for a superseded tracker.
- [ ] Regression coverage in the releases suite either way.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/gh32-releases-app.sh,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/_setup.sh,test/lib/fixture-guard.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-222-releases-tracking-repoint RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh \
  --pre-advance-cmd 'bash validate.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text


## Debug mantra (auto-triggered — 2 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.
Last recorded reason (`marathon-system/gh-222-releases-tracking-repoint/ESCALATION.md`): `timeout-no-artifact`. Read it before re-guessing.

---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick claim MARATHON-GH-222-RELEASES-TRACKING-REPOINT-TURN-3-4 --agent agy --paths "marathon-system/gh-222-releases-tracking-repoint/RELAY.md,utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick ping MARATHON-GH-222-RELEASES-TRACKING-REPOINT-TURN-3-4 --agent agy
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick release MARATHON-GH-222-RELEASES-TRACKING-REPOINT-TURN-3-4 --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-222-releases-tracking-repoint/RELAY.md and utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick release MARATHON-GH-222-RELEASES-TRACKING-REPOINT-TURN-3-4 --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick done MARATHON-GH-222-RELEASES-TRACKING-REPOINT-TURN-3-4 --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/bin/tick
   Edit ONLY marathon-system/gh-222-releases-tracking-repoint/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
