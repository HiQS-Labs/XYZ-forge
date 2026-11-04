# Marathon Phase gh-1265-consult-installed-kimi-cmd
STATUS: Open
NEXT: agy (Builder)

<!-- marathon-drive: task=MARATHON-GH-1265-CONSULT-INSTALLED-KIMI-CMD-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1265-consult-installed-kimi-cmd

- Generated: 2026-11-04T01:57:36Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/PROJECT/2-WORKING/GH-1265-CONSULT-INSTALLED-KIMI-CMD.md 
- Target root: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03 (development @ b8e94727e)
- Suggested branch: `marathon/gh-1265-consult-installed-kimi-cmd-2026-11-04` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash test/consult.sh`

- Artifacts: utils/py/consult.py,skills/1-hourly/consult/SKILL.md,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 1280 LOC across 5 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/PROJECT/2-WORKING/GH-1265-CONSULT-INSTALLED-KIMI-CMD.md` (its `## Acceptance` section, 5 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #1265](https://github.com/HiQS-Labs/XYZ-forge/issues/1265) — 5/5 criteria copied verbatim from issue #1265.*
- [ ] `relay-automation/consult.sh --prompt "Reply with the single word OK." --models kimi --label probe` exits 0 with one non-empty `answer-*.md` whose payload contains `OK` (recorded). Red control: on the base the same command prints `unknown model 'kimi' — skipping` and exits 2 (no valid model reaches `die`, `consult.py:185,862`; recorded).
- [ ] The same for `--models cmd` (recorded; if `cmd` is not authenticated on the box, the run must fail as a stated advisor failure, not a silent 0, and the receipt says so).
- [ ] Neutralizer witness: a prompt that makes the seat name its vendor ("state your vendor") yields a neutral payload with no `kimi`, `moonshot`, `cmd` or `commandcode` token (recorded). Red control: on the base, an in-memory `_neutralize_answer_text` replay of "I am kimi from Moonshot" keeps `Moonshot` (recorded).
- [ ] `--models codex,agy` output layout is unchanged: both runs exit 0 and both produce `answer-A.md`, `answer-B.md` and `key.json` (asserted present and non-empty before comparing), and the sorted file-name sets are equal (an empty pair does not pass; recorded).
- [ ] `bash test/consult.sh` passes on the final commit.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/consult.py,skills/1-hourly/consult/SKILL.md,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash test/consult.sh`, and NOT `test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1265-consult-installed-kimi-cmd RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/consult.py,skills/1-hourly/consult/SKILL.md,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh \
  --pre-advance-cmd 'bash test/consult.sh' \
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
1. Implement the brief by creating/editing the artifact file(s): utils/py/consult.py,skills/1-hourly/consult/SKILL.md,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick claim MARATHON-GH-1265-CONSULT-INSTALLED-KIMI-CMD-TURN --agent agy --paths "marathon-system/gh-1265-consult-installed-kimi-cmd/RELAY.md,utils/py/consult.py,skills/1-hourly/consult/SKILL.md,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh"
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick ping MARATHON-GH-1265-CONSULT-INSTALLED-KIMI-CMD-TURN --agent agy
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick release MARATHON-GH-1265-CONSULT-INSTALLED-KIMI-CMD-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-1265-consult-installed-kimi-cmd/RELAY.md and utils/py/consult.py,skills/1-hourly/consult/SKILL.md,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/consult.py,skills/1-hourly/consult/SKILL.md,test/gh375-auth-timeout-verdict.sh,test/synthetic/gh101-consult-programmatic.sh,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick release MARATHON-GH-1265-CONSULT-INSTALLED-KIMI-CMD-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick done MARATHON-GH-1265-CONSULT-INSTALLED-KIMI-CMD-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick
   Edit ONLY marathon-system/gh-1265-consult-installed-kimi-cmd/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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
