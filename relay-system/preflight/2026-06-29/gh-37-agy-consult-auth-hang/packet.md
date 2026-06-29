# Marathon preflight packet — gh-37-agy-consult-auth-hang

- Generated: 2026-06-29T22:33:40Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-37-AGY-CONSULT-AUTH-HANG.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (main @ 2ae0584eb)
- Verdict: ready
- Gate: `bash validate.sh`
- Artifacts: relay-automation/consult.sh,relay-automation/agy-turn.sh
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=300` (artifacts ≈ 335 LOC; large files need more than the 300s default)

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
- [ ] Fast pre-flight auth probe (e.g. a short-timeout `agy whoami`/token check) in the agy shim /
- [ ] Alternatively force non-interactive failure so an expired token exits non-zero immediately.
- [ ] Document the `agy login` re-auth step where the agy harness is described.
- [ ] Re-verify: valid auth → agy lane answers; expired auth → consult degrades fast with the real cause.
- [ ] `bash validate.sh` green; Codex lane behavior unchanged.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/consult.sh,relay-automation/agy-turn.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash validate.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/consult.sh,relay-automation/agy-turn.sh \
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
