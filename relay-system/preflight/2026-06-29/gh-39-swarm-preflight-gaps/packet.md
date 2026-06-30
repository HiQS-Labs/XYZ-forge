# Marathon preflight packet — gh-39-swarm-preflight-gaps

- Generated: 2026-06-29T00:25:43Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-39-SWARM-PREFLIGHT-GAPS.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (main @ de2b5ce76)
- Verdict: ready
- Gate: `bash validate.sh`
- Artifacts: utils/swarm-preflight.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Suggested marathon-drive.sh invocation

```bash
relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/swarm-preflight.sh \
  --target-root . \
  --pre-advance-cmd 'bash validate.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
