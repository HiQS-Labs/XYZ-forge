# Marathon Phase gh-1171-branch-artifact-preflight
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-1171-BRANCH-ARTIFACT-PREFLIGHT-TURN builder=codex reviewer=agy round-cap=2 -->

## Phase Brief

# Marathon preflight packet — gh-1171-branch-artifact-preflight

- Generated: 2026-11-11T06:23:02Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-runner-20261111/PROJECT/2-WORKING/GH-1171-BRANCH-ARTIFACT-PREFLIGHT.md 
- Target root: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-runner-20261111 (development @ 7901dddd6)
- Suggested branch: `marathon/gh-1171-branch-artifact-preflight-2026-11-11` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash test/gh376-relay-drive-lock-parity.sh`

- Artifacts: utils/py/relay_drive.py,TESTS-RESULTS/2026-11-11+GH-1171/,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1181 LOC across 17 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-runner-20261111/PROJECT/2-WORKING/GH-1171-BRANCH-ARTIFACT-PREFLIGHT.md` (its `## Acceptance` section, 3 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #1171](https://github.com/HiQS-Labs/XYZ-forge/issues/1171) — 0 issue criteria reconciled: 3 deviation(s) declared and accounted for.*  [Unverified — no citation]
- [ ] An existing slash-containing local branch on Artifact under review passes preflight.
- [ ] A genuinely missing docs/gh1171-missing.md still fails with the existing diagnostic.
- [ ] Record manual regression controls with provenance; no new suite or gate.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/relay_drive.py,TESTS-RESULTS/2026-11-11+GH-1171/,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash test/gh376-relay-drive-lock-parity.sh`, and NOT `test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1171-branch-artifact-preflight RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex --round-cap 2 \
  --artifact utils/py/relay_drive.py,TESTS-RESULTS/2026-11-11+GH-1171/,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh \
  --pre-advance-cmd 'bash test/gh376-relay-drive-lock-parity.sh' \
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
1. Implement the brief by creating/editing the artifact file(s): utils/py/relay_drive.py,TESTS-RESULTS/2026-11-11+GH-1171/,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-runner-20261111/bin/tick
   - /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-runner-20261111/bin/tick claim MARATHON-GH-1171-BRANCH-ARTIFACT-PREFLIGHT-TURN --agent codex --paths "marathon-system/gh-1171-branch-artifact-preflight/RELAY.md,utils/py/relay_drive.py,TESTS-RESULTS/2026-11-11+GH-1171/,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh"
   - /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-runner-20261111/bin/tick ping MARATHON-GH-1171-BRANCH-ARTIFACT-PREFLIGHT-TURN --agent codex
   - /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-runner-20261111/bin/tick release MARATHON-GH-1171-BRANCH-ARTIFACT-PREFLIGHT-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-1171-branch-artifact-preflight/RELAY.md and utils/py/relay_drive.py,TESTS-RESULTS/2026-11-11+GH-1171/,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/relay_drive.py,TESTS-RESULTS/2026-11-11+GH-1171/,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-runner-20261111/bin/tick release MARATHON-GH-1171-BRANCH-ARTIFACT-PREFLIGHT-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-runner-20261111/bin/tick done MARATHON-GH-1171-BRANCH-ARTIFACT-PREFLIGHT-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-7f312279/temp/gh1386-runner-20261111/bin/tick
   Edit ONLY marathon-system/gh-1171-branch-artifact-preflight/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

Implemented GH-1171 in `utils/py/relay_drive.py`. Missing filesystem candidates are now checked against exact `refs/heads/<candidate>` and `refs/remotes/origin/<candidate>` in the resolved target repository using `show-ref --verify --quiet`. Only verified branches bypass the existing missing-path diagnostic; tags and arbitrary revisions do not qualify. Existing file, URL and embedded-artifact handling is unchanged. Frozen Bash twin and existing suites untouched.

Root cause: slash-containing branch names satisfy the path heuristic but were never checked as refs; fix site: the existing missing-artifact admission branch; why here: this is where the overloaded Setup artifact field is interpreted. Easy reversibility: one bounded source change, no persistent state migration.

Manual control: `python3 .relay-scratch/control.py` exited 0. AST-extracted pre-change functions reject controlled local/origin branch inputs; changed functions accept both; `docs/gh1171-missing.md` and a branch-shaped typo still fail with the exact existing diagnostic. Exact lookup argv and target-root anchoring asserted. Python AST parsing also passed. Subprocess lookup was stubbed: no Git command was executed and this is not a real-repository integration claim. Receipt appended to `TESTS-RESULTS/2026-11-11+GH-1171/provenance.jsonl`, bound to the source SHA-256; generated outputs remain in `.relay-scratch/`. Existing `manual_probe.py` remains available for the harness's real fixture witness.

Verification limit: no shell suite or gate run in this worktree, as instructed by the scope lock; harness must run the declared gh376 gate and real manual regression probe before completion. No new suite or gate, no git operations, no changes to adjacent helpers. The required NEXT header update is the sole edit above this appended block.

Handing off to agy for independent review.
