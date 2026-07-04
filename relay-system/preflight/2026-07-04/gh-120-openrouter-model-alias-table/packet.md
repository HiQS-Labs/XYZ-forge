# Marathon preflight packet — gh-120-openrouter-model-alias-table

- Generated: 2026-07-04T03:41:06Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-120-OPENROUTER-MODEL-ALIAS-TABLE.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (main @ e8dd88fd7)
- Suggested branch: `marathon/gh-120-openrouter-model-alias-table-2026-07-04` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Gate: `bash test/model-alias.sh`
- Artifacts: relay-automation/openrouter-model-aliases.yml,test/model-alias.sh
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=300` (sized to ≈ 20 LOC across 2 artifact(s); a build that also edits tests needs headroom over the 300s default)

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
(no '- [ ]' checklist found in /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-120-OPENROUTER-MODEL-ALIAS-TABLE.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/openrouter-model-aliases.yml,test/model-alias.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash test/model-alias.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-120-openrouter-model-alias-table relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/openrouter-model-aliases.yml,test/model-alias.sh \
  --pre-advance-cmd 'bash test/model-alias.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
