# Marathon Phase gh96seam1
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH96SEAM1-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-96-xyz-json-emit-contract-heartbeat

- Generated: 2026-07-06T00:44:36Z
- Mode: project-doc
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-96-XYZ-JSON-EMIT-CONTRACT-HEARTBEAT.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (main @ c7f84316a)
- Suggested branch: `marathon/gh-96-xyz-json-emit-contract-heartbeat-2026-07-06` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Gate: `bash test/xyz-completion.sh`

- Artifacts: utils/telemetry/write-xyz-heartbeat.sh,relay-automation/relay-drive.sh,relay-automation/marathon-drive.sh,relay-automation/README.md,.gitignore,test/xyz-completion.sh,test/agy-turn.sh,test/aider-turn.sh,test/archive-commit.sh,test/claude-turn.sh,test/codex-turn.sh,test/driver-lock.sh,test/find-harness.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/poll-relay.sh,test/relay-artifact-file.sh,test/relay-concurrent-commit.sh,test/relay-escalation-not-stall.sh,test/relay-review-once.sh,test/relay-self-sufficiency.sh,test/relay-target-root-newfile.sh,test/relay-target-root-paths.sh,test/relay-target-root-relayfile.sh,test/relay-target-root.sh,test/relay-token-collision.sh,test/relay-turn-timeout.sh,test/relay-untracked-file-warn.sh,test/relay-xyz-skill-guard.sh,test/shim-worktree.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/xyz-vendor.sh,test/_setup.sh,test/_scratch-repo.sh
- Auto-included covering tests/helpers: test/agy-turn.sh,test/aider-turn.sh,test/archive-commit.sh,test/claude-turn.sh,test/codex-turn.sh,test/driver-lock.sh,test/find-harness.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/poll-relay.sh,test/relay-artifact-file.sh,test/relay-concurrent-commit.sh,test/relay-escalation-not-stall.sh,test/relay-review-once.sh,test/relay-self-sufficiency.sh,test/relay-target-root-newfile.sh,test/relay-target-root-paths.sh,test/relay-target-root-relayfile.sh,test/relay-target-root.sh,test/relay-token-collision.sh,test/relay-turn-timeout.sh,test/relay-untracked-file-warn.sh,test/relay-xyz-skill-guard.sh,test/shim-worktree.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/xyz-vendor.sh,test/_setup.sh,test/_scratch-repo.sh
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=900` (sized to ≈ 6094 LOC across 37 artifact(s); a build that also edits tests needs headroom over the 300s default)

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
- [ ] `relay-automation/README.md` gains a documented `XYZ.json` schema + emit-cadence section
- [ ] `utils/telemetry/write-xyz-heartbeat.sh <harness> <sessionId>` — atomic overwrite of
- [ ] `marathon-drive.sh:437` calls the heartbeat writer right after `marathon.phase.start`
- [ ] `relay-drive.sh`'s round-loop top calls the heartbeat writer once per round, gated by
- [ ] Each harness's existing terminal `append-xyz-completion.sh` call also clears
- [ ] `XYZ.heartbeat.json` (+ its lock artifact, if any) added to `.gitignore` alongside `XYZ.json`
- [ ] `test/xyz-completion.sh` extended (already covers `append-xyz-completion.sh`/health-lib; add the
- [ ] `bash validate.sh` green

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/telemetry/write-xyz-heartbeat.sh,relay-automation/relay-drive.sh,relay-automation/marathon-drive.sh,relay-automation/README.md,.gitignore,test/xyz-completion.sh,test/agy-turn.sh,test/aider-turn.sh,test/archive-commit.sh,test/claude-turn.sh,test/codex-turn.sh,test/driver-lock.sh,test/find-harness.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/poll-relay.sh,test/relay-artifact-file.sh,test/relay-concurrent-commit.sh,test/relay-escalation-not-stall.sh,test/relay-review-once.sh,test/relay-self-sufficiency.sh,test/relay-target-root-newfile.sh,test/relay-target-root-paths.sh,test/relay-target-root-relayfile.sh,test/relay-target-root.sh,test/relay-token-collision.sh,test/relay-turn-timeout.sh,test/relay-untracked-file-warn.sh,test/relay-xyz-skill-guard.sh,test/shim-worktree.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/xyz-vendor.sh,test/_setup.sh,test/_scratch-repo.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash test/xyz-completion.sh`, and NOT `test/xyz-completion.sh,test/agy-turn.sh,test/aider-turn.sh,test/archive-commit.sh,test/claude-turn.sh,test/codex-turn.sh,test/driver-lock.sh,test/find-harness.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/poll-relay.sh,test/relay-artifact-file.sh,test/relay-concurrent-commit.sh,test/relay-escalation-not-stall.sh,test/relay-review-once.sh,test/relay-self-sufficiency.sh,test/relay-target-root-newfile.sh,test/relay-target-root-paths.sh,test/relay-target-root-relayfile.sh,test/relay-target-root.sh,test/relay-token-collision.sh,test/relay-turn-timeout.sh,test/relay-untracked-file-warn.sh,test/relay-xyz-skill-guard.sh,test/shim-worktree.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/xyz-vendor.sh,test/_setup.sh,test/_scratch-repo.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-96-xyz-json-emit-contract-heartbeat relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/telemetry/write-xyz-heartbeat.sh,relay-automation/relay-drive.sh,relay-automation/marathon-drive.sh,relay-automation/README.md,.gitignore,test/xyz-completion.sh,test/agy-turn.sh,test/aider-turn.sh,test/archive-commit.sh,test/claude-turn.sh,test/codex-turn.sh,test/driver-lock.sh,test/find-harness.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/poll-relay.sh,test/relay-artifact-file.sh,test/relay-concurrent-commit.sh,test/relay-escalation-not-stall.sh,test/relay-review-once.sh,test/relay-self-sufficiency.sh,test/relay-target-root-newfile.sh,test/relay-target-root-paths.sh,test/relay-target-root-relayfile.sh,test/relay-target-root.sh,test/relay-token-collision.sh,test/relay-turn-timeout.sh,test/relay-untracked-file-warn.sh,test/relay-xyz-skill-guard.sh,test/shim-worktree.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/xyz-vendor.sh,test/_setup.sh,test/_scratch-repo.sh \
  --pre-advance-cmd 'bash test/xyz-completion.sh' \
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
1. Implement the brief by creating/editing the artifact file(s): utils/telemetry/write-xyz-heartbeat.sh,relay-automation/relay-drive.sh,relay-automation/marathon-drive.sh,relay-automation/README.md,.gitignore,test/xyz-completion.sh,test/agy-turn.sh,test/aider-turn.sh,test/archive-commit.sh,test/claude-turn.sh,test/codex-turn.sh,test/driver-lock.sh,test/find-harness.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/poll-relay.sh,test/relay-artifact-file.sh,test/relay-concurrent-commit.sh,test/relay-escalation-not-stall.sh,test/relay-review-once.sh,test/relay-self-sufficiency.sh,test/relay-target-root-newfile.sh,test/relay-target-root-paths.sh,test/relay-target-root-relayfile.sh,test/relay-target-root.sh,test/relay-token-collision.sh,test/relay-turn-timeout.sh,test/relay-untracked-file-warn.sh,test/relay-xyz-skill-guard.sh,test/shim-worktree.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/xyz-vendor.sh,test/_setup.sh,test/_scratch-repo.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH96SEAM1-TURN --agent codex --paths "phases/gh96seam1/RELAY.md,utils/telemetry/write-xyz-heartbeat.sh,relay-automation/relay-drive.sh,relay-automation/marathon-drive.sh,relay-automation/README.md,.gitignore,test/xyz-completion.sh,test/agy-turn.sh,test/aider-turn.sh,test/archive-commit.sh,test/claude-turn.sh,test/codex-turn.sh,test/driver-lock.sh,test/find-harness.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/poll-relay.sh,test/relay-artifact-file.sh,test/relay-concurrent-commit.sh,test/relay-escalation-not-stall.sh,test/relay-review-once.sh,test/relay-self-sufficiency.sh,test/relay-target-root-newfile.sh,test/relay-target-root-paths.sh,test/relay-target-root-relayfile.sh,test/relay-target-root.sh,test/relay-token-collision.sh,test/relay-turn-timeout.sh,test/relay-untracked-file-warn.sh,test/relay-xyz-skill-guard.sh,test/shim-worktree.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/xyz-vendor.sh,test/_setup.sh,test/_scratch-repo.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH96SEAM1-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH96SEAM1-TURN --agent codex --to agy
4. Edit ONLY these paths: phases/gh96seam1/RELAY.md and utils/telemetry/write-xyz-heartbeat.sh,relay-automation/relay-drive.sh,relay-automation/marathon-drive.sh,relay-automation/README.md,.gitignore,test/xyz-completion.sh,test/agy-turn.sh,test/aider-turn.sh,test/archive-commit.sh,test/claude-turn.sh,test/codex-turn.sh,test/driver-lock.sh,test/find-harness.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/poll-relay.sh,test/relay-artifact-file.sh,test/relay-concurrent-commit.sh,test/relay-escalation-not-stall.sh,test/relay-review-once.sh,test/relay-self-sufficiency.sh,test/relay-target-root-newfile.sh,test/relay-target-root-paths.sh,test/relay-target-root-relayfile.sh,test/relay-target-root.sh,test/relay-token-collision.sh,test/relay-turn-timeout.sh,test/relay-untracked-file-warn.sh,test/relay-xyz-skill-guard.sh,test/shim-worktree.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/xyz-vendor.sh,test/_setup.sh,test/_scratch-repo.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/telemetry/write-xyz-heartbeat.sh,relay-automation/relay-drive.sh,relay-automation/marathon-drive.sh,relay-automation/README.md,.gitignore,test/xyz-completion.sh,test/agy-turn.sh,test/aider-turn.sh,test/archive-commit.sh,test/claude-turn.sh,test/codex-turn.sh,test/driver-lock.sh,test/find-harness.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/poll-relay.sh,test/relay-artifact-file.sh,test/relay-concurrent-commit.sh,test/relay-escalation-not-stall.sh,test/relay-review-once.sh,test/relay-self-sufficiency.sh,test/relay-target-root-newfile.sh,test/relay-target-root-paths.sh,test/relay-target-root-relayfile.sh,test/relay-target-root.sh,test/relay-token-collision.sh,test/relay-turn-timeout.sh,test/relay-untracked-file-warn.sh,test/relay-xyz-skill-guard.sh,test/shim-worktree.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/xyz-vendor.sh,test/_setup.sh,test/_scratch-repo.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH96SEAM1-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH96SEAM1-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh96seam1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
