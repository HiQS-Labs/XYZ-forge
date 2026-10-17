---
gh_issue: 1108
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1108
title: "Land Jog deliveries after bounded repair from the canonical checkout"
status: Inbox
created: 2026-10-17
updated: 2026-10-17
owner: noelsaw1
goal: "Land verified merged Jog deliveries using external execution receipts and canonical PRS state."
doc_type: fix
effort: 3
complexity: 3
risk: 3
phases: 1
---
## Status

| What was just completed | What's next |
|---|---|
| Fresh canonical clone and bounded recon | Register, review plan, then admit implementation |

# GH-1108: Jog landing receipts

## Observed failure and recon

At base `b26c9edb73f61587a71287f68cb4338409188042`, `jog_land` requires exact PR/receipt head equality (`utils/py/jog_run.py:966`), tests merged reachability against a potentially stale local branch (`:990`), and uses one root for both execution evidence and canonical PRS writes. CLI aliases at `utils/py/releases_app.py:4981,6823` cannot select a source ledger. Source GIDs may differ from destination queue GIDs. Existing landing saves its marker before queue completion and skips that completion on replay (`jog_run.py:1015`), so an interrupted transition can remain stranded.

Issue #1108 records approved receipt `6f521bc5`, repaired head `974d98db` and merged PR #1102. Direct Git history confirms ancestry but its endpoint diff also imports PROJECT, TESTS-RESULTS, marathon and relay documents, beyond the six requested paths. The bounded exception below intentionally refuses that historic head; it needs renewed approval. We do not silently classify all imported upstream work as approved repair.

Graph project XYZ-forge, generation 2026-09-01T15:54:30Z, supplied provisional symbol/edge leads only. Coverage reported changed metadata/not-tracked and partial gh280 lines 628–629; current source was read for every material claim. Bounded read-only recon independently traced approval and storage roots. Prior-art scan found #1104 (dispatch root) and #733 (shipping evidence), neither changes this landing seam; no competing fix identified.

## Solution fit and containment

Outcome: a primary checkout can complete its queue and lifecycle from task-clone receipts after a merged delivery, including a narrowly permitted ledger/view repair. Extend existing `jog_land`, the PRS writer `jog_set_status`, and `wave_reconcile`; no schema or parallel state writer.

Smallest bet: retain exact-head fast path; permit a differing head only when the approved head is its ancestor and the NUL-delimited endpoint diff changes only `releases.db`, `releases.sql`, `LEADERBOARD.md`, `RELEASES-PREVIEW.html`, `LEADERBOARD.html`, `CHANGELOG.md`. Missing objects, ancestry/diff failures and any other path refuse before writes. This is a landing-only exception; pre-merge approval remains exact. The gate belongs to the approved head, not the repaired head; record both and changed paths in landing evidence. Path confinement is not a semantic attestation of B1 repair.

Add optional `--ledger-root` to land/reconcile. `--root` remains the destination for GitHub truth, Git fetch/reachability, PRS and lifecycle. Source root owns receipt lookup, original execution GID, state and manifest. Require an existing source DB/root, receipt source path match, and matching nonempty GitHub origins for distinct roots. Resolve exactly one canonical queue row before writes. Do not copy/rekey execution state. Relative evidence resolves against the source execution directory.

After GitHub identity/gate checks, fetch integration into its explicit origin tracking ref (no checkout or local branch update); verify merged SHA reaches `origin/<base>`. Fetch the PR head ref when needed for repair proof. Fail closed on fetch failure. Check base is a valid branch ref before interpolating refspecs. A successful ordinary replay performs verification but emits no duplicate PRS receipts. Destination root and destination GID join the landing key; a changed projection clears prior reconciliation success. Ensure canonical queue completion before honoring a reconciled marker, so replay repairs the interrupted boundary.

Simpler alternatives rejected: document running land in the receipt clone still strands primary state; exact equality still rejects safe six-path repair; broadly accepting any ancestor head accepts unreviewed source. Import-aware merge proof is deferred because it adds topology/tree merge machinery beyond the issue's explicit six-path requirement. Existing operator-configured accounts only; no new network exposure.

Reversibility: Costly approval/state-root boundary. Roll back code/CLI/docs together by reverting the PR; existing JSON receipts remain readable. Never alter approved receipt content. Scope excludes merge-cleanup algorithms, global relay attestation policy, pre-merge checks, retry dispatch, schema, new tests/gates and historic queue repair/live land execution.

## Ordered implementation and verification

1. Commit plan/recon and PRS rating, run independent Codex plan relay; admit the owned roadmap row with `--accepted-start` only after Approved.
2. Extend existing land and both CLI aliases with source/destination routing and bounded approval proof; retain canonical writers. Verify manual red controls against base and candidate in disposable full clone, including allowed repair, forbidden source path, nonancestor/missing objects, fetch failure/stale local integration, split roots with reminted GID, missing/wrong root, replay and interrupted queue completion. Assert nonempty extracted evidence.
3. Update existing gh280 fixture only where new origin fetch/gate wording changes its pinned behavior; run its full existing suite and relevant receipt/reconcile coverage in a separate full clone, checking Git identity before/after. No new suite or registry entry. Record manual commands/results with committed provenance under `TESTS-RESULTS/2026-10-17+GH-1108/`.
4. Document `--ledger-root` in Jog skill and record the consequential bet in CHANGELOG. Run independent final Codex relay, then the routed push gate at final approved code revision, open a development PR with evidence/limitations and inspect actual head/base/checks. Retire only safely published task/helper clones.

## Acceptance

- Six-path repaired descendant lands; nonallowed endpoint changes, nonancestor/unavailable heads and failed fetch refuse without queue/lifecycle writes.
- Fetched origin integration is authoritative even when local integration is stale; no local branch rewrite.
- Primary destination with task-clone ledger (including distinct GIDs) completes only canonical PRS/lifecycle; source DB is unchanged and original receipts are intact.
- Same-root callers and both verbs work; replay emits no duplicate PRS operation receipts; interrupted queue projection recovers.
- Existing suite and required gate pass; plan/final independent QA and all cited run provenance are committed.

## Rating

PRS pri/sev/appeal/effort = 85/80/50/60. Canonical landing is blocked after routine repair; rerunning completed work risks duplicate execution. Moderate two-root adapter work across existing writers. Appeal 50 is neutral; no operator override. #1102 and GH-1087's clone-local projection are reported manifestations in one landing batch, not proof of independent recurrence. No verified trend comparison across the prior two 14-day windows; no recurrence boost claimed.
