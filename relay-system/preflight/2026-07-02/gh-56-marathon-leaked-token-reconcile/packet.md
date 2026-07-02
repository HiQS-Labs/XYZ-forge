# Marathon preflight packet — gh-56-marathon-leaked-token-reconcile

- Generated: 2026-07-02T18:46:07Z
- Mode: project-doc
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/1-INBOX/GH-56-MARATHON-LEAKED-TOKEN-RECONCILE.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (marathon/gh-56-leaked-token-2026-07-02 @ 424bff271)
- Suggested branch: `marathon/gh-56-marathon-leaked-token-reconcile-2026-07-02` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Gate: `bash test/marathon-drive.sh`
- Artifacts: relay-automation/marathon-drive.sh,test/marathon-drive.sh
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=900` (sized to ≈ 672 LOC across 2 artifact(s); a build that also edits tests needs headroom over the 300s default)

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
- [ ] Re-running the same phase-id after an aborted run seeds cleanly (no `task ... is open`) — either by reconciling/terminating the leftover `open`/handoff token before `task.created`, or by deriving a fresh per-attempt token id.
- [ ] A live claim of the same token is NEVER reaped (mirror GH-43's epoch-safe, never-reap-a-live-claim guard).
- [ ] The change carries a `GH-56` marker comment at the reconcile/fresh-id site in `relay-automation/marathon-drive.sh`.
- [ ] A regression case is added to `test/marathon-drive.sh` that reproduces the leaked-token collision (seed a token, leave it open/handed-off, re-seed the same phase-id) and asserts the clean re-seed; it fails without the fix and passes with it.
- [ ] `bash test/marathon-drive.sh` passes; no edit outside `relay-automation/marathon-drive.sh` + `test/marathon-drive.sh`.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/marathon-drive.sh,test/marathon-drive.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash test/marathon-drive.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-56-marathon-leaked-token-reconcile relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/marathon-drive.sh,test/marathon-drive.sh \
  --pre-advance-cmd 'bash test/marathon-drive.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
