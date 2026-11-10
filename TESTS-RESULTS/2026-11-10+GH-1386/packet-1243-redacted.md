# Marathon preflight packet — gh-1243-consult-answer-payload

- Generated: 2026-11-10T05:31:13Z
- Mode: project-doc
- Sources: <local-root>/PROJECT/1-INBOX/GH-1243-CONSULT-ANSWER-PAYLOAD.md
- Target root: <local-root>/temp/b-jog-transition-gate-b7urqpag/repo (development @ bb7cff2b6)
- Suggested branch: `marathon/gh-1243-consult-answer-payload-2026-11-10` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- **Source issue state: unknown** — preflight could not determine it; this does not block the lane.
- Gate: `bash validate.sh --auto development`

- Artifacts: utils/py/consult.py,TESTS-RESULTS/2026-11-10+GH-1243/manual.md,TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1116 LOC across 6 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `<local-root>/PROJECT/1-INBOX/GH-1243-CONSULT-ANSWER-PAYLOAD.md` (its `## Acceptance` section, 5 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified against the source issue — could not fetch issue #1243 (gh missing, unauthenticated, or offline) — acceptance fidelity NOT verified. Treat this list as a summary, not a contract: if anything here is ambiguous, read the issue before building.*
- [ ] Re-running a small Codex + agy consult gives neutral payloads of comparable shape and size: answer text only, with no exec logs, prompt echo or token footer.
- [ ] A Codex answer that cites file:line next to its `[Pass]` lines is not stamped. An answer with an uncited `[Pass]` still is.
- [ ] Verified per GH-831 with existing suites (`test/consult.sh`) plus a manual TESTS-RESULTS receipt. No new suites.
- [ ] Preserve baseline failure and final passing evidence in the declared manual/provenance artifacts; use existing checks only.
- [ ] Do not install or publish anything, change versions or release tags, add dependencies, create new test suites, or modify unrelated paths.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/consult.py,TESTS-RESULTS/2026-11-10+GH-1243/manual.md,TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh --auto development`, and NOT `test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1243-consult-answer-payload RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/consult.py,TESTS-RESULTS/2026-11-10+GH-1243/manual.md,TESTS-RESULTS/2026-11-10+GH-1243/provenance.jsonl,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh \
  --target-root <local-root>/temp/b-jog-transition-gate-b7urqpag/repo \
  --pre-advance-cmd 'bash validate.sh --auto development' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text
