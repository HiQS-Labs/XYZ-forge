# Marathon Phase gh-529-relay-marker-attestation
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-GH-529-RELAY-MARKER-ATTESTATION-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-529-relay-marker-attestation

- Generated: 2026-09-11T01:38:18Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/PROJECT/2-WORKING/GH-529-RELAY-MARKER-ATTESTATION.md 
- Target root: /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561 (development @ 4424c9ef3)
- Suggested branch: `marathon/gh-529-relay-marker-attestation-2026-09-11` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash test/new-relay.sh && bash test/gh410-relay-block-driven-path.sh`

- Artifacts: relay-automation/new-relay.sh,utils/py/relay_attest.py,utils/py/relay_drive.py,test/new-relay.sh,test/gh410-relay-block-driven-path.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1985 LOC across 21 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/PROJECT/2-WORKING/GH-529-RELAY-MARKER-ATTESTATION.md` (its `## Acceptance` section, 5 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #529](https://github.com/HiQS-Labs/XYZ-forge/issues/529) — 5/5 criteria copied verbatim from issue #529.*
- [ ] A reviewer following the generated `TAKE YOUR TURN` instructions can append a valid terminal review and pass canonical-prefix attestation.
- [ ] A reviewer that changes content above its own new block is still refused.
- [ ] Repeated turns do not accumulate competing trailing markers.
- [ ] Refused terminal turns return to a resumable header/token state.
- [ ] The regression test exercises the generated scaffold rather than a hand-built approximation.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/new-relay.sh,utils/py/relay_attest.py,utils/py/relay_drive.py,test/new-relay.sh,test/gh410-relay-block-driven-path.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash test/new-relay.sh && bash test/gh410-relay-block-driven-path.sh`, and NOT `test/new-relay.sh,test/gh410-relay-block-driven-path.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-529-relay-marker-attestation RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/new-relay.sh,utils/py/relay_attest.py,utils/py/relay_drive.py,test/new-relay.sh,test/gh410-relay-block-driven-path.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh \
  --pre-advance-cmd 'bash test/new-relay.sh && bash test/gh410-relay-block-driven-path.sh' \
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

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): relay-automation/new-relay.sh,utils/py/relay_attest.py,utils/py/relay_drive.py,test/new-relay.sh,test/gh410-relay-block-driven-path.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick
   - /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick claim MARATHON-GH-529-RELAY-MARKER-ATTESTATION-TURN --agent agy --paths "marathon-system/gh-529-relay-marker-attestation/RELAY.md,relay-automation/new-relay.sh,utils/py/relay_attest.py,utils/py/relay_drive.py,test/new-relay.sh,test/gh410-relay-block-driven-path.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh"
   - /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick ping MARATHON-GH-529-RELAY-MARKER-ATTESTATION-TURN --agent agy
   - /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick release MARATHON-GH-529-RELAY-MARKER-ATTESTATION-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-529-relay-marker-attestation/RELAY.md and relay-automation/new-relay.sh,utils/py/relay_attest.py,utils/py/relay_drive.py,test/new-relay.sh,test/gh410-relay-block-driven-path.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/new-relay.sh,utils/py/relay_attest.py,utils/py/relay_drive.py,test/new-relay.sh,test/gh410-relay-block-driven-path.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/marathon-root-audit.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick release MARATHON-GH-529-RELAY-MARKER-ATTESTATION-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick done MARATHON-GH-529-RELAY-MARKER-ATTESTATION-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/xyz-jog-529-533-555-561/bin/tick
   Edit ONLY marathon-system/gh-529-relay-marker-attestation/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
