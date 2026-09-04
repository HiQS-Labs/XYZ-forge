# Marathon Phase gh-414
STATUS: Open
NEXT: codex (Builder)

<!-- marathon-drive: task=MARATHON-GH-414-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-414-comment-reference-check

- Generated: 2026-09-04T00:08:16Z
- Mode: project-doc
- Sources: /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md 
- Target root: /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation (development @ 1130f5294)
- Suggested branch: `marathon/gh-414-comment-reference-check-2026-09-04` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: utils/pdda/pdda.sh,test/gh414-comment-reference-check.sh,test/baselines/GH-414-negative-control.md,test/gh165-governance-canonical-paths-guard.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh280-jog-marathon-adapter.sh,test/gh284-p3-release-milestone.sh,test/gh35-test-tiers.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh365-pdda-gov-scan.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-hardening.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/pdda-local-checks.sh,test/pdda-repo-contract.sh,test/pdda-roadmap-coverage.sh,test/sentinel-overlay.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1525 LOC across 27 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh165-governance-canonical-paths-guard.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh280-jog-marathon-adapter.sh,test/gh284-p3-release-milestone.sh,test/gh35-test-tiers.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh365-pdda-gov-scan.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-hardening.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/pdda-local-checks.sh,test/pdda-repo-contract.sh,test/pdda-roadmap-coverage.sh,test/sentinel-overlay.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/PROJECT/1-INBOX/GH-414-COMMENT-REFERENCE-CHECK.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #414](https://github.com/HiQS-Labs/XYZ-forge/issues/414) — 4/4 criteria copied verbatim from issue #414.*
- [ ] A source comment citing a non-existent path **fails** the check.
- [ ] The check runs against the built artifact, not only the source tree.
- [ ] Existing markdown dead-reference warnings are at zero or explicitly accepted.
- [ ] Red control witnessed: the two ADR citations in `src/events.js` fail pre-fix.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/pdda/pdda.sh,test/gh414-comment-reference-check.sh,test/baselines/GH-414-negative-control.md,test/gh165-governance-canonical-paths-guard.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh280-jog-marathon-adapter.sh,test/gh284-p3-release-milestone.sh,test/gh35-test-tiers.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh365-pdda-gov-scan.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-hardening.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/pdda-local-checks.sh,test/pdda-repo-contract.sh,test/pdda-roadmap-coverage.sh,test/sentinel-overlay.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/gh165-governance-canonical-paths-guard.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh280-jog-marathon-adapter.sh,test/gh284-p3-release-milestone.sh,test/gh35-test-tiers.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh365-pdda-gov-scan.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-hardening.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/pdda-local-checks.sh,test/pdda-roadmap-coverage.sh,test/sentinel-overlay.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-414-comment-reference-check RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/pdda/pdda.sh,test/gh414-comment-reference-check.sh,test/baselines/GH-414-negative-control.md,test/gh165-governance-canonical-paths-guard.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh280-jog-marathon-adapter.sh,test/gh284-p3-release-milestone.sh,test/gh35-test-tiers.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh365-pdda-gov-scan.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-hardening.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/pdda-local-checks.sh,test/pdda-repo-contract.sh,test/pdda-roadmap-coverage.sh,test/sentinel-overlay.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh \
  --pre-advance-cmd 'bash validate.sh' \
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
1. Implement the brief by creating/editing the artifact file(s): utils/pdda/pdda.sh,test/gh414-comment-reference-check.sh,test/baselines/GH-414-negative-control.md,test/gh165-governance-canonical-paths-guard.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh280-jog-marathon-adapter.sh,test/gh284-p3-release-milestone.sh,test/gh35-test-tiers.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh365-pdda-gov-scan.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-hardening.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/pdda-local-checks.sh,test/pdda-repo-contract.sh,test/pdda-roadmap-coverage.sh,test/sentinel-overlay.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick claim MARATHON-GH-414-TURN --agent codex --paths "marathon-system/gh-414/RELAY.md,utils/pdda/pdda.sh,test/gh414-comment-reference-check.sh,test/baselines/GH-414-negative-control.md,test/gh165-governance-canonical-paths-guard.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh280-jog-marathon-adapter.sh,test/gh284-p3-release-milestone.sh,test/gh35-test-tiers.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh365-pdda-gov-scan.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-hardening.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/pdda-local-checks.sh,test/pdda-repo-contract.sh,test/pdda-roadmap-coverage.sh,test/sentinel-overlay.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh"
   - /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick ping MARATHON-GH-414-TURN --agent codex
   - /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick release MARATHON-GH-414-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-414/RELAY.md and utils/pdda/pdda.sh,test/gh414-comment-reference-check.sh,test/baselines/GH-414-negative-control.md,test/gh165-governance-canonical-paths-guard.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh280-jog-marathon-adapter.sh,test/gh284-p3-release-milestone.sh,test/gh35-test-tiers.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh365-pdda-gov-scan.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-hardening.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/pdda-local-checks.sh,test/pdda-repo-contract.sh,test/pdda-roadmap-coverage.sh,test/sentinel-overlay.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/pdda/pdda.sh,test/gh414-comment-reference-check.sh,test/baselines/GH-414-negative-control.md,test/gh165-governance-canonical-paths-guard.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh280-jog-marathon-adapter.sh,test/gh284-p3-release-milestone.sh,test/gh35-test-tiers.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh365-pdda-gov-scan.sh,test/gh365-runner-envelope.sh,test/gh365-validate-telemetry.sh,test/gh544-pre-push-gate.sh,test/hq-hardening.sh,test/hq-park-synthesis.sh,test/hq-park.sh,test/hq-promote.sh,test/hq.sh,test/pdda-local-checks.sh,test/pdda-repo-contract.sh,test/pdda-roadmap-coverage.sh,test/sentinel-overlay.sh,test/wave-reconcile.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick release MARATHON-GH-414-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick done MARATHON-GH-414-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick
   Edit ONLY marathon-system/gh-414/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to codex —
   codex, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
