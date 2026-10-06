# RELAY · GH-981 optional Paperclip dashboard plan QA
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-10-06.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 3

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **VERDICT**
     (exactly PASS, FAIL, or PARKED) and a **Basis** (explanation). **Review the whole file, not just the diff** (GH-268):
     a beta test had this loop reach `Approved` in two rounds while an independent audit of the same
     branch found 20 issues (1 critical, 4 high) — every one of them in the pre-existing code the
     change sat on, which nobody had read. Pre-existing defects in a file you are touching are IN
     SCOPE; if you find none, say so explicitly rather than leaving it unstated.
     **Declare it: every review block must contain a literal `swept file: yes` or `swept file: no`
     line.** Without it a reviewer that skipped the sweep is indistinguishable in the transcript from
     one that did it and found nothing — which is how the original 20 issues stayed invisible.
     Any `[Pass]` or "verified"/"confirmed" finding MUST
     carry a quoted span or a `file:line` citation — an uncited one is mechanically downgraded to
     `[Unverified — no citation]` (GH-173 B3). Do **not** edit the artifact; only append findings here.
     **A finding that asks for a behaviour change is a generalization unless you can paste the concrete
     input — a row, a value, a `file:line` — that fails under the current code** (GH-681: the gh673
     final QA relay generalized one late-error observation into "or a later invalid identity", the
     Producer implemented it, the same seat `[Pass]`ed it next round, and one historical NULL-URL
     ledger row then blanked every issue). Every `[Blocker]` or `[Should]` requesting a behaviour
     change MUST carry three lines: `Observed input:` (the failing input you saw), `Affected scope:`
     (the input predicate the change would govern), `Falsifier:` (the fixture or data that would show
     the change unnecessary or wrong, and its expected result).
     A `[Blocker]` must cite an observed failure. This is a protocol rule, not a mechanical check —
     the Producer may disposition a request lacking these as `Declined — unproven generalization`.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why,
     including `Declined — unproven generalization` for a behaviour-change request that carries no
     `Observed input:` / `Affected scope:` / `Falsifier:`), make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
   Reviewer headings may be `### Reviewer · Round N`, `### Round N · Reviewer · <agent>`, `### Reviewer (<agent>)` (optionally followed by `— rN`), or `### Reviewer — Round N` (optionally followed by `(<agent>)`); follow the heading with a non-empty review body.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(gh-981-optional-paperclip-dashboard-plan-qa): <role> r<N>`); no push. **Stop** and report one line.
7. **Hand off explicitly — EVERY turn, not just the first** (GH-268). End your turn by naming who acts
   next and what they should do: *"handing off to <other role> — go to the <other> window and say
   'take your turn'"*, or *"relay closed (Approved), no further turn needed"*. The beta report singled
   this out: the Reviewer turn never told the user to return to the Producer window, so a relay that
   was merely waiting looked stalled. A turn that ends without this line is not finished.

## Setup
- Artifact under review: **GH-981-PAPERCLIP-DASHBOARD.md** (embedded below — read it here).
- Reviewer: codex   ·   Producer: codex-author
- Started: 2026-10-06

### Artifact — GH-981-PAPERCLIP-DASHBOARD.md
```
---
gh_issue: 981
source: https://github.com/HiQS-Labs/XYZ-forge/issues/981
title: Optional Paperclip dashboard — technical spike
status: In progress — plan QA pending
created: 2026-10-06
updated: 2026-10-06
owner: Codex
goal: Let the operator evaluate a Paperclip-inspired dashboard without making it a core path or merging before review.
doc_type: experiment
effort: 2
complexity: 2
risk: 1
phases: 2
reversibility: Easy — stop or remove the optional add-on; existing producers and UI are unchanged.
branch: feat/gh981-paperclip-dashboard
---

# GH-981 — Optional Paperclip dashboard

## Status

| What was just completed | What's next |
|---|---|
| Fresh full clone, issue registration, PRS rating and bounded Recon Map. | Independent Codex plan QA, then implement the approved add-on. |

## Quad Concepts
- Evaluate a denser operator UI → isolated, optional Paperclip-inspired presentation.
- Preserve one data authority → reuse Flightdeck aggregator and status selectors.
- See the design before landing → synthetic preview, opt-in local reads and visual evidence.
- Preserve provenance → pin borrowing and MIT attribution inside the add-on folder.

## Table of contents
- [Phase 1: build the optional preview](#phase-1-build-the-optional-preview)
- [Phase 2: verify and prepare operator review](#phase-2-verify-and-prepare-operator-review)

## Recon and solution-fit bet

Ground truth: [Recon Map](recon-gh981-paperclip-dashboard.md), integration base
`85556455a3e734708235ef23869818a0dc743ba5`. Paperclip source reference
`90182b4f8b40d6ee217937ba61199b4abc31dee7` in `noelsaw1/paperclip-fork`.

Outcome sought: a runnable visual comparison that helps the operator choose
keep/revise/abandon before merging. This spike is not a claim of improved
execution or complete production readiness.

Smallest viable bet: `addons/paperclip-dashboard/` contains static native-module
UI, a non-executable Python preview module invoked explicitly with Python,
synthetic demo, usage README, attribution record and upstream MIT notice.
Adapt sidebar/collapsed rail, metric cards, work/activity rows and a contextual
right detail panel. Use system fonts and inline locally defined SVG shapes;
no upstream brand assets or font downloads. Simple repository filtering, work/
lanes/PR sections, keyboard Escape, dark/light mode and mobile layout make the
comparison usable. All runtime UI writes are local preference storage only.

Alternative considered: restyle existing Flightdeck directly. Rejected because
it would replace the comparison baseline before the operator chooses. A full
React/Tailwind import is unnecessary for testing the requested appearance and
would add dependency/build costs. An alternate optional renderer is justified
by this explicit experiment; it adds no duplicate data projection or writer.

The preview module subclasses `FlightdeckHandler`, uses its snapshot GET and
security response helpers, and serves only a finite add-on asset map plus the
two existing shared selector modules. Default launch uses synthetic demo only:
no source configuration/reader is consulted, and snapshot requests return a
clear disabled response. `--live` explicitly attaches `FlightdeckAggregator`
using `ConnectorConfig.from_environment`. Bind only `127.0.0.1`, default 8769.
No package registry, default startup, core server, connector, schema, tick,
relay implementation or existing Flightdeck file changes.

Demo records are clearly labelled synthetic and use the schema-1 shape. Live
mode consumes only current bounded snapshots, displays coverage/source status,
and calls shared `issueCards`/`issueStatus`/`snapshotFresh`/`progressTone`.
Lane observations must not be called running agents. PR rows stay verification-
needed; progress remains unmeasured. Show observed counts with partial context,
not global totals or invented costs. Poll at the current 150-second cadence,
with request timeout and a three-failure pause; manual refresh remains available.
Recompute expiry independently of polling. Never cache live records to disk or
commit private live prompt/task content or screenshots containing that content.

Blast: only add-on files and issue/doc/ledger/evidence/relay receipts. A failed
add-on affects its browser/loopback port only. Shield: explicit optional launch,
demo default, passive shared reads. Undo class Easy; stop preview and revert the
folder plus its intake in a future reviewed PR. Tripwire: unexpected source writes,
network exposure or fabricated readiness stops the preview and blocks approval.
Use debug-mantra if a verification failure needs debugging; cap relay reviews at
three rounds each, with no speculative machinery demanded for this local spike.

## PRS rating rationale — 2026-10-06

Persisted `rated 55/20/50/65`, sum 190, no operator override. Priority 55 reflects
explicit user sequencing for evaluation. Severity 20: usability opportunity,
no observed crash or data-loss incident. Appeal 50 neutral; no numeric user score
was supplied. Cheapness 65: presentation adaptation and small optional launcher,
reusing existing contract with no dependencies. Recurrence is not applicable to
this feature; issue/PR/roadmap prior-art search found no matching tracked spike.
No defect-frequency claim is made. Reassess only on new evidence.

## Phase 1: build the optional preview

**Goal:** a standalone read-only add-on with documented borrowing, approved plan,
and an explicit demo/live launch.

1. Commit this plan and recon, run independent Codex plan QA → expect Approved.
2. Admit exact issue URL via owned roadmap gid and `--accepted-start` → expect one established start.
3. Implement only `addons/paperclip-dashboard/` with the shared read seam above → expect existing core file hashes unchanged.
4. Document source revision, per-file adaptation and upstream MIT notice → expect attribution in the standalone folder.
5. Launch synthetic demo and opt-in local preview → expect loopback-only binding, labelled data mode and no producer writes.

### Phase 1 — QA checklist
- [ ] Plan reviewer Approved with dated receipt; accepted start recorded afterwards.
- [ ] Optional module and all presentation files stay in the standalone add-on folder.
- [ ] Demo launch performs no live reads; live mode uses the existing projection.
- [ ] Source attribution and MIT notice present; core/startup/dependencies unchanged.
- [ ] Status table refreshed after observed outputs.

## Phase 2: verify and prepare operator review

**Goal:** inspectable preview, honest checks and independent final QA, with merge
left to the operator after visual review.

6. Record manual checks under `TESTS-RESULTS/2026-10-06+GH-981/` with nonempty artifacts and `provenance.jsonl` → expect desktop/mobile screenshots and browser interaction evidence.
7. Verify empty/stale/failure/partial states, literal hostile text, keyboard navigation, filters and demo/live data mode; witness a deliberate broken assertion/input as a red control → expect the check to fail for the reason it guards.
8. Run existing relevant Flightdeck manual checks and PDDA checks in a disposable full clone; compare source fixture bytes and Git identity before/after → expect no write/drift.
9. Commit implementation/evidence, run independent final Codex QA; choose required gate with existing classifier and run full qualifying gate once on the approved revision only if required → expect Approved and required gate green.
10. Push from the disposable gate clone through its installed pre-push boundary, open PR against development, inspect emitted base/head/scope/checks → expect reviewable spike awaiting operator decision, no merge.

### Phase 2 — QA checklist
- [ ] Desktop and mobile synthetic screenshots retained; no private live content committed.
- [ ] Manual pass/fail evidence includes source immutability, snapshot failure/staleness and red control.
- [ ] Existing focused checks and appropriate final gate have committed provenance.
- [ ] Final Codex reviewer Approved for the artifact revision; no new suite/registry/gate.
- [ ] Findings written back here, with keep/revise/abandon questions for operator review.
- [ ] PR inspected, clone retained, no merge or promotion; status remains awaiting review.

## Verification scope and non-scope

No new tests, gate machinery, registry entries, synthetic test runners or fuzzers.
Use existing `src.flightdeck.manual_harness --check`, existing focused Python
Flightdeck tests where relevant, browser inspection and recorded one-off manual
checks in temp/evidence. No test suite runs in the valued task clone or a linked
worktree. Separate disposable full-clone gates protect Git state. Automatic CI
is evidence only when an actual run appears for the exact PR SHA.

## Spike findings

Pending implementation/visual verification; do not infer adoption from a green
review. Operator must still decide whether to merge the optional add-on.
```
- Definition of Done: _<fill in the acceptance criteria the Reviewer grades against>_

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.


## Review envelope

Grade the committed plan and Recon Map against GH-981 user requirements: optional
standalone folder, accurate Paperclip attribution, visual evaluation before any
merge, and reuse of the existing Flightdeck read seam. This is a local read-only
technical spike, not an enterprise multi-tenant platform. Require commensurate
complexity, no new tests/gates/registries, no core dependency/startup changes and
honest uncertainty/freshness. Confirm falsifiable checks, rollback, PRS rating
55/20/50/65 (neutral appeal), and sequential ordering before implementation.
Read src/flightdeck/server.py, aggregate.py, contract.py and the two shared browser
selectors to verify the proposed adapter works. Report only blocking omissions
or grounded findings; do not expand to unrequested execution control or build
systems. You may write ONLY this relay thread. Do not run validate.sh or test/*.sh
in the review worktree. Use the embedded protocol to approve and close the token
or hand back findings.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
