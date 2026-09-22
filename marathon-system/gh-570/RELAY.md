# Marathon Phase gh-570
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-570-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-570-hq-known-repos-empty-db

- Generated: 2026-09-22T02:58:49Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-570/PROJECT/2-WORKING/GH-570-HQ-KNOWN-REPOS-EMPTY-DB.md 
- Target root: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-570 (marathon/10days-2026-09-21 @ 866ded4ab)
- Suggested branch: `marathon/gh-570-hq-known-repos-empty-db-2026-09-22` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: utils/hq/hq-lib.sh,test/hq-rollup.sh,test/gh239-hq-status-releases-mode.sh,test/hq-hardening.sh,test/hq-promote.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 971 LOC across 6 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/hq-hardening.sh,test/hq-promote.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-570/PROJECT/2-WORKING/GH-570-HQ-KNOWN-REPOS-EMPTY-DB.md` (its `## Acceptance` section, 4 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #570 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] `hq_known_repos` guards the DB with `[ -s "$HQ_REBALANCE_DB" ]` (or a `.tables` check) and runs
      the query so it cannot abort the brace group; an unreadable, empty, or table-less DB
      prints a one-line stderr warning and the XYZ + PDDA registry repos are still listed. Red
      control: a 0-byte file at the DB path must still list the registry repos and print the
      warning.
- [ ] `test/hq-rollup.sh` and `test/gh239-hq-status-releases-mode.sh` pin `HQ_REBALANCE_DB` to a
      fixture or `/nonexistent` the way gh405 pins `XYZ_DEVICE_CONFIG_PATH`, and pass with any
      garbage at the operator's real path.
- [ ] `bash validate.sh` exits 0.
- [ ] `bash test/gh139-pipe-grep-guard.sh` stays green: every new assertion in `test/hq-hardening.sh` (and the other allowlisted suites) uses capture-then-match — `grep -q PAT <<<"$(cmd)"` — never `cmd | grep -q PAT` (marathon attempt 1 on 2026-09-22 grew the pipe-into-grep count 13→15 and failed the gate).

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/hq/hq-lib.sh,test/hq-rollup.sh,test/gh239-hq-status-releases-mode.sh,test/hq-hardening.sh,test/hq-promote.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/hq-rollup.sh,test/gh239-hq-status-releases-mode.sh,test/hq-hardening.sh,test/hq-promote.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-570-hq-known-repos-empty-db RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/hq/hq-lib.sh,test/hq-rollup.sh,test/gh239-hq-status-releases-mode.sh,test/hq-hardening.sh,test/hq-promote.sh,test/_setup.sh \
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
1. Implement the brief by creating/editing the artifact file(s): utils/hq/hq-lib.sh,test/hq-rollup.sh,test/gh239-hq-status-releases-mode.sh,test/hq-hardening.sh,test/hq-promote.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-570/bin/tick
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-570/bin/tick claim MARATHON-GH-570-TURN --agent codex --paths "marathon-system/gh-570/RELAY.md,utils/hq/hq-lib.sh,test/hq-rollup.sh,test/gh239-hq-status-releases-mode.sh,test/hq-hardening.sh,test/hq-promote.sh,test/_setup.sh"
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-570/bin/tick ping MARATHON-GH-570-TURN --agent codex
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-570/bin/tick release MARATHON-GH-570-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-570/RELAY.md and utils/hq/hq-lib.sh,test/hq-rollup.sh,test/gh239-hq-status-releases-mode.sh,test/hq-hardening.sh,test/hq-promote.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/hq/hq-lib.sh,test/hq-rollup.sh,test/gh239-hq-status-releases-mode.sh,test/hq-hardening.sh,test/hq-promote.sh,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-570/bin/tick release MARATHON-GH-570-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-570/bin/tick done MARATHON-GH-570-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-570/bin/tick
   Edit ONLY marathon-system/gh-570/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

Implemented GH-570 within the scoped HQ artifacts:

- `utils/hq/hq-lib.sh`: made `hq_known_repos` reject unreadable, empty, and query-invalid Rebalance databases with a one-line stderr warning while allowing the XYZ and PDDA registry branches to continue.
- `test/hq-rollup.sh` and `test/gh239-hq-status-releases-mode.sh`: pinned `HQ_REBALANCE_DB` to `/nonexistent` so ambient operator database contents cannot affect these suites.
- `test/hq-hardening.sh`: added the zero-byte database red-control fixture, proving the warning is emitted and the XYZ registry repo remains listed; all new matches use captured output with here-string assertions.
- Left `test/hq-promote.sh` and `test/_setup.sh` unchanged because no additional fixture seam was needed.

Verification: intentionally not run in this worktree. The phase scope lock forbids executing even focused test scripts because their generated fixtures can trip containment; the harness will run the gate after handoff.
