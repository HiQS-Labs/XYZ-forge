# Marathon Phase gh-1050-no-swap-false-low-swap-warning
STATUS: Open
NEXT: claude (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-1050-NO-SWAP-FALSE-LOW-SWAP-WARNING-TURN builder=codex reviewer=claude round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1050-no-swap-false-low-swap-warning

- Generated: 2026-11-16T05:11:40Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/PROJECT/2-WORKING/GH-1050-NO-SWAP-FALSE-LOW-SWAP-WARNING.md 
- Target root: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15 (development @ 2f4e9e540)
- Suggested branch: `marathon/gh-1050-no-swap-false-low-swap-warning-2026-11-16` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh --auto development`

- Artifacts: utils/py/marathon_drive.py,test/gh382-marathon-memory-telemetry.sh,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 4021 LOC across 33 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/PROJECT/2-WORKING/GH-1050-NO-SWAP-FALSE-LOW-SWAP-WARNING.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #1050 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] darwin stub `total = 0.00M used = 0.00M free = 0.00M` produces no low-swap warning and no `swap_free=` bit.
- [ ] darwin stub `total = 3072.00M used = 2560.00M free = 512.00M` still produces `warn: host free swap is critically low (512MB < 1024MB)`.
- [ ] Linux `/proc/meminfo` parsing also reads `SwapTotal:` and applies the same no-swap rule (verified by diff review; the suite's swap case is darwin-only).
- [ ] `test/gh382-marathon-memory-telemetry.sh` gains the no-swap case next to the existing low-swap case; all its cases pass.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/marathon_drive.py,test/gh382-marathon-memory-telemetry.sh,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh --auto development`, and NOT `test/gh382-marathon-memory-telemetry.sh,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/_setup.sh,test/lib/fixture-guard.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1050-no-swap-false-low-swap-warning RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/marathon_drive.py,test/gh382-marathon-memory-telemetry.sh,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh \
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
1. Implement the brief by creating/editing the artifact file(s): utils/py/marathon_drive.py,test/gh382-marathon-memory-telemetry.sh,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
   If a verification the brief asks for could not run (e.g. your sandbox denied a local service), put it on its own line: `unverified: <what> — <why>` (GH-1428).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick claim MARATHON-GH-1050-NO-SWAP-FALSE-LOW-SWAP-WARNING-TURN --agent codex --paths "marathon-system/gh-1050-no-swap-false-low-swap-warning/RELAY.md,utils/py/marathon_drive.py,test/gh382-marathon-memory-telemetry.sh,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick ping MARATHON-GH-1050-NO-SWAP-FALSE-LOW-SWAP-WARNING-TURN --agent codex
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick release MARATHON-GH-1050-NO-SWAP-FALSE-LOW-SWAP-WARNING-TURN --agent codex --to claude
4. Edit ONLY these paths: marathon-system/gh-1050-no-swap-false-low-swap-warning/RELAY.md and utils/py/marathon_drive.py,test/gh382-marathon-memory-telemetry.sh,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to claude — claude, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: claude (Reviewer)`

---

▶ TAKE YOUR TURN (claude — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/marathon_drive.py,test/gh382-marathon-memory-telemetry.sh,test/gh115-round-cap.sh,test/gh217-gate-env-plan-outside.sh,test/gh256-target-root-guard-root.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh307-gate-env-scrub.sh,test/gh322-runlog-python-lane.sh,test/gh342-sentinel-debug-log-python.sh,test/gh346-gateway-allowlists.sh,test/gh365-driver-lane-registry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh378-gate-requires-green-suite.sh,test/gh379-claude-builder-diagnosis.sh,test/gh385-retry-token-satisfied.sh,test/gh390-gate-guard.sh,test/gh399-packet-acceptance-continuation.sh,test/gh407-gate-ran-attribution.sh,test/gh438-acceptance-recheck.sh,test/gh438-removal-is-progress.sh,test/gh441-gate-env-contract.sh,test/gh457-gate-tiers.sh,test/gh467-index-only-lane-blocked.sh,test/gh491-gate-only-refire.sh,test/gh520-default-reviewer-stub.sh,test/gh642-consumer-fruit.sh,test/baselines/GH-402-negative-control.md,test/baselines/GH-514-negative-control.md,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · claude` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick release MARATHON-GH-1050-NO-SWAP-FALSE-LOW-SWAP-WARNING-TURN --agent claude --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick done MARATHON-GH-1050-NO-SWAP-FALSE-LOW-SWAP-WARNING-TURN --agent claude
3a. GATE EVIDENCE (GH-1428): this phase's gate (`bash validate.sh --auto development`) is not a focused file-only command, so it runs only in the harness after your turn — do NOT run it. Declare a literal `gate run: no — harness gate` line in your review block.
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1400-dogfood-exec-2026-11-15/bin/tick
   Edit ONLY marathon-system/gh-1050-no-swap-false-low-swap-warning/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

Implemented GH-1050 in `utils/py/marathon_drive.py` and extended the existing `test/gh382-marathon-memory-telemetry.sh` suite only.

Root cause: the sampler interpreted zero free swap without checking whether any swap existed; Fix site: platform swap parsing and the shared pre-telemetry normalization; Why not upstream/downstream: sysctl and /proc correctly report zero total, and normalization prevents both the warning and the tick cost argument from receiving a false exhausted-swap sample.

- Darwin reads `total` from the same sysctl response; Linux reads `SwapTotal:` regardless of line order. An explicit zero total sets `swap_free_mb` to None before logging and tick emission. Missing total preserves prior behavior. Positive total with zero free still warns.
- Added a Darwin no-swap fixture adjacent to the existing 512 MB low-swap fixture, checking successful execution, nonempty confirmation output, omitted free-swap sample and absence of warning / `swap_free=` output. Corrected the stale comment that claimed the sampler had no Linux branch.
- Reversibility: Easy; only the existing memory sampler and its existing covering suite change. Phase start, complete and escalation callers retain the same interface; compressor telemetry is preserved.
- Red control observed before editing: Darwin `total = 0.00M used = 0.00M free = 0.00M` returned swap_free_mb=0 and logged both the critically-low warning and `swap_free=0MB`.
- Focused isolated sampler verification passed 8 cases: Darwin/Linux each with total/free MB 0/0, 3072/512, 3072/0 and 3072/2048. Checks covered returned values, exact 512 MB warning, absent no-swap warning/log bit/tick argument, preserved compressor sample and exhausted-swap warning. Python source parsing and `bash -n test/gh382-marathon-memory-telemetry.sh` passed. Probes/logs are transient under `.relay-scratch/` and are not committed gate receipts.
- Graph tools unavailable in this session; inspected the exact sampler, its three callers and the covering suite by targeted source reads.

unverified: full gh382 fixture suite and project gate — relay scope lock assigns execution to the harness outside this linked worktree; neither was run here.

The top-level NEXT routing field was updated as explicitly required by the builder handoff instruction; other pre-existing relay text is unchanged.

handing off to claude — claude, take your turn.
