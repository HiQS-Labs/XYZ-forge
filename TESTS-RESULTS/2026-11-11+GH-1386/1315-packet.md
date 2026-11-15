# Marathon preflight packet — gh-1315-legacy-preview-parity

- Generated: 2026-11-11T06:14:39Z
- Mode: project-doc
- Sources: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-engine-20261111/PROJECT/1-INBOX/GH-1315-LEGACY-PREVIEW-PARITY.md 
- Target root: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-engine-20261111 (development @ 3d7f5dc00)
- Suggested branch: `marathon/gh-1315-legacy-preview-parity-2026-11-11` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash test/skills-army-hq.sh`

- Artifacts: skills/3-weekly/skills-army-hq/scripts/sync.py,TESTS-RESULTS/2026-11-11+GH-1315/
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 436 LOC across 2 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.


This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-engine-20261111/PROJECT/1-INBOX/GH-1315-LEGACY-PREVIEW-PARITY.md` (its `## Acceptance` section, 3 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #1315 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] An unadopted real legacy directory is refused by preview and apply with an adoption remedy.
- [ ] Refusal creates no backup, staging retirement, or link and preserves the directory.
- [ ] Recorded-skill migration remains supported; verify in isolated fixtures only.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `skills/3-weekly/skills-army-hq/scripts/sync.py,TESTS-RESULTS/2026-11-11+GH-1315/` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash test/skills-army-hq.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1315-legacy-preview-parity RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex --round-cap 2 \
  --artifact skills/3-weekly/skills-army-hq/scripts/sync.py,TESTS-RESULTS/2026-11-11+GH-1315/ \
  --pre-advance-cmd 'bash test/skills-army-hq.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text
