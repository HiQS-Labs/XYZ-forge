# Marathon Phase gh85
STATUS: Approved
NEXT: codex

<!-- marathon-drive: task=MARATHON-GH85-TURN builder=agy reviewer=codex round-cap=5 -->

## Phase Brief

# Phase brief — GH-85: fix marathon-plan undocumented-partial-completion false-positive

## Goal
Stop `utils/marathon-plan.sh`'s `undocumented-partial-completion` detector from false-flagging a
rated+contracted lane as `partial` just because its fix **edits existing files** and its issue is
name-dropped in `CHANGELOG.md`.

## Current bug
In `utils/marathon-plan.sh` (~line 439, `if (r.state == null)` block), the detector sets
`r.state = "partial"` when ≥2 signals fire. Two misfire for a normal edit-existing-file lane:
- `some-artifacts-exist` — fires when *some but not all* of the contract's `artifacts[]` exist. But a
  fix that MODIFIES existing files legitimately lists existing paths → fires at 0% built.
- `changelog-mentions-it` — fires when `CHANGELOG.md` contains `#<n>` or the slug. A *queued/contracted*
  mention (which the CHANGELOG contract encourages) trips it.
Together they hold genuinely-unbuilt lanes (observed: GH-45, GH-30 held at 0% built).

## Fix
1. Make `some-artifacts-exist` require a **NEW/created** artifact to be present — e.g. count an
   artifact toward the signal only if it is the contract's gate NEW-test path (or otherwise net-new),
   NOT merely any existing (being-edited) path. (Simplest: the signal fires only when an artifact that
   did NOT exist at the lane's base ref now exists — i.e. evidence of *output*, not of an edit target.)
2. **Drop** `changelog-mentions-it` as a partial-completion signal (a queued/contracted mention is not
   evidence of completion).
3. Preserve the TRUE positive: a genuinely partial lane (GH-44 style — real prior work: a branch
   matching the slug AND/OR tests referencing it) is STILL flagged `partial`.
Add a `GH-85` marker comment.

## New tests (the gate)
Add to `test/marathon-plan.sh` two regression cases:
- (a) A rated+contracted lane whose `artifacts[]` all pre-exist AND whose `#n` is in CHANGELOG is
  classified **READY / active** (NOT `partial`).
- (b) A lane with genuine partial signals (branch-matches-slug + tests-reference-slug) is STILL
  `partial`.

## Scope lock (ALLOW_PATHS)
Edit ONLY: `utils/marathon-plan.sh`, `test/marathon-plan.sh`. Do NOT touch the kernel
(`relay-turn-lib.sh` / `bin/tick` / `relay-drive.sh`) or `marathon-drive.sh`.

## Definition of done (gate)
- `bash test/marathon-plan.sh` passes, including the two new regression cases.
- An edit-existing-file lane documented in CHANGELOG is no longer `partial`; a genuine partial still is.

Contract of record: `PROJECT/1-INBOX/GH-85-MARATHON-PLAN-PARTIAL-FALSE-POSITIVE.md`.

---

▶ TAKE YOUR TURN (agy — BUILDER role)

You are the BUILDER for this phase. Read the phase brief above and implement it.
1. Implement the brief by creating/editing the artifact file(s): utils/marathon-plan.sh,test/marathon-plan.sh
2. Append a build block to this relay file: `### Round N · Builder · agy` summarizing what you did (files touched, key decisions).
3. Use this exact tick binary (run it from any directory): /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick claim MARATHON-GH85-TURN --agent agy --paths "phases/gh85/RELAY.md,utils/marathon-plan.sh,test/marathon-plan.sh"
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick ping MARATHON-GH85-TURN --agent agy
   - /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH85-TURN --agent agy --to codex
4. Edit ONLY these paths: phases/gh85/RELAY.md and utils/marathon-plan.sh,test/marathon-plan.sh. Do NOT run git. Do NOT touch any other file — the harness commits for you.

---

▶ TAKE YOUR TURN (codex — REVIEWER role)

You are the REVIEWER for this phase. Read the latest builder block above AND review the artifact file(s) on disk: utils/marathon-plan.sh,test/marathon-plan.sh.
1. Append a review block: `### Round N · Reviewer · codex` followed by your assessment.
2. If changes needed: add `**Verdict:** Changes requested` then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick release MARATHON-GH85-TURN --agent codex --to agy
3. If satisfied: add `**Verdict:** Approved`, set `STATUS: Approved`, then: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick done MARATHON-GH85-TURN --agent codex
4. Use this exact tick binary (run it from any directory) for all token operations: /Users/noelsaw/Documents/GH Repos/xyz-3-agents-swarm/bin/tick
   Edit ONLY phases/gh85/RELAY.md (your review block + STATUS). Do NOT edit the artifact yourself — request changes instead. Do NOT run git.

### Round 1 · Builder · agy

- **Files modified**:
  - [utils/marathon-plan.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/utils/marathon-plan.sh)
  - [test/marathon-plan.sh](file:///Users/noelsaw/Documents/GH%20Repos/xyz-3-agents-swarm/test/marathon-plan.sh)
- **Key Decisions & Implementation**:
  - Implemented `fileExistedAtBaseRef` in `utils/marathon-plan.sh` to check if an artifact was pre-existing in the base ref (stubbed via `QUEUE_PLAN_BASE_FILES_FILE` in tests, otherwise verified via `git cat-file -e`).
  - Modified `some-artifacts-exist` logic to only check for existence of newly created artifacts (net-new), resolving the false-positive on edit-existing-file lanes at 0% completion.
  - Dropped the `changelog-mentions-it` signal from the `undocumented-partial-completion` detector.
  - Added regression test cases in `test/marathon-plan.sh` Scenario J verifying both that edit-existing-file lanes are READY/active and that genuine partial lanes are still flagged `partial`.
  - Ran `bash test/marathon-plan.sh` to confirm all 36 test cases pass successfully.

### Round 1 · Reviewer · codex

**Verdict:** Approved

- Reviewed the on-disk changes in `utils/marathon-plan.sh` and `test/marathon-plan.sh` against the GH-85 brief.
- Confirmed the partial detector now requires evidence of a net-new artifact at the contract base ref before adding `some-artifacts-exist`, and `changelog-mentions-it` is no longer used as a signal.
- Confirmed the new Scenario J regression cases cover both sides of the brief: edit-existing-file lanes documented in `CHANGELOG.md` stay active, while genuine branch+test partial work still resolves to `partial`.
- Verification: `bash test/marathon-plan.sh` -> 36 passed, 0 failed.
