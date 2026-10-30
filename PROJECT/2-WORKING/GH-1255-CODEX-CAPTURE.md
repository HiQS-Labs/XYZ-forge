---
gh_issue: 1255
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1255
title: "Restore CLIO Codex Desktop prompt capture"
status: Deployed — fresh timed acceptance pending
created: 2026-10-29
updated: 2026-10-29
owner: Codex
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
goal: Restore submitted-prompt capture without importing injected context or losing retry guarantees.
---

# Restore CLIO Codex Desktop prompt capture

Canonical request: [Forge #1255](https://github.com/HiQS-Labs/XYZ-forge/issues/1255).
Implementation owner: [rebalanceOS issue #368](https://github.com/HiQS-Labs/rebalanceOS/issues/368); landing vehicle: [PR #369](https://github.com/HiQS-Labs/rebalanceOS/pull/369).
Standalone reports: [CLIO #14](https://github.com/HiQS-Labs/XYZ-CLIO/issues/14), [#22](https://github.com/HiQS-Labs/XYZ-CLIO/issues/22).

## Requirements

Accept event_msg/item_completed/UserMessage text parts alongside legacy user_message; never read response_item text. Preserve source provenance, cutoff, partial-line cursor and writer retries. Extend the existing fixture/suite, warn after consecutive active zero-delivery ticks, and support explicit replay of missed history. Following reviewed upstream landing, publish unchanged to standalone, deploy through Skills Army HQ and verify recovery of requested sessions where submitted events exist.

## Rating

2026-10-29: rated 85/85/50/65. Silent history loss has continued since the format change. CLIO #14 (October 24 local) and Forge #1255 (October 29 local) report one continuing incident; the preceding September 30–October 13 and recent October 14–29 windows have incomplete coverage, so incident trend is unknown. Appeal remains neutral; cheapness reflects a bounded parser/cursor change. No operator override.

## Status

| What was just completed | What's next |
|---|---|
| Upstream, Forge and standalone PRs merged; device deployed; seven requested submissions verified. | Fresh timed submission for strict 120-second acceptance; preserve unrecoverable-session disposition. |

## Recon map

Base Forge `835254712a0696c08d3dae94054bc62a09f3fde6`; Rebalance `f10764f6db909b9c3b770a05213bd43285452589`; standalone `83af59668c2e1ad58c56ef2c9db1794dcc4891b2`.
Grep-only trace, one bounded serial lane across the capture seam; no graph service available.

| Seam | Confirmed source | Contract / failure |
|---|---|---|
| Entry and parser | rebalanceOS `utils/clio-capture/clio-codex-tail.sh:100-197` | Only legacy event_msg/user_message accepted; modern UserMessage silently consumed. First session_meta controls child exclusion independently of resumed context. |
| Cursor and retry | same file `:228-325` | Per-file inode/offset/context/cutoff; newline-only advance after shared writer success. Backfill currently applies only to unseen files. Writer nonzero defers, next scheduled tick retries. |
| Writer and SQLite | `utils/clio-capture/INSTALL.md:59-243`; `clio-store.py:229-271` | Existing shared writer cleans/filter prompts, SQLite capture retains source_event_id and deduplicates. Tailer delivered count means writer acceptance, including filtering/dedup, not necessarily new rows. |
| Publication | XYZ-CLIO `AGENTS.md`; `scripts/publish-from-rebalance.sh:75-85` | Rebalance is canonical; publisher refuses source HEAD not merged into development. No duplicate runtime belongs in Forge. |
| Deployment | Rebalance `utils/clio-capture/README.md`; `clio-runtime.sh` | Skills Army HQ owns deployed bytes; installer owns hooks/jobs. Do not copy task files into installed hooks. |

Consumer hop: writer --record forwards normalized row and original source_event_id to SQLite capture; successful durable capture/pending receipt permits cursor advancement. Legacy JSONL mode also supported. Retry hop: nonzero writer response leaves file cursor unchanged for next launchd tick. Rollback: old reader tolerates extra comment headers; no DB schema change, source rollouts stay read-only. Recorded prompts remain durable when code rolls back.

Measured ground truth: the published manifest contains 15 nonempty files, all byte-identical upstream/standalone (committed `TESTS-RESULTS/2026-10-29+GH-1255/parity.json`). Forge main/development contain no CLIO runtime. Shared deployed files match; installed helper/tailer copies drift. Sampled requested sessions 01a188ca and 01a1892e have modern UserMessage events; 01a18930 has no modern or legacy user-prompt events. No live prompt text is committed.

Unknowns: the latter session cannot be recovered from submitted events on this device; target-device acceptance and installed schedule require approved deployment after landing. No claim of fleet health or two-minute delivery is supported yet. Prior CLIO #13/#15 reconciled copies but explicitly excluded modern-format fix #14; merged prior art does not solve this issue.

Root cause: Codex changed its submitted-event schema; the tailer consumes unknown events while advancing its cursor. Fix site: existing upstream parser plus explicit replay eligibility. Upstream producer is external; reading response_item would mix injected context with submissions and violates the request.

## Solution-fit and blast radius

Outcome: real submitted Codex prompts reach existing CLIO history and missed eligible events can be recovered.
Smallest bet: extend the existing parser, state comments and explicit backfill; reuse the existing writer and deployment/publication. No new service, suite, CI gate, storage schema, renderer, installer mechanism or response_item fallback.
Alternatives: configuration alone cannot recognize the new schema; resetting state manually loses the capture cutoff; response_item fallback violates provenance; a parallel reader creates a second writer. Prefer a bounded parser extension over these alternatives.
Reversibility: Easy for code; history replay is additive and deduplicated, source files remain unchanged. Stop on unexpected source mutation, duplicate SQLite rows, or cursor advance on writer failure. Roll back the code commit; retain captured history, never rewind the canonical DB.
Affected users: Codex Desktop/CLI capture users; legacy capture, child exclusions and SQLite/JSONL consumers must retain their contracts.

## Ordered implementation and verification

1. Obtain Codex plan approval against this scope, upstream source, issue requirements and commensurate complexity -> production code unchanged until Approved. Reviewer writes relay only. Register explicit Forge accepted-start after approval.
2. Extend only existing event_msg parsing to accept item_completed whose item.type is UserMessage; join string text parts in order, ignore image/nontext parts and other event types -> sanitized 0.165 shape must fail on base and deliver nonzero on candidate; legacy and response_item exclusion remain covered by the existing suite.
3. Make CLIO_TAIL_BACKFILL=1 rescan already-known root files from byte zero with explicit history eligibility. Before any replay write, atomically checkpoint that file at offset zero/eligibility 0 through existing state_update, preserving the global capture cutoff. On parse/writer failure the rewind stays pending; an ordinary tick without the backfill flag retries from it. Verify two historical events at known EOF, fail the second writer call after accepting the first, then retry normally -> both stored exactly once, cutoff/source bytes unchanged. Repeat replay must retain stored row identities, and child copies stay excluded. Preserve default normal incremental behavior.
4. Add a bounded zero-delivery streak comment to the existing state, warning once at three consecutive complete root-source-active ticks with no writer acceptance; reset on idle, delivery or deferred writer, suppress during explicit backfill -> existing suite/manual controls distinguish warning threshold, reset and idle. Warning is diagnostic only: assistant output can cause activity and it does not prove missing prompts. Keep stdout compatible.
5. Extend the existing Codex fixture/suite and document replay/canary semantics in INSTALL -> no new suite or gate. Verify main SQLite capture path plus rerun/legacy/child/partial-line/retry paths in a disposable full clone with a throwaway HOME. Witness base failure and retain sanitized logs/provenance. Update Rebalance patch version/changelog per its contract.
6. Obtain final independent Codex review, run required path-appropriate checks in a disposable clone, push upstream PR to development and Forge tracking/evidence PR to development -> read back actual heads/bases and report checks honestly. Retire only fully published safe task clones through the existing cleanup driver; preserve blocked/dependent evidence.
7. After upstream PR merges, publish through standalone's existing publisher and review its PR; deploy through Skills Army HQ, then quiesce the existing Codex tailer schedule before manual replay: record its loaded state/plist, boot out only that job, verify no scheduled/manual tailer process remains, back up the existing state, run replay exclusively, and restore the identical previously loaded job in a cleanup/finally path whether replay succeeds or fails. Leave a previously unloaded job unloaded. Correct INSTALL's age-only lock claim; do not alter the lock mechanism. Timestamp a new substantive Desktop submission on the requested target and observe the matching agent=codex SQLite row within 120 seconds; record each requested session as recovered or unrecoverable based on submitted-event evidence -> blocked on merge/deployment authority; start-task alone does not authorize merge. Keep Forge #1255 open until actual acceptance is met.

## Acceptance and retained evidence

All checks use the existing suites or manual receipts under TESTS-RESULTS; no new test file or registry entry. Red control: new-format submitted event and seen-file replay assertions must fail against unchanged upstream. Canary red control: candidate threshold assertion must fail if warning logic is disabled. SQLite verification must assert nonempty rows and stable record IDs after replay, not rely on delivered count. Legacy, partial line, provenance and busy-writer tests remain truthful. No live databases/prompts or machine paths enter committed artifacts.

Plan QA round 1 requested durable replay intent and exclusive scheduling; both incorporated above. Independent final QA is Approved; deployment acceptance remains outstanding. Lessons: NO_ENTRY (no observed intervention outcome yet).

## Implementation state

Upstream implementation at rebalanceOS a18664a extends the existing parser, durable per-file replay checkpoint and state-comment warning. Existing fixture now includes one legacy and one modern submitted event. Existing Codex suite proves nonempty SQLite rows, pending replay after a failed second write, normal retry, stable replay IDs, live IDE request and diagnostic reset/threshold. No live acceptance or deployment claimed. Plan and final QA receipts are retained below; live deployment acceptance remains pending.

## Verification handoff

All six existing upstream CLIO suites now pass, including 17 store cases. Three negative controls fail as expected. The unchanged base has a stale September fixture failure in one store projection case; a one-line timestamp correction preserves the five-row assertion and makes the existing suite truthful. No production store change or new suite. Upstream receipts live in `TESTS-RESULTS/2026-10-29+GH-368/`; final Codex review covers the implementation, that fixture correction, and this Forge tracking/parity record. Final QA Approved with the validated superseding receipt below; no merge, standalone publication, installed repair or target-device acceptance claimed.

## Final QA

Independent Codex plan and final reviews are Approved (round 2 each), with committed relay receipts. All six upstream CLIO suites pass; 17 store cases pass; three negative controls fail as intended. Forge deterministic PDDA passes with existing warnings. Rebalance observe-mode PDDA retains existing unrelated findings; these are disclosed in its PR/evidence. No full Forge runtime suite was run for this docs-classified tracking change. Lessons: NO_ENTRY.

## Machine receipt closeout

The cross-repository final peer review was Approved, but its driver returned 4 because Rebalance ignores relay-system and Git add refused the ignored parent. Do not treat that attempt as a successful machine gate. Final review round 3 ran in Forge against the complete upstream source, prior dispositions and retained logs; relay-drive returned 0 and relay_attest.load validated its driver-written receipt. The superseding receipt is `relay-system/2026-10-29/gh1255-publication.codex.md`; sanitized machine fields are retained in TESTS-RESULTS. No harness or ignore-policy change was made.

## Manual live-device check

A foreground trial using the current real Codex submission passed without deployment: source event → reviewed tailer → shared writer → isolated SQLite → query/JSONL/Markdown. Base captured zero; candidate captured one; ordinary rerun and explicit backfill kept the current record ID/count stable. Installed helpers were unchanged. [Sanitized receipt](../../TESTS-RESULTS/2026-10-29+GH-1255/LIVE-DEVICE-TRIAL.md). Scheduled normal-store delivery and live acceptance remain outstanding.

## Pre-landing review disposition

Corrected the current QA/roadmap status and upstream PR pointer. Rebalance’s ignored transcript copies are removed; Forge retains the canonical reviews. Recovery instructions now follow scheduling and explicitly distinguish visited-file retry from a full scan: an interrupted whole-history scan requires repeating the explicit flag. No run-wide replay journal is added to the approved per-file repair. The actual deployment will run exclusively to completion and verify requested session identities. No runtime change.

## Merge evidence

- PR #1256 merged 2026-10-30 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).

## Device deployment and recovery

The user authorized merging, publication, this-device deployment and recovery. Rebalance #369, Forge #1256 and standalone #23 are merged. HQ and installed-runtime receipts are current; whole-folder and published byte/mode parity pass. Exclusive active and archived-source replay verified all seven recoverable source events. 01a18930 has zero submitted events and remains unrecoverable. The original schedule is restored, and normal-interval capture was observed. Strict 120-second acceptance remains pending a fresh timed submission. [Deployment receipt](../../TESTS-RESULTS/2026-10-29+GH-1255/DEVICE-DEPLOYMENT.md). Historical pre-deployment sections above describe their recorded state. Keep this issue open until the final timing check is measured.
