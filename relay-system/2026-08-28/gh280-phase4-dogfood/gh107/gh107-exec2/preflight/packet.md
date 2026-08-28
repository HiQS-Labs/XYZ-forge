# Marathon preflight packet — gh-107-releases-db-read-seams

- Generated: 2026-08-28T02:22:20Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh280-dogfood/PROJECT/2-WORKING/GH-107-RELEASES-DB-READ-SEAMS.md 
- Target root: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh280-dogfood (marathon/gh-107-releases-db-read-seams-2026-08-27 @ bf2a7b6d2)
- Suggested branch: `marathon/gh-107-releases-db-read-seams-2026-08-28` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: utils/timeline/export_timeline.py,skills/10days/SKILL.md,skills/radar/SKILL.md,PARKED/2026-08-16-xyz-forge-2143.md,PARKED/2026-08-19-session-close.md,PARKED/README.md,test/gh107-timeline-json-seam.sh,test/gh103-timeline-exporter.sh,test/gh153-releases-sidebar-rollup.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1697 LOC across 16 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh103-timeline-exporter.sh,test/gh153-releases-sidebar-rollup.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh280-dogfood/PROJECT/2-WORKING/GH-107-RELEASES-DB-READ-SEAMS.md` (6 checkbox(es) found across the WHOLE document — the doc has no `## Acceptance` section, so this list may include phase checklists). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #107 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] `utils/timeline/export_timeline.py --json` prints the same `data.json` projection the
      HTML viewer uses to stdout as valid JSON, with no other stdout output (the shared query
      seam for `/radar` and `/10days`).
- [ ] `skills/10days/SKILL.md` gains a ledger cross-check step: before calling a swept issue
      valid, query `releases.db` (manifest/marathon/roadmap rows by GH number) and grep recent
      `GH-nn` commits for completion evidence. Prompt edit only — no code.
- [ ] `skills/radar/SKILL.md`'s drift lens reads the DB (`releases check`, `releases roadmap
      sync --dry-run`, the `--json` payload) instead of hand-parsing `RELEASES.md`, citing
      generation numbers in the report.
- [ ] The two older park files (`PARKED/2026-08-16-*.md`, `PARKED/2026-08-19-session-close.md`)
      carry the standup lens-8 read-only `check:` field, and the PARKED format notes the
      convention so parked-but-finished rot is machine-detectable.
- [ ] `bash test/gh107-timeline-json-seam.sh` exists and pins the `--json` seam (stdout parses
      as JSON; drift guard behavior unchanged without the flag).
- [ ] No skill writes to `releases.db` or `RELEASES.md` — read-only seams only (issue non-goal).
  human-adjudicated. The "outside-the-box" research items in the issue are explicitly out of
  scope for this lane.
  "target": { "repo": ".", "ref": "development" },
  "gate": "bash validate.sh",
  "fix_probes": [ { "type": "path_absent", "path": "test/gh107-timeline-json-seam.sh" } ],
  "artifacts": [
    "utils/timeline/export_timeline.py",
    "skills/10days/SKILL.md",
    "skills/radar/SKILL.md",
    "PARKED/2026-08-16-xyz-forge-2143.md",
    "PARKED/2026-08-19-session-close.md",
    "PARKED/README.md",
    "test/gh107-timeline-json-seam.sh"
  ],
  "artifacts_new": [ "test/gh107-timeline-json-seam.sh" ]

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/timeline/export_timeline.py,skills/10days/SKILL.md,skills/radar/SKILL.md,PARKED/2026-08-16-xyz-forge-2143.md,PARKED/2026-08-19-session-close.md,PARKED/README.md,test/gh107-timeline-json-seam.sh,test/gh103-timeline-exporter.sh,test/gh153-releases-sidebar-rollup.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/gh107-timeline-json-seam.sh,test/gh103-timeline-exporter.sh,test/gh153-releases-sidebar-rollup.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-107-releases-db-read-seams RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/timeline/export_timeline.py,skills/10days/SKILL.md,skills/radar/SKILL.md,PARKED/2026-08-16-xyz-forge-2143.md,PARKED/2026-08-19-session-close.md,PARKED/README.md,test/gh107-timeline-json-seam.sh,test/gh103-timeline-exporter.sh,test/gh153-releases-sidebar-rollup.sh,test/gh168-wave-reconcile-scope.sh,test/gh197-vendor-tier-split.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh \
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
