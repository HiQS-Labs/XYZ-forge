# Marathon Phase gh158
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH158-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-158-hq-marathon-scan

- Generated: 2026-07-07T02:56:22Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-158-HQ-MARATHON-SCAN.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (main @ 104417f95)
- Suggested branch: `marathon/gh-158-hq-marathon-scan-2026-07-07` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Gate: `bash validate.sh`

- Artifacts: utils/hq/marathon-scan.sh,test/hq-marathon-scan.sh

- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=300` (sized to ≈ 0 LOC across 2 artifact(s); a build that also edits tests needs headroom over the 300s default)

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
- [ ] Running the script with no args reproduces the same aggregation the two manual passes
- [ ] Correctly classifies all five verdict states above, including Held-not-counted.
- [ ] Writes no files to any *target* repo (read-only over sleuth-app/rebalance-OS/etc.);
- [ ] Test coverage (`test/hq-marathon-scan.sh` or similar) for the classification logic

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/hq/marathon-scan.sh,test/hq-marathon-scan.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash validate.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-158-hq-marathon-scan relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/hq/marathon-scan.sh,test/hq-marathon-scan.sh \
  --pre-advance-cmd 'bash validate.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/hq/marathon-scan.sh,test/hq-marathon-scan.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH158-TURN --agent codex --paths "phases/gh158/RELAY.md,utils/hq/marathon-scan.sh,test/hq-marathon-scan.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH158-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH158-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh158/RELAY.md and utils/hq/marathon-scan.sh,test/hq-marathon-scan.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/hq/marathon-scan.sh,test/hq-marathon-scan.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH158-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH158-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh158/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
