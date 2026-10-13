---
gh_issue: 901
source: https://github.com/HiQS-Labs/XYZ-forge/issues/901
title: Codex desktop native sidebar heartbeat
status: Complete
created: 2026-09-30
updated: 2026-10-02
owner: Codex
goal: Extend the central task-sync planner with native Codex sidebar grooming
doc_type: feedback
---

Extend GH-896 / PR #900's centralized task-sync with a read-only Codex snapshot
adapter and supported native desktop title/pin tools. One 15-minute heartbeat;
reuse core stamp/report semantics, the CLI, and the Skills Army deployment path.
No direct app-store writes or parallel scheduler. Default recent window 24 hours;
preserve manual pins and custom sections, skip remote/cloud and non-Codex chats,
and exclude the heartbeat itself. Actual turn activity supplies the date so
metadata grooming cannot make an old chat appear newly worked on.

Live requirements and discussion: [GH-901](https://github.com/HiQS-Labs/XYZ-forge/issues/901).

## Status

| What was just completed | What's next |
|---|---|
| 28 manual probes pass; 5 native renames + 6 pins readback verified; independent reviewer PASS | Small gate 75/75 PASS and native heartbeat ACTIVE; publish dependent PR and await #900 landing |

Review cleanup: all eight CodeRabbit threads addressed; reviewed PR900 prerequisite incorporated. Fresh Codex QA r3 Approved at `a615e2dc`; final macOS Small gate 75/75 (Python 21/21), zero retries. Merge order remains 900 → 902; primary checkout deferral requires the operator’s pending response.

## Recon and decisions

Graph generation 2026-09-01 is stale and missing task-sync, so exact source from
PR #900 was read. The CLI dispatches per-IDE sweep/doctor via _build_adapter;
core owns clean_base, local_stamp and new_ide_report. Codex supplies an external
native snapshot; it reads no private stores and mutates nothing. Existing
ZCode/Agy defaults and writer paths stay in place. Native list_threads exposes
Unix-second updatedAt and sections/itemKeys; read_thread exposes latest turn
startedAt/completedAt in seconds. The inventory is bounded (all pins + 50 recent
chats), not exhaustive. Project-grouped chats and custom sections are preserved.

Easy reversibility: native tools restore the retained old title or move newly
pinned chats back to their observed section. No deletion or automatic unpin.
The latest actual turn time drives the stamp and pin window. Missing activity
aborts instead of falling back to UI updatedAt. Heartbeat chat excluded.

Plan consult: both advisors endorsed native-tools-only I/O and central core reuse.
Codex blockers on title truncation, snapshot scope and conditional application
were accepted. Agy's suggestion to make --apply a successful no-op was declined:
that would misrepresent writes/receipts. CLI preflight refuses unsupported mixed
invocations before any adapter can write. Its timestamp-format suggestion was
falsified by observed numeric-second native responses.

## Verification and delivery

1. Run recorded manual probes with nonempty inventory and malformed/stale/empty/missing-activity red controls; retain provenance.
2. Verify native title/pin readback and replan idempotence; stale preconditions skip instead of overwriting changes.
3. Run independent Codex final review with retained receipt; fix concrete findings.
4. Run the appropriate existing gate in a separate disposable full clone, validate ledger/doc contracts, commit and push the dependent branch.
5. Reuse or install one native 15-minute heartbeat; quiet unchanged, notify failures or required action. Retain this task clone while PR #900 and this extension are unlanded.

## Final review and live evidence

Independent Codex final review: VERDICT PASS with firsthand narrow positive,
missing-activity, old-actual-activity and idempotence probes. The first supervisor
run exited 4 (close-mismatch): the reviewer authored Approved but released the
coordination token back to producer rather than closing it. That protocol failure
is not recorded as a driver-attested approval. The second turn reached driver-attested Approved against 0b18f924
and verified the integrated state. Source was unchanged by integrating current development;
ledger conflicts retained both branches' keyed rows and higher generation before
the canonical resolver rebuilt and checked the DB. Code was not hand-merged.

Live native smoke: five recent loose chats renamed, six newly pinned, all six
read back successfully; current heartbeat chat separately renamed/pinned. Raw
private titles/IDs and undo receipt remain in local temp; committed provenance
retains aggregate observations. Existing legacy ZCode task-stamp heartbeat found
active; paused through app UI and readback verified disabled/idle before enabling
the single native Codex heartbeat every 15 minutes with shared ZCode grooming. Antigravity is not newly enabled. The branch
contains PR #900 as a prerequisite; neither PR is considered landed.
