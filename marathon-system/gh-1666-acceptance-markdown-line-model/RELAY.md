# Marathon Phase gh-1666-acceptance-markdown-line-model
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL-TURN builder=codex reviewer=agy round-cap=9 -->

## Phase Brief

# Marathon preflight packet — gh-1666-acceptance-markdown-line-model

- Generated: 2026-11-27T22:57:34Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/flywheel-runA-exec/PROJECT/2-WORKING/GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL.md 
- Target root: /Users/noelsaw/flywheel-runA-exec (development @ 5515712e1)
- Suggested branch: `marathon/gh-1666-acceptance-markdown-line-model-2026-11-27` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash test/gh400-acceptance-fidelity.sh`

- Artifacts: utils/py/swarm_preflight.py,test/gh400-acceptance-fidelity.sh,TESTS-RESULTS/2026-11-27+GH-1666/delivery.md,test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/test_python_layer.py,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 2847 LOC across 15 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/test_python_layer.py,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/flywheel-runA-exec/PROJECT/2-WORKING/GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL.md` (its `## Acceptance` section, 3 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #1666](https://github.com/HiQS-Labs/XYZ-forge/issues/1666) — 3/3 criteria copied verbatim from issue #1666.*
- [ ] Issue extraction, capture extraction and `collect_inline_checklist` split lines on `\r\n`, `\r`, `\n` only.
- [ ] The U+2028 fence-closer input and the `Alpha
- [ ] Covered in the existing `test/gh400-acceptance-fidelity.sh` (no new suite, GH-831).

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/swarm_preflight.py,test/gh400-acceptance-fidelity.sh,TESTS-RESULTS/2026-11-27+GH-1666/delivery.md,test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/test_python_layer.py,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash test/gh400-acceptance-fidelity.sh`, and NOT `test/gh400-acceptance-fidelity.sh,test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1666-acceptance-markdown-line-model RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex --round-cap 9 \
  --artifact utils/py/swarm_preflight.py,test/gh400-acceptance-fidelity.sh,TESTS-RESULTS/2026-11-27+GH-1666/delivery.md,test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/test_python_layer.py,test/_setup.sh \
  --pre-advance-cmd 'bash test/gh400-acceptance-fidelity.sh' \
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
1. Implement the brief by creating/editing the artifact file(s): utils/py/swarm_preflight.py,test/gh400-acceptance-fidelity.sh,TESTS-RESULTS/2026-11-27+GH-1666/delivery.md,test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/test_python_layer.py,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
   If a verification the brief asks for could not run (e.g. your sandbox denied a local service), put it on its own line: `unverified: <what> — <why>` (GH-1428).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/flywheel-runA-exec/bin/tick
   - /Users/noelsaw/flywheel-runA-exec/bin/tick claim MARATHON-GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL-TURN --agent codex --paths "marathon-system/gh-1666-acceptance-markdown-line-model/RELAY.md,utils/py/swarm_preflight.py,test/gh400-acceptance-fidelity.sh,TESTS-RESULTS/2026-11-27+GH-1666/delivery.md,test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/test_python_layer.py,test/_setup.sh"
   - /Users/noelsaw/flywheel-runA-exec/bin/tick ping MARATHON-GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL-TURN --agent codex
   - /Users/noelsaw/flywheel-runA-exec/bin/tick release MARATHON-GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-1666-acceptance-markdown-line-model/RELAY.md and utils/py/swarm_preflight.py,test/gh400-acceptance-fidelity.sh,TESTS-RESULTS/2026-11-27+GH-1666/delivery.md,test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/test_python_layer.py,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/swarm_preflight.py,test/gh400-acceptance-fidelity.sh,TESTS-RESULTS/2026-11-27+GH-1666/delivery.md,test/gh280-jog-marathon-adapter.sh,test/gh343-gate-program-target-root.sh,test/gh386-turn-budget-honesty.sh,test/gh399-packet-acceptance-continuation.sh,test/gh400-source-url.sh,test/gh418-issue-state-frozen.sh,test/gh422-backfill-source-url.sh,test/gh425-source-url-slug.sh,test/gh557-unknown-blocks-manifest.sh,test/gh642-consumer-fruit.sh,test/test_python_layer.py,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/flywheel-runA-exec/bin/tick release MARATHON-GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/flywheel-runA-exec/bin/tick done MARATHON-GH-1666-ACCEPTANCE-MARKDOWN-LINE-MODEL-TURN --agent agy
3a. GATE EVIDENCE (GH-1428): this phase's gate (`bash test/gh400-acceptance-fidelity.sh`) is not a focused file-only command, so it runs only in the harness after your turn — do NOT run it. Declare a literal `gate run: no — harness gate` line in your review block.
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/flywheel-runA-exec/bin/tick
   Edit ONLY marathon-system/gh-1666-acceptance-markdown-line-model/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

### Round 1 · Builder · codex

- `utils/py/swarm_preflight.py` now uses a shared Markdown line splitter for issue and capture criteria, declared deviations, and packet checklists. Issue-side fence detection uses the same lines directly.
- `test/gh400-acceptance-fidelity.sh` adds the shortened U+2028 copy and covers all eight extra Python separators across the readers, with mixed CRLF/CR/LF boundaries. The existing positive U+2028 fidelity cases remain in the suite.
- The local GH-1666 issue document supplied the packet's truncated second criterion. The prepared manual probe failed before the change with `('0xb', ['Alpha', 'Gamma'], ['Alpha', 'Gamma'])` and passed afterward. Direct fidelity calls returned `match` for the U+2028 fence-closer input and verbatim copy, and `diverged` for the shortened copy. Packet rendering retained U+2028. Shell and Python syntax checks passed. See `TESTS-RESULTS/2026-11-27+GH-1666/delivery.md`.

unverified: `bash test/gh400-acceptance-fidelity.sh` — the relay reserves this fixture-writing gate for harness execution.

handing off to agy — agy, take your turn.
