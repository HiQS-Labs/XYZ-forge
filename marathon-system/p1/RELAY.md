# Marathon Phase p1
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-P1-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-413-launch-artifact-marker-destruction

- Generated: 2026-09-03T23:28:44Z
- Mode: project-doc
- Sources: /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/PROJECT/1-INBOX/GH-413-LAUNCH-ARTIFACT-MARKER-DESTRUCTION.md 
- Target root: /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation (development @ c205ef3fd)
- Suggested branch: `marathon/gh-413-launch-artifact-marker-destruction-2026-09-03` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: utils/build-launch-artifact.sh,test/gh413-launch-artifact-destination-guard.sh,test/baselines/GH-413-negative-control.md,test/gh204-sed-portability.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 352 LOC across 5 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh204-sed-portability.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/PROJECT/1-INBOX/GH-413-LAUNCH-ARTIFACT-MARKER-DESTRUCTION.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #413](https://github.com/HiQS-Labs/XYZ-forge/issues/413) — 4/4 criteria copied verbatim from issue #413.*
- [ ] A marker-only directory with no git history is **refused**.
- [ ] A destination with >1 commit is refused without `--discard-history`.
- [ ] Both cited ADRs survive into the built artifact.
- [ ] Red control recorded: the pre-fix script wipes the marker-only fixture; the fixed one refuses it.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/build-launch-artifact.sh,test/gh413-launch-artifact-destination-guard.sh,test/baselines/GH-413-negative-control.md,test/gh204-sed-portability.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/gh204-sed-portability.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-413-launch-artifact-marker-destruction RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/build-launch-artifact.sh,test/gh413-launch-artifact-destination-guard.sh,test/baselines/GH-413-negative-control.md,test/gh204-sed-portability.sh,test/_setup.sh \
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
1. Implement the brief by creating/editing the artifact file(s): utils/build-launch-artifact.sh,test/gh413-launch-artifact-destination-guard.sh,test/baselines/GH-413-negative-control.md,test/gh204-sed-portability.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick
   - /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick claim MARATHON-P1-TURN --agent codex --paths "marathon-system/p1/RELAY.md,utils/build-launch-artifact.sh,test/gh413-launch-artifact-destination-guard.sh,test/baselines/GH-413-negative-control.md,test/gh204-sed-portability.sh,test/_setup.sh"
   - /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick ping MARATHON-P1-TURN --agent codex
   - /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick release MARATHON-P1-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/p1/RELAY.md and utils/build-launch-artifact.sh,test/gh413-launch-artifact-destination-guard.sh,test/baselines/GH-413-negative-control.md,test/gh204-sed-portability.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/build-launch-artifact.sh,test/gh413-launch-artifact-destination-guard.sh,test/baselines/GH-413-negative-control.md,test/gh204-sed-portability.sh,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick release MARATHON-P1-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick done MARATHON-P1-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/marathon-gh-417-gh406-remediation/bin/tick
   Edit ONLY marathon-system/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

Implemented GH-413 in `utils/build-launch-artifact.sh`: removed the copyable marker as rebuild
authority and artifact output, reject non-git nonempty directories (including marker-only ones),
and require explicit `--discard-history` before clearing a destination with more than one commit.
The legacy marker is pruned from generated artifacts. Added the focused destination-guard suite and
recorded the pre-fix destructive control in `test/baselines/GH-413-negative-control.md`; the suite
checks marker refusal/payload preservation, multi-commit refusal, explicit opt-in rebuild, marker
absence, and retention of the two cited launch decision records. Per the phase scope lock, I did not
run tests; the harness will run the gate outside this worktree.
