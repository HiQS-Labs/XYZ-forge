---
title: "GH-1037: release-review sync ownership fixes"
status: captured
created: 2026-10-12
updated: 2026-10-12
owner: Codex
goal: "Preserve child deletions and commit only the manager update's owned README mirror."
gh_issue: https://github.com/HiQS-Labs/XYZ-forge/issues/1037
related: [GH-1012]
branch: fix/XYZ-forge-gh1012-sync-fixes-2026-10-12
---

# GH-1037: sync ownership fixes

## Status

| What was just completed | What's next |
|---|---|
| Two P2 release-review defects reproduced on development 2f8969a2; operator authorized both bounded fixes and corrected release merge | Independent bounded plan QA, implement, existing checks and retained manual red/green controls |

## Scope and evidence

This child implementation plan records only the two authorized findings; it does not replace or update the separately blocked GH-1012 release plan. Evidence is the GH-1012 review on PR #1036 and its supporting draft #1035. Base is 2f8969a292e8dd230ab69ab9fe4ddc96a898ab55; main remains a076b1b117a68252dc3d9d1c4901b0c31fcb4db3. No active hosted reconciliation observed before setup. Fresh owned workspace full clone uses parent issue 1012 in its group name; selected workspace write boundary governs its location. Other clones, stashes and refs remain untouched.

Ratings: priority 70 (release correction), severity 65 (P2 downstream sync correctness), appeal 50 (neutral; no operator value override), effort cheapness 85 (two localized mechanisms); sum 270. Recurrence is not inferred beyond these recorded reproductions.

## Recon and smallest bet

The publisher's MANIFEST.txt is the existing ownership/deletion source. publish_one derives established adapted entries from previous file paths, but an entirely removed entry leaves no ownership witness. Retain a trailing-slash adapted-root marker in the same manifest, separate markers from payload paths before deletion/retry checks, keep legacy file-path inference, and remove markers when an upstream adapted entry is removed. No sidecar database or new publisher.

Skills Army finish refreshes root README from the manager in the existing transaction. commit_skill currently accepts only the selected folder. Before an update of skills-army-hq, establish that root README is a clean tracked mirror of the old manager README; only that transaction-owned path may join the existing commit pathspec. Other updates and preexisting/unrelated dirt retain refusal. No push/deploy writer is added. A broad README exception is rejected because it could sweep unrelated edits.

Changes are Easy to revert via the normal PR revert. Risks: markers must never be sent to git rm or treated as missing payload on retry; the README exception must be captured before transaction overwrite, limited to the manager update and exact collection-relative path. This fixes future ownership retention; already lost legacy markers cannot reconstruct a past deletion reliably.

## Ordered implementation and acceptance

1. Retain adapted root ownership in the existing manifest, treating marker rows as metadata rather than payload -> the recorded entire-entry deletion control remains absent across two publications; upstream drop/re-add existing checks retain behavior.
2. Extend commit_skill with explicitly owned transaction paths captured before manager update -> clean fixture commits both managed README files; unrelated/preexisting dirt is never admitted to that commit.
3. Replay recorded pre-fix red controls and corrected local fixtures with all deployment targets disabled, no pushes/providers; run existing skills-army/mini suites in a disposable full clone -> nonempty raw results and no new CI case/parameter/registration.
4. Independent native Codex QA on committed diff and evidence, maximum three rounds -> Approved before supporting landing. Native invocation satisfies independent peer parity; do not fabricate Forge relay-driver attestation or call providers.
5. Normal gated PR to development, preserving history and exact-head merge protection; monitor hosted reconciliation. Supporting evidence landing is authorized. Freeze final development/main; full existing release regression and recovery/red controls plus firsthand review and independent QA -> promote #1036 only after exact heads/checks clear, then require exact resulting-main MACOS-BOUNDARY green.

## Holds and boundaries

#954 and #1024 remain excluded; #930 held; #1033 separate. Preserve #1024's failed/exhausted review state, #1031 and unfinished work. No canonical #1012 issue/plan retry, live provider/pilot, installed skill deployment, schedule, credential/access changes, new CI tests or gate bypass. New high/critical findings, exhausted QA budget or scope expansion stop the dependent merge.
