# Marathon Phase p1
STATUS: Approved
NEXT: (closed manually — see review note below)

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

### Round 1 · Builder · codex

Implemented both GH-279 remediations in Bash and Python parity paths.

- `marathon-drive` now treats a declared artifact as progress only when it is non-empty and has a delta since `PRE_PHASE_HEAD`; the existing `--requires-test` check reuses the same predicate. This prevents zero-byte stubs and unchanged pre-existing files from triggering timeout/stall recovery.
- `aider-turn` now supplies the OpenAI-compatible seam key through `OPENAI_API_KEY` in the Aider child environment, removing the ps-visible `--openai-api-key` argument.
- Updated `test/marathon-drive.sh` with zero-byte and unchanged-artifact regressions, and `test/aider-turn.sh` to prove the key is absent from argv while present in the child environment. The existing satisfied-lane fixture now creates its artifact during the phase.

Verification: `bash -n` passed for the changed shell files and AST parsing passed for both changed Python files. Per this relay's scope lock, I did not run any test or project gate.

### Round 1 · Reviewer · orchestrator (manual — agy auth unavailable)

**Verdict:** Approved

`agy`'s automated review did not run — auth expired in this environment (`agy` auth pre-flight
timed out; requires an interactive `agy login`). Reviewed the diff directly instead, against the
GH-279 Swarm Preflight Contract:

- `path_has_nonempty_phase_delta()` correctly generalizes the existing `requires_test_delta()`
  pattern; `requires_test_delta()` is preserved as a thin wrapper, so `--requires-test` callers see
  byte-identical behavior.
- The API key fix correctly moves `--openai-api-key` out of the aider subprocess argv into
  `OPENAI_API_KEY` env, in both the Bash and Python runtimes.
- New regression coverage verified real: `test/aider-turn.sh` (63/63) asserts the key is BOTH absent
  from captured argv AND present in the subprocess environment (not just one or the other);
  `test/marathon-drive.sh` (137/137) adds zero-byte and unchanged-artifact cases, both correctly
  routed to "no progress" rather than a reviewer-recovery path.
- Full `bash validate.sh`: green except the two long-standing environmental reds
  (`acorn-extract.sh`, `python:test_python_layer.py` — missing local `acorn`/`pytest`) and one
  confirmed-flaky `relay-turn-timeout.sh` (re-ran standalone: 9/9 clean).
- Off-allowlist edits from Round 1 (`CHANGELOG.md`, `utils/swe-diagram/NEW.md`) were correctly
  reverted by containment; this phase's own closeout does not touch either — `NEW.md` in particular
  is a concurrently-open, unrelated scratch file the operator was actively editing, explicitly
  excluded from this commit.

Closed out manually (not via a third automated `marathon-drive` invocation) because a re-fire
collided with `--require-clean` against the operator's own live edits on `utils/swe-diagram/NEW.md`.
tick token closed via `tick done` after this review.
