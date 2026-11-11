---
gh_issue: 1000
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1000
title: "Umbrella: Consolidate Storyline, Kanban, and dashboard efforts into an evidence-linked workflow"
status: Plan drafted — awaiting plan QA
created: 2026-11-10
updated: 2026-11-10
owner: Claude
doc_type: feedback
branch: docs/XYZ-forge-gh1000-evidence-linked-consolidation-2026-11-10
effort: 3
complexity: 3
risk: 1
phases: 4
non_goals:
  - no code, schema, contract or gate change in this PR
  - no new board, dashboard, knowledge graph, event bus or task-state store
  - no migration, deletion, deployment, bulk closing or relabelling of older efforts
  - no new tests (GH-831)
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/996
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1414
goal: >
  Decide what to reuse, finish, combine, defer or retire among the Storyline, Kanban and dashboard
  efforts, prove on one real resumed task which evidence links exist today, and define the small
  implementation sequence that lets an operator reconstruct a task from one entry point.
---

# GH-1000 · Evidence-linked consolidation of Storyline, Kanban and dashboard efforts

## Status

| What was just completed | What's next |
|---|---|
| Intake registered, recon written back (Phase 0), plan drafted at base `68367d668` | Codex plan QA, then write Phases 1–4 and the manual reconstruction receipt |

## Table of contents

- [Scope of this PR and the bet](#scope-of-this-pr-and-the-bet)
- [Rating](#rating)
- [Phase 0 — Recon findings](#phase-0--recon-findings)
- [Plan](#plan)
- [Phase 1 — Inventory and dispositions](#phase-1--inventory-and-dispositions)
- [Phase 2 — Worked reconstruction](#phase-2--worked-reconstruction)
- [Phase 3 — Interface selection](#phase-3--interface-selection)
- [Phase 4 — Implementation sequence](#phase-4--implementation-sequence)
- [Acceptance map](#acceptance-map)

## Scope of this PR and the bet

The issue limits "scope now" to consolidation, evidence review and selection of a small
end-to-end plan. Its checklist section 4 also asks for a demonstration in the selected interface.
[#1414](https://github.com/HiQS-Labs/XYZ-forge/issues/1414) already flags that boundary as
unresolved. This plan proposes the narrow reading; the operator has not ruled on it, and the
interface demonstration stays explicitly owed:

- **Outcome sought:** the operator can stop treating these as five projects, knows which three
  references are missing, and has follow-on work small enough to schedule.
- **Smallest viable bet:** one documentation PR holding the inventory with dispositions, a
  reconstruction of one real resumed task from committed records, a recommended interface, and
  drafted follow-on issues. **Not built here:** any code, the three missing references, evidence
  links in an interface, or the section 4 interface demonstration. Those are the follow-on issues.
- **Alternative rejected:** implement the references and a Flightdeck evidence panel in this PR.
  Rejected because the issue withholds authorization for it, two operator decisions (board target,
  Paperclip) come first, and a `marathon-drive/result@1` field is a shared-contract change that
  deserves its own reviewed PR.
- **Alternative rejected:** a new `showme`-style report script. Rejected because
  `load_work_evidence` and `releases work status` already are the shared reader; a second reader is
  the duplication this umbrella exists to remove.
- **Rollback / containment:** Easy. Revert the PR; the only non-doc change is one roadmap row
  written through the CLI. Dispositions are recommendations until the operator accepts them, so
  nothing downstream acts on them.

Assumption that could be wrong: that the committed records for GH-1254 are representative. They
are unusually complete because the GH-1358 rehearsal copied failed receipts by hand; Phase 2 says
so and Phase 4 treats that as a gap.

## Rating

`rated 45/35/50/55` (pri/sev/appeal/effort), row `rmi-01M74K4FNE7GBY2S1W3F24NF5K`, written with
`roadmap pickup` and read back on 2026-11-10.

- **Severity 35:** no crash, data loss or blocked work. The cost is duplicated effort, stale plan
  docs and a failed attempt that cannot be traced off the machine that ran it.
- **Priority 45:** radar [#1352](https://github.com/HiQS-Labs/XYZ-forge/issues/1352) lists this as
  holding and quiet; no deadline or operator ordering was given.
- **Appeal 50:** neutral; the operator supplied no value.
- **Effort 55:** this slice is documentation plus read-only evidence gathering across four repos.
- **Recurrence:** not a defect class, so no incident window applies. Trend unknown.

## Phase 0 — Recon findings

Traced at `68367d668`. Sibling-repo state was read with `gh` on 2026-11-10.

**The issue body is stale in four places.**

1. PR #982 (Paperclip) merged on 2026-10-10 and #981 is closed; the issue calls it an open draft.
2. No PR or commit named for a "knowledge graph" exists in rebalanceOS or the org. The nearest
   early-October merges are rebalanceOS #308 (2026-10-03) and #311 (2026-10-14). The component
   the operator meant is unidentified.
3. The board target is unresolved: #897's body says device config pointed at project 4 while the
   operator watches project 3. This device has no `~/.xyz/device_config.json`, and `gh` here lacks
   `read:project`, so neither board was read.
4. Missing from the inventory: #709, #786, #646, the work-ledger relocation issues #1175 / #1200 /
   #1224, rebalanceOS #232 / #310 / #202, and Needle-fork PR #79.

**There is already one shared reader.** `load_work_evidence` (`utils/py/releases_app.py:5746`)
reads `roadmap_items`, `jog_queue` and `work_events`. The board policy
(`utils/py/board_sync.py:1192`), the labels connector, Flightdeck (through
`utils/py/releases_cycle.py:40`) and Paperclip (through Flightdeck) all read it. Two things sit
outside it: the raw `github_board` connector, which replays `events_after`, and GH-39's release
cards, which read the `releases` table.

**No view shows evidence.** Neither Flightdeck nor Paperclip renders a link to a transcript, gate
receipt or PR, and no view models a blocker, an owner or an attempt.

**Attempts are visible only on the machine that ran them.** The attempt identity is the execution
ID (`gh<n>-exec<k>`, `-gateretry<k>`; `utils/py/jog_run.py:574`, `:963`). It is recorded in
`.tick/jog/<gid>/state.json`, which is gitignored. Committed `work_events` carry `jog_global_id`
but no execution ID, and `releases work status` returns only the latest event per issue.

**Three references are missing.**

1. `jog_*` work events have no `execution_id` or result path in their payload.
2. `marathon-drive/result@1` has no transcript path. A candidate join exists for some attempts:
   the result's `head_sha` matching the commit that saved the transcript. It is not a contract.
   `head_sha` is the observational receipt-time HEAD of the target repo
   (`utils/py/marathon_drive.py:216`, `MACHINE-CONTRACTS.md:105`), the transcript is committed
   in the harness root (`:2322`), and a post-approval command can move HEAD before the receipt
   (`:2859`). Phase 2 tests the join per attempt and does not assume it.
3. Only an approved result is copied into `TESTS-RESULTS/` (`jog_run.py:1077`). A failed
   attempt's receipt stays machine-local, and `gate.receipt_path` and `attest_path` are absolute
   paths that are dead off-machine.

**Doc drift.** GH-402 sits in `2-WORKING` with a parked ledger row and a Status table that
predates GH-549. GH-549, GH-494, GH-39, GH-606 and GH-981 are in `3-COMPLETED` with Status tables
that still describe unfinished publication steps.

**Not traced:** `releases dashboard` and `utils/timeline`; whether connectors or a board policy
are enabled on any device; whether rebalance `--close-loop` is switched on anywhere; live Slack
activation of Product Compass (Sleuth #234 is still open).

## Plan

Extends the existing subsystem: this plan doc under PDDA, the roadmap row through
`releases_app.py`, and a manual check under `TESTS-RESULTS/`. No writer is added.

1. Write Phase 1: one row per effort with verified state, live consumer, identity key and a
   disposition with rationale and dependency. -> expect every effort in the issue table plus the
   eight missed ones to have exactly one disposition, and every "shipped" claim to cite a merged
   PR or a file path.
2. Run the reconstruction walk for GH-1254 with read-only commands only (`grep` on `releases.sql`,
   `git log`, `python3` JSON reads, `gh issue view` / `gh pr view`), starting from the issue
   number alone. Record commands, output and verdict in
   `TESTS-RESULTS/2026-11-10+GH-1000/` with `provenance.jsonl`. For every discovered attempt,
   gate retries included, fill one row with seven cells: execution ID, invocation (path, and
   whether any independent invocation ID exists), token, transcript, gate receipt, result
   receipt, attestation. Each cell is `RESOLVED` with the join used, or `MISSING` / `UNKNOWN`
   with the reason. Rules: a transcript approval trailer is not the machine attestation record
   and never fills the attestation cell; a gate or review cell counts only when its SHA binds it
   to that attempt's candidate, not on a green label; the transcript is joined by commit SHA
   where that holds, otherwise by the token in its header and commit message, and an ambiguous
   match (two transcripts, one token) is `UNKNOWN`. -> expect a complete table in which the
   machine-local records (attestation JSON, failed-attempt results that were not hand-copied,
   raw tick events) read `MISSING`, and no attempt is called complete on a trailer alone.
3. Red control for step 2: run the same walk for GH-1064, which has start-task relays but no
   execution records. -> expect the walk to report zero attempts and `UNKNOWN`, not a completed
   reconstruction. A walk that reports success on an empty attempt list fails this check. Second
   control, on GH-1254 itself: the published `gh1254-exec2-gateretry2` bundle has no attestation
   file and its `attest_path` is machine-local, so that cell must read `MISSING`.
4. Write Phase 2 from the receipt: goal, attempts, current state, blocker, last verified outcome,
   safe next step, with machine evidence, human decisions and model summaries labelled
   separately, and every link that needed an implicit join named.
5. Write Phase 3: compare Flightdeck, Paperclip and the board against the five first-slice
   questions using the GH-1254 records, then recommend one primary interface and a Paperclip
   call. -> expect each question marked answerable / not answerable today per interface, with the
   code reference.
6. Write Phase 4: follow-on issues as drafts in this doc, each with owner, dependency and
   acceptance criteria, and the operator decisions that gate them. Do not file them or comment on
   older issues; the issue requires dispositions to be agreed first.
7. Run `utils/pdda/pdda.sh run` and `python3 utils/py/releases_app.py check`. -> expect zero
   errors. `utils/ci-route.sh` decides the push gate; `releases.sql` plus Markdown is expected to
   route Small.
8. Final Codex QA on the diff, then PR against `development`.

**Proposed dispositions the reviewer should check before they are written up.**

| Effort | Proposed disposition |
|---|---|
| `work_events` + `load_work_evidence` (GH-549, GH-605) | Reuse as the one work-state reader |
| `board_sync` policy and `github_board` connector (GH-402, GH-605) | Combine: one board writer per board; retire GH-402's unbuilt Phase 2 adapters and sweeper |
| Hourly board review (#897) | Defer until the board target is decided; no scheduler |
| End of Week skill (GH-606) | Reuse; fix its path being refused on a policy-covered board |
| Flightdeck (GH-494, #646, #673, #797) | Finish as the primary interface for the first slice |
| Release cards (GH-39) | Reuse unchanged as a release view, not a task view |
| Paperclip add-on (GH-981) | Keep as an optional skin, frozen; not the primary interface |
| Rebalance journey replay and close-loop (#231, #308, #311) | Reuse as the history layer; no Forge work |
| Storyline integration (rebalanceOS #300) and the unidentified knowledge-graph component | Defer; operator to identify the component |
| CLIO | Reuse as a history producer; defer session-to-execution linking |
| Whiteboard, code-intelligence, Sleuth / Product Compass | Defer; adjacent, not a task backend |
| Work-ledger relocation (#1175, #1200, #1224) | Dependency to sequence against, not part of this umbrella |

**Test scope.** No suite, registry entry or gate machinery is added. Verification is the manual
check in steps 2–3 and the existing PDDA and RELEASES checks in step 7.

## Phase 1 — Inventory and dispositions

Pending plan QA.

## Phase 2 — Worked reconstruction

Pending plan QA.

## Phase 3 — Interface selection

Pending plan QA.

## Phase 4 — Implementation sequence

Pending plan QA.

## Acceptance map

| Issue checklist | Delivered by | State |
|---|---|---|
| 1. Establish what already exists (4 items) | Phase 1 | Planned |
| 2. Smallest useful connection: select task, map IDs, reconstruct, keep evidence kinds apart | Phase 2 and its receipt | Planned |
| 2. "Add only missing references" | Phase 4 follow-on issue | Deferred to follow-on |
| 3. Review Paperclip with Flightdeck and board; choose one primary interface | Phase 3 | Planned as a recommendation; the keep/revise/abandon call is the operator's |
| 3. Show evidence-backed status, blockers, owner, freshness and links | Phase 4 follow-on issue | Deferred to follow-on |
| 4. Demonstrate in the interface; repeated ingestion; stale state cannot become done | Phase 4 follow-on acceptance criteria | Deferred to follow-on |
| 4. Define implementation sequence with owners and acceptance criteria | Phase 4 | Planned |
| 4. Link implementation issues; update older efforts | After the operator accepts the dispositions | Open |

The umbrella stays open after this PR.
