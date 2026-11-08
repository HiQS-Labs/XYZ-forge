# Marathon Phase gh-1160-local-reconcile-startup
STATUS: Approved
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1160-local-reconcile-startup

- Generated: 2026-11-08T10:14:05Z
- Mode: gh-bundle
- Sources: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/PROJECT/2-WORKING/GH-1160-LOCAL-RECONCILE-STARTUP.md 
- Target root: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner (development @ ba7545ec5)
- Suggested branch: `marathon/gh-1160-local-reconcile-startup-2026-11-08` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash utils/pdda/pdda.sh run`

- Artifacts: AGENTS.md,test/gh527-destructive-git-guard.sh,test/gh649-pdda-migration.sh,test/hq.sh,test/pdda-install-startup-docs.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 510 LOC across 5 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh527-destructive-git-guard.sh,test/gh649-pdda-migration.sh,test/hq.sh,test/pdda-install-startup-docs.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/PROJECT/2-WORKING/GH-1160-LOCAL-RECONCILE-STARTUP.md` (its `## Acceptance` section, 2 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #1160](https://github.com/HiQS-Labs/XYZ-forge/issues/1160) — 2/2 criteria copied verbatim from issue #1160.*
- [ ] No startup or router text describes automatic hosted reconciliation after a development merge.
- [ ] `pdda.sh run` is clean.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `AGENTS.md,test/gh527-destructive-git-guard.sh,test/gh649-pdda-migration.sh,test/hq.sh,test/pdda-install-startup-docs.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash utils/pdda/pdda.sh run`, and NOT `test/gh527-destructive-git-guard.sh,test/gh649-pdda-migration.sh,test/hq.sh,test/pdda-install-startup-docs.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1160-local-reconcile-startup RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact AGENTS.md,test/gh527-destructive-git-guard.sh,test/gh649-pdda-migration.sh,test/hq.sh,test/pdda-install-startup-docs.sh \
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

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): AGENTS.md,test/gh527-destructive-git-guard.sh,test/gh649-pdda-migration.sh,test/hq.sh,test/pdda-install-startup-docs.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick claim MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN --agent codex --paths "marathon-system/gh-1160-local-reconcile-startup/RELAY.md,AGENTS.md,test/gh527-destructive-git-guard.sh,test/gh649-pdda-migration.sh,test/hq.sh,test/pdda-install-startup-docs.sh"
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick ping MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN --agent codex
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick release MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-1160-local-reconcile-startup/RELAY.md and AGENTS.md,test/gh527-destructive-git-guard.sh,test/gh649-pdda-migration.sh,test/hq.sh,test/pdda-install-startup-docs.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: AGENTS.md,test/gh527-destructive-git-guard.sh,test/gh649-pdda-migration.sh,test/hq.sh,test/pdda-install-startup-docs.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick release MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick done MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick
   Edit ONLY marathon-system/gh-1160-local-reconcile-startup/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

- Updated only the contradictory startup paragraph in `AGENTS.md`: merge-cleanup runs local reconciliation after development merges; hosted reconciliation is dispatch-only before promotion.
- Preserved the routine-view restriction, hosted-in-flight refusal, explicit override, and issue-doc-sync drift check; linked the existing Promotion procedure.
- Read the workflow dispatch declaration and local-writer safeguards as supporting evidence. Left all four allowed test files unchanged because this is a documentation correction.
- Verification: no tests or gates executed, as required by the phase scope lock. Harness `pdda.sh run` remains pending; no passing gate claimed.
- Updated NEXT for the reviewer as explicitly required by the handoff instruction; all other prior relay content retained.

Handing off to agy — agy, take your turn.

### Round 1 · Reviewer · agy

swept file: yes

- **Whole-file sweep:** Read `AGENTS.md` (511 lines), `ROUTER.md` (230 lines), and all four auto-included covering test files (`test/gh527-destructive-git-guard.sh`, `test/gh649-pdda-migration.sh`, `test/hq.sh`, `test/pdda-install-startup-docs.sh`) in full, plus `.github/workflows/wave-reconcile.yml` and `utils/py/wave_reconcile.py`. Found no pre-existing defects in the touched or scoped files.
- **Criterion 1 (`No startup or router text describes automatic hosted reconciliation after a development merge`):** Verified via read-only probe:
  - Command: `grep -nE 'automatically reconciles docs, ledger, and views|serves as an emergency fallback' AGENTS.md ROUTER.md || echo "rc=$? (0 matches)"; grep -n 'wave_reconcile.py --pr' AGENTS.md ROUTER.md`
  - Exit status: `0` (first grep exited `1` with 0 matches)
  - Decisive output:
    ```
    rc=1 (0 matches)
    AGENTS.md:74:(`LEADERBOARD.md`) locally via `python3 utils/py/wave_reconcile.py --pr <N>`. Task
    AGENTS.md:236:    After a merge, merge-cleanup reconciles the ledger locally (`wave_reconcile.py --pr N`); no hosted
    ROUTER.md:119:(merge-cleanup → `wave_reconcile.py --pr N`). `wave-reconcile.yml` is dispatch-only; before each promotion
    ```
  - `AGENTS.md` lines 73–78 now match `AGENTS.md` lines 235–241, `ROUTER.md` lines 118–122, `.github/workflows/wave-reconcile.yml` (`on: workflow_dispatch`), and `utils/py/wave_reconcile.py` (`check_hosted_reconciler_in_flight`), while preserving the routine-view restriction (`LEADERBOARD.md`), hosted-in-flight fail-closed check + `--force-local-reconcile` override, Promotion reference, and `pdda.sh issue-doc-sync` drift check.
- **Criterion 2 (`pdda.sh run` is clean):** [Unverified — needs clone run] — deferred to the post-turn harness gate (`bash utils/pdda/pdda.sh run`) per worktree containment rules.

**Verdict:** Approved

relay closed, no further turn needed

### Attestation · relay-drive — 2026-11-08T10:17:22Z
task: MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN
reviewer: agy
status: Approved
reviewed-head: 171bb7293bc29376633f6457fd3045b3f8294913
added-range: 10898+1953
added-sha256: 97a9691e68389c38f5d77991e832f2fa4c5f27ef4fda213df7cb67e2ce04bd76
config-sha256: 02cb1dec7863cd4668d263531a1a18a9d88d3311be610dc4ae1daac674762fd9
