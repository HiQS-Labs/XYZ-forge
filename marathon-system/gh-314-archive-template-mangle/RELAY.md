# Marathon Phase gh-314-archive-template-mangle
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-GH-314-ARCHIVE-TEMPLATE-MANGLE-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-314-archive-template-mangle

- Generated: 2026-08-29T07:44:38Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/XYZ-forge-jog-run/PROJECT/2-WORKING/GH-314-ARCHIVE-TEMPLATE-MANGLE.md 
- Target root: /Users/noelsaw/Documents/GH Repos/XYZ-forge-jog-run (development @ 5e0061013)
- Suggested branch: `marathon/gh-314-archive-template-mangle-2026-08-29` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1236 LOC across 8 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/_setup.sh,test/lib/fixture-guard.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GH Repos/XYZ-forge-jog-run/PROJECT/2-WORKING/GH-314-ARCHIVE-TEMPLATE-MANGLE.md` (its `## Acceptance` section, 3 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #314](https://github.com/HiQS-Labs/XYZ-forge/issues/314) — 3/3 criteria copied verbatim from issue #314.*
- [ ] `bash test/wave-reconcile.sh` passes with a new regression assertion archiving a
  separator-less fixture entry — the archived line carries no nested/mismatched bold markers.
- [ ] The existing mangled GH-222 Completed line in `ROADMAP.md` is normalized
  (no `- **GH-222 ** ✅` shape remains).
- [ ] `./validate.sh` green on the lane branch.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/_setup.sh,test/lib/fixture-guard.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/_setup.sh,test/lib/fixture-guard.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-314-archive-template-mangle RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/_setup.sh,test/lib/fixture-guard.sh \
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

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/_setup.sh,test/lib/fixture-guard.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-jog-run/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-jog-run/bin/tick claim MARATHON-GH-314-ARCHIVE-TEMPLATE-MANGLE-TURN --agent agy --paths "marathon-system/gh-314-archive-template-mangle/RELAY.md,utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/_setup.sh,test/lib/fixture-guard.sh"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-jog-run/bin/tick ping MARATHON-GH-314-ARCHIVE-TEMPLATE-MANGLE-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-jog-run/bin/tick release MARATHON-GH-314-ARCHIVE-TEMPLATE-MANGLE-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-314-archive-template-mangle/RELAY.md and utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/_setup.sh,test/lib/fixture-guard.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-jog-run/bin/tick release MARATHON-GH-314-ARCHIVE-TEMPLATE-MANGLE-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-jog-run/bin/tick done MARATHON-GH-314-ARCHIVE-TEMPLATE-MANGLE-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-jog-run/bin/tick
   Edit ONLY marathon-system/gh-314-archive-template-mangle/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
