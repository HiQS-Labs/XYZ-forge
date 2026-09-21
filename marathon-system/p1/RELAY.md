# Marathon Phase p1
STATUS: Open
NEXT: codex (Builder)

<!-- marathon-drive: task=MARATHON-P1-TURN builder=codex reviewer=agy round-cap=5 -->

## Phase Brief

# Marathon preflight packet — gh-742-vendor-package-json-esm

- Generated: 2026-09-21T23:31:00Z
- Mode: gh-bundle
- Sources: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010/PROJECT/2-WORKING/GH-742-VENDOR-PACKAGE-JSON-ESM.md 
- Target root: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010 (development @ e565c0fe6)
- Suggested branch: `marathon/gh-742-vendor-package-json-esm-2026-09-21` (branch_ready=false — carve-out: risk=1/independent zone, proceed on the current branch without asking)
- Verdict: ready
- Source issue state: OPEN.
- Gate: `bash validate.sh`

- Artifacts: relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,test/gh105-vendor-releases-addon.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh642-consumer-fruit.sh,test/gh708-vendored-suite-skips.sh,test/xyz-sync-check.sh,test/lib/vendored-fixture.sh,test/_setup.sh
- Suggested turn budget: `turn_timeout_s: 1800` in this phase's MARATHON.yaml entry (≈ 860 LOC across 11 artifact(s) — over the 900s default, so it needs headroom). marathon.sh reads that field and applies it to the phase; the value is a starting point, not a measurement.
- Auto-included covering tests/helpers: test/gh105-vendor-releases-addon.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh642-consumer-fruit.sh,test/gh708-vendored-suite-skips.sh,test/xyz-sync-check.sh,test/lib/vendored-fixture.sh,test/_setup.sh

This packet is the producer's output. The orchestrator launches the run; the planner does not
(GUIDING-PRINCIPLES.md §8).

## Acceptance criteria — the build is DONE when these hold
*Inlined verbatim from `/Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010/PROJECT/2-WORKING/GH-742-VENDOR-PACKAGE-JSON-ESM.md` (its `## Acceptance` section, 3 criterion(a)). Continuation lines included; if a
criterion here reads as a fragment, that is the source text, not a truncation.*
*NOT verified, and NOT verifiable as things stand — issue #742 has no '## Acceptance' section — nothing to copy from. This list exists only in the capture doc; reading the issue will not confirm it, because the issue states no criteria. Establish the criteria on the issue before treating anything below as the definition of done.*
- [ ] `materialize_vendor()` in `relay-automation/xyz-vendor.sh` writes `.xyz/package.json` containing
      `"type": "commonjs"` on every vendor/update.
- [ ] `test/xyz-vendor.sh` gains a fixture whose root `package.json` declares `"type": "module"`;
      after vendoring, `TICK_REPO_ROOT=<target> .xyz/bin/tick --help` exits 0. Red control: with
      `.xyz/package.json` removed the same invocation fails.
- [ ] `bash validate.sh` exits 0.

## Scope lock — builder, do exactly this and nothing else
- Edit ONLY: `relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,test/gh105-vendor-releases-addon.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh642-consumer-fruit.sh,test/gh708-vendored-suite-skips.sh,test/xyz-sync-check.sh,test/lib/vendored-fixture.sh,test/_setup.sh` (plus the relay file). Any other edit is reverted and FAILS the turn.
- Do NOT run ANY test or gate yourself — not `bash validate.sh`, and NOT `test/xyz-vendor.sh,test/gh105-vendor-releases-addon.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh642-consumer-fruit.sh,test/gh708-vendored-suite-skips.sh,test/xyz-sync-check.sh,test/lib/vendored-fixture.sh,test/_setup.sh` either. Those tests create temporary git fixtures/files inside your isolated worktree, which containment treats as off-lane edits and can discard your whole turn. Read them as specs instead; the harness runs the real gate after your turn, outside the worktree.
- Do NOT analyze the roadmap, file issues, or refactor adjacent code. Implement the acceptance criteria above — nothing more.

## Suggested marathon-drive.sh invocation

```bash
XYZ_HARNESS_CONTEXT=swarm XYZ_SESSION_ID=gh-742-vendor-package-json-esm RELAY_WORKTREE_ISOLATION=1 relay-automation/marathon-drive.sh \
  --phase-brief <packet>/packet.md \
  --reviewer agy \
  --builder codex \
  --artifact relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,test/gh105-vendor-releases-addon.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh642-consumer-fruit.sh,test/gh708-vendored-suite-skips.sh,test/xyz-sync-check.sh,test/lib/vendored-fixture.sh,test/_setup.sh \
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
1. Implement the brief by creating/editing the artifact file(s): relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,test/gh105-vendor-releases-addon.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh642-consumer-fruit.sh,test/gh708-vendored-suite-skips.sh,test/xyz-sync-check.sh,test/lib/vendored-fixture.sh,test/_setup.sh
2. Append a build block to this relay file: `### Round N · Builder · codex` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010/bin/tick
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010/bin/tick claim MARATHON-P1-TURN --agent codex --paths "marathon-system/p1/RELAY.md,relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,test/gh105-vendor-releases-addon.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh642-consumer-fruit.sh,test/gh708-vendored-suite-skips.sh,test/xyz-sync-check.sh,test/lib/vendored-fixture.sh,test/_setup.sh"
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010/bin/tick ping MARATHON-P1-TURN --agent codex
   - /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010/bin/tick release MARATHON-P1-TURN --agent codex --to agy
4. Edit ONLY these paths: marathon-system/p1/RELAY.md and relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,test/gh105-vendor-releases-addon.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh642-consumer-fruit.sh,test/gh708-vendored-suite-skips.sh,test/xyz-sync-check.sh,test/lib/vendored-fixture.sh,test/_setup.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.
5. HAND OFF EXPLICITLY (GH-268): after releasing the token, end your turn by naming who acts next —
   "handing off to agy — agy, take your turn." A turn that ends without that line
   leaves a human guessing whether the relay is waiting on them or has stalled. Do this EVERY round,
   not just the first. ALSO, you MUST update the `NEXT:` line at the top of this file to exactly: `NEXT: agy (Reviewer)`

---

▶ TAKE YOUR TURN (agy — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: relay-automation/xyz-vendor.sh,test/xyz-vendor.sh,test/gh105-vendor-releases-addon.sh,test/gh197-vendor-tier-split.sh,test/gh293-vendored-guard-drift.sh,test/gh312-vendor-preserves-state.sh,test/gh642-consumer-fruit.sh,test/gh708-vendored-suite-skips.sh,test/xyz-sync-check.sh,test/lib/vendored-fixture.sh,test/_setup.sh. REVIEW THE WHOLE FILE, NOT JUST THE DIFF (GH-268): a beta test had this loop reach 'Approved' in two rounds while an independent audit of the same branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN SCOPE; say so explicitly if you find none. DECLARE IT: your review block MUST contain a literal 'swept file: yes' or 'swept file: no' line — without it a reviewer that skipped the sweep is indistinguishable in the transcript from one that did it and found nothing, which is exactly how those 20 issues stayed invisible.
APPEND-ONLY FILE (GH-529 attestation): add your block at the END and never delete, reorder, or rewrite any existing content — the terminal attestation refuses the approval if any byte above your block changed, even a tidy-up.
1. Append a review block: `### Round N · Reviewer · agy` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested`, update the `NEXT:` line to exactly `NEXT: codex (Builder)`, then: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010/bin/tick release MARATHON-P1-TURN --agent agy --to codex
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010/bin/tick done MARATHON-P1-TURN --agent agy
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/marathon-clones/10days-2026-09-21-HiQS-Labs-XYZ-forge-20260921-160010/bin/tick
   Edit ONLY marathon-system/p1/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.
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

---

### Round 1 · Reviewer · agy

**Verdict:** Changes requested

swept file: yes

#### Overview
The Builder turn for Round 1 encountered an execution/IPC error in the tool runtime (`failed to decode code-mode IPC frame: missing field code_mode_host_duration_ns`) and exited without making changes to tracked code or writing a build summary block to `RELAY.md`. Both core functional requirements for GH-742 remain unaddressed.

#### Findings

##### Finding 1 [Blocker]
`materialize_vendor()` in `relay-automation/xyz-vendor.sh` does not create `.xyz/package.json` with `"type": "commonjs"`.
- Observed input: `relay-automation/xyz-vendor.sh:435-500` (`materialize_vendor()`). Probe command `grep -n "package\.json" relay-automation/xyz-vendor.sh` exited with code 1 and no matches.
- Affected scope: `relay-automation/xyz-vendor.sh:470-476` in `materialize_vendor()`.
- Observed failure: In a consumer repository configured with `"type": "module"` in its root `package.json`, executing `.xyz/bin/tick` fails with `ReferenceError: require is not defined in ES module scope` because Node traverses up the directory tree and interprets `.xyz`'s CommonJS files as ESM.
- Falsifier: Run `xyz-vendor.sh <target-repo>` on a target repo and inspect `<target-repo>/.xyz/package.json`:
  ```bash
  grep -F '"type": "commonjs"' "<target-repo>/.xyz/package.json"
  ```
  Currently fails (exit status 1, file does not exist).

##### Finding 2 [Blocker]
`test/xyz-vendor.sh` lacks the test fixture for `"type": "module"` target repos and the red control check.
- Observed input: `test/xyz-vendor.sh:1-350`. Probe command `grep -n "package\.json" test/xyz-vendor.sh` exited with code 1 and no matches.
- Affected scope: `test/xyz-vendor.sh`.
- Observed failure: There is no test verifying that vendoring into a repository whose root `package.json` contains `"type": "module"` allows `TICK_REPO_ROOT=<target> .xyz/bin/tick --help` to exit 0, nor a red control verifying failure when `.xyz/package.json` is removed.
- Falsifier: Checking `test/xyz-vendor.sh` for an ESM target test fixture yields zero matches.

#### Acceptance Criteria Tracking
- [ ] `materialize_vendor()` in `relay-automation/xyz-vendor.sh` writes `.xyz/package.json` containing `"type": "commonjs"` on every vendor/update. -> Incomplete (`relay-automation/xyz-vendor.sh` not yet modified).
- [ ] `test/xyz-vendor.sh` gains a fixture whose root `package.json` declares `"type": "module"`; after vendoring, `TICK_REPO_ROOT=<target> .xyz/bin/tick --help` exits 0. Red control: with `.xyz/package.json` removed the same invocation fails. -> Incomplete (`test/xyz-vendor.sh` not yet modified).
- [ ] `bash validate.sh` exits 0. -> [Unverified — needs clone run].

#### Pre-existing Sweep
Files swept in full:
- `relay-automation/xyz-vendor.sh`: Swept lines 1–512 (locking, registry, exclude handling, state preservation, staging). Pre-existing code is clean; no unhandled defects identified.
- `test/xyz-vendor.sh`: Swept lines 1–350 (fixtures, registry, collision safety, ignore rules). Pre-existing assertions are clean; no unhandled defects identified.

#### Next Steps
Builder needs to:
1. In `relay-automation/xyz-vendor.sh` (`materialize_vendor()`): write `$STAGE_DIR/package.json` containing `{"type": "commonjs"}` (or formatted JSON with `"type": "commonjs"`).
2. In `test/xyz-vendor.sh`: add a test fixture initializing a repo with root `package.json` having `{"type": "module"}`, vendor into it, assert `TICK_REPO_ROOT=<target> .xyz/bin/tick --help` exits 0, and assert red control: removing `.xyz/package.json` causes the invocation to fail.
3. Append a build block to `RELAY.md`, update `NEXT:` to `agy (Reviewer)`, and release token to `agy`.
