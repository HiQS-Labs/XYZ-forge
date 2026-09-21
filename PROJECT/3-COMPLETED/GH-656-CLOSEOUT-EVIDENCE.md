---
title: Jog and pre-merge closeout evidence repairs
status: Complete
created: 2026-09-16
updated: 2026-09-21
owner: Claude Code (merge-cleanup-deep → fresh-clone re-delivery)
gh_issue: 656
source: https://github.com/HiQS-Labs/XYZ-forge/issues/656
doc_type: bugfix
effort: 2
complexity: 2
risk: 2
phases: 1
fix_probes:
  - bash test/gh280-jog-marathon-adapter.sh
  - bash test/gh496-phase2-reconciliation-views.sh
goal: Repair two existing closeout evidence guards without adding machinery.
---

# GH-656 / GH-657 — Closeout evidence Jog

## Status

| What was just completed | What's next |
|---|---|
| Re-delivered 2026-09-21 from the 2026-09-16 clone (`XYZ-forge-closeout-evidence-fixes`, plan Codex-attested, final QA never run): the four hunks apply cleanly on `development@39bb1392`; red controls witnessed again (unfixed source: gh496 `GH-657 committed receipt outcomes` red, Jog L5 refuses rc=6), green gh496 exit 0 and gh280 223/0, neighbours gh425 and wave-reconcile.sh green — `TESTS-RESULTS/2026-09-21+GH-656/`. | Independent cross-model review on the PR diff, gated push, one PR closing #656 and #657 and referencing #646. **Do not auto-merge** (issue delivery rule); operator merges. |

## Quad Concepts

- Verified merge proof omitted → preserve it in the existing manifest.
- Failed tests accepted → validate every supplied outcome before acceptance.

## Scope

Shared repair plan for GH-656 and GH-657, discovered in GH-646 final review.
Fresh canonical development clone, branch `fix/gh656-657-closeout-evidence` (fresh clone of 2026-09-21; the 2026-09-16 branch was never pushed), one PR into development.
No automatic merge, deployment, production migration, or reader changes.

## Recon

Canonical trace: [Recon Map](recon-closeout-evidence.md), preserving the intake observations below.

Base: `a605f5d40a178611a0f64a8dc9d0ae87caaa04ab`; grep-only, one bounded local lane.
`jog_run.py:jog_land` verifies PR identity and merge reachability, persists landing,
then writes an offline manifest and invokes the real wave reconciler. The manifest omits
`mergeCommit`, although `merged_sha` is available. `wave_reconcile.py:ship_manifest_items`
requires that full SHA for nonempty release membership; empty legacy fixtures miss this edge.
`wave_reconcile.py:validate_pre_merge_receipts` reads committed JSONL at HEAD, checks identity
and staleness, but accepts positive result OR integer-equal-zero rc. Contradictory and
boolean outcomes can therefore qualify. Its post-merge attribution guard is separate and unchanged.
Callers: Jog land/reconcile; wave reconcile pre-merge; existing GH-280 and GH-496 tests.
State: existing Jog queue/landing record, release membership, committed test receipts. No new writer.
Unknown: final registered-suite behavior on current development; settle in disposable validation clone.
Failure/rollback: existing refusal messages and replay; focused revert is Easy before deployment.

## Rating rationale

GH-656: 90/85/50/80 — recoverable task-completion blocker; user requests immediate repair.
GH-657: 95/90/50/75 — failed-test evidence can falsely qualify delivery; higher consequence.
Appeal remains neutral. One observed incident each, traced from GH-646 review; recurrence trend
unknown (searches found related evidence work but no duplicate focused report).

## Plan

1. Independent Codex plan QA, capped at three review rounds; no production edits before approval.
2. GH-656: extend existing verified landing fixture with a real owned dialed-in member;
   observe omission failure, carry `mergeCommit: {oid: merged_sha}`, prove shipping and replay.
   Use GH-280 section L; assert that exact member is dialed_in before landing and shipped
   afterward with evidence equal to the full verified merge SHA. Normal L6 and missing-step L7
   replay must retain identical member/evidence/receipt counts; omission must fail shipping.
3. GH-657: extend existing committed-receipt tests; reject any supplied unsuccessful or malformed
   result/status/rc, including contradictions and boolean rc. Retain supported result-only,
   status-only, integer-zero-only successes; missing outcomes refuse. Observe old guard failing negatives.
   Isolate one committed, identity-matching, nonstale candidate per case: both result/rc
   contradictions, both result/status contradictions, boolean rc with and without pass,
   null/empty/wrong-type fields, absent outcomes. Positive controls independently cover all
   pass/passed/PASS tokens in result and status, integer zero, and consistent combined success.
4. Run focused regressions and fail-open/omission controls in a disposable full clone; retain raw
   outputs and source-pinned JSONL in TESTS-RESULTS. Debug-mantra is the execution debugging protocol.
5. Final Codex source/evidence QA, capped at three rounds; applicable qualification and gated push,
   then one PR closing both child issues and referencing (not closing) GH-646. Stop before merge.
   Required commands: `bash test/gh280-jog-marathon-adapter.sh` and
   `bash test/gh496-phase2-reconciliation-views.sh`; `bash ci-local.sh --base origin/development`
   (full, not --fast); `./validate.sh` at gated push; `utils/pdda/pdda.sh run` and `releases check`.
   Run heavy gates in a disposable full clone on macOS. Failed gates block ready PR publication.
   Final QA examines source-pinned outcomes; do not infer passing from empty or missing logs.

## QA acceptance

Execution evidence lives in `TESTS-RESULTS/2026-09-21+GH-656/` (the 2026-09-16 clone's evidence stayed in that clone; its zip is under `~/Documents/Backups/XYZ-forge-clones-2026-09-21/`). Delivery is not complete
until actual focused/full gates and final QA pass. Final QA transcript is retained there as
test-review evidence, so receipt-only follow-up commits do not alter tested source.

- [x] Nonempty release membership ships through real Jog → reconciler; replay duplicates nothing.
- [x] Contradictions, failure tokens, malformed outcomes and boolean rc refuse; legacy/current positive controls pass.
- [x] Both regressions are observed red before repair or under a targeted revert mutant.
- [ ] Independent review on the delivered diff recorded on the PR; pre-push full gate green on the delivered source.
- [ ] PR link and remaining integration gates posted to both issues and GH-646.

## Jog execution boundary

### Verification fixture prerequisite (GH-653)

The canonical GH-642 fixture's R1 repository has no initial commit before the bare-parented
worktree case. Direct baseline fails "worktree fixture not created". Add one empty initial
fixture commit (test-only, Easy, no runtime changes); rerun the existing GH-642 suite and retain
red/green evidence. This is necessary gate preparation, not another production repair.

The existing SQLite `jog_queue` is authoritative. This file is the human-readable Jog brief,
not another queue engine. Register both tasks using existing roadmap/Jog verbs. Execute this
same-seam batch together; do not fire unrelated inherited queue entries or auto-merge between repairs.
Preserve inherited queue state. If serial supervisor requires landing between tasks, keep the
shared PR implementation manual rather than granting unrequested merge authority.

## Merge evidence

- (recorded at landing)

## Lessons Learned (For Future Agents)

- A finished-but-unpushed fix is one `/merge-cleanup-deep` pass from being lost: the 2026-09-16
  clone held both repairs and a Codex-attested plan, but its final QA relay was a scaffold with an
  empty log and the branch never left the machine. Push the branch the day the red/green exists.
- Port hunks, not the branch: the old base was 64 commits behind and `wave_reconcile.py` had moved
  (GH-684, GH-693, GH-698); `git apply --3way` of the four file diffs onto current `development`
  applied cleanly where a rebase of 18 commits would have been conflict archaeology.
- The receipt gate's two bugs are one class — "any positive token wins" — so one predicate
  (`outcome_ok`: every supplied outcome valid *and* successful, absent outcome refuses) is the
  whole repair; do not add a status vocabulary.
