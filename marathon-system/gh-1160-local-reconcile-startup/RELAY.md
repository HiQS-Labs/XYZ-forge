# Marathon Phase gh-1160-local-reconcile-startup
STATUS: Approved
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN-2 builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1160-local-reconcile-startup

- Generated: 2026-11-08T10:25:39Z
- Mode: gh-bundle
- Sources: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/PROJECT/2-WORKING/GH-1160-LOCAL-RECONCILE-STARTUP.md 
- Target root: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner (development @ 1276bb4d5)
- Suggested branch: `marathon/gh-1160-local-reconcile-startup-2026-11-08` (branch_ready=true — carve-out: risk=1/independent zone, proceed on the current branch without asking)
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


## Debug mantra (auto-triggered — 1 prior attempt(s) on this phase did not reach Approved)

Before trying again, read `relay-automation/DEBUG-MANTRA.md` (relative to the harness root) and follow its four-step discipline: reproduce reliably, know the fail path, question the hypothesis, treat this round as a breadcrumb for the next one.

---

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): AGENTS.md,test/gh527-destructive-git-guard.sh,test/gh649-pdda-migration.sh,test/hq.sh,test/pdda-install-startup-docs.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick claim MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN-2 --agent codex --paths "marathon-system/gh-1160-local-reconcile-startup/RELAY.md,AGENTS.md,test/gh527-destructive-git-guard.sh,test/gh649-pdda-migration.sh,test/hq.sh,test/pdda-install-startup-docs.sh"
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick ping MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN-2 --agent codex
   - /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick release MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN-2 --agent codex --to agy
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
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick release MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN-2 --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /private/var/folders/55/4ncr895946v1jymn1561yy340000gn/T/gh1358-live-deployment-dr61f_tg/runner/bin/tick done MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN-2 --agent agy
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

- Retry token: `MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN-2`.
- Files touched: only this relay file (required NEXT routing update and appended block). The prior attempt's AGENTS.md correction is already present at lines 73–77; no further artifact changes were justified.
- Source inspection confirms local `python3 utils/py/wave_reconcile.py --pr <N>` after development merges, the restriction on task branches committing routine views, the hosted-in-flight fail-closed check and explicit override, and hosted dispatch before promotion. ROUTER.md agrees; wave-reconcile.yml has only workflow_dispatch.
- Reversibility: Easy. Preserve the existing correction. Assumption: the carried-forward wording satisfies the first criterion; a contradictory startup/router passage would falsify it. Searches of AGENTS.md and ROUTER.md found no automatic hosted reconciliation or emergency-fallback instructions.
- Breadcrumb: ESCALATION.md reports pre-advance-failed / gate red after prior reviewer approval, but includes no actual failing gate diagnostic. No test-file repair can be grounded in that excerpt; the four allowed test files remain unchanged.
- Verification: source inspection only. No git commands, tests, or gates run, per embedded scope lock. `pdda.sh run` remains unverified pending the post-turn harness gate; no clean-gate or completed-acceptance claim.
- Root cause: the original stale startup paragraph was corrected by the prior attempt; fix site: AGENTS.md startup paragraph. No further artifact change required by the observed source.
- Handoff bookkeeping: the first update command stopped on an overbroad occurrence-count assertion before writing; the required routing update and this block were then written. The env-pinned tick release to agy succeeded.

handing off to agy — agy, take your turn.


### Round 1 · Reviewer · agy

swept file: yes

- **Sweep & Pre-existing Defect Audit:** Read `AGENTS.md` (511 lines), `ROUTER.md` (230 lines), `test/gh527-destructive-git-guard.sh` (153 lines), `test/gh649-pdda-migration.sh` (165 lines), `test/hq.sh` (131 lines), and `test/pdda-install-startup-docs.sh` (293 lines) in full. Found no pre-existing defects in `AGENTS.md` or the four scoped test files.
- **Acceptance Criterion 1 (No startup or router text describes automatic hosted reconciliation after a development merge):**
  - `AGENTS.md:73-78` states: *"After a PR merges into `development`, merge-cleanup reconciles docs, ledger, and views (`LEADERBOARD.md`) locally via `python3 utils/py/wave_reconcile.py --pr <N>`. Task branches do not commit routine views. The local writer fails closed if a hosted reconciler is in-flight (pass `--force-local-reconcile` to override). The hosted `wave-reconcile.yml` is dispatch-only and runs before promotion to qualify the development tip; see **Promotion** below. `pdda.sh issue-doc-sync` is the deterministic drift detector when in doubt."*
  - Verified against `.github/workflows/wave-reconcile.yml:9-10` (`on: workflow_dispatch:`), `utils/py/wave_reconcile.py:84-150` (`check_hosted_reconciler_in_flight`), `AGENTS.md:235-241`, `AGENTS.md:458-472`, and `ROUTER.md:118-122`.
  - Non-mutating probe for both preflight `fix_probes` patterns across `AGENTS.md` and `ROUTER.md`:
    - Command: `python3 -c 'import pathlib, re; [print(f"{p} | {pat} -> count={len(re.findall(re.escape(pat), pathlib.Path(p).read_text()))}") for p in ("AGENTS.md", "ROUTER.md") for pat in ("automatically reconciles docs, ledger, and views", "serves as an emergency fallback")]'`
    - Exit status: `0`
    - Decisive output:
      ```text
      AGENTS.md | automatically reconciles docs, ledger, and views -> count=0
      AGENTS.md | serves as an emergency fallback -> count=0
      ROUTER.md | automatically reconciles docs, ledger, and views -> count=0
      ROUTER.md | serves as an emergency fallback -> count=0
      ```
- **Acceptance Criterion 2 (`pdda.sh run` is clean):**
  - Graded `[Unverified — needs clone run]` for the authoritative post-turn harness gate per reviewer constraints; non-mutating check with activity log and state cache redirected to `$TMPDIR` (`PDDA_ACTIVITY_LOG="$TMPDIR/act.jsonl" PDDA_GH_STATE_CACHE="$TMPDIR/gh.tsv" PDDA_ISSUE_SYNC_SOURCE=cache bash utils/pdda/pdda.sh run`) exited `0` with `errors=0` across all 11 deterministic checks (`PDDA run complete: no errors, 646 warning(s) to review`).

**Verdict:** Approved

relay closed, no further turn needed

### Attestation · relay-drive — 2026-11-08T10:32:35Z
task: MARATHON-GH-1160-LOCAL-RECONCILE-STARTUP-TURN-2
reviewer: agy
status: Approved
reviewed-head: c8224dcf6cbf3cff825ced1ad23e62b6ce519a6f
added-range: 12228+2625
added-sha256: c44e0cd1a27d4a83bc2fe5f5e5b8a01ed71dcfde0c791aabf3a6b48740f06308
config-sha256: e409a4f0dd60934cd22690b155ec425bbdabe5b8f9d361313343009a2a5b7511
