# Marathon Phase gh-707
STATUS: Open
NEXT: codex (Builder)

<!-- marathon-drive: task=MARATHON-GH-707-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-707-reconcile-rollback-envelope

- Generated: 2026-09-22T04:04:38Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-707/PROJECT/2-WORKING/GH-707-RECONCILE-ROLLBACK-ENVELOPE.md 
- Target root: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-707 (marathon/10days-2026-09-21 @ df8ee36f1)
- Suggested branch: `marathon/gh-707-reconcile-rollback-envelope-2026-09-22` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh496-phase2-reconciliation-views.sh,test/gh567-roadmap-dashboard-retired.sh,test/gh568-releases-md-retired.sh,test/gh693-lessons-learned-advisory.sh,test/baselines/gh678-pulse2/baseline-gh425.log,test/_setup.sh,test/lib/fixture-guard.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 2557 LOC across 15 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh496-phase2-reconciliation-views.sh,test/gh567-roadmap-dashboard-retired.sh,test/gh568-releases-md-retired.sh,test/gh693-lessons-learned-advisory.sh,test/baselines/gh678-pulse2/baseline-gh425.log,test/_setup.sh,test/lib/fixture-guard.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-707/PROJECT/2-WORKING/GH-707-RECONCILE-ROLLBACK-ENVELOPE.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #707 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] `TxnGuard.rollback()` emits the record with the envelope express uses (`schema_version:
      "0.2.0"`, ISO `ts`, `type: "wave_reconcile.rollback"`, `agent: "wave_reconcile"`, keeps
      `reason`), written beside the log under `.tick/reconcile/` (preferred) — or, if the
      minimal option is taken, keeps the location with a non-`task.*` `type`, no `task`, and
      this doc records that it relies on the #702 filter.
- [ ] `test/wave-reconcile.sh` forces a rollback in a fixture with a live `.tick/` and asserts `tick
      project` exits 0 and offers no phantom task; red control: the old bare record shape copied
      into `.tick/events/` on a `src/project.js` with the two filter lines removed reproduces
      the #694 phantom/crash.
- [ ] `bash validate.sh` exits 0.
- [ ] `bash test/gh202-wave-reconcile-issue-state.sh` and `bash test/gh421-auto-wave-reconcile.sh` stay green: their rollback assertions (`GH-271: rollback tripwire fired despite complete restore`, `porcelain dirty after rollback: ?? .tick/reconcile/`, `ReconcileTests.test_rollback_each_boundary` file-snapshot equality) require the tree to be byte-identical after a rollback — the envelope record must not leave a new file those checks can see (marathon attempt 1 on 2026-09-22 wrote `.tick/reconcile/<ts>.jsonl` and failed both). Run both suites before handing off.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh496-phase2-reconciliation-views.sh,test/gh567-roadmap-dashboard-retired.sh,test/gh568-releases-md-retired.sh,test/gh693-lessons-learned-advisory.sh,test/baselines/gh678-pulse2/baseline-gh425.log,test/_setup.sh,test/lib/fixture-guard.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh496-phase2-reconciliation-views.sh,test/gh567-roadmap-dashboard-retired.sh,test/gh568-releases-md-retired.sh,test/gh693-lessons-learned-advisory.sh,test/_setup.sh,test/lib/fixture-guard.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-707-reconcile-rollback-envelope RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh496-phase2-reconciliation-views.sh,test/gh567-roadmap-dashboard-retired.sh,test/gh568-releases-md-retired.sh,test/gh693-lessons-learned-advisory.sh,test/baselines/gh678-pulse2/baseline-gh425.log,test/_setup.sh,test/lib/fixture-guard.sh \
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
1. Implement the brief by creating/editing the artifact file(s): utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh496-phase2-reconciliation-views.sh,test/gh567-roadmap-dashboard-retired.sh,test/gh568-releases-md-retired.sh,test/gh693-lessons-learned-advisory.sh,test/baselines/gh678-pulse2/baseline-gh425.log,test/_setup.sh,test/lib/fixture-guard.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-707/bin/tick
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-707/bin/tick claim MARATHON-GH-707-TURN --agent codex --paths "marathon-system/gh-707/RELAY.md,utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh496-phase2-reconciliation-views.sh,test/gh567-roadmap-dashboard-retired.sh,test/gh568-releases-md-retired.sh,test/gh693-lessons-learned-advisory.sh,test/baselines/gh678-pulse2/baseline-gh425.log,test/_setup.sh,test/lib/fixture-guard.sh"
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-707/bin/tick ping MARATHON-GH-707-TURN --agent codex
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-707/bin/tick release MARATHON-GH-707-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-707/RELAY.md and utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh496-phase2-reconciliation-views.sh,test/gh567-roadmap-dashboard-retired.sh,test/gh568-releases-md-retired.sh,test/gh693-lessons-learned-advisory.sh,test/baselines/gh678-pulse2/baseline-gh425.log,test/_setup.sh,test/lib/fixture-guard.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/wave_reconcile.py,test/wave-reconcile.sh,test/gh168-wave-reconcile-scope.sh,test/gh202-wave-reconcile-issue-state.sh,test/gh232-wave-reconcile-multiphase.sh,test/gh267-express-skill.sh,test/gh358-wave-reconcile-vendored-paths.sh,test/gh429-wave-reconcile-vendored-observe.sh,test/gh496-phase2-reconciliation-views.sh,test/gh567-roadmap-dashboard-retired.sh,test/gh568-releases-md-retired.sh,test/gh693-lessons-learned-advisory.sh,test/baselines/gh678-pulse2/baseline-gh425.log,test/_setup.sh,test/lib/fixture-guard.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-707/bin/tick release MARATHON-GH-707-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-707/bin/tick done MARATHON-GH-707-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-707/bin/tick
   Edit ONLY marathon-system/gh-707/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
