# Marathon preflight packet — run3-hard-ambiguous

- Generated: 2026-08-20T14:02:06Z
- Mode: project-doc
- Sources: /home/arnoldadero/marathon-target/PROJECT/2-WORKING/RUN3-HARD-AMBIGUOUS.md 
- Target root: /home/arnoldadero/marathon-target (main @ a642bbcd6)
- Suggested branch: `marathon/run3-hard-ambiguous-2026-08-20` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- **Source issue state: unknown** — preflight could not determine it; this does not block the lane.
- Gate: `npm test`

- Artifacts: src/parse.js,src/index.js,src/sort.js,test/sort.test.js,src/decimal.js,test/decimal.test.js,src/fuzzy-match.js,test/fuzzy-match.test.js,src/stats.js,test/stats.test.js
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 59 LOC across 10 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.


This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/home/arnoldadero/marathon-target/PROJECT/2-WORKING/RUN3-HARD-AMBIGUOUS.md` (0 checkbox(es) found across the WHOLE document — the doc has no `## Acceptance` section, so this list may include phase checklists). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified against the source issue — capture doc has no gh_issue — nothing to compare against. Treat this list as a summary, not a contract: if anything here is ambiguous, read the issue before building.*
(no '- [ ]' checklist found in /home/arnoldadero/marathon-target/PROJECT/2-WORKING/RUN3-HARD-AMBIGUOUS.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `src/parse.js,src/index.js,src/sort.js,test/sort.test.js,src/decimal.js,test/decimal.test.js,src/fuzzy-match.js,test/fuzzy-match.test.js,src/stats.js,test/stats.test.js` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`npm test`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=run3-hard-ambiguous RELAY_WORKTREE_ISOLATION=1 .xyz/relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact src/parse.js,src/index.js,src/sort.js,test/sort.test.js,src/decimal.js,test/decimal.test.js,src/fuzzy-match.js,test/fuzzy-match.test.js,src/stats.js,test/stats.test.js \
  --pre-advance-cmd 'npm test' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
