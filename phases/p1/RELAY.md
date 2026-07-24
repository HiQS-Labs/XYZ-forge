# Marathon Phase p1
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-P1-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-279-aider-qwen-marathon-trial-findings

- Generated: 2026-07-24T00:16:14Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-279-AIDER-QWEN-MARATHON-TRIAL-FINDINGS.md 
- Target root: /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm (gh-296-relay-drive-tick-eperm @ be935a881)
- Suggested branch: `marathon/gh-279-aider-qwen-marathon-trial-findings-2026-07-24` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Gate: `bash validate.sh`

- Artifacts: relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,relay-automation/aider-turn.sh,utils/py/aider-turn.py,test/marathon-drive.sh,test/aider-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/lane-attempt-cap.sh,test/marathon-root-audit.sh,test/marathon.sh,test/relay-xyz-skill-guard.sh,test/sentinel-driver-hooks.sh,test/test_python_layer.py,test/xyz-harness-hooks.sh,test/_setup.sh
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=900` (sized to ≈ 3827 LOC across 16 artifact(s); a build that also edits tests needs headroom over the 300s default)
- Auto-included covering tests/helpers: test/debug-mantra.sh,test/driver-lock.sh,test/lane-attempt-cap.sh,test/marathon-root-audit.sh,test/marathon.sh,test/relay-xyz-skill-guard.sh,test/sentinel-driver-hooks.sh,test/test_python_layer.py,test/xyz-harness-hooks.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
(no '- [ ]' checklist found in /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-279-AIDER-QWEN-MARATHON-TRIAL-FINDINGS.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,relay-automation/aider-turn.sh,utils/py/aider-turn.py,test/marathon-drive.sh,test/aider-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/lane-attempt-cap.sh,test/marathon-root-audit.sh,test/marathon.sh,test/relay-xyz-skill-guard.sh,test/sentinel-driver-hooks.sh,test/test_python_layer.py,test/xyz-harness-hooks.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/marathon-drive.sh,test/aider-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/lane-attempt-cap.sh,test/marathon-root-audit.sh,test/marathon.sh,test/relay-xyz-skill-guard.sh,test/sentinel-driver-hooks.sh,test/xyz-harness-hooks.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-279-aider-qwen-marathon-trial-findings relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,relay-automation/aider-turn.sh,utils/py/aider-turn.py,test/marathon-drive.sh,test/aider-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/lane-attempt-cap.sh,test/marathon-root-audit.sh,test/marathon.sh,test/relay-xyz-skill-guard.sh,test/sentinel-driver-hooks.sh,test/test_python_layer.py,test/xyz-harness-hooks.sh,test/_setup.sh \
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
1. Implement the brief by creating/editing the artifact file(s): relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,relay-automation/aider-turn.sh,utils/py/aider-turn.py,test/marathon-drive.sh,test/aider-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/lane-attempt-cap.sh,test/marathon-root-audit.sh,test/marathon.sh,test/relay-xyz-skill-guard.sh,test/sentinel-driver-hooks.sh,test/test_python_layer.py,test/xyz-harness-hooks.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-P1-TURN --agent codex --paths "phases/p1/RELAY.md,relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,relay-automation/aider-turn.sh,utils/py/aider-turn.py,test/marathon-drive.sh,test/aider-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/lane-attempt-cap.sh,test/marathon-root-audit.sh,test/marathon.sh,test/relay-xyz-skill-guard.sh,test/sentinel-driver-hooks.sh,test/test_python_layer.py,test/xyz-harness-hooks.sh,test/_setup.sh"
   - /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-P1-TURN --agent codex
   - /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick release MARATHON-P1-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/p1/RELAY.md and relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,relay-automation/aider-turn.sh,utils/py/aider-turn.py,test/marathon-drive.sh,test/aider-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/lane-attempt-cap.sh,test/marathon-root-audit.sh,test/marathon.sh,test/relay-xyz-skill-guard.sh,test/sentinel-driver-hooks.sh,test/test_python_layer.py,test/xyz-harness-hooks.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/marathon-drive.sh,utils/py/marathon_drive.py,relay-automation/aider-turn.sh,utils/py/aider-turn.py,test/marathon-drive.sh,test/aider-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/lane-attempt-cap.sh,test/marathon-root-audit.sh,test/marathon.sh,test/relay-xyz-skill-guard.sh,test/sentinel-driver-hooks.sh,test/test_python_layer.py,test/xyz-harness-hooks.sh,test/_setup.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick release MARATHON-P1-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick done MARATHON-P1-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GitHub-Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
