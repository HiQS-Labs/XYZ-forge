# Marathon preflight packet — gh-222-releases-tracking-repoint

- Generated: 2026-08-29T03:45:38Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222/PROJECT/2-WORKING/GH-222-RELEASES-TRACKING-REPOINT.md 
- Target root: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh222 (development @ b471df15a)
- Suggested branch: `marathon/gh-222-releases-tracking-repoint-2026-08-29` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: utils/py/releases_app.py,test/gh32-releases-app.sh,RELEASES-DB-FAQS.md,test/gh103-timeline-exporter.sh,test/gh105-vendor-releases-addon.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh238-hq-releases-mode.sh,test/gh239-hq-status-releases-mode.sh,test/gh257-roadmap-ledger-fixes.sh,test/gh267-express-skill.sh,test/gh280-jog-marathon-adapter.sh,test/gh290-ate-variation-grid.sh,test/gh32-release-target-advisory.sh,test/gh32-releases-artifacts.sh,test/gh39-releases-project-sync.sh,test/gh53-releases-merge-resolve.sh,test/gh54-merged-dump-refusals.sh,test/gh57-live-merge-resolve.sh,test/gh57-releases-fuzz.sh,test/gh69-roadmap-shadow.sh,test/gh75-dashboard.sh,test/jog-queue.sh,test/wave-reconcile.sh,test/xyz-vendor.sh,test/baselines/GH-32-negative-control.md,test/baselines/GH-52-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 5420 LOC across 31 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
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
