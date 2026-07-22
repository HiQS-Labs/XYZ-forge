# Marathon Phase p1
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-P1-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-273-marathon-closeout-automation

- Generated: 2026-07-22T02:25:57Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (development @ e9fdb0883)
- Suggested branch: `marathon/gh-273-marathon-closeout-automation-2026-07-22` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Gate: `bash validate.sh`

- Artifacts: relay-automation/hooks/skill-nudge.sh,.claude/settings.json,test/xyz-harness-hooks.sh,test/_setup.sh
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=900` (sized to ≈ 320 LOC across 4 artifact(s); a build that also edits tests needs headroom over the 300s default)
- Auto-included covering tests/helpers: test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
(no '- [ ]' checklist found in /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-273-MARATHON-CLOSEOUT-AUTOMATION.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/hooks/skill-nudge.sh,.claude/settings.json,test/xyz-harness-hooks.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/xyz-harness-hooks.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-273-marathon-closeout-automation relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/hooks/skill-nudge.sh,.claude/settings.json,test/xyz-harness-hooks.sh,test/_setup.sh \
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
1. Implement the brief by creating/editing the artifact file(s): relay-automation/hooks/skill-nudge.sh,.claude/settings.json,test/xyz-harness-hooks.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-P1-TURN --agent codex --paths "phases/p1/RELAY.md,relay-automation/hooks/skill-nudge.sh,.claude/settings.json,test/xyz-harness-hooks.sh,test/_setup.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-P1-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-P1-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/p1/RELAY.md and relay-automation/hooks/skill-nudge.sh,.claude/settings.json,test/xyz-harness-hooks.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/hooks/skill-nudge.sh,.claude/settings.json,test/xyz-harness-hooks.sh,test/_setup.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-P1-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-P1-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · codex

- Added `relay-automation/hooks/skill-nudge.sh`, a fail-open `UserPromptSubmit` hook that parses the
  event payload, matches only the Phase 0 marathon lifecycle phrase table, injects one line of
  non-blocking `additionalContext`, and supports `XYZ_NO_SKILL_NUDGE=1`.
- Added the hook to `.claude/settings.json` without changing the existing `PreToolUse` or
  `SessionStart` entries.
- Extended `test/xyz-harness-hooks.sh` with positive phrase-table cases, unrelated-prompt
  non-matches, malformed-input fail-open coverage, and opt-out coverage. `test/_setup.sh` was
  inspected as the auto-included helper and did not require changes.
- Kept parsing and JSON emission in Python's standard library so prompt text is decoded safely and
  hook output remains valid one-line JSON. No test or gate was run in-turn, per this phase's
  containment instruction; the harness owns verification after handoff.

### Round 1 · Reviewer · agy

The implementation looks solid. The `skill-nudge.sh` script correctly handles fail-open conditions and parses JSON safely via the Python standard library. The regular expressions accurately target the specified marathon lifecycle intent without false positives. `.claude/settings.json` is properly updated to invoke the hook on `UserPromptSubmit`. `test/xyz-harness-hooks.sh` effectively covers the positive, negative, and fail-open test cases.

**Verdict:** Approved
