# Marathon Phase gh273-phase1
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH273-PHASE1-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-273-marathon-closeout-automation

- Generated: 2026-07-22T02:55:52Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (development @ 6f74d5ded)
- Suggested branch: `marathon/gh-273-marathon-closeout-automation-2026-07-22` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Gate: `bash validate.sh`

- Artifacts: .claude/commands/pre-marathon.md,.claude/commands/post-marathon.md
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=300` (sized to ≈ 0 LOC across 2 artifact(s); a build that also edits tests needs headroom over the 300s default)


This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
(no '- [ ]' checklist found in /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `.claude/commands/pre-marathon.md,.claude/commands/post-marathon.md` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash validate.sh`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-273-marathon-closeout-automation relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact .claude/commands/pre-marathon.md,.claude/commands/post-marathon.md \
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
1. Implement the brief by creating/editing the artifact file(s): .claude/commands/pre-marathon.md,.claude/commands/post-marathon.md
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH273-PHASE1-TURN --agent codex --paths "phases/gh273-phase1/RELAY.md,.claude/commands/pre-marathon.md,.claude/commands/post-marathon.md"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH273-PHASE1-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH273-PHASE1-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh273-phase1/RELAY.md and .claude/commands/pre-marathon.md,.claude/commands/post-marathon.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: .claude/commands/pre-marathon.md,.claude/commands/post-marathon.md.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH273-PHASE1-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH273-PHASE1-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh273-phase1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

- Created `.claude/commands/pre-marathon.md` as a thin `marathon-triage` wrapper: it preserves the
  skill's read-only/no-fire boundary, reports stale `PROJECT/2-WORKING` and `phases/*/` artifacts,
  dry-runs every ready plan, and requires explicit confirmation of the exact execution order before
  firing.
- Created `.claude/commands/post-marathon.md` with the contracted closeout order: reviewed complete
  commit/push, PR notes, green-only merge, return to updated `development`, resolved-issue closure,
  evidence-gated doc archival, full PDDA sweep, then `/loose-ends`.
- Key decision: stale cleanup and evidence-sensitive closeout actions are report-first so neither
  command silently deletes, archives, merges, or closes ambiguous work.
- Targeted verification: file-presence and contract-marker assertions for both command bodies passed;
  the full project gate was intentionally left to the harness as required by the phase brief.
