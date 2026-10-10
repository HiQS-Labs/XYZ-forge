---
title: "GH-1015 · Progress observer receipt path attribution"
gh_issue: 1015
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1015
status: Planning — independent plan QA pending
created: 2026-10-10
updated: 2026-10-10
owner: Codex
goal: Recognize qualified driver receipts through logical target paths without weakening attribution.
doc_type: bugfix
---

Source: [post-merge review on #1012](https://github.com/HiQS-Labs/XYZ-forge/issues/1012#issuecomment-6099632746).

Scope: observer init path representation, missed-check JSON ordering, stale GH-609 registry comment. No driver receipt schema change, new suite, gate, or automatic continuation. The relay package does not contain marathon.sh (18 members verified); no package change is needed.

## Status

| What was just completed | What's next |
|---|---|
| Independent baseline reproduction, intake and rating; bounded recon completed | Independent Codex plan QA before implementation |

## Recon and root cause

Base: `9a923f3cc131f432f2682e7a11f57d03597fb5df`. [Recon Map](GH-1015-OBSERVER-PATH/recon-observer.md) records the observed launcher → driver receipt → observer → stdout/context path.

Root cause: observer init changes the caller's logical product path to a physical path, unlike the driver receipt producer; Fix site: observer init; Why not upstream/downstream: the driver's established abspath representation remains the contract, and exact matching stays strict instead of tolerating foreign receipts.

Baseline retained under `TESTS-RESULTS/2026-10-10+GH-1015/`: physical accepted (1), logical symlink rejected (0), foreign execution rejected (0). This is a synthetic receipt check, not a live marathon qualification.

## Outcome and bet

A fully qualified receipt matching the supplied target path is recognized, including logical symlink paths. The assumption is that both launcher consumers receive the same unchanged target argument (read at marathon.sh:565 and :604). Easy to revert the three source edits; observer-only observation can be omitted. Failure signal: logical-path acceptance or a foreign-input negative control fails.

Alternatives: keeping resolve on both sides would require changing the existing driver receipt representation; comparing realpaths at the receipt reader loosens the exact target identity policy and adds input handling. Aligning init with driver abspath is the smallest compatible fix. Strongest counterargument: a consumer could have relied on physical product_root output; that representation was already inconsistent with its receipt. Coordination/harness roots remain unchanged.

## Scope, blast and non-goals

Two production files: `relay-automation/marathon.sh` and the comment in `validate.sh`. Observer product_root now reports the driver-compatible logical absolute path; missed-check JSON gets the same sorted keys as normal emit. No receipt/schema, executor, heartbeat, qualification, lock, schedule, retry, containment, installed skill, or continuation change. No new suite, registry entry, gate, or controller. Archive regeneration is unnecessary: the existing builder and 18-member archive exclude marathon.sh.

The current radius is the launcher's opted-in observer and its context/stdout consumers. The new effect is successful attribution under logical target roots and consistent JSON presentation. External consumers not exercised here are an explicit limit, including Flightdeck and live provider marathons.

## Ordered implementation and acceptance

1. After Approved plan QA, admit only GH-1015's exact owned RELEASES row with accepted-start; replace init product_root resolve with os.path.abspath. → Expect driver and observer paths identical for physical, absolute symlink and relative symlink inputs; qualified finish increments verified_phases to 1.
2. Add sort_keys=True to missed-check json.dumps and refresh GH-609 registry comment to workload-scoped online migrations. → Exercise overdue slots with controlled clock: both missed-check and normal JSON parse nonempty and keys sort deterministically; read the existing GH-609 safeguards to verify the comment's wording.
3. In a disposable full clone, replay manual init/phase/finish and emit checks with synthetic attributable receipts. → Foreign execution, token, target, schema, phase and lane remain rejected; missing/non-green qualification remains unverified. Red control: replay the same symlink acceptance check on committed base (0), candidate (1), and a copied payload with the old init restored (0). Restore only owned experiment copies. Retain commands, raw observations, source hashes and provenance under TESTS-RESULTS/2026-10-10+GH-1015. No registered test files are added.
4. Run existing applicable focused checks (Codex shim prerequisite, GH-609 comment scope, relay package freshness) only in the disposable full clone; bracket HEAD/origin/bare/local identity. Obtain independent final Codex QA on the committed diff and manual evidence. → Approved with no unresolved required findings; no empty-output substitute.
5. Classify actual diff against development; the launcher and validate.sh require the full route. Execute the required macOS full gate once through the normal pre-push hook in a disposable publication clone. → Passing gate with intact Git identity for the reviewed source revision. Retain provenance, publish any evidence-only tail through the docs gate, verify exact emitted PR base/head/checks, hand off ready PR without merging.

## PRS assessment — 2026-10-10

Canonical RELEASES read-back: rated 60/35/50/90, no operator override. Priority 60 follows the operator's requested next work and cheap fix; severity 35 is conservative loss of observation fidelity, not work loss or unsafe execution; appeal 50 is neutral; cheapness 90 reflects three local edits plus governed verification.

Recurrence search: created 2026-09-26 through 2026-10-10 versus 2026-09-12 through 2026-09-25, keyword symlink in issues. This review and #1015 are one incident, not two. #814 (created 2026-09-25) is a concrete logical/physical resolver mismatch in a different seam. Search results also contain unrelated skill-link issues; no inferred shared root or numeric trend. Comment/reopening history is not exhaustively audited, so velocity is unknown. Evidence justifies a narrow fix without escalating to a safety incident.

## QA and handoff

Plan QA: pending. Final QA: pending. Verification: baseline reproduced; candidate and qualifying gate pending. Issue remains open until landing; batch #1012 remains open for other carry-overs. Task clone retained until merge-cleanup verifies origin landing.
