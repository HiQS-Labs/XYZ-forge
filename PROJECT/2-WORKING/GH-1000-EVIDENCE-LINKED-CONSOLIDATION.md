---
gh_issue: 1000
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1000
title: "Umbrella: Consolidate Storyline, Kanban, and dashboard efforts into an evidence-linked workflow"
status: Consolidation written — awaiting final QA and operator decisions D1–D3
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
| Codex plan QA Approved (`relay-system/2026-11-10/gh1000-plan.codex.md`); Phases 1–4 written; reconstruction receipt recorded in `TESTS-RESULTS/2026-11-10+GH-1000/` | Final Codex QA and PR. Then operator decisions D1–D3, after which follow-on issues A–E can be filed |

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

**How many efforts are there?** Not four or five products. There are three systems and a set of
adjacent producers:

1. **Forge work ledger and its board writers.** One state store (`roadmap_items`, `jog_queue`,
   `work_events` in the RELEASES DB), one shared reader, two board writers.
2. **Forge read-only views.** Flightdeck, with Paperclip as a skin over it, plus GH-39's release
   cards as a separate view of releases rather than tasks.
3. **Rebalance history layer.** Journey replay and close-loop flags, derived from CLIO prompt
   history and local GitHub tables. This is what "Storyline" has shipped so far.

CLIO is a producer for system 3. Whiteboard, code-intelligence and Sleuth / Product Compass are
adjacent and hold no task state.

"Shipped" below means a merged PR or a file in this repo. "Live consumer" means something calls
it without a person typing the command.

| # | Effort | Verified state | Live consumer | Task identity | Disposition | Rationale and dependency |
|---|---|---|---|---|---|---|
| 1 | Work events and shared reader (#549, #605) | Shipped. `work_events` and `connector_cursors` in `utils/py/releases_app.py:895-947`; reader `load_work_evidence` at `:5746`; `releases work emit / backfill / reconcile / status` | Yes: every ledger write records an event (`:1566`); `merge_cleanup.py:692` emits `pr_merged` | `gh_number` + repo; no attempt concept outside jog payloads | **Reuse** | Already the one reader behind every view. Follow-on A and B extend it. Depends on the ledger-relocation outcome (row 14). |
| 2 | Board writers (#402, #605) | Shipped: `github_board` connector (`utils/py/work_connectors/`) and the `board_sync` policy preview/apply (`utils/py/board_sync.py:1189`, `:1235`). Not shipped: #402's Phase 2 adapters and hourly sweeper | Connector fires on ledger writes only when enabled in device config; policy commands are hand-run | Connector: `gh_number`, first configured repo only. Policy: repo + kind + number | **Combine** | Two writers target one board with different column vocabularies, kept apart only by a refusal (`github_board.py:126-133`). Pick one writer per board. **Retire** #402's unbuilt Phase 2: #549's connectors replaced it. Blocked on operator decision D1 (board target). |
| 3 | Hourly board review (#897) | Proposed only. No doc, code or ledger row | None | n/a | **Defer** | Its Phase 0 (which board) is unresolved, and the issue forbids adding a scheduler by default. Revisit after D1. |
| 4 | End of Week skill (#606) | Shipped as `skills/3-weekly/end-of-week/SKILL.md`; no scripts | Hand-run | n/a | **Reuse**, one fix | Step 6 prescribes `work reconcile --connector github_board`, which is refused on a policy-covered board, and never mentions `policy-preview` / `policy-apply`. Fix with row 2. |
| 5 | Flightdeck (#494, #646, #673, #797) | Shipped: `src/flightdeck/` loopback server on port 8768, six readers, read-only. Not shipped: session-context connectors; `topology` and `continuity` have no producer | Hand-started. Its tests are outside the `validate.sh` registry, and the GH-981 doc records five failing on macOS | repo + issue number; no attempt concept | **Finish** as the first-slice interface | Already reads the shared reader, is local and read-only, and carries GitHub URLs in its snapshot. Needs follow-on B and C. |
| 6 | Release cards (#39) | Shipped: `releases project sync` (`releases_app.py:3191`), dry-run unless `--apply` | Hand-run | Release ID | **Reuse unchanged** | A view of releases, not tasks. It shares no state with the task board, so it does not compete. |
| 7 | Paperclip add-on (#981, PR #982 merged 2026-10-10) | Shipped: `addons/paperclip-dashboard/`, synthetic demo by default, `--live` reads Flightdeck | Hand-run; no tests of its own | Inherits Flightdeck's | **Keep, frozen** | Pure reuse with no reader of its own, so it costs nothing to keep and cannot drift from Flightdeck's data. It adds no evidence, attempt or blocker that Flightdeck lacks, so it is not the primary interface. Operator decision D2. |
| 8 | Journey replay (rebalanceOS PR #231, merged 2026-09-22) | Shipped: `rebalance clio-journey-replay`, opt-in, no model calls, writes files only | Not verified | owner/repo + issue or PR number, parsed from references | **Reuse** | It is the history layer. No Forge work. |
| 9 | Close-loop flags (rebalanceOS PR #308, 2026-10-03; PR #311, 2026-10-14) | Shipped: `rebalance github-close-loop`; `--releases-scan` reads each clone's `releases.db` read-only | The deployed Daily skill offers `--close-loop`; whether it is switched on is not verified | repo + number | **Reuse** | Already reads the Forge ledger read-only, which is the right direction of dependency. |
| 10 | Storyline integration (rebalanceOS #300) and the "knowledge-graph component" | #300 is open; the usefulness verdict and the goal-anchored narrative experiment are outstanding. No PR or commit for a knowledge graph was found in the org | n/a | n/a | **Defer**; component **unknown** | Cannot disposition what cannot be identified. Operator decision D3. Rows 8 and 9 do not establish #300 as complete. |
| 11 | CLIO (XYZ-CLIO; developed in rebalanceOS `utils/clio-capture`) | Shipped as a capture producer. SQLite pilot (XYZ-CLIO #3) is open | Capture on this device not verified | `session_id`, `record_id`; stores no issue or PR link | **Reuse** as a producer; **defer** linking | A session ID is not an execution ID, and nothing joins them today. Do not add that join before follow-on A proves the execution ID is reachable from the ledger. |
| 12 | Whiteboard #3, code-intelligence #20 | Proposals only, no PRs | None | n/a | **Defer** | Map and search surfaces, not a task backend. |
| 13 | Sleuth / Product Compass (Sleuth PR #216, merged 2026-10-08) | Shipped in Sleuth. Live Compass re-test (Sleuth #234) is open | Not verified | n/a | **Defer** | Adjacent release-answer surface with a different owner; no integration assumed. |
| 14 | Work-ledger relocation (#1175, #1200, #1224) | Open | n/a | n/a | **Sequence against** | A competing home for work state. Follow-on A writes into `work_events`; land it before any relocation or carry the fields across. |
| 15 | Merge-batch issues (#786), shared in-progress label (#646, closed), work-classification umbrella (#709) | #646 shipped; #786 and #709 open | #646: the labels connector | `gh_number` | **Reuse** (#646); **no action** (#786, #709) | Already consumers or parents of row 1. Listed so the inventory is complete. |
| 16 | Rebalance follow-ups (#232, #310, #202) and Needle-fork PR #79 | Open; PR #79 unmerged | n/a | #202 proposes producer-owned session identity | **Defer** | #202 is the right owner for session identity. PR #79 is a prototype joining CLIO and transcripts by session ID; assess it only after follow-on A. |

**Doc drift to correct once dispositions are accepted** (not done in this PR; the issue forbids
bulk changes on older efforts without agreement): GH-402's doc sits in `2-WORKING` with a parked
ledger row and a Status table that predates #549; the docs for #549, #494, #39, #606 and #981 are
in `3-COMPLETED` with Status tables that still describe unfinished publication.

**Operator decisions this inventory cannot make.**

- **D1 — Board target.** #897 says device config pointed at project 4 while the operator watches
  project 3. Neither was read here (`gh` lacks `read:project`; no device config on this machine).
- **D2 — Paperclip.** Recommended: keep, frozen. The merge of PR #982 records an intent to retain
  it but is not a keep/revise/abandon decision.
- **D3 — The knowledge-graph component.** Name the repo and PR, or confirm it is rows 8–9.

## Phase 2 — Worked reconstruction

Task: [GH-1254](https://github.com/HiQS-Labs/XYZ-forge/issues/1254). Receipt:
`TESTS-RESULTS/2026-11-10+GH-1000/` (commands in `walk.py.txt`, output in `walk-gh1254.txt`,
control in `walk-gh1064-control.txt`). The walk started from the issue number alone and read only
committed files and `git log`.

Evidence kinds are labelled: **[M]** machine record, **[H]** human decision, **[S]** summary
written for this doc.

**Goal.** [M] Roadmap row `rmi-01M6WTMK376C3R6EGNG4BG4HTH`: borrow declared supervision and
cache-warmth dispatch into the #1248 outer loop.

**Attempts.** [M] One jog row, `jog-01M6Y67FAWQFFXC8VQZ1J7HRNH`, six execution IDs.

| Execution ID | Outcome | Result receipt | Invocation | Transcript | Gate receipt | Attestation |
|---|---|---|---|---|---|---|
| `gh1254-exec1` | escalated, pre-advance-failed | Resolved | Resolved (implicit) | Resolved (implicit) | Missing | Missing |
| `gh1254-exec1-gateretry1` | escalated | **Missing** | Unknown | Unknown | Unknown | Unknown |
| `gh1254-exec1-gateretry2` | escalated | **Missing** | Unknown | Unknown | Unknown | Unknown |
| `gh1254-exec2` | escalated, pre-advance-failed | Resolved | Resolved (implicit) | Resolved (implicit) | Missing | Missing |
| `gh1254-exec2-gateretry1` | escalated, gate-killed | Resolved | Missing | Resolved (implicit) | **Conflict** | Missing |
| `gh1254-exec2-gateretry2` | approved | Resolved | Missing | Resolved (implicit) | Resolved | **Missing** |

No attempt has a fully resolved chain, including the approved one.

**What each gap means.**

- **Attempts are not listed by the ledger.** [M] All ten `work_events` for the issue carry zero
  execution IDs. The six IDs came from two jog-ledger snapshots that the GH-1358 rehearsal copied
  into `TESTS-RESULTS/` by hand. Without those copies the walk finds one attempt, the approved
  one, and the five failures vanish.
- **Two failed attempts have no committed record at all.** [M] The `exec1` gate retries exist only
  as names in a snapshot whose `result_path` points into `.tick/` on the machine that ran them.
- **Every transcript join is implicit.** [M] Four transcripts joined because the result's
  `head_sha` equals the commit that saved the transcript. That held here; it is not a contract
  (Phase 0). Two more transcripts for the same issue share one token and join to no attempt. They
  are probably the `exec1` gate retries, and that is a guess, so they stay unjoined.
- **Invocations carry no execution ID.** [M] Six committed invocation records name the issue and
  none has an `execution_id` field. The join is the execution ID appearing as a path segment of
  `result_path`. Both gate retries of `exec2` have no invocation that names them.
- **The approved attempt's attestation record is not in the repo.** [M] `attest_path` is an
  absolute path in a temp directory. The transcript trailer and the result agree on
  `reviewed_head` `bd4b0462c`, which binds the review text to a revision, but the trailer is not
  the attestation record.
- **One gate receipt contradicts its result.** [M] `gh1254-exec2-gateretry1` reports the gate red
  (gate-killed), while a committed full-gate receipt for the same SHA `8d541d012` has exit 0. The
  later receipt is from a separate hand-run after the kill. Both are true of different runs; the
  records do not say so, and a view that read only the receipt would show green.
- **Tokens do not identify attempts.** [M] `exec2` used `…-TURN-2`, its first gate retry reports
  `…-TURN`, and its second `…-TURN-2` again.

**Current state.** [M] PR #1379 merged at `9d2ecf868` on 2026-11-08; `jog_queue` status
`completed`; latest work event `jog_completed`. [M] The issue is open and the roadmap row is still
"In progress". [H] The 21:33 UTC comment says "delivered, left open because Acceptance checklist
is absent, empty or incomplete and no independent whole-issue coverage assertion is recorded."
`releases work status` returns only the latest event, so it shows `jog_completed` and none of the
five failed attempts.

**Blocker.** [M] The working doc's Status table lists restart verification, overloaded deadlines
and observed live savings as unmet. [S] So the blocker is unmet acceptance, not a failing run.

**Last verified outcome.** [M] `gh1254-exec2-gateretry2`: approved, gate green on
`fc7896aae` with a committed receipt bound to that SHA, reviewed head `bd4b0462c`, landed as PR
#1379.

**Safe next step.** [S] Write the acceptance checklist on the issue and verify the three unmet
items. No action on the failed attempts is needed. Allowed without approval: reading. Needs
approval: closing the issue, since neither condition for closing at merge holds.

**The five first-slice questions, answered from committed records alone.**

| Question | Answerable today? |
|---|---|
| 1. Goal and current verified state | Yes, from the ledger and the approved bundle |
| 2. What ran, failed or resumed | Only because failed records were hand-copied; not from the ledger |
| 3. Which evidence supports the outcome | Partly: result, gate receipt and transcript yes; attestation record no |
| 4. Who or what blocks the next step | Only from prose in the working doc and an issue comment |
| 5. What is allowed next and what needs approval | No record holds this; inferred from policy text |

**Caveat.** GH-1254 is unusually well preserved. A normal failed jog leaves nothing committed but
`jog_failed` events.

**The check on the check.** The first run of the walk marked the approved attempt's attestation
`RESOLVED`, because the temp directory still exists on this host. That output is kept as
`walk-gh1254-first-run-red.txt`. The walk now treats any absolute path outside the repo as
machine-local. The GH-1064 control reports zero attempts and `UNKNOWN`.

## Phase 3 — Interface selection

Each interface was checked against the five questions using the GH-1254 records.

| Question | Flightdeck | Paperclip | GitHub board |
|---|---|---|---|
| 1. Goal and verified state | Partly. `issueStatus` (`web/flightdeck/issue-context.mjs:14`) compares the ledger label with cached GitHub state and can show `conflict` or `unknown`. No goal text | Same data as Flightdeck | Column only. Two column vocabularies (`board_sync.py:82`, `github_board.py:64`) |
| 2. What ran, failed, resumed | No. The reader returns the latest event; no attempt concept | No | No |
| 3. Supporting evidence | No. The snapshot carries GitHub URLs, but `web/flightdeck/app.js` renders no links and nothing points at a transcript or receipt | No | PR link only, through GitHub itself |
| 4. Blocker and owner | No blocker field; PR readiness is always `needs-qa` (`src/flightdeck/aggregate.py:40`). Owner is the CLIO agent name | Same | No blocker; the policy planner's `unresolved[]` is the nearest thing |
| 5. Allowed next action | No | No | No |
| Freshness | Yes: 300 s evidence age, 7200 s cached-GitHub age, ledger `recent_start` recent/stale | Same | `activity_lookback_days` only |
| Writes state | No | No | Yes, on a GitHub Project |

**Recommendation: Flightdeck is the primary operator interface for the first slice.**

- It already reads the shared reader, so nothing new has to be joined in the view.
- It is local and read-only. Transcript and receipt paths stay on the operator's machine, which
  the issue's privacy anti-goal requires. A GitHub Project board cannot hold links to private
  transcripts safely.
- It already models `unknown` and `conflict`, so missing or contradictory evidence has a place to
  appear instead of collapsing to green.

**Other interfaces stay as projections.**

- **GitHub board:** shared, coarse status for people who are not at the operator's machine. One
  writer per board after D1.
- **Release cards (#39):** releases, not tasks.
- **Paperclip:** keep, frozen, as an optional skin (D2). It inherits whatever Flightdeck gains.
- **Rebalance journey replay and close-loop:** history and narrative across repos. It reads the
  Forge ledger; Forge does not read it.

**No new status vocabulary.** The first slice shows the ledger's own event names and the result
receipt's own `outcome` and `reason`. It does not add a merged status word.

## Phase 4 — Implementation sequence

These are drafts. They are not filed, and no older issue has been commented on or relabelled. The
issue asks for dispositions to be agreed first.

**Order.** A, then B, then C. D is independent and waits on D1. E is housekeeping after the
dispositions are accepted.

### A. Record the attempt in the committed ledger

- **Change:** add `execution_id` and a repo-relative result path to the payload of `jog_*` work
  events, through the existing writer (`utils/py/releases_app.py:1508-1511`). Commit a failed
  attempt's result receipt to the same `TESTS-RESULTS/<date>+GH-<n>/jog/<execution_id>/` path
  that `publish_jog_receipt` already uses for an approved one, with the outcome kept as recorded.
- **Owner:** Codex builder; Claude review. **Depends on:** nothing. Sequence before row 14.
- **Reversibility:** Easy for the payload fields (additive JSON). Publishing failed receipts
  changes what `publish_jog_receipt` refuses (`jog_run.py:1083`), so the PR must show that a
  failed receipt cannot be read as a landing receipt.
- **Acceptance:**
  1. For a jog that fails once and then succeeds, the committed `releases.sql` lists both
     execution IDs under the issue number, with no machine-local file needed.
  2. Re-running the projection or a jog resume does not add a second event for the same
     execution ID.
  3. A failed attempt's committed receipt never satisfies merge admission or `jog land`.
  4. Existing suites `test/gh549-work-events.sh` and `test/gh605-work-state.sh` stay green; no
     new suite.

### B. Close the two unkeyed links in the result receipt

- **Change:** add an optional repo-relative `transcript_path` to `marathon-drive/result@1`
  (`save_transcript` already knows the destination, `utils/py/marathon_drive.py:2333`), and copy
  the attestation record into the committed bundle beside `gate-receipt.json`. Additive optional
  fields within `@1` follow `MACHINE-CONTRACTS.md` precedent (GH-505 / GH-509).
- **Owner:** Codex builder; Claude review. **Depends on:** nothing; lands independently of A.
- **Reversibility:** Easy, but it is a shared-contract edit: readers must tolerate the field
  being null, and the contract doc changes in the same PR.
- **Acceptance:**
  1. A new result names its transcript, and the walk in this doc's receipt resolves the
     transcript cell without the `head_sha` match.
  2. An approved bundle contains its attestation record, and its content matches the
     `reviewed_head` and `added_sha256` in the result.
  3. A result written before the change still loads.
  4. A transcript trailer alone still does not satisfy the attestation check.

### C. Show attempts and evidence in Flightdeck

- **Change:** extend `load_work_evidence` / `releases work status` to return the attempt list
  for an issue (execution ID, outcome, reason, repo-relative receipt and transcript paths), and
  render it in Flightdeck's issue view with links. No new reader and no new status words.
- **Owner:** Codex builder; Claude review. **Depends on:** A and B.
- **Acceptance (this is checklist section 4 of the umbrella):**
  1. Demonstrated on one task from creation through execution, review and completion, and on
     one failure-and-resume case, both from retained evidence.
  2. From one issue row the operator can answer the five first-slice questions, or sees
     `unknown` where no record exists.
  3. Loading the snapshot twice shows each attempt once.
  4. A contradiction like `gh1254-exec2-gateretry1` (result red, later receipt green) is shown
     as a conflict, and a stale or conflicting state is never shown as done.
  5. A telemetry or reader failure shows as `unknown`; it never produces or replaces an
     approval.
  6. Transcript content is not rendered, only its path.

### D. One board writer

- **Change:** after D1, make the chosen board have one writer and one column vocabulary, and fix
  the End of Week skill's step 6 to use it.
- **Owner:** operator decision first, then Codex builder. **Depends on:** D1.
- **Acceptance:** the End of Week path runs on a policy-covered board without a refusal, and a
  repeated reconcile makes no card move.

### E. Reconcile older docs and issues

- **Change:** apply the accepted dispositions: correct the stale Status tables named in Phase 1,
  move GH-402's doc to match its ledger row, and comment each disposition on its issue.
- **Owner:** Claude. **Depends on:** the operator accepting Phase 1.
- **Acceptance:** `utils/pdda/pdda.sh issue-doc-sync` reports no drift for those docs; no issue
  is closed on title similarity.

**Not proposed.** A join between CLIO sessions and executions; any work in rebalanceOS; a
scheduler for board review; a `showme` command.

## Acceptance map

| Issue checklist | Delivered by | State |
|---|---|---|
| 1. Establish what already exists (4 items) | Phase 1 | Done, except the knowledge-graph component, which is unidentified (D3) |
| 2. Smallest useful connection: select task, map IDs, reconstruct, keep evidence kinds apart | Phase 2 and its receipt | Done |
| 2. "Add only missing references" | Phase 4 drafts A and B | Deferred to follow-on |
| 3. Review Paperclip with Flightdeck and board; choose one primary interface | Phase 3 | Recommendation written; the keep/revise/abandon call is the operator's (D2) |
| 3. Show evidence-backed status, blockers, owner, freshness and links | Phase 4 draft C | Deferred to follow-on |
| 4. Demonstrate in the interface; repeated ingestion; stale state cannot become done | Phase 4 draft C acceptance criteria | Deferred to follow-on; still owed |
| 4. Define implementation sequence with owners and acceptance criteria | Phase 4 | Done as drafts |
| 4. Link implementation issues; update older efforts | After the operator accepts the dispositions | Open |

The umbrella stays open after this PR.
