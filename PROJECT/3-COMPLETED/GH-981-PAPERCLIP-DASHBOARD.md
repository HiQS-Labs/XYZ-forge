---
gh_issue: 981
source: https://github.com/HiQS-Labs/XYZ-forge/issues/981
title: Optional Paperclip dashboard — technical spike
status: Complete
created: 2026-10-06
updated: 2026-10-10
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
| Current development integrated; independent implementation and gate-repair QA Approved; normal full push gate GREEN 410/410. | Land PR #982 and complete hosted reconciliation under the 2026-10-09 operator request. |

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
- [x] Plan reviewer Approved with [dated receipt](../../relay-system/2026-10-06/gh981-plan.codex.md); accepted start recorded afterwards.
- [x] Optional module and all presentation files stay in the standalone add-on folder.
- [x] Demo launch performs no live reads; live mode uses the existing projection.
- [x] Source attribution and MIT notice present; core/startup/dependencies unchanged.
- [x] Status table refreshed after observed outputs.

## Phase 2: verify and prepare operator review

**Goal:** inspectable preview, honest checks and independent final QA, with merge
left to the operator after visual review.

6. Record manual checks under `TESTS-RESULTS/2026-10-06+GH-981/` with nonempty artifacts and `provenance.jsonl` → expect desktop/mobile screenshots and browser interaction evidence.
7. Verify empty/stale/failure/partial states, literal hostile text, keyboard navigation, filters and demo/live data mode; witness a deliberate broken assertion/input as a red control → expect the check to fail for the reason it guards.
8. Run existing relevant Flightdeck manual checks and PDDA checks in a disposable full clone; compare source fixture bytes and Git identity before/after → expect no write/drift.
9. Commit implementation/evidence, run independent final Codex QA; record classifier and operator qualification direction → expect Approved for visual/draft review. The operator explicitly deferred the full suite to merge on 2026-10-06; the already-started run was stopped and retained as interrupted, not green.
10. Publish from the disposable clone with the full pre-push gate explicitly skipped under operator direction; open draft PR against development and inspect base/head/scope/checks → expect reviewable spike awaiting operator decision, no merge or development catch-up.

### Phase 2 — QA checklist
- [x] Desktop and 430px compact synthetic screenshots retained; no private live content committed.
- [x] Manual pass/fail evidence includes source immutability, snapshot failure/staleness and red control.
- [x] Focused checks have committed provenance; interrupted full run is retained and qualification deferred to merge by operator.
- [x] Final Codex reviewer Approved in two rounds for the artifact revision; no new suite/registry/gate.
- [x] Findings written back here, with keep/revise/abandon choices for operator review.
- [x] [PR #982](https://github.com/HiQS-Labs/XYZ-forge/pull/982) inspected against development; clone retained, no merge or promotion; status remains awaiting review.

## Verification scope and non-scope

No new tests, gate machinery, registry entries, synthetic test runners or fuzzers.
Use existing `src.flightdeck.manual_harness --check`, existing focused Python
Flightdeck tests where relevant, browser inspection and recorded one-off manual
checks in temp/evidence. No test suite runs in the valued task clone or a linked
worktree. Separate disposable full-clone gates protect Git state. Automatic CI
is evidence only when an actual run appears for the exact PR SHA.

## Spike findings

The standalone UI borrows navigation/card/filter/activity presentation patterns;
it reuses existing Flightdeck data and status rules without importing Paperclip's
React build, control APIs or domain model. Browser review caught and fixed row
focus loss. Evidence: [verification](../../TESTS-RESULTS/2026-10-06+GH-981/SUMMARY.md).
Existing focused checks report 34 pass / 5 fail at a pre-existing Darwin `waitid`
incompatibility; manual fixture boundary checks passed. No merge readiness claim.
The original visual-review phase offered keep/revise/abandon. The 2026-10-09
operator request below supplies landing intent; merge readiness still requires
the deferred full gate.

## Operator steering — 2026-10-06

Preserve this branch and prepare the PR; do not catch up with development. This
additive spike defers full-suite qualification until merge. The full run already
in progress was stopped (143), not qualified; its transcript and unchanged Git
identity are retained in the [gate disposition](../../TESTS-RESULTS/2026-10-06+GH-981/gate-disposition.md).
Runtime bytes remain those independently reviewed. No merge is authorized.


## Operator steering — 2026-10-09

The operator requested merge-cleanup of all open PRs except the held test-canary
PR #930. This supplies intent to retain and land this optional renderer once
its merge criteria pass. It supersedes the earlier review-only/no-merge direction;
it does not waive the deferred full gate or authorize network exposure.

Prepared integration `c4ef7f3dbd2ed937150fd84d3aef0f0d2335946e` is based on
`47fb72dfcb13af1d0f64ed7d527a8db467171cbb`. Only disjoint ledger conflicts were
resolved; all eight add-on files retain their original reviewed bytes.
Renewed independent [Codex merge QA](../../relay-system/2026-10-09/gh982-merge.codex.md)
is Approved Round2 with a mechanical attestation. Round1's implementation PASS
was rejected for a closure-protocol mismatch; both rounds and their provenance
are retained under [current receipts](../../TESTS-RESULTS/2026-10-09+GH-981/SUMMARY.md).

The normal full pre-push gate refused candidate `209fd0bd` (409/410; gh609 only)
in an independent disposable full clone, without Git identity drift. The existing
SWE contract checker is adapted to #1009’s intentionally changed policy, with
[retained differential and red controls](../../TESTS-RESULTS/2026-10-09+GH-981/gate-repair.md).
Independent repair review is Approved; the completed development reconciliation
is integrated at `bd6300c7`. The repaired full-gate outcome is recorded below. Historical evidence remains bounded. Historical focused Darwin failures and the interrupted Lanes
timer-focus observation remain bounded findings; no expectations were weakened.


Full merge-time push gate completed on `59a924ba`: 410/410, exit 0, no bypass, unchanged Git identity. [Retained result and provenance](../../TESTS-RESULTS/2026-10-09+GH-981/SUMMARY.md). This receipt-only follow-up changes no reviewed code. Ready for the authorized landing; hosted post-merge qualification and promotion are separate.
