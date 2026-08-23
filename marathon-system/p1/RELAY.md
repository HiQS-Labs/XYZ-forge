# Marathon Phase p1
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-P1-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-8-kernel-boundary-hardening

- Generated: 2026-08-23T16:13:11Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-8-kernel-boundary-hardening/PROJECT/2-WORKING/GH-8-KERNEL-BOUNDARY-HARDENING.md 
- Target root: /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-8-kernel-boundary-hardening (development @ 6e8e49657)
- Suggested branch: `marathon/gh-8-kernel-boundary-hardening-2026-08-23` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: bin/tick,src/events.js,test/unit/cli.test.js,test/unit/lock.test.js,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh14-atomic-append.sh,test/gh148-deepseek-turn.sh,test/gh292-worktree-vendored-discovery.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 667 LOC across 35 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh14-atomic-append.sh,test/gh148-deepseek-turn.sh,test/gh292-worktree-vendored-discovery.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-8-kernel-boundary-hardening/PROJECT/2-WORKING/GH-8-KERNEL-BOUNDARY-HARDENING.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #8](https://github.com/HiQS-Suite/XYZ-forge/issues/8) — 4/4 criteria copied verbatim from issue #8.*
- [ ] `--priority abc` / `--epoch -1` / `--priority=3` all behave correctly (reject, reject, accept).
- [ ] Malformed `task`/`agent` strings are refused at write time with actionable errors.
- [ ] `test/unit/cli.test.js` and `test/unit/lock.test.js` exist and pass via `npm run test:unit`.
- [ ] Full `./validate.sh` green in a disposable clone.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `bin/tick,src/events.js,test/unit/cli.test.js,test/unit/lock.test.js,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh14-atomic-append.sh,test/gh148-deepseek-turn.sh,test/gh292-worktree-vendored-discovery.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh14-atomic-append.sh,test/gh148-deepseek-turn.sh,test/gh292-worktree-vendored-discovery.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-8-kernel-boundary-hardening RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact bin/tick,src/events.js,test/unit/cli.test.js,test/unit/lock.test.js,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh14-atomic-append.sh,test/gh148-deepseek-turn.sh,test/gh292-worktree-vendored-discovery.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh \
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

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): bin/tick,src/events.js,test/unit/cli.test.js,test/unit/lock.test.js,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh14-atomic-append.sh,test/gh148-deepseek-turn.sh,test/gh292-worktree-vendored-discovery.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-8-kernel-boundary-hardening/bin/tick
   - /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-8-kernel-boundary-hardening/bin/tick claim MARATHON-P1-TURN --agent agy --paths "marathon-system/p1/RELAY.md,bin/tick,src/events.js,test/unit/cli.test.js,test/unit/lock.test.js,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh14-atomic-append.sh,test/gh148-deepseek-turn.sh,test/gh292-worktree-vendored-discovery.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh"
   - /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-8-kernel-boundary-hardening/bin/tick ping MARATHON-P1-TURN --agent agy
   - /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-8-kernel-boundary-hardening/bin/tick release MARATHON-P1-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/p1/RELAY.md and bin/tick,src/events.js,test/unit/cli.test.js,test/unit/lock.test.js,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh14-atomic-append.sh,test/gh148-deepseek-turn.sh,test/gh292-worktree-vendored-discovery.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: bin/tick,src/events.js,test/unit/cli.test.js,test/unit/lock.test.js,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh14-atomic-append.sh,test/gh148-deepseek-turn.sh,test/gh292-worktree-vendored-discovery.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-sync-check.sh,test/xyz-vendor.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-8-kernel-boundary-hardening/bin/tick release MARATHON-P1-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-8-kernel-boundary-hardening/bin/tick done MARATHON-P1-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/bulkhead-2026-08-23/gh-8-kernel-boundary-hardening/bin/tick
   Edit ONLY marathon-system/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
4b. TO VERIFY A FINDING, WRITE PROBE FILES OUTSIDE THE REPO — under $TMPDIR, never inside the
   working tree. Creating even one scratch file in the repo is an off-lane write: containment
   reverts it and FAILS YOUR WHOLE TURN, discarding the review you just did (GH-441). Observed
   2026-08-08: a reviewer found a real latent crash, wrote two probe files in-tree to demonstrate
   it, and lost the turn for doing so — the finding survived only because RELAY.md happens to be
   on your allowlist. `cp` what you need to "$TMPDIR/probe.$$/" and work there instead. Verifying
   is wanted; verifying in-tree is what costs you the turn.
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
