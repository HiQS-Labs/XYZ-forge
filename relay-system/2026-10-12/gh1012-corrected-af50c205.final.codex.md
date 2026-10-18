# Independent native Codex final release QA

Mechanically invoked via collaboration.followup_task on /root/range_runtime after the exact F full local gate completed. GH-1012 final release QA round2 of cap3; prior D Changes Requested round1 preserved. This is native Codex peer QA, not Forge relay-driver/provider attestation. No review-cap reset or takeover of #1024.

**Verdict: Approved — GH-1012 final release QA round 2 of cap 3**, for frozen B a076b1b117a68252dc3d9d1c4901b0c31fcb4db3 to F af50c205e3f04f3fc6a02ac6c402f2013123b127. Both original P2 findings are resolved; no outstanding confirmed Blocker or Should finding.

Independent checks confirmed:

- HEAD F, merge base B,366 commits/2162 no-rename paths.
- D to F changes only the two authorized product surfaces: xyz_mini_sync.py and intake.py.
- Exact-F canonical ci-local.sh --base B: exit0,10 green pipeline stages,408 recorded verdicts comprising407 passes and duplicate-acorn skip after successful npm/acorn. Transcript bytes/hash match the gate record; external identity is unchanged.
- Corrected controls preserve whole-entry deletion, commit the clean manager mirror, refuse unrelated/staged README dirt, and accept publication retry. Removing the retry filter produces the retained red control.
- Mainline1 recovery restores exact B; mainline2 fails. Package parity passes.
- Hosted landing and exact-F smoke receipts support their stated claims. Main-only boundary remains skipped and is not credited as stable qualification.
- Original D-bound seam receipts retain their provenance; relevant source continuity supports reuse.

Minor publication wording: change Evidence is published to pending tense until the final carrier SHA/URL exists. This does not block candidate approval. Root corrected that wording before publication; no additional QA round claimed.

Approval remains conditional on immediate head/base/check revalidation before the authorized merge. Stable requires the exact resulting-main MACOS-BOUNDARY: green SHA.

This is native Codex peer QA, not Forge relay-driver/provider attestation. No tests, edits, live calls or cleanup performed. Inherited interpreter/worktree limitations, installed-state recovery, live provider validation and historical test-approval provenance remain outside this approval.
