# Marathon Phase gh-1638-relay-seed-dir-nesting
STATUS: Approved
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-1638-RELAY-SEED-DIR-NESTING-TURN builder=codex reviewer=agy round-cap=9 -->

## Phase Brief

# Marathon preflight packet — gh-1638-relay-seed-dir-nesting

- Generated: 2026-11-27T23:57:38Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/flywheel-runA-exec/PROJECT/2-WORKING/GH-1638-RELAY-SEED-DIR-NESTING.md 
- Target root: /Users/noelsaw/flywheel-runA-exec (development @ 445161727)
- Suggested branch: `marathon/gh-1638-relay-seed-dir-nesting-2026-11-27` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash test/worktree-isolation.sh`

- Artifacts: relay-automation/relay-turn-lib.sh,skills/1-hourly/relay-automation/relay-pkg.tar.gz,TESTS-RESULTS/2026-11-27+GH-1638/delivery.md,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/path-integrity.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-pkg-freshness.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/skill-extract.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1835 LOC across 48 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/path-integrity.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-pkg-freshness.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/skill-extract.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/flywheel-runA-exec/PROJECT/2-WORKING/GH-1638-RELAY-SEED-DIR-NESTING.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #1638 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] Seeding an allowlisted directory that already exists in the worktree leaves no nested `<dir>/<basename(dir)>` copy: the issue's red control (`find "$dir" -mindepth 1 -maxdepth 2 -name "$(basename "$dir")"`) is empty.
- [ ] The seeded directory mirrors the host tree's current content: an uncommitted edit under it is visible in the worktree, nested files are kept, a tracked child deleted on the host is absent, and ordinary file entries seed as before.
- [ ] A directory seed whose copy fails makes `rtl_worktree_begin` return non-zero (no successful but partial seed), and any removal before the copy is confined to a path that resolves strictly inside the worktree.
- [ ] A manual red/green check is recorded under `TESTS-RESULTS/` (GH-831: no new suite), and the vendored `relay-pkg.tar.gz` is regenerated with `skills/1-hourly/relay-automation/make-pkg.sh` so `bash test/relay-pkg-freshness.sh` passes (its result recorded in the delivery receipt).

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/relay-turn-lib.sh,skills/1-hourly/relay-automation/relay-pkg.tar.gz,TESTS-RESULTS/2026-11-27+GH-1638/delivery.md,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/path-integrity.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-pkg-freshness.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/skill-extract.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash test/worktree-isolation.sh`, and NOT `test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/path-integrity.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-pkg-freshness.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/skill-extract.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1638-relay-seed-dir-nesting RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex --round-cap 9 \
  --artifact relay-automation/relay-turn-lib.sh,skills/1-hourly/relay-automation/relay-pkg.tar.gz,TESTS-RESULTS/2026-11-27+GH-1638/delivery.md,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/path-integrity.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-pkg-freshness.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/skill-extract.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh \
  --pre-advance-cmd 'bash test/worktree-isolation.sh' \
  --require-clean
```

## Files in this packet
- `run-candidate.json` — normalized run candidate (provenance + contract + checks)
- `freshness.json` — branch state + fix-still-required probes
- `readiness.json` — remediation readiness verdict
- `lane-plan.json` — Codex / agy / orchestrator lane assignment
- `marathon-invocation.txt` — the invocation hint above
- `marathon-invocation.json` — the same invocation as structured data (`swarm-preflight/marathon-invocation@1`, GH-280); supervisors consume this, never the shell text


---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/relay-turn-lib.sh,skills/1-hourly/relay-automation/relay-pkg.tar.gz,TESTS-RESULTS/2026-11-27+GH-1638/delivery.md,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/path-integrity.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-pkg-freshness.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/skill-extract.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
   If a verification the brief asks for could not run (e.g. your sandbox denied a local service), put it on its own line: `unverified: <what> — <why>` (GH-1428).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/flywheel-runA-exec/bin/tick
   - /Users/noelsaw/flywheel-runA-exec/bin/tick claim MARATHON-GH-1638-RELAY-SEED-DIR-NESTING-TURN --agent codex --paths "marathon-system/gh-1638-relay-seed-dir-nesting/RELAY.md,relay-automation/relay-turn-lib.sh,skills/1-hourly/relay-automation/relay-pkg.tar.gz,TESTS-RESULTS/2026-11-27+GH-1638/delivery.md,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/path-integrity.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-pkg-freshness.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/skill-extract.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh"
   - /Users/noelsaw/flywheel-runA-exec/bin/tick ping MARATHON-GH-1638-RELAY-SEED-DIR-NESTING-TURN --agent codex
   - /Users/noelsaw/flywheel-runA-exec/bin/tick release MARATHON-GH-1638-RELAY-SEED-DIR-NESTING-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-1638-relay-seed-dir-nesting/RELAY.md and relay-automation/relay-turn-lib.sh,skills/1-hourly/relay-automation/relay-pkg.tar.gz,TESTS-RESULTS/2026-11-27+GH-1638/delivery.md,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/path-integrity.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-pkg-freshness.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/skill-extract.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/relay-turn-lib.sh,skills/1-hourly/relay-automation/relay-pkg.tar.gz,TESTS-RESULTS/2026-11-27+GH-1638/delivery.md,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/path-integrity.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-dep-drift.sh,test/relay-file-seeding-visibility.sh,test/relay-pkg-freshness.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/skill-extract.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/flywheel-runA-exec/bin/tick release MARATHON-GH-1638-RELAY-SEED-DIR-NESTING-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/flywheel-runA-exec/bin/tick done MARATHON-GH-1638-RELAY-SEED-DIR-NESTING-TURN --agent agy
3a. GATE EVIDENCE (GH-1428): this phase's gate (`bash test/worktree-isolation.sh`) is not a focused file-only command, so it runs only in the harness after your turn — do NOT run it. Declare a literal `gate run: no — harness gate` line in your review block.
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/flywheel-runA-exec/bin/tick
   Edit ONLY marathon-system/gh-1638-relay-seed-dir-nesting/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
4c. A finding that asks for a behaviour change is a generalization unless you can paste the concrete
   input — a row, a value, a `file:line` — that fails under the current code (GH-681). Every
   `[Blocker]` or `[Should]` requesting a behaviour change MUST carry `Observed input:`,
   `Affected scope:` and `Falsifier:` lines. `Observed input:` accepts two strict, non-speculative forms:
   (1) Form 1 (observed failure or concrete `fileA:line` vs `fileB:line` artifact contradiction), or
   (2) Form 2 (unrunnable runtime hazard trace, permitted ONLY when verification requires an external service,
   multi-process concurrency, or browser/container runtime forbidden here: hop-by-hop `file:line` trace plus
   an exact `Clone probe:` command/script for the Builder's disposable full clone).
   Default severity for an unexecuted Form 2 hazard is `[Should]`; a `[Blocker]` must cite an observed failure
   (Form 1), and an unexecuted Form 2 hazard stays `[Should]` until a probe reproduces it. Read the probe before
   running it — refuse any probe that reaches the network, credentials, or paths outside the disposable clone
   and record the refusal as `[Unverified — clone probe failed/unavailable]` — then any Form 2 finding remains
   pending probe verification until the Builder executes safe `Clone probe:` commands (reproduced → fix +
   before/after output; falsified → `Declined — falsified by clone probe: <cmd → exit + output>`;
   errored/refused/unavailable → stays OPEN as `[Unverified — clone probe failed/unavailable]`, blocking
   `STATUS: Approved` until re-run cleanly or escalated/parked).
   A finding from an earlier round stays open, and the verdict stays failing, until new evidence closes it.
   This includes earlier [Nit] findings; only a newly raised [Nit] on an Approved verdict remains optional.
   The falsifier names the fixture or data and its expected result.
   The Builder may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.

### Round 1 · Builder · codex

- Updated `relay-automation/relay-turn-lib.sh` to mirror directory seeds in place. The seed checks destination parents physically, refuses malformed paths and the worktree Git pointer, and fails setup if it cannot clear or copy the directory. Git-managed teardown reports a refusal and preserves the worktree for inspection.
- Regenerated `skills/1-hourly/relay-automation/relay-pkg.tar.gz` and recorded evidence in `TESTS-RESULTS/2026-11-27+GH-1638/delivery.md`.
- Verified Bash syntax, red and green filesystem behavior through `rtl_worktree_begin` with stubbed worktree operations, and byte-for-byte freshness of all 18 archive members. The baseline demonstrated a nested duplicate and stale contents. The candidate passed 34 assertions, including failed copy and clear, refused teardown, multi-segment paths, and an outside-pointing parent symlink.
- The first manual probe reached a read-only signature call before the signature callback was stubbed. The receipt excludes that attempt and records the fully stubbed runs.

unverified: `bash test/relay-pkg-freshness.sh` — relay scope forbids running repository test scripts in this turn. The archive content was checked independently.
unverified: `bash test/worktree-isolation.sh` and the real-Git preparation replay against the delivered source — the relay assigns the gate to the harness and prohibits running Git in the turn.

### Round 1 · Reviewer · agy

swept file: yes
gate run: no — harness gate

- **Implementation (`relay-automation/relay-turn-lib.sh:722-765`, `:827-837`):** [Pass] `_rtl_seed_directory` rejects `.`, `..`, and empty path segments lexically before touching the filesystem (`relay-automation/relay-turn-lib.sh:724-728`), absolutizes relative `$RTL_ROOT` paths before `cd -P` (`:729`), resolves the worktree and walks each parent physically (`cd -P`) requiring containment inside `$worktree` before creating missing parents (`:730-748`), protects root `.git` case-insensitively (`:750-753`), clears any existing destination or leaf symlink without following it and confirms removal (`:757-763`), and copies the host directory via `cp -R "$src" "$dest"` (`:764`). On any failure, `rtl_worktree_begin` tears down only via `git -C "$RTL_ROOT" worktree remove --force "$wt"`, deregisters on success, reports a refused teardown while leaving the worktree in place, and returns 1 with empty stdout (`:827-836`). Ordinary file entries (`:838-841`), archive-absolute skips (`:823-826`), and the `SEED-DELETE` branch (`:842-846`) retain existing behavior.
- **Whole-file sweep (`relay-automation/relay-turn-lib.sh:1-1891`):** [Pass] Reviewed the entire file (`relay-automation/relay-turn-lib.sh:1-1891`). No defects found in the changed seeding path and no new blocking pre-existing defects introduced or uncovered within this phase's scope. Noted out-of-scope pre-existing items left intentionally untouched per `PROJECT/2-WORKING/GH-1638-RELAY-SEED-DIR-NESTING.md:12-15` and `test/write-ops-log.sh:84-91`: commit-pathspec filtering for directory lanes (`relay-automation/relay-turn-lib.sh:1687-1690`, tracked separately on `#1638`) and the pre-existing `rm -rf "$wt"` fallbacks outside the seeding loop (`:870`, `:1040`).
- **Package & delivery receipt (`skills/1-hourly/relay-automation/relay-pkg.tar.gz`, `TESTS-RESULTS/2026-11-27+GH-1638/delivery.md:1-33`):** [Pass] Delivery receipt records baseline red/candidate green evidence, hashes, and scope-imposed `unverified:` notes matching `RELAY.md:38`, `:70`, `:90`.
- **Independent reviewer probes (non-mutating, run under `$PWD/.relay-scratch/tmp` without Git or repo test scripts):**
  1. Syntax, digests, and tarball freshness (`bash -n relay-automation/relay-turn-lib.sh`, `shasum -a 256`, Python `tarfile` byte-for-byte comparison against live files) -> exit `0`: `bash -n: OK`, `49d3ecb23aec17f1aca6ed6d046aaee385b156de0317177ce84bb50a53b2663c  relay-automation/relay-turn-lib.sh`, `d9638f90215f80b1748c4432944efe5985e123a9899bde955976005e6ab6045f  skills/1-hourly/relay-automation/relay-pkg.tar.gz`, `tar member count: 18`, `mismatches: []`. Digests match `TESTS-RESULTS/2026-11-27+GH-1638/delivery.md:32-33`.
  2. Edge-case harness probe (`/bin/bash` 3.2 sourcing `relay-automation/relay-turn-lib.sh` with stubbed `git`/`_rtl_sig` and `CDPATH` set) -> exit `0`: `REVIEWER_PROBE: PASS=31 FAIL=0` covering top-level and multi-segment mirroring (edits, nested files, dotfiles, retired child deletion, ordinary file entry), missing checkout parents, unreadable source copy failure, failed and no-op `rm` clear, refused `git worktree remove` preserving worktree and reporting `worktree remove`, escaping and dangling parent symlinks, leaf symlink replacement preserving external target, `.`/`..`/empty/trailing-slash segments, `.git`/`.GIT`/`selflink/.git`, spaces and leading-dash directory names, and relative `RTL_ROOT`.
- **Unverified in-turn items (disclosed):** `bash test/relay-pkg-freshness.sh` (script execution forbidden by `RELAY.md:38`; equivalent 18-member byte-for-byte check verified above) and `bash test/worktree-isolation.sh` (harness gate per `RELAY.md:90`).

**Verdict:** Approved

relay closed, no further turn needed.
