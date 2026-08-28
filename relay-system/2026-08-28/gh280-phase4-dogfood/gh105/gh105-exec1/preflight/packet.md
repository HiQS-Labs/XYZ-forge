# Marathon preflight packet — gh-105-vendor-releases-addon

- Generated: 2026-08-28T03:42:16Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh280-dogfood/PROJECT/2-WORKING/GH-105-VENDOR-RELEASES-ADDON.md 
- Target root: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh280-dogfood (development @ 4751d3ce4)
- Suggested branch: `marathon/gh-105-vendor-releases-addon-2026-08-28` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: relay-automation/xyz-vendor.sh,relay-automation/xyz-sync.sh,RELEASES-DB-FAQS.md,test/find-harness.sh,test/gh105-vendor-releases-addon.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/write-ops-log.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/baselines/GH-52-negative-control.md,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1657 LOC across 13 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/write-ops-log.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/baselines/GH-52-negative-control.md,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh280-dogfood/PROJECT/2-WORKING/GH-105-VENDOR-RELEASES-ADDON.md` (6 checkbox(es) found across the WHOLE document — the doc has no `## Acceptance` section, so this list may include phase checklists). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #105 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] `bash relay-automation/xyz-vendor.sh materialize` (or the documented invocation) ships
      `utils/py/releases_app.py`, `utils/releases-merge-resolve.sh`, `RELEASES-DB-FAQS.md`,
      and `utils/timeline/` (exporter + `RELEASES.html`) into the vendored `.xyz/` payload.
- [ ] Target-repo ledger state stays at the target root; any `.xyz/`-resident runtime state
      the subsystem creates is on the GH-312 preserve list so `xyz-sync.sh update` preserves it.
- [ ] `RELEASES-DB-FAQS.md` (or the payload docs) carry a short "enable the RELEASES ledger"
      recipe (`releases init`, optional `RELEASES.md` authoring); nothing runs until invoked.
- [ ] `test/find-harness.sh` (or the equivalent discovery surface) names the vendored RELEASES
      add-on with a one-line pointer.
- [ ] `bash test/gh105-vendor-releases-addon.sh` exists and pins the payload (a vendored
      fixture contains the RELEASES files; a sync/update round-trip preserves target ledger
      state).
- [ ] Existing vendored installs without ledger state behave exactly as before (zero behavior
      until `releases init`).

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/xyz-vendor.sh,relay-automation/xyz-sync.sh,RELEASES-DB-FAQS.md,test/find-harness.sh,test/gh105-vendor-releases-addon.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/write-ops-log.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/baselines/GH-52-negative-control.md,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/find-harness.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/write-ops-log.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-105-vendor-releases-addon RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/xyz-vendor.sh,relay-automation/xyz-sync.sh,RELEASES-DB-FAQS.md,test/find-harness.sh,test/gh105-vendor-releases-addon.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/write-ops-log.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/baselines/GH-52-negative-control.md,test/_setup.sh \
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
