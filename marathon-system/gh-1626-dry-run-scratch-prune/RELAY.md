# Marathon Phase gh-1626-dry-run-scratch-prune
STATUS: Open
NEXT: codex (Builder)

<!-- marathon-drive: task=MARATHON-GH-1626-DRY-RUN-SCRATCH-PRUNE-TURN builder=codex reviewer=agy round-cap=2 -->

## Phase Brief

# Marathon preflight packet — gh-1626-dry-run-scratch-prune

- Generated: 2026-11-27T16:07:21Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/flywheel-day3-exec/PROJECT/2-WORKING/GH-1626-DRY-RUN-SCRATCH-PRUNE.md 
- Target root: /Users/noelsaw/flywheel-day3-exec (development @ ee57cf67a)
- Suggested branch: `marathon/gh-1626-dry-run-scratch-prune-2026-11-27` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash test/gh436-merge-cleanup.sh`

- Artifacts: skills/2-daily/merge-cleanup/scripts/merge_cleanup.py,TESTS-RESULTS/2026-11-27+GH-1626/delivery.md,test/gh549-work-events.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 3327 LOC across 3 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh549-work-events.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/flywheel-day3-exec/PROJECT/2-WORKING/GH-1626-DRY-RUN-SCRATCH-PRUNE.md` (its `## Acceptance` section, 3 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #1626 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] A `merge_cleanup.py` landing run without `--execute` (dry run) removes no retained `merge-cleanup-*` / `merge-check-*` folder: `prune_retained_scratch` is skipped or reports only.
- [ ] An executing landing run still prunes old retained scratch folders exactly as today (same keep count, age floor, tool-shape and lsof checks).
- [ ] The existing `test/gh436-merge-cleanup.sh` suite stays green; a manual check under `TESTS-RESULTS/` records both cases (GH-831: no new tests).

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `skills/2-daily/merge-cleanup/scripts/merge_cleanup.py,TESTS-RESULTS/2026-11-27+GH-1626/delivery.md,test/gh549-work-events.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash test/gh436-merge-cleanup.sh`, and NOT `test/gh549-work-events.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1626-dry-run-scratch-prune RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex --round-cap 2 \
  --artifact skills/2-daily/merge-cleanup/scripts/merge_cleanup.py,TESTS-RESULTS/2026-11-27+GH-1626/delivery.md,test/gh549-work-events.sh \
  --pre-advance-cmd 'bash test/gh436-merge-cleanup.sh' \
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
1. Implement the brief by creating/editing the artifact file(s): skills/2-daily/merge-cleanup/scripts/merge_cleanup.py,TESTS-RESULTS/2026-11-27+GH-1626/delivery.md,test/gh549-work-events.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
   If a verification the brief asks for could not run (e.g. your sandbox denied a local service), put it on its own line: `unverified: <what> — <why>` (GH-1428).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/flywheel-day3-exec/bin/tick
   - /Users/noelsaw/flywheel-day3-exec/bin/tick claim MARATHON-GH-1626-DRY-RUN-SCRATCH-PRUNE-TURN --agent codex --paths "marathon-system/gh-1626-dry-run-scratch-prune/RELAY.md,skills/2-daily/merge-cleanup/scripts/merge_cleanup.py,TESTS-RESULTS/2026-11-27+GH-1626/delivery.md,test/gh549-work-events.sh"
   - /Users/noelsaw/flywheel-day3-exec/bin/tick ping MARATHON-GH-1626-DRY-RUN-SCRATCH-PRUNE-TURN --agent codex
   - /Users/noelsaw/flywheel-day3-exec/bin/tick release MARATHON-GH-1626-DRY-RUN-SCRATCH-PRUNE-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-1626-dry-run-scratch-prune/RELAY.md and skills/2-daily/merge-cleanup/scripts/merge_cleanup.py,TESTS-RESULTS/2026-11-27+GH-1626/delivery.md,test/gh549-work-events.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: skills/2-daily/merge-cleanup/scripts/merge_cleanup.py,TESTS-RESULTS/2026-11-27+GH-1626/delivery.md,test/gh549-work-events.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/flywheel-day3-exec/bin/tick release MARATHON-GH-1626-DRY-RUN-SCRATCH-PRUNE-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/flywheel-day3-exec/bin/tick done MARATHON-GH-1626-DRY-RUN-SCRATCH-PRUNE-TURN --agent agy
3a. GATE EVIDENCE (GH-1428): this phase's gate (`bash test/gh436-merge-cleanup.sh`) is not a focused file-only command, so it runs only in the harness after your turn — do NOT run it. Declare a literal `gate run: no — harness gate` line in your review block.
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/flywheel-day3-exec/bin/tick
   Edit ONLY marathon-system/gh-1626-dry-run-scratch-prune/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
