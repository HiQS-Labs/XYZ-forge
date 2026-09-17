# RELAY · GH653 GH665 fixture-only plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-09-17.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh653-gh665-fixture-only-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-653-FIXTURE-SAFETY.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: producer
- Started: 2026-09-17

### Artifact — GH-653-FIXTURE-SAFETY.md
```
---
title: Repair unborn fixture and fail closed on unsafe fixture paths
status: Active
created: 2026-09-17
updated: 2026-09-17
gh_issue: 653
source: https://github.com/HiQS-Labs/XYZ-forge/issues/653
doc_type: bugfix
owner: noel
goal: Restore complete GH-642 coverage without permitting fixture failures to write into caller repositories.
effort: 1
complexity: 2
risk: 3
phases: 1
---

# GH-653 — Fixture safety

## Status

| What was just completed | What's next |
|---|---|
| Existing repair located in held GH-661 clone; current development failure observed; both issues registered/rated | Independent plan QA, extract only fixture changes, verify and open separate PR; test combined with #669 without publishing a stack |

## Quad Concepts

- Unborn fixture prevents complete checks → seed only a validated sandbox repository.

## Recon, diagnosis and recent PRs

Base: development 011113f6. validate.sh:505 registers the existing suite. Its
test/gh642-consumer-fruit.sh:24–29 mkrepo initializes a repository but makes no
commit; :49–53 pushes HEAD then clones/adds a worktree with errors suppressed.
Fresh full-clone reproduction fails after six checks, before real worktree coverage.
Protocol: debug-mantra. Ranked causes: missing commit (source/observed); worktree
feature unsupported (not demonstrated; setup never seeded); full-clone isolation
failure (falsified by controlled unchanged clone identity); vendor behavior failure
(earlier normal-clone assertions pass). Do not imply caller damage on current base.

GH-665: adding a seed alone is unsafe. Failed mkrepo substitution can return empty;
git -C empty targets caller. Existing held GH-661 fixture repair stops construction
failures and reuses test/lib/fixture-guard.sh. That shared guard resolves physical
descendants and refuses empty/traversal/symlink escapes with exit2. _setup.sh pins
the owned root and traps cleanup; do not change either shared file. Source/test
write sites and cleanup boundaries in the complete GH-642 suite were read, including
its RTL temporary worktree, standalone fixture clones and generated stub/output paths.

Recent PR sample: #643 (merged Sep16) introduced this suite; #614 (Sep15) repaired
Claude isolation/routing tests, related class but not this cause; #652 (Sep17)
fixed vendored ledger-conflict tool lookup, separate failure path. Historical #6
(Aug16) introduced the reusable guard, #89 expanded adoption. Existing #669
repairs a different inherited-CWD probe. Search windows Sep03–17 vs Aug20–Sep02:
examples, not exhaustive incident counts; recurrence trend unknown. No other
published PR specifically repairing #653/#665 found. Existing unpublished repair
remains held under #661; extract only this test file, preserving that clone/branch.

## Task map and persisted ratings

| Issue | Requirement | Shared delivery / acceptance | Rating |
|---|---|---|---|
| #653 | Seed validated repository before HEAD use; retain actual worktree coverage | fix/gh653-gh665-fixture-safety; this plan; entire GH-642 suite passes | 90/85/50/90 |
| #665 | Fail closed on malformed/failed fixture setup; caller preserved | same clone/branch/PR; empty/traversal/symlink/mkdir/init faults exit2 with caller HEAD/identity/tree unchanged | 95/95/50/85 |

Ratings: #653 blocks required qualification; #665 has demonstrated potential caller
commit damage in a controlled reproduction. Severity-led urgency, appeal neutral,
local existing repair cheap. Neither canonical nor held-source ledger previously
contained these rows; use existing CLI for intake/rating/promotion, no overrides.
GH-665's issue-named doc links here rather than duplicating the implementation plan.

## Scope and reversibility

Bet: the existing guarded fixture pattern plus one test-local seed restores
coverage without runtime behavior changes. Easy code rollback by reviewed revert;
safety consequences deserve risk3 and independent QA. Shield: owned controlled
callers and separate full validation clones. Tripwire: any changed real clone
HEAD/origin/bare state or caller sentinel invalidates results/stops publication.
One edited test, existing shared guard, no dependencies or new guard abstraction.
No runtime/kernel/Bash-twin changes, worktree removal/policy migration, unrelated
base repairs, merge, deployment, #661 resumption, or stacked-PR publication.

## Phase 1 — Repair and verification

1. Commit plan/intake; independent Codex plan QA cap3 → Approved before code.
2. Extract only GH-642 fixture edits from held source via apply_patch; keep actual
   feature assertions. Require nonempty/owned paths at writes, explicit seed
   identity, checked substitutions, and fail-closed construction → fault tests
   exit2 and preserve controlled caller; full suite reaches true worktree assertions.
3. In disposable full clone, retain original-base red and repaired green. Run
   bounded in-memory controls: disable fixture guard → symlink refusal turns red;
   inject controlled caller commit → caller-preservation check turns red. No tracked
   mutation; all generated fixtures remain inside _setup's owned outer sandbox.
4. Commit code/docs/evidence with source/hash/exit provenance; focused suite and
   static/full local gate in independent disposable clone → green and identity stable.
   Independent final Codex QA cap3 → Approved or explicit blocker, no silent retry.
5. Normal gated push and one PR into development → exact head/base/scope/CI checked,
   issues remain open. In a separate disposable combined-verification clone, merge
   #669 with fixture candidate locally, using existing ledger resolver if needed;
   preserve both ledgers, move resolver backup intact under temp, run full checks.
   Label as combined proposed-change evidence, not qualification of published #669.
   #669 remains draft until prerequisite lands; recheck actual hosted checks without
   claiming a configured/skipped check passed. No merge to development authorized.

### Phase 1 — QA checklist

- [ ] Original unborn fixture red retained and actual linked-worktree coverage green.
- [ ] All five fault refusals and caller checks pass; guard/caller controls witnessed red.
- [ ] Focused/static/full gate green at final source, clone identity stable, provenance committed.
- [ ] Independent plan/final QA Approved; separate PR base/head/scope verified.
- [ ] Combined #669 checks recorded separately; prerequisite and merge hold explicit.

## Lessons Learned (For Future Agents)

An initial commit is a prerequisite of worktree coverage, not a reason to skip it.
Guard path construction before introducing that commit; empty git -C targets caller.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

### Producer R1 — fixture-only plan review

VERDICT: PARKED
Basis: awaiting independent plan review; producer makes no approval claim.

Review PROJECT/2-WORKING/GH-653-FIXTURE-SAFETY.md and the GH-665 adapter against the current complete test/gh642-consumer-fruit.sh, test/lib/fixture-guard.sh, test/_setup.sh, and its validate.sh registration. This is plan QA, not implementation approval. Read-only review: do not run tests, mutate Git, or edit any artifact besides this relay thread. This valued source clone must not host mutation-heavy checks. Apply commensurate review: one existing test, existing guard, no runtime changes.

Questions: (1) Does guard-before-seed plus checked construction/substitution prevent empty/path-escape caller writes? (2) Does the bounded extraction preserve actual worktree coverage and reuse the existing guard? (3) Are the separate issue receipts and shared plan sufficient, with historical PR examples not exaggerated into a measured trend? (4) Do baseline red, guard/caller negative controls, isolated gates, and conditional combined #669 verification prove the stated outcomes without claiming the published draft is qualified?

Definition of Done: approve this bounded plan only when these four questions are satisfied; otherwise give precise graded blockers. Source extraction starts only after Approved. Final code QA is a separate relay. No merge or draft-to-ready authorization. On approval set STATUS Approved and finish the tick task through the existing protocol.

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
