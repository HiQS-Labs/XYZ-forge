# Marathon preflight packet — preflight-main

- Generated: 2026-11-14T00:00:00Z
- Mode: project-doc
- Sources: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1479-static-analysis-swarm-2026-11-14/temp/gh1479/preflight-main.md 
- Target root: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1479-static-analysis-swarm-2026-11-14 (feat/XYZ-forge-gh1479-static-analysis-swarm-2026-11-14 @ 5967bde25)
- Suggested branch: `marathon/preflight-main-2026-11-14` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `python3 -c "print('gate-ok')"`

- Artifacts: utils/py/swarm_preflight.py,test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-acceptance-fidelity.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/test_python_layer.py,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1942 LOC across 14 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-acceptance-fidelity.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/test_python_layer.py,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1479-static-analysis-swarm-2026-11-14/temp/gh1479/preflight-main.md` (its `## Acceptance` section, 0 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #1479](https://github.com/HiQS-Labs/XYZ-forge/issues/1479) — 0/0 criteria copied verbatim from issue #1479.*
(no '- [ ]' checklist found in /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh1479-static-analysis-swarm-2026-11-14/temp/gh1479/preflight-main.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/swarm_preflight.py,test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-acceptance-fidelity.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/test_python_layer.py,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `python3 -c "print('gate-ok')"`, and NOT `test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-acceptance-fidelity.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=preflight-main RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex --round-cap 1 \
  --artifact utils/py/swarm_preflight.py,test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-acceptance-fidelity.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/test_python_layer.py,test/_setup.sh \
  --pre-advance-cmd 'python3 -c "print('gate-ok')"' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text
