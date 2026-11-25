---
gh_issue: 1603
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1603
title: "Merge-cleanup readiness and transcript parking"
status: "In Progress"
created: 2026-11-25
updated: 2026-11-25
doc_type: bugfix
goal: "Report the landing blockers together and keep unverifiable transcripts local."
effort: 2
complexity: 2
risk: 2
phases: 1
---

# GH-1603 — Merge-cleanup readiness and transcript parking

## Status

| What was just completed | What's next |
|---|---|
| Codex approved the plan in round 2. Implemented and passed the disposable-repository red/green matrix. | Final Codex QA and full-gate qualification. |

## Quad Concepts

- Lost Phase 0 context → one snapshot and a compact final verdict.
- Mixed commit and ref counts → separate readiness from preservation evidence.
- Unverified transcripts in local commits → pin the checked commit or park it locally.

## Recon

Base `c2e528dd13d504e5650c2c97b987ae17dd157ac6`. In `scan_clones.py`, `inspect_primary_landing` accumulates dirty, operation, ahead and fast-forward failures. Stashes affect checkout preservation only. `inspect_checkout` counts refs held by `classify_local_refs`, which fetches, accepts proven squash equivalence, and can fail without an unlanded list reaching the table. These are distinct questions. The linked-worktree ref can give two ref entries for one commit. A zero on an inconclusive provenance probe is misleading. On the incident run, tailing output lost Phase 0 and the PR warning only referred back to it. A later status/stash-only check could not see divergence.

`merge_cleanup.py` owns Phase 0, the table, PR sequencing and the final report. Actual docs parking is caller-owned in its skill (GH-1005); there is no parking writer to patch. Deep cleanup backs up locally, prohibits pushes, and sends PR-worthy fragments through a fresh reviewed PR; it has no independent temp-branch route. Consult runs default to the relay transcript root. Forge also keeps marathon logs, test receipts and evidence under their own roots. Prior art GH-523 fixed the missing early inspection; this is a reporting recurrence with a separate unsafe parking recommendation. GH-1470 addresses conflict forecasts; GH-1536 addresses orchestration and repeated qualification.

Re-anchored to `782451b2298964aa0b534f2c8b0bb9e78913c4df` after plan round 1. The incoming diff does not touch these script or skill paths. Source prevention is tracked separately in GH-1604.

Rating 85/85/50/75. A repeated stop in an exercised landing path and foreseeable public disclosure drive priority/severity. Neutral appeal. Local CLI and compact instructions with existing verification drive effort.

## Plan

1. Extend the primary snapshot with all-file porcelain status, stash count and symmetric behind/ahead. Feed this same snapshot into the audit's primary row. Use the cached integration ref as of Phase 0 for its counts, audit readiness fields, and footer, even if audit later fetches. Label the independent audit column “Refs to preserve.” Mark failed top-level proof unknown and mark conservative counts incomplete if merged-PR lookup or necessary comparison failed, or a truncated lookup missed a tip. Keep behind-only and stashes advisory; preserve the existing execution gate. Repeat blockers plus counts and any parking refusal in a compact footer of normal, scan-only, and PR-only dry runs, including PR-discovery and selection errors where applicable.
2. Extend `scan_clones.py` with a read-only transcript parking precheck reused by Phase 0 and available separately for any candidate through a flag on the existing CLI. Read full changed blobs in local-only history (including transient commits and rename sides), the index and changed/untracked working files under `relay-system/` (including canonical consult output), `marathon-system/`, `consult/`, `consult-receipts/`, `TESTS-RESULTS/` and `evidence/`. Dispatch the standalone precheck before any audit fetch, and use read-only Git commands without optional index updates. In Phase 0 cover both HEAD and the integration branch if different. Use structural repository references (GitHub remotes/URLs or explicit owner/repo fields), compare with the checkout origin, and treat unreadable evidence, unidentifiable transcript content, private visibility and lookup failure as a refusal. Query only structured GitHub slugs, check the exact returned identity and public visibility, and avoid echoing names or transcript text. For remote parking, first verify the actual push destination is the same canonical repository as the fetched origin and obtain its integration OID from a successful refresh. Pass the exact candidate commit OID to the precheck in that checkout, and publish only that OID with the existing creation-only destination lease. If the candidate or baseline changes, repeat the check and require the candidate checkout to stay quiescent through publication; a green heuristic never certifies sensitive content is absent. It can miss references expressed indirectly or omitted alongside a recognized identity, references outside covered roots and other secrets.
3. Refuse the remote parking procedure on a failed precheck. Recommend a verified local bundle/ZIP, preserved local branch, clean integration ref recreated from origin and a record in the existing temp-docs ledger, subject to operator decision. No automatic publication, reset or deletion. Deep cleanup will refer to this check for transcript-bearing hunks before the fresh-PR handoff. Relay source prevention requires its own target/routing review (GH-1604).

Adding only another Phase 0 paragraph leaves tail truncation, audit ambiguity and the parking path unresolved. Revert the patch to roll back. Scope is the local developer CLI and caller runbook; no global secret scanner, new service, suite or automatic repair. Do not touch another session's clones. Full gate is required for this skill text and script.

## Acceptance Checks

- Real throwaway bare upstream, diverged checkout, same-tip linked branch, one dirty path and one stash. Fake only GitHub responses with the existing CLI seam. Base dry run prints 1 local commit near the top, 2 unlanded refs, no behind count, and a final warning without details. Compare labeled dirty, stash, ahead and behind counts with the primary audit row. Confirm that the distinct ref count can be two with complete proof, two with incomplete proof after a failed merged-PR lookup, or unknown after a failed top-level query. Require every blocker (including a separate operation-marker variant) and all readiness counts in the last 20 lines of normal, scan-only, and PR-only previews, and after discovery and selection errors with unchanged exit status. Advance the bare origin without fetching in the fixture to check the audit does not rewrite the Phase 0 snapshot.
- Base neither flags the committed foreign transcript nor provides a publish precheck. Require a refused precheck and Phase 0 advice for fixture private and lookup failure, a public-positive control, and a same-repo transcript plus ordinary docs control. Exercise separate staged and untracked artifacts, same-tip worktrees with different index content, a removed intermediate commit and a rename across the transcript boundary. Reject unknown target identity, unreadable evidence and a mismatched lookup result. Require unchanged refs, status, index and FETCH_HEAD. In the caller procedure skip publication on refusal and confirm no remote temp ref exists. On a passing candidate advance the temp ref after inspection and confirm the creation-only push in the fixture still publishes the inspected OID.
- A fast-forward-ready primary without local work has no additional warning or footer. Confirm stash/behind-only do not block. Record observed red/green and run existing merge-cleanup and Codex harness suites in disposal isolation. No new tests under GH-831.

## Verification

- [Manual check and red controls](../../TESTS-RESULTS/2026-11-25+GH-1603/manual-check.md).
- Integrating the latest development tip touched only generated ledger conflicts. The existing semantic resolver replayed the issue rating and accepted start through the writer, and the attempt admission still covers the task branch.
