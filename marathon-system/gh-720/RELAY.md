# Marathon Phase gh-720
STATUS: Approved
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-720-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-720-review-once-block-regex

- Generated: 2026-09-22T02:01:48Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-720/PROJECT/2-WORKING/GH-720-REVIEW-ONCE-BLOCK-REGEX.md 
- Target root: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-720 (marathon/10days-2026-09-21 @ 8c311e74f)
- Suggested branch: `marathon/gh-720-review-once-block-regex-2026-09-22` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: utils/py/relay_drive.py,test/relay-review-once.sh,relay-automation/new-relay.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/gh681-reviewer-probe-rules.sh,test/marathon-root-audit.sh,test/new-relay.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1420 LOC across 21 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/gh681-reviewer-probe-rules.sh,test/marathon-root-audit.sh,test/new-relay.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-720/PROJECT/2-WORKING/GH-720-REVIEW-ONCE-BLOCK-REGEX.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #720 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] `review_blocks_added` in `utils/py/relay_drive.py` (regex at `:39`) counts a reviewer block
      whose heading is `### Reviewer (<agent>)` or `### Reviewer — Round N` as well as the `·`
      forms, while still requiring a non-empty body after the heading so a zero-output turn is
      still graded a stall (GH-397 intent preserved).
- [ ] `relay-automation/new-relay.sh`'s `▶ TAKE YOUR TURN` block states the heading form the oracle
      accepts, so a headless reviewer following the scaffold produces a countable block.
- [ ] `test/relay-review-once.sh` gains a regression case: a turn that appends a substantive block
      under `### Reviewer (agy)` and flips NEXT: exits 5, not 3; red control: a turn that moves
      the file but appends no block still exits 3.
- [ ] `bash validate.sh` exits 0.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/relay_drive.py,test/relay-review-once.sh,relay-automation/new-relay.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/gh681-reviewer-probe-rules.sh,test/marathon-root-audit.sh,test/new-relay.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/relay-review-once.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/gh681-reviewer-probe-rules.sh,test/marathon-root-audit.sh,test/new-relay.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-720-review-once-block-regex RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/relay_drive.py,test/relay-review-once.sh,relay-automation/new-relay.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/gh681-reviewer-probe-rules.sh,test/marathon-root-audit.sh,test/new-relay.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh \
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
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): utils/py/relay_drive.py,test/relay-review-once.sh,relay-automation/new-relay.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/gh681-reviewer-probe-rules.sh,test/marathon-root-audit.sh,test/new-relay.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-720/bin/tick
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-720/bin/tick claim MARATHON-GH-720-TURN --agent codex --paths "marathon-system/gh-720/RELAY.md,utils/py/relay_drive.py,test/relay-review-once.sh,relay-automation/new-relay.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/gh681-reviewer-probe-rules.sh,test/marathon-root-audit.sh,test/new-relay.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh"
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-720/bin/tick ping MARATHON-GH-720-TURN --agent codex
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-720/bin/tick release MARATHON-GH-720-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-720/RELAY.md and utils/py/relay_drive.py,test/relay-review-once.sh,relay-automation/new-relay.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/gh681-reviewer-probe-rules.sh,test/marathon-root-audit.sh,test/new-relay.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/relay_drive.py,test/relay-review-once.sh,relay-automation/new-relay.sh,test/gh115-round-cap.sh,test/gh204-sed-portability.sh,test/gh268-relay-cue-and-target-checks.sh,test/gh273-marathon-root-audit-python-shape.sh,test/gh331-cost-summary.sh,test/gh370-progress-telemetry.sh,test/gh371-interrupt-snapshot.sh,test/gh372-escalation-log-tail.sh,test/gh376-relay-drive-lock-parity.sh,test/gh441-gate-env-contract.sh,test/gh505-relay-attest.sh,test/gh681-reviewer-probe-rules.sh,test/marathon-root-audit.sh,test/new-relay.sh,test/synthetic/gh101-relay-programmatic-stress.sh,test/synthetic/gh129-relay-tick-root.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-720/bin/tick release MARATHON-GH-720-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-720/bin/tick done MARATHON-GH-720-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-720/bin/tick
   Edit ONLY marathon-system/gh-720/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

- Updated `utils/py/relay_drive.py` so the review-once oracle recognizes `Reviewer (<agent>)` and
  `Reviewer — Round N` headings alongside the existing middle-dot forms, while requiring substantive
  non-heading body text after every accepted heading.
- Updated `relay-automation/new-relay.sh` to tell reviewers exactly which countable heading forms the
  oracle accepts and that the block body must be non-empty.
- Added GH-720 coverage to `test/relay-review-once.sh`: a substantive `### Reviewer (agy)` block exits
  5, while a relay-file/NEXT mutation with no reviewer block remains a stall and exits 3.
- Verification: not run, as this phase brief explicitly forbids executing tests in the isolated
  worktree; the harness will run the gate after handoff.

### Round 1 · Reviewer · agy

swept file: yes

**Verdict:** Approved

#### Findings

- [Pass] `utils/py/relay_drive.py:42-51`: The `review_blocks_added` regex was extended to match `Reviewer (<agent>)` and `Reviewer — Round [^\r\n]+` headings in addition to the middle-dot forms (`Round ... · Reviewer` and `Reviewer · Round ...`), and preserves the GH-397 zero-output stall distinction with `(?!###(?:[ \t]|$))(?=[^\r\n]*\S)[^\r\n]+` requiring non-empty, non-heading body text. Verified with probe suite testing all heading variants, trailing whitespace, multiline whitespace, and empty blocks.
- [Pass] `relay-automation/new-relay.sh:106-107`: Step 4 of the scaffolded `▶ TAKE YOUR TURN` block explicitly states the accepted countable heading forms (`### Reviewer (<agent>)`, `### Reviewer · Round N`, or `### Reviewer — Round N`) and notes that the body must be non-empty, preventing headless reviewer stall false positives.
- [Pass] `test/relay-review-once.sh:114-142`: Case G added for GH-720 verifying that a substantive block under `### Reviewer (agy)` with `NEXT: producer` exits 5; Case H added verifying the red control where relay metadata moves without a reviewer block still exits 3 as a genuine stall.
- [Unverified — needs clone run] Acceptance criterion 4: `bash validate.sh` exits 0. Per phase brief instructions, full test/gate suites must not be executed inside the isolated worktree to prevent containment failures; deferred to the post-turn harness gate.

#### Sweep Notes
- `utils/py/relay_drive.py`: Swept full file (1130 lines). Python syntax validated (`py_compile` cleanly passed), `test/gh648-l8-zero-output-handback.sh` unit test suite confirmed passing. Pre-existing code has no unhandled exceptions in the review oracle call path.
- `relay-automation/new-relay.sh`: Swept full file (191 lines). Bash syntax validated (`bash -n` cleanly passed).
- `test/relay-review-once.sh`: Swept full file (145 lines). Bash syntax validated (`bash -n` cleanly passed).
- Pre-existing defects: None found in swept files.

relay closed, no further turn needed
