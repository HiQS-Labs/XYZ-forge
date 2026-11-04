# Marathon Phase gh-1266-architecture-md-skills-index
STATUS: Open
NEXT: codex (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-1266-ARCHITECTURE-MD-SKILLS-INDEX-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1266-architecture-md-skills-index

- Generated: 2026-11-04T04:35:42Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/PROJECT/2-WORKING/GH-1266-ARCHITECTURE-MD-SKILLS-INDEX.md 
- Target root: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03 (development @ 964c63f44)
- Suggested branch: `marathon/gh-1266-architecture-md-skills-index-2026-11-04` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash utils/pdda/pdda.sh run`

- Artifacts: ARCHITECTURE.md,test/gh778-review-code-skill.sh,test/gh798-status-skill.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 572 LOC across 4 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh778-review-code-skill.sh,test/gh798-status-skill.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/PROJECT/2-WORKING/GH-1266-ARCHITECTURE-MD-SKILLS-INDEX.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #1266](https://github.com/HiQS-Labs/XYZ-forge/issues/1266) — 4/4 criteria copied verbatim from issue #1266.*
- [ ] For every tier, `ls -d skills/<tier>/*/ | wc -l` is positive and equals `grep -c "(skills/<tier>/" ARCHITECTURE.md` (recorded for all four with the actual numbers; a 0 = 0 pair does not pass). Red control: on the base, `3-weekly` gives 16 vs 15 (recorded).
- [ ] `grep -c '(skills/3-weekly/weekly-planner/SKILL.md)' ARCHITECTURE.md` is 1. Red control: base gives 0.
- [ ] `grep -cE '^### `[0-9]-[a-z]+`.*\([0-9]+\)$' ARCHITECTURE.md` is 0 (no counts left) **and** `grep -cE '^### `[0-9]-[a-z]+` — [^(]+$' ARCHITECTURE.md` is 4 (the four count-free headings are present, so an empty file cannot pass). Red control: base gives 4 and 0 respectively (recorded).
- [ ] `bash utils/pdda/pdda.sh run` passes on the final commit.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `ARCHITECTURE.md,test/gh778-review-code-skill.sh,test/gh798-status-skill.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash utils/pdda/pdda.sh run`, and NOT `test/gh778-review-code-skill.sh,test/gh798-status-skill.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1266-architecture-md-skills-index RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact ARCHITECTURE.md,test/gh778-review-code-skill.sh,test/gh798-status-skill.sh,test/_setup.sh \
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
1. Implement the brief by creating/editing the artifact file(s): ARCHITECTURE.md,test/gh778-review-code-skill.sh,test/gh798-status-skill.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick claim MARATHON-GH-1266-ARCHITECTURE-MD-SKILLS-INDEX-TURN --agent agy --paths "marathon-system/gh-1266-architecture-md-skills-index/RELAY.md,ARCHITECTURE.md,test/gh778-review-code-skill.sh,test/gh798-status-skill.sh,test/_setup.sh"
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick ping MARATHON-GH-1266-ARCHITECTURE-MD-SKILLS-INDEX-TURN --agent agy
   - /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick release MARATHON-GH-1266-ARCHITECTURE-MD-SKILLS-INDEX-TURN --agent agy --to codex
4. Edit ONLY these paths: marathon-system/gh-1266-architecture-md-skills-index/RELAY.md and ARCHITECTURE.md,test/gh778-review-code-skill.sh,test/gh798-status-skill.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to codex — codex, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: codex (Reviewer)`

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: ARCHITECTURE.md,test/gh778-review-code-skill.sh,test/gh798-status-skill.sh,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: agy (Builder)`, then: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick release MARATHON-GH-1266-ARCHITECTURE-MD-SKILLS-INDEX-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick done MARATHON-GH-1266-ARCHITECTURE-MD-SKILLS-INDEX-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GitHub Repos/XYZ-forge-factory-batch1-2026-11-03/bin/tick
   Edit ONLY marathon-system/gh-1266-architecture-md-skills-index/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

---

### Round 1 · Builder · agy

- **Files touched:**
  - `ARCHITECTURE.md`:
    1. Added the missing `[weekly-planner](skills/3-weekly/weekly-planner/SKILL.md)` row in the `3-weekly` Skills Index table in alphabetical order (immediately before `weekly-shipped`), with its one-line purpose drawn from `skills/3-weekly/weekly-planner/SKILL.md:3`.
    2. Removed the four hand-maintained `(N)` counts from the tier headers (`### \`1-hourly\` — Every hour`, `### \`2-daily\` — A few times a day`, `### \`3-weekly\` — Weekly`, and `### \`4-occasional\` — Least frequently`).
  - `test/gh778-review-code-skill.sh`, `test/gh798-status-skill.sh`, `test/_setup.sh`: left untouched per `PROJECT/2-WORKING/GH-1266-ARCHITECTURE-MD-SKILLS-INDEX.md` (`ARCHITECTURE.md only` in `## Key concepts`, `## Write-set`, `## Non-goals`, and `## Preflight Contract`; those files were only auto-included by `swarm-preflight` because `## Observed` cites the two retired suites).
- **Acceptance criteria verification (read-only probes):**
  - Criterion 1 (`ls -d skills/<tier>/*/ | wc -l` vs `grep -c "(skills/<tier>/" ARCHITECTURE.md`):
    - `1-hourly`: `17` vs `17`
    - `2-daily`: `23` vs `23`
    - `3-weekly`: `16` vs `16` (red control on base: `16` vs `15`)
    - `4-occasional`: `20` vs `20`
  - Criterion 2 (`grep -c '(skills/3-weekly/weekly-planner/SKILL.md)' ARCHITECTURE.md`): `1` (red control on base: `0`)
  - Criterion 3 (`grep -cE '^### \`[0-9]-[a-z]+\`.*\([0-9]+\)$' ARCHITECTURE.md` and `grep -cE '^### \`[0-9]-[a-z]+\` — [^(]+$' ARCHITECTURE.md`): `0` and `4` (red control on base: `4` and `0`)
  - Criterion 4 (`bash utils/pdda/pdda.sh run`): deferred to the harness pre-advance gate outside the isolated worktree per the scope lock.
- Handing off to codex — codex, take your turn.
