---
gh_issue: 901
source: https://github.com/HiQS-Labs/XYZ-forge/issues/901
title: Codex desktop native sidebar heartbeat
status: Active
created: 2026-09-30
updated: 2026-09-30
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
| Native title/pin tool smoke; Codex/Agy plan consult reconciled; adapter implemented | Recorded manual probes, independent final QA, disposable-clone gate, push and native heartbeat |

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
