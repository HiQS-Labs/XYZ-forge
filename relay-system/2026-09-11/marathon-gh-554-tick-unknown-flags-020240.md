# Marathon Phase gh-554-tick-unknown-flags
STATUS: Approved
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-554-TICK-UNKNOWN-FLAGS-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-554-tick-unknown-flags

- Generated: 2026-09-11T01:55:16Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/PROJECT/2-WORKING/GH-554-TICK-UNKNOWN-FLAGS.md 
- Target root: /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561 (development @ b9048bc0e)
- Suggested branch: `marathon/gh-554-tick-unknown-flags-2026-09-11` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `node --check bin/tick && bash test/gh411-tick-log-foreign-cwd.sh`

- Artifacts: bin/tick,test/gh554-tick-unknown-flags.sh,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh148-deepseek-turn.sh,test/gh197-vendor-tier-split.sh,test/gh292-worktree-vendored-discovery.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh410-relay-block-driven-path.sh,test/gh412-transient-claim-exit.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh505-relay-attest.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-vendor.sh,test/lib/attest-stub.sh,test/lib/vendored-fixture.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh,test/unit/cli.test.js
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 522 LOC across 37 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh148-deepseek-turn.sh,test/gh197-vendor-tier-split.sh,test/gh292-worktree-vendored-discovery.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh410-relay-block-driven-path.sh,test/gh412-transient-claim-exit.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh505-relay-attest.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-vendor.sh,test/lib/attest-stub.sh,test/lib/vendored-fixture.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh,test/unit/cli.test.js

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/PROJECT/2-WORKING/GH-554-TICK-UNKNOWN-FLAGS.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #554](https://github.com/HiQS-Labs/XYZ-forge/issues/554) — 4/4 criteria copied verbatim from issue #554.*
- [ ] Every `tick` verb rejects an unknown flag with exit 2 and a usage diagnostic before reading or writing task state.
- [ ] `tick release ... --status done` and `--bogus-flag` leave ownership and event count unchanged.
- [ ] Documented valid flags, `--flag=value`, and environment fallbacks continue to work.
- [ ] Tests cover at least one read-only and every mutating verb, including the original release reproduction.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `bin/tick,test/gh554-tick-unknown-flags.sh,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh148-deepseek-turn.sh,test/gh197-vendor-tier-split.sh,test/gh292-worktree-vendored-discovery.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh410-relay-block-driven-path.sh,test/gh412-transient-claim-exit.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh505-relay-attest.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-vendor.sh,test/lib/attest-stub.sh,test/lib/vendored-fixture.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh,test/unit/cli.test.js` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `node --check bin/tick && bash test/gh411-tick-log-foreign-cwd.sh`, and NOT `test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh148-deepseek-turn.sh,test/gh197-vendor-tier-split.sh,test/gh292-worktree-vendored-discovery.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh410-relay-block-driven-path.sh,test/gh412-transient-claim-exit.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh505-relay-attest.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-vendor.sh,test/lib/attest-stub.sh,test/lib/vendored-fixture.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-554-tick-unknown-flags RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact bin/tick,test/gh554-tick-unknown-flags.sh,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh148-deepseek-turn.sh,test/gh197-vendor-tier-split.sh,test/gh292-worktree-vendored-discovery.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh410-relay-block-driven-path.sh,test/gh412-transient-claim-exit.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh505-relay-attest.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-vendor.sh,test/lib/attest-stub.sh,test/lib/vendored-fixture.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh,test/unit/cli.test.js \
  --pre-advance-cmd 'node --check bin/tick && bash test/gh411-tick-log-foreign-cwd.sh' \
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
1. Implement the brief by creating/editing the artifact file(s): bin/tick,test/gh554-tick-unknown-flags.sh,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh148-deepseek-turn.sh,test/gh197-vendor-tier-split.sh,test/gh292-worktree-vendored-discovery.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh410-relay-block-driven-path.sh,test/gh412-transient-claim-exit.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh505-relay-attest.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-vendor.sh,test/lib/attest-stub.sh,test/lib/vendored-fixture.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh,test/unit/cli.test.js
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick
   - /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick claim MARATHON-GH-554-TICK-UNKNOWN-FLAGS-TURN --agent codex --paths "marathon-system/gh-554-tick-unknown-flags/RELAY.md,bin/tick,test/gh554-tick-unknown-flags.sh,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh148-deepseek-turn.sh,test/gh197-vendor-tier-split.sh,test/gh292-worktree-vendored-discovery.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh410-relay-block-driven-path.sh,test/gh412-transient-claim-exit.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh505-relay-attest.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-vendor.sh,test/lib/attest-stub.sh,test/lib/vendored-fixture.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh,test/unit/cli.test.js"
   - /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick ping MARATHON-GH-554-TICK-UNKNOWN-FLAGS-TURN --agent codex
   - /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick release MARATHON-GH-554-TICK-UNKNOWN-FLAGS-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-554-tick-unknown-flags/RELAY.md and bin/tick,test/gh554-tick-unknown-flags.sh,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh148-deepseek-turn.sh,test/gh197-vendor-tier-split.sh,test/gh292-worktree-vendored-discovery.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh410-relay-block-driven-path.sh,test/gh412-transient-claim-exit.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh505-relay-attest.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-vendor.sh,test/lib/attest-stub.sh,test/lib/vendored-fixture.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh,test/unit/cli.test.js. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: bin/tick,test/gh554-tick-unknown-flags.sh,test/_setup.sh,test/aider-turn.sh,test/codex-turn.sh,test/commandcode-turn.sh,test/find-harness.sh,test/gh148-deepseek-turn.sh,test/gh197-vendor-tier-split.sh,test/gh292-worktree-vendored-discovery.sh,test/gh312-vendor-preserves-state.sh,test/gh331-cost-summary.sh,test/gh387-gate-not-first-executor.sh,test/gh410-containment-advisory.sh,test/gh410-relay-block-driven-path.sh,test/gh412-transient-claim-exit.sh,test/gh417-turn-root-symlink-prefix.sh,test/gh448-driver-lock-resolver.sh,test/gh505-relay-attest.sh,test/gh551-resolver-refuses.sh,test/gh90-allowlist-directory.sh,test/hq-marathon-live.sh,test/marathon-closeout.sh,test/marathon-drive.sh,test/marathon.sh,test/relay-dep-drift.sh,test/relay-self-sufficiency.sh,test/relay-turn-handoff.sh,test/relay-turn-trace.sh,test/swarm-preflight.sh,test/xyz-vendor.sh,test/lib/attest-stub.sh,test/lib/vendored-fixture.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/synthetic/gh131-marathon-target-root.sh,test/unit/cli.test.js. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick release MARATHON-GH-554-TICK-UNKNOWN-FLAGS-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick done MARATHON-GH-554-TICK-UNKNOWN-FLAGS-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick
   Edit ONLY marathon-system/gh-554-tick-unknown-flags/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

### Round 1 · Builder · codex

Implemented a verb-specific flag allowlist in `bin/tick`, checked immediately after parsing and before
repository/root resolution, so an unknown option exits 2 with usage without reading or writing coordination
state. Added `test/gh554-tick-unknown-flags.sh`: it covers the original `release --status done` and arbitrary
unknown-flag reproductions, every other mutating verb, read-only verbs, an invalid `init` with no state
directory, and valid `--flag=value` plus `TICK_AGENT` fallback behavior. No tests were run locally, as
required by this isolated relay turn.

### Round 1 · Reviewer · agy

**swept file: yes**

I reviewed `bin/tick` and `test/gh554-tick-unknown-flags.sh` in their entirety.
- The newly added `FLAGS_BY_VERB` and `validateFlags` correctly intercept unknown flags and exit 2 with usage before touching any state or files.
- The flag validation works across all mutating verbs and read-only verbs as specified.
- The tests are comprehensive and correctly cover both the specific regression (`--status done`) and the general case for all verbs.
- No pre-existing defects were identified in `bin/tick` during the sweep. 

**Verdict:** Approved

relay closed, no further turn needed

### Attestation · relay-drive — 2026-09-11T02:02:38Z
task: MARATHON-GH-554-TICK-UNKNOWN-FLAGS-TURN
reviewer: agy
status: Approved
reviewed-head: 379fd76d40d93f3759e9ee817f53cfd31b5177d6
added-range: 18044+637
added-sha256: fcf38c56363587921d6eaec1219907fe53b64759b6ec8779e1f40b2e59ca77ed
