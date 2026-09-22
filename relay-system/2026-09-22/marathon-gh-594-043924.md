# Marathon Phase gh-594
STATUS: Approved
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-594-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-594-express-doc-path-bounds

- Generated: 2026-09-22T04:30:27Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-594/PROJECT/2-WORKING/GH-594-EXPRESS-DOC-PATH-BOUNDS.md 
- Target root: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-594 (marathon/10days-2026-09-21 @ 494fa55fe)
- Suggested branch: `marathon/gh-594-express-doc-path-bounds-2026-09-22` (branch_ready=false — not cut yet; ask the operator before proceeding, per GUIDING-PRINCIPLES.md §8)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: utils/py/express.py,test/gh267-express-skill.sh,skills/express/SKILL.md
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 2059 LOC across 3 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.


This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-594/PROJECT/2-WORKING/GH-594-EXPRESS-DOC-PATH-BOUNDS.md` (its `## Acceptance` section, 5 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #594 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] `is_doc_path` (or its callers) exempts only the current issue's capture doc
      (`capture_doc_path(root, issue)`) plus `CHANGELOG.md`, passing the issue through the
      existing helpers; every other `PROJECT/**` edit is counted by both the core-file and
      insertion bounds.
- [ ] `test/gh267-express-skill.sh` gains a red control: a diff that also edits an unrelated
      `PROJECT/**` file trips `bounds`; the lane's own capture doc + CHANGELOG.md still pass.
- [ ] `skills/express/SKILL.md` states the narrowed exemption where it describes bounds.
- [ ] `bash validate.sh` exits 0.
- [ ] `bash test/gh267-express-skill.sh` passes in full (109+ assertions): the lane's own red controls (`unrelated PROJECT doc must count against bounds` / `... insertion bound`) pass, AND the pre-existing controls keep passing — a counted `PROJECT/**` path must NOT be treated as a subsystem by the multi-subsystem rule (marathon attempt 1 on 2026-09-22 made control (ii) and the standalone check fail with `express-refused: rule=multi-subsystem — core paths span PROJECT, utils`, and its own two red controls also failed). Run the suite before handing off.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `utils/py/express.py,test/gh267-express-skill.sh,skills/express/SKILL.md` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/gh267-express-skill.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-594-express-doc-path-bounds RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact utils/py/express.py,test/gh267-express-skill.sh,skills/express/SKILL.md \
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
1. Implement the brief by creating/editing the artifact file(s): utils/py/express.py,test/gh267-express-skill.sh,skills/express/SKILL.md
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-594/bin/tick
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-594/bin/tick claim MARATHON-GH-594-TURN --agent codex --paths "marathon-system/gh-594/RELAY.md,utils/py/express.py,test/gh267-express-skill.sh,skills/express/SKILL.md"
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-594/bin/tick ping MARATHON-GH-594-TURN --agent codex
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-594/bin/tick release MARATHON-GH-594-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-594/RELAY.md and utils/py/express.py,test/gh267-express-skill.sh,skills/express/SKILL.md. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/py/express.py,test/gh267-express-skill.sh,skills/express/SKILL.md. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-594/bin/tick release MARATHON-GH-594-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-594/bin/tick done MARATHON-GH-594-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010-lane-gh-594/bin/tick
   Edit ONLY marathon-system/gh-594/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

- Updated `utils/py/express.py` so only `CHANGELOG.md` and the current issue's
  `capture_doc_path(root, issue)` are exempt from core-file and insertion
  bounds. Other `PROJECT/**` paths count against both bounds, while remaining
  outside the independent multi-subsystem classification.
- Added focused controls to `test/gh267-express-skill.sh` proving the lane's own
  capture doc plus changelog remain exempt and that an unrelated `PROJECT/**`
  edit trips both the file and insertion bounds with their intended rules.
- Narrowed the bounds contract in `skills/express/SKILL.md` to match runtime
  behavior.
- Verification: source/call-site inspection only. Per this phase's scope lock,
  neither the focused suite nor the full gate was run in the isolated worktree;
  the harness owns test execution after handoff.

Handing off to agy — agy, take your turn.

### Round 1 · Reviewer · agy

swept file: yes

**Verdict:** Approved

#### Verification & Assessment

- [Pass] Narrowed doc path exemption in `utils/py/express.py:398-401`: `is_doc_path(root, issue, p)` exempts only `CHANGELOG.md` and `capture_doc_path(root, issue)`. Callers in `core_paths`, `insertions`, and `cmd_check` now pass `root` and `issue`. Other `PROJECT/**` paths are treated as core files and count against both core-file (`--max-files`) and insertion (`--max-insertions`) bounds.
- [Pass] Multi-subsystem classification safety in `utils/py/express.py:513`: `non_test = [p for p in core if not p.startswith(("test/", "PROJECT/"))]` correctly prevents counted `PROJECT/**` paperwork from being classified as an independent product subsystem, preventing the false `multi-subsystem` refusal seen in marathon attempt 1.
- [Pass] Red controls in `test/gh267-express-skill.sh:341-346`: Red controls verify that adding an unrelated `PROJECT/4-MISC/OTHER.md` file trips `too-many-files` when core file count exceeds bound, and trips `too-large` when insertions exceed bound, while the lane's own capture doc (`GH-999-DEMO-HOTFIX.md`) and `CHANGELOG.md` remain exempt.
- [Pass] Bounds documentation contract in `skills/express/SKILL.md:107-111`: Bounds section updated to document that only `CHANGELOG.md` and the current issue's capture doc (`capture_doc_path(root, issue)`) are exempt, and every other `PROJECT/**` path counts.
- [Pass] Non-mutating out-of-tree probe execution: Verified via Python in isolated scratch under `$TMPDIR` (`python3 -c '...; assert express.is_doc_path(...); ...'`) that lane capture doc and changelog are exempt, unrelated project docs are not exempt, and `tops` reflects only code subsystems (`utils`). Exit status 0, decisive output `PROBE_RESULT=PASS`.
- [Pass] Whole-file sweep: Swept `utils/py/express.py` (1198 LOC), `test/gh267-express-skill.sh` (696 LOC), and `skills/express/SKILL.md` (177 LOC). No syntax errors (`python3 -m py_compile`, `bash -n`). No pre-existing defects found in touched scopes.
- [Unverified — needs clone run] Gate execution (`bash validate.sh`) and full test suite (`test/gh267-express-skill.sh`): Not executed in-tree per scope lock and turn instructions (in-tree execution creates temporary fixtures conflicting with containment). Left for post-turn harness execution in a disposable full clone.

relay closed, no further turn needed.

### Attestation · relay-drive — 2026-09-22T04:37:29Z
task: MARATHON-GH-594-TURN
reviewer: agy
status: Approved
reviewed-head: 2d082f5f85b75bf03e2f2ea61dad54e71d96e797
added-range: 11319+2411
added-sha256: 126a5d9c179183af26393fc2cdee88223f84ce1af48ac86e30ecd6d18a3b82b6
