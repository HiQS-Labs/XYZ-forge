# Marathon preflight packet — gh-1171-branch-artifact-preflight

- Generated: 2026-11-11T06:14:16Z
- Mode: project-doc
- Sources: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-engine-20261111/PROJECT/1-INBOX/GH-1171-BRANCH-ARTIFACT-PREFLIGHT.md 
- Target root: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-engine-20261111 (development @ 3d7f5dc00)
- Suggested branch: `marathon/gh-1171-branch-artifact-preflight-2026-11-11` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash test/gh376-relay-drive-lock-parity.sh`

- Artifacts: utils/py/relay_drive.py,TESTS-RESULTS/2026-11-11+GH-1171/,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1181 LOC across 17 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-engine-20261111/PROJECT/1-INBOX/GH-1171-BRANCH-ARTIFACT-PREFLIGHT.md` (its `## Acceptance` section, 3 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #1171](https://github.com/HiQS-Labs/XYZ-forge/issues/1171) — 0 issue criteria reconciled: 3 deviation(s) declared and accounted for.*
- [ ] An existing slash-containing local branch on Artifact under review passes preflight.
- [ ] A genuinely missing docs/gh1171-missing.md still fails with the existing diagnostic.
- [ ] Record manual regression controls with provenance; no new suite or gate.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/relay_drive.py,TESTS-RESULTS/2026-11-11+GH-1171/,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash test/gh376-relay-drive-lock-parity.sh`, and NOT `test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1171-branch-artifact-preflight RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex --round-cap 2 \
  --artifact utils/py/relay_drive.py,TESTS-RESULTS/2026-11-11+GH-1171/,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh \
  --pre-advance-cmd 'bash test/gh376-relay-drive-lock-parity.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text
