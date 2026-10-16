# Marathon Phase gh-1087-gh1051-record-spacing
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-GH-1087-GH1051-RECORD-SPACING-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1087-gh1051-record-spacing

- Generated: 2026-10-16T21:54:47Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/PROJECT/2-WORKING/GH-1087-GH1051-RECORD-SPACING.md 
- Target root: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify (development @ f7710e25b)
- Suggested branch: `marathon/gh-1087-gh1051-record-spacing-2026-10-16` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash utils/pdda/pdda.sh run`

- Artifacts: PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md
- Suggested turn budget: none needed — ≈ 58 LOC across 1 artifact(s) fits the 900s default. Set `turn_timeout_s:` in this phase's MARATHON.yaml entry only to raise it; marathon.sh reads that field, and nothing reads a bare RELAY_TURN_TIMEOUT_S written into a packet.


This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/PROJECT/2-WORKING/GH-1087-GH1051-RECORD-SPACING.md` (its `## Acceptance` section, 3 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #1087 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] The three named joined tokens are gone and read as separated words / formatted identifiers.
- [ ] No other line of the file changed in meaning; `git diff --stat` touches only that file.
- [ ] `bash utils/pdda/pdda.sh run` has zero errors (GH-831: no new suite).

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run the full gate (`bash utils/pdda/pdda.sh run`) yourself — it can create files that trip containment and discard your turn. Verify with ONLY the specific test for the file(s) you changed; the harness runs the gate after your turn.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1087-gh1051-record-spacing RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md \
  --pre-advance-cmd 'bash utils/pdda/pdda.sh run' \
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
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick claim MARATHON-GH-1087-GH1051-RECORD-SPACING-TURN --agent agy --paths "marathon-system/gh-1087-gh1051-record-spacing/RELAY.md,PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md"
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick ping MARATHON-GH-1087-GH1051-RECORD-SPACING-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick release MARATHON-GH-1087-GH1051-RECORD-SPACING-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-1087-gh1051-record-spacing/RELAY.md and PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: PROJECT/3-COMPLETED/GH-1051-PAGES-DEVELOPMENT.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick release MARATHON-GH-1087-GH1051-RECORD-SPACING-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick done MARATHON-GH-1087-GH1051-RECORD-SPACING-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/XYZ-forge-gh1098-shift-phase3-2026-10-16-verify/bin/tick
   Edit ONLY marathon-system/gh-1087-gh1051-record-spacing/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
5. HAND OFF EXPLICITLY (GH-268): end your turn by naming who acts next — "handing off to agy —
   agy, take your turn" when requesting changes, or "relay closed, no further turn needed" when
   approving. The beta report singled this out: the Reviewer turn did not tell the user to go back to the
   Producer, so the relay looked stalled when it was simply waiting. Do this EVERY round.
