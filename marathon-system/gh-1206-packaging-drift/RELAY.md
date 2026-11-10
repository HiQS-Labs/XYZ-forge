# Marathon Phase gh-1206-packaging-drift
STATUS: Open
NEXT: agy (Reviewer)

<!-- marathon-drive: task=MARATHON-GH-1206-PACKAGING-DRIFT-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-1206-packaging-drift

- Generated: 2026-11-10T05:13:25Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b-jog-retry-qualification-fxxifouv/repo/PROJECT/2-WORKING/GH-1206-PACKAGING-DRIFT.md 
- Target root: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b-jog-retry-qualification-fxxifouv/repo (development @ f8e0f7820)
- Suggested branch: `marathon/gh-1206-packaging-drift-2026-11-10` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh --auto development`

- Artifacts: package.json,package-lock.json,TESTS-RESULTS/2026-11-10+GH-1206/manual.md,TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl,test/xyz-vendor.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 65 LOC across 6 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/xyz-vendor.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b-jog-retry-qualification-fxxifouv/repo/PROJECT/2-WORKING/GH-1206-PACKAGING-DRIFT.md` (its `## Acceptance` section, 0 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*Verified against [issue #1206](https://github.com/HiQS-Labs/XYZ-forge/issues/1206) — 0/0 criteria copied verbatim from issue #1206.*
(no '- [ ]' checklist found in /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b-jog-retry-qualification-fxxifouv/repo/PROJECT/2-WORKING/GH-1206-PACKAGING-DRIFT.md — add an Acceptance criteria list)

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `package.json,package-lock.json,TESTS-RESULTS/2026-11-10+GH-1206/manual.md,TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl,test/xyz-vendor.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh --auto development`, and NOT `test/xyz-vendor.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-1206-packaging-drift RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact package.json,package-lock.json,TESTS-RESULTS/2026-11-10+GH-1206/manual.md,TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl,test/xyz-vendor.sh,test/_setup.sh \
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

▶ TAKE YOUR TURN (codex — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Implement the brief by creating/editing the artifact file(s): package.json,package-lock.json,TESTS-RESULTS/2026-11-10+GH-1206/manual.md,TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl,test/xyz-vendor.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b-jog-retry-qualification-fxxifouv/repo/bin/tick
   - /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b-jog-retry-qualification-fxxifouv/repo/bin/tick claim MARATHON-GH-1206-PACKAGING-DRIFT-TURN --agent codex --paths "marathon-system/gh-1206-packaging-drift/RELAY.md,package.json,package-lock.json,TESTS-RESULTS/2026-11-10+GH-1206/manual.md,TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl,test/xyz-vendor.sh,test/_setup.sh"
   - /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b-jog-retry-qualification-fxxifouv/repo/bin/tick ping MARATHON-GH-1206-PACKAGING-DRIFT-TURN --agent codex
   - /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b-jog-retry-qualification-fxxifouv/repo/bin/tick release MARATHON-GH-1206-PACKAGING-DRIFT-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/gh-1206-packaging-drift/RELAY.md and package.json,package-lock.json,TESTS-RESULTS/2026-11-10+GH-1206/manual.md,TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl,test/xyz-vendor.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: package.json,package-lock.json,TESTS-RESULTS/2026-11-10+GH-1206/manual.md,TESTS-RESULTS/2026-11-10+GH-1206/provenance.jsonl,test/xyz-vendor.sh,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b-jog-retry-qualification-fxxifouv/repo/bin/tick release MARATHON-GH-1206-PACKAGING-DRIFT-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b-jog-retry-qualification-fxxifouv/repo/bin/tick done MARATHON-GH-1206-PACKAGING-DRIFT-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/.t3/worktrees/XYZ-forge/t3-ec20080d/temp/b-jog-retry-qualification-fxxifouv/repo/bin/tick
   Edit ONLY marathon-system/gh-1206-packaging-drift/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

Changed `package.json` and `package-lock.json`: aligned root names to `xyz-forge`, retained version 1.0.1 and dependencies, declared Node >=18, removed nonexistent `main` and obsolete directory hints. Package purpose is explicitly a repository-development/source snapshot; no npm CLI or library entry point is declared. Minimal `files` allowlist ships top-level JS sources and licenses/readme/metadata, excluding full harness installation and historical/runtime material.

Added `TESTS-RESULTS/2026-11-10+GH-1206/manual.md` and `provenance.jsonl` with baseline/final dry-run metrics, exact final paths, red-control observations, metadata assertions, and artifact hashes. Baseline: 10,447 files / 186,258,993 unpacked bytes; final: 17 files / 152,679 unpacked bytes. Manual probes passed; raw output and cache stayed in `.relay-scratch/`. Reversibility: Easy, metadata-only changes; no publication or installation.

`test/xyz-vendor.sh` and `test/_setup.sh` read and left unchanged. No git commands or test suites run. Kernel unit tests and full gate remain pending harness verification, per embedded scope lock. No claim of runtime or full-gate completion.

NEXT: agy (Reviewer)
