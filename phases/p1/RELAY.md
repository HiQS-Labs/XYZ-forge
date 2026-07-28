# Marathon Phase p1
STATUS: Open
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH284-PHASE2-20260728 builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-284-marathon-closeout-pr

- Generated: 2026-07-28T03:58:37Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/PROJECT/2-WORKING/GH-284-MARATHON-CLOSEOUT-PR.md 
- Target root: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm (marathon/gh-284-phase2-runlog-2026-07-28 @ 2bb13e5ae)
- Suggested branch: `marathon/gh-284-marathon-closeout-pr-2026-07-28` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Gate: `bash validate.sh`

- Artifacts: relay-automation/marathon-drive.sh,relay-automation/relay-turn-lib.sh,test/gh284-runlog-heartbeat.sh,validate.sh,test/archive-commit.sh,test/archive-root.sh,test/ci-workflow.sh,test/codex-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/gh304-vendored-relay-path.sh,test/gh307-gate-env-scrub.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/marathon-root-audit.sh,test/marathon.sh,test/oracle-guard.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/sentinel-driver-hooks.sh,test/swarm-preflight.sh,test/test_python_layer.py,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/fixtures/gamma-poison/CANDIDATE.md,test/fixtures/gamma-poison/EXPECTED.md,test/fixtures/gamma-poison/README.md,test/fixtures/gamma-poison/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh
- Suggested turn budget: `RELAY_TURN_TIMEOUT_S=900` (sized to ≈ 2484 LOC across 40 artifact(s); a build that also edits tests needs headroom over the 300s default)
- Auto-included covering tests/helpers: test/archive-commit.sh,test/archive-root.sh,test/ci-workflow.sh,test/codex-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/gh304-vendored-relay-path.sh,test/gh307-gate-env-scrub.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/marathon-root-audit.sh,test/marathon.sh,test/oracle-guard.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/sentinel-driver-hooks.sh,test/swarm-preflight.sh,test/test_python_layer.py,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/fixtures/gamma-poison/CANDIDATE.md,test/fixtures/gamma-poison/EXPECTED.md,test/fixtures/gamma-poison/README.md,test/fixtures/gamma-poison/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold (inlined from the capture doc)
- [ ] Heartbeat file is readable by a **sandboxed** reader — demonstrated, since that is the entire point
- [ ] A live driver is never reported as finished; a dead one is never reported as running
- [ ] Staleness requires BOTH stale-heartbeat AND absent-PID — verified with a live-PID/stale-file case
- [ ] Re-firing the same lane updates ONE comment, does not append a second
- [ ] `--log-github` is default OFF; with `gh` unavailable the run's exit code is unchanged
- [ ] No code path files a new issue or closes one
- [ ] Trunk name is derived, not the literal `development`
- [ ] Define the signature function and prove two runs of one bug collide to one signature
- [ ] Zero-diff-deliverable check against the phase base commit (the #315 catch)
- [ ] Dedupe query against existing open+closed issues before any write
- [ ] Breaker: N-consecutive or novel-only, reusing `loop-stop.sh`
- [ ] Propose-then-confirm path; `--auto-file` opt-in with `auto-filed`+`needs-triage` labels
- [ ] Degradation test: `gh` absent/unauthenticated → local-only, run exit code unchanged
- [ ] A deliberately re-run identical failure files **one** issue, not two — demonstrated, not assumed
- [ ] A single transient failure files **nothing**
- [ ] A false success (approved + green gate + zero artifact diff) **is** reported — replay #315
- [ ] No auto-close path exists anywhere in the implementation
- [ ] `/10days`'s candidate set is unpolluted: auto-filed issues are distinguishable by label

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/marathon-drive.sh,relay-automation/relay-turn-lib.sh,test/gh284-runlog-heartbeat.sh,validate.sh,test/archive-commit.sh,test/archive-root.sh,test/ci-workflow.sh,test/codex-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/gh304-vendored-relay-path.sh,test/gh307-gate-env-scrub.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/marathon-root-audit.sh,test/marathon.sh,test/oracle-guard.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/sentinel-driver-hooks.sh,test/swarm-preflight.sh,test/test_python_layer.py,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/fixtures/gamma-poison/CANDIDATE.md,test/fixtures/gamma-poison/EXPECTED.md,test/fixtures/gamma-poison/README.md,test/fixtures/gamma-poison/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/archive-commit.sh,test/archive-root.sh,test/ci-workflow.sh,test/codex-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/gh304-vendored-relay-path.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/marathon-root-audit.sh,test/marathon.sh,test/oracle-guard.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/sentinel-driver-hooks.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/fixtures/gamma-poison/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-284-marathon-closeout-pr RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/marathon-drive.sh,relay-automation/relay-turn-lib.sh,test/gh284-runlog-heartbeat.sh,validate.sh,test/archive-commit.sh,test/archive-root.sh,test/ci-workflow.sh,test/codex-turn.sh,test/debug-mantra.sh,test/driver-lock.sh,test/gh304-vendored-relay-path.sh,test/gh307-gate-env-scrub.sh,test/lane-attempt-cap.sh,test/marathon-drive.sh,test/marathon-root-audit.sh,test/marathon.sh,test/oracle-guard.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/sentinel-driver-hooks.sh,test/swarm-preflight.sh,test/test_python_layer.py,test/worktree-isolation.sh,test/xyz-harness-hooks.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/fixtures/gamma-poison/CANDIDATE.md,test/fixtures/gamma-poison/EXPECTED.md,test/fixtures/gamma-poison/README.md,test/fixtures/gamma-poison/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh \
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
1. Implement the brief by creating/editing the artifact file(s): relay-automation/marathon-drive.sh,relay-automation/relay-turn-lib.sh,test/gh284-runlog-heartbeat.sh,validate.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH284-PHASE2-20260728 --agent codex --paths "phases/p1/RELAY.md,relay-automation/marathon-drive.sh,relay-automation/relay-turn-lib.sh,test/gh284-runlog-heartbeat.sh,validate.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH284-PHASE2-20260728 --agent codex
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH284-PHASE2-20260728 --agent codex --to agy
4. Edit ONLY these paths: phases/p1/RELAY.md and relay-automation/marathon-drive.sh,relay-automation/relay-turn-lib.sh,test/gh284-runlog-heartbeat.sh,validate.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/marathon-drive.sh,relay-automation/relay-turn-lib.sh,test/gh284-runlog-heartbeat.sh,validate.sh.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH284-PHASE2-20260728 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH284-PHASE2-20260728 --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
