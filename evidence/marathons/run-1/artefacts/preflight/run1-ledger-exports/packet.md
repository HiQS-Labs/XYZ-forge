# Marathon preflight packet — run1-ledger-exports

- Generated: 2026-08-20T13:13:23Z
- Mode: project-doc
- Sources: /home/arnoldadero/marathon-target/PROJECT/2-WORKING/RUN1-LEDGER-EXPORTS.md 
- Target root: /home/arnoldadero/marathon-target (main @ 599e87f63)
- Suggested branch: `marathon/run1-ledger-exports-2026-08-20` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- **Source issue state: unknown** — preflight could not determine it; this does not block the lane.
- Gate: `npm test`

- Artifacts: src/parse.js,src/validate.js,src/index.js,package.json,src/export-csv.js,test/export-csv.test.js,src/fx.js,test/fx.test.js,src/cli.js,test/cli.test.js,src/dedupe.js,test/dedupe.test.js
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 111 LOC across 12 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.


This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/home/arnoldadero/marathon-target/PROJECT/2-WORKING/RUN1-LEDGER-EXPORTS.md` (0 checkbox(es) found across the WHOLE document — the doc has no `## Acceptance` section, so this list may include phase checklists). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified against the source issue — capture doc has no gh_issue — nothing to compare against. Treat this list as a summary, not a contract: if anything here is ambiguous, read the issue before building.*
(no '- [ ]' checklist found in /home/arnoldadero/marathon-target/PROJECT/2-WORKING/RUN1-LEDGER-EXPORTS.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `src/parse.js,src/validate.js,src/index.js,package.json,src/export-csv.js,test/export-csv.test.js,src/fx.js,test/fx.test.js,src/cli.js,test/cli.test.js,src/dedupe.js,test/dedupe.test.js` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`npm test`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=run1-ledger-exports RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact src/parse.js,src/validate.js,src/index.js,package.json,src/export-csv.js,test/export-csv.test.js,src/fx.js,test/fx.test.js,src/cli.js,test/cli.test.js,src/dedupe.js,test/dedupe.test.js \
  --target-root /home/arnoldadero/marathon-target \
  --pre-advance-cmd 'npm test' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
