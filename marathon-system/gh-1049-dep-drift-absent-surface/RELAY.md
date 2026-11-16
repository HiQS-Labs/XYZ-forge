# Marathon Phase gh-1049-dep-drift-absent-surface
STATUS: Open
NEXT: claude (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-1049-DEP-DRIFT-ABSENT-SURFACE-TURN builder=codex reviewer=claude round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1049-dep-drift-absent-surface

- Generated: 2026-11-16T05:47:21Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/PROJECT/2-WORKING/GH-1049-DEP-DRIFT-ABSENT-SURFACE.md 
- Target root: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15 (development @ 15716ba9e)
- Suggested branch: `marathon/gh-1049-dep-drift-absent-surface-2026-11-16` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh --auto development`

- Artifacts: relay-automation/relay-turn-lib.sh,test/relay-dep-drift.sh,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1931 LOC across 43 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/PROJECT/2-WORKING/GH-1049-DEP-DRIFT-ABSENT-SURFACE.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #1049 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] Surfaces absent at both revs across a commit: zero `dependency.drift` events.
- [ ] A real change to a present surface still emits with real blob SHAs (existing positive case).
- [ ] A surface added between the two revs emits once with `prior_sha` `none`.
- [ ] `test/relay-dep-drift.sh` covers the three cases and passes.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/relay-turn-lib.sh,test/relay-dep-drift.sh,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh --auto development`, and NOT `test/relay-dep-drift.sh,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1049-dep-drift-absent-surface RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/relay-turn-lib.sh,test/relay-dep-drift.sh,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh \
  --pre-advance-cmd 'bash validate.sh --auto development' \
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
1. Implement the brief by creating/editing the artifact file(s): relay-automation/relay-turn-lib.sh,test/relay-dep-drift.sh,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
   If a verification the brief asks for could not run (e.g. your sandbox denied a local service), put it on its own line: `unverified: <what> — <why>` (GH-1428).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick claim MARATHON-GH-1049-DEP-DRIFT-ABSENT-SURFACE-TURN --agent codex --paths "marathon-system/gh-1049-dep-drift-absent-surface/RELAY.md,relay-automation/relay-turn-lib.sh,test/relay-dep-drift.sh,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick ping MARATHON-GH-1049-DEP-DRIFT-ABSENT-SURFACE-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick release MARATHON-GH-1049-DEP-DRIFT-ABSENT-SURFACE-TURN --agent codex --to claude
4. Edit ONLY these paths: marathon-system/gh-1049-dep-drift-absent-surface/RELAY.md and relay-automation/relay-turn-lib.sh,test/relay-dep-drift.sh,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to claude — claude, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: claude (Reviewer)`

---

▶ TAKE YOUR TURN (claude — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/relay-turn-lib.sh,test/relay-dep-drift.sh,test/archive-commit.sh,test/archive-root.sh,test/codex-turn.sh,test/gh113-headless-scratch.sh,test/gh197-vendor-tier-split.sh,test/gh2-orphan-backup-repro.sh,test/gh267-express-skill.sh,test/gh284-runlog-heartbeat.sh,test/gh304-vendored-relay-path.sh,test/gh308-frozen-twin-guard.sh,test/gh322-runlog-python-lane.sh,test/gh369-group-kill.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh374-drift-path-filter.sh,test/gh388-run-log-durability.sh,test/gh397-reviewer-turn-role.sh,test/gh410-relay-block-driven-path.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh505-relay-attest.sh,test/gh642-consumer-fruit.sh,test/gh648-l2-token-aftermath.sh,test/gh681-reviewer-probe-rules.sh,test/gh90-allowlist-directory.sh,test/gh91-relay-scratch.sh,test/phase3-signoff-guard.sh,test/relay-case-insensitive.sh,test/relay-commit-pathspec.sh,test/relay-concurrent-commit.sh,test/relay-file-seeding-visibility.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/relay-uncited-findings.sh,test/rtl-orphan-backup.sh,test/swarm-preflight.sh,test/worktree-isolation.sh,test/write-ops-log.sh,test/fixtures/canary-peer-orphan/verify-fixture.sh,test/fixtures/canary-reviewer-overstep/verify-fixture.sh,test/_setup.sh,test/_scratch-repo.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · claude` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick release MARATHON-GH-1049-DEP-DRIFT-ABSENT-SURFACE-TURN --agent claude --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick done MARATHON-GH-1049-DEP-DRIFT-ABSENT-SURFACE-TURN --agent claude
3a. GATE EVIDENCE (GH-1428): this phase's gate (`bash validate.sh --auto development`) is not a focused file-only command, so it runs only in the harness after your turn — do NOT run it. Declare a literal `gate run: no — harness gate` line in your review block.
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick
   Edit ONLY marathon-system/gh-1049-dep-drift-absent-surface/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
   `Affected scope:` and `Falsifier:` lines; a `[Blocker]` must cite an observed failure. The Builder
   may disposition a request lacking these as `Declined — unproven generalization`.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.


### Round 1 · Builder · codex

Implemented GH-1049 in `relay-automation/relay-turn-lib.sh` and updated the existing `test/relay-dep-drift.sh`; no other artifacts changed.

Root cause: failed plain `git rev-parse rev:path` lookups can print the unresolved input, so two missing paths compare as different revision-prefixed strings; Fix site: the shared-surface blob lookups in `rtl_enforce`; Why not upstream/downstream: this is where failed Git output first becomes a supposed object ID, before event emission.

Both lookups now use `rev-parse --verify` and explicitly clear the result on failure. Identical empty results skip emission; added or removed surfaces retain the existing `none` field encoding. Warn-only emission and the fixed surface list are unchanged.

The existing suite now requires exactly one event for a changed surface and compares its emitted SHA fields to the actual expected blob IDs. It also exercises a real thread-only commit with all three surfaces absent (zero events), followed by adding `src/project.js` (one event, prior SHA `none`, actual current blob ID). The absent assertion first requires a populated event directory, avoiding vacuous success on missing fixture output. These are discriminating controls: the old lookups would report missing surfaces and fail the exact-count/zero-event assertions.

Verification performed: `bash -n relay-automation/relay-turn-lib.sh test/relay-dep-drift.sh` passed; all three embedded Python assertion blocks compiled successfully without execution. Syntax output is in `.relay-scratch/gh1049-syntax.log` (ephemeral).
unverified: runtime regression suite, pre-fix red control, and full gate — the embedded scope lock reserves test/gate execution for the harness outside this linked worktree; only syntax checks were run. No runtime pass is claimed.

Reversibility: Easy — two localized lookup changes and existing-suite assertions. Source inspection used direct shell reads because no graph MCP tools are available in this session. No Git commands were executed by the builder.

NEXT: claude (Reviewer)
