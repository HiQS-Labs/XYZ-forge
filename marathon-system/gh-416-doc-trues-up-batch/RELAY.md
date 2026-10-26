# Marathon Phase gh-416-doc-trues-up-batch
STATUS: Open
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-416-DOC-TRUES-UP-BATCH-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-416-doc-trues-up-batch

- Generated: 2026-10-26T03:26:18Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh416-phase0-r2/PROJECT/2-WORKING/GH-416-DOC-TRUES-UP-BATCH.md 
- Target root: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh416-phase0-r2 (development @ 1f5b05084)
- Suggested branch: `marathon/gh-416-doc-trues-up-batch-2026-10-26` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh --auto development` (routed by validate.sh --auto from contract gate `bash validate.sh`)

- Artifacts: package.json,package-lock.json,skills/1-hourly/relay-xyz/SKILL.md,test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh346-gateway-allowlists.sh,test/gh617-relay-xyz-commensurate-review.sh,test/gh681-reviewer-probe-rules.sh,test/xyz-vendor.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 825 LOC across 10 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh346-gateway-allowlists.sh,test/gh617-relay-xyz-commensurate-review.sh,test/gh681-reviewer-probe-rules.sh,test/xyz-vendor.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh416-phase0-r2/PROJECT/2-WORKING/GH-416-DOC-TRUES-UP-BATCH.md` (its `## Acceptance` section, 2 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #416](https://github.com/HiQS-Labs/XYZ-forge/issues/416) — 4 issue criteria reconciled: 2 deviation(s) declared and accounted for.*
- [ ] `acorn` / `acorn-walk` under `devDependencies`; §7 reads true.
- [ ] `SKILL.md` states the real `CODEX_FLAGS` default **and** a real escalation rung.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `package.json,package-lock.json,skills/1-hourly/relay-xyz/SKILL.md,test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh346-gateway-allowlists.sh,test/gh617-relay-xyz-commensurate-review.sh,test/gh681-reviewer-probe-rules.sh,test/xyz-vendor.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh --auto development`, and NOT `test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh346-gateway-allowlists.sh,test/gh617-relay-xyz-commensurate-review.sh,test/gh681-reviewer-probe-rules.sh,test/xyz-vendor.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-416-doc-trues-up-batch RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact package.json,package-lock.json,skills/1-hourly/relay-xyz/SKILL.md,test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh346-gateway-allowlists.sh,test/gh617-relay-xyz-commensurate-review.sh,test/gh681-reviewer-probe-rules.sh,test/xyz-vendor.sh,test/_setup.sh \
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

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): package.json,package-lock.json,skills/1-hourly/relay-xyz/SKILL.md,test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh346-gateway-allowlists.sh,test/gh617-relay-xyz-commensurate-review.sh,test/gh681-reviewer-probe-rules.sh,test/xyz-vendor.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh416-phase0-r2/bin/tick
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh416-phase0-r2/bin/tick claim MARATHON-GH-416-DOC-TRUES-UP-BATCH-TURN --agent agy --paths "marathon-system/gh-416-doc-trues-up-batch/RELAY.md,package.json,package-lock.json,skills/1-hourly/relay-xyz/SKILL.md,test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh346-gateway-allowlists.sh,test/gh617-relay-xyz-commensurate-review.sh,test/gh681-reviewer-probe-rules.sh,test/xyz-vendor.sh,test/_setup.sh"
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh416-phase0-r2/bin/tick ping MARATHON-GH-416-DOC-TRUES-UP-BATCH-TURN --agent agy
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh416-phase0-r2/bin/tick release MARATHON-GH-416-DOC-TRUES-UP-BATCH-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-416-doc-trues-up-batch/RELAY.md and package.json,package-lock.json,skills/1-hourly/relay-xyz/SKILL.md,test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh346-gateway-allowlists.sh,test/gh617-relay-xyz-commensurate-review.sh,test/gh681-reviewer-probe-rules.sh,test/xyz-vendor.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: package.json,package-lock.json,skills/1-hourly/relay-xyz/SKILL.md,test/find-harness.sh,test/gh278-turn-timeout-parity.sh,test/gh346-gateway-allowlists.sh,test/gh617-relay-xyz-commensurate-review.sh,test/gh681-reviewer-probe-rules.sh,test/xyz-vendor.sh,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh416-phase0-r2/bin/tick release MARATHON-GH-416-DOC-TRUES-UP-BATCH-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh416-phase0-r2/bin/tick done MARATHON-GH-416-DOC-TRUES-UP-BATCH-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-gh416-phase0-r2/bin/tick
   Edit ONLY marathon-system/gh-416-doc-trues-up-batch/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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


### Round 1 · Builder · agy

- **Files touched:**
  - `package.json`: Moved `acorn` (`^8.17.0`) and `acorn-walk` (`^8.3.5`) from `dependencies` to `devDependencies`.
  - `package-lock.json`: Mirrored the `devDependencies` classification under root `packages[""]` and added `"dev": true` to `node_modules/acorn` and `node_modules/acorn-walk`.
  - `skills/1-hourly/relay-xyz/SKILL.md`: Updated the `CODEX_FLAGS` default in the turn-taker env table (line 597) from `-s workspace-write` to `-s workspace-write -c approval_policy=never`, and removed the dead `(or -c approval_policy=never)` escalation suffix on line 602 so only `CODEX_FLAGS='--dangerously-bypass-approvals-and-sandbox'` is named as the escalation rung.
- **Verification:** Checked against `GH-416-DOC-TRUES-UP-BATCH.md` fix probes and acceptance criteria (no test scripts run inside the isolated worktree per the scope lock).
