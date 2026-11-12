---
gh_issue: 1448
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1448
title: "Explore advisory contract-quality linting in existing Jog and preflight validators"
status: Active
updated: 2026-11-12
created: 2026-11-12
owner: Codex
doc_type: feedback
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: false
non_goals:
  - new runner
  - automatic admission
  - broad semantic lint
related:
  - #1447
  - #1439
  - #1386
goal: >
  Evaluate advisory contract-quality checks in existing validators
---

## Key concepts

- observed outcomes
- command forms
- false positives

> **Note for plan writers:** apply the `/ponytail` lens — favor the laziest approach that actually
> works over new infrastructure, and question whether new surface needs to exist at all.

# Explore advisory contract-quality linting in existing Jog and preflight validators

## Status

| What was just completed | What's next |
|---|---|
| Reused canonical capture; rated and traced current validators at development `7acaa245`. | Independent plan QA, then bounded eight-case study; implementation only if findings justify a reviewed amendment. |

## Current authorized plan (2026-11-12)

The current operator request supersedes the historical research-only/later-authorization
wording retained below: investigate and, if promising, implement a small grounded change
following independent plan QA and publish a reviewed PR. This is not authorization for
broad lint. Use the T3-provided checkout and existing branch, no shell task clone, primary
writes, deployment, merge, cleanup or Pulse changes. Parent owns merge. Prior GH1447
receipts are published in development and will be consumed, never replayed here.

**Outcome sought:** reduce misleading preparation confidence while preserving valid
specialized probes. Lexical command-form recognition cannot establish the task's outcome.
**Smallest viable bet:** eight named non-executing command classifications and source trace,
with a go/no-go recommendation. No runtime edit is predetermined. A promising runtime
change requires a specific reviewed plan amendment before implementation.
**Alternative:** already-shipped GH1447 outcome-sensitive review wording plus real script
probes is the zero-code baseline. Compare a deliberately simple advisory hypothesis H:
warn when a command begins with `printf`, `echo`, `true` or `exit 0`. It is a research
hypothesis, not a new helper or gate. Compare with existing hard refusals, not replace them.
**Reversibility: Easy:** evidence/docs and owned PRS row only; revert this task's commit.
A runtime amendment must separately size callers/blast radius. No new tests, registry,
runner, ledger, hook or telemetry machinery; no imported unlazy code.

1. Record eight inputs, expected existing admission and desired advisory classifications
   in `TESTS-RESULTS/2026-11-12+GH-1448/cases.json` before running. Include retained GH1243
   and GH1254 contracts, fixed-output positive controls and legitimate specialized negatives.
   Consume GH1447 empty/trivial/missing and inline-command controls without repeating them.
2. After approved plan QA, admit the exact GH1448 PRS row with `--accepted-start`, then
   evaluate only `lint_probe` and H over the eight inputs; never execute inherited commands.
   Research clock starts at evaluation (30 minutes maximum; eight cases maximum).
   Inspect extraction and promotion statically. Record actual versus expected classifications,
   false positives/negatives and limits. No population accuracy claim from a selected sample.
3. Decide go/no-go: a useful change must add actionable information beyond existing review
   without weakening refusals or claiming relevance. If no small improvement is justified,
   publish a no-code recommendation and evidence. If promising, amend this plan with exact
   helper, controls and rollout, obtain independent review within three rounds, then implement.
4. Verify evidence is nonempty, inputs predate evaluation, GH1447 hashes are retained and
   source remains unchanged on the no-code path. Read the report from the issue's main
   preparation consumer and adjacent specialized-check case; record limits rather than
   claiming runtime delivery. Run the classifier-selected gate (disposable full clone for
   mutation-heavy suites); independent final Codex relay QA; publish to development and
   idempotently close out GH1448, leaving merge to parent. No checkout retirement.

**Acceptance / falsifiers:** H must warn on fixed `printf` positive and remain silent on
retained specialized checks. An input-dependent `printf` and pipeline exercise false
positives; `env printf` exercises an obvious false negative. An unrelated real regression
command must not be presented as proof of this issue's outcome. Report adverse results,
not tune the sample until green. Existing compatibility refusals remain intact. No code
means no new decision gate; the hypothesis's failing controls establish its limitations.

**Ratings readback:** PRS pickup `60/55/50/70`, no operator override. Priority follows
explicit investigation order; severity is bounded wasted runs/misleading evidence, no
observed data loss; appeal neutral; research is cheap. Recurrence windows 2026-10-30–11-12
versus 2026-10-16–29: issue search found GH1232 (different extraction bug) and retained
GH1171/GH1315 command-form examples consumed by GH1447. No distinct incident count or
rising trend can be inferred from keyword matches; trend remains unknown. Prior-art
PR1237 fixed JSON extraction and PR1449 supplied the prerequisite wording/replay; neither
implements this study. No candidate already delivers this requested comparison.

## Historical intake (scope superseded above)

## Observed

| Claim | Command / source | Observation |
|---|---|---|
| Existing command-form/path filter | GH1447 recorded replay.py using current jog_run.lint_probe | Two retained inline python commands refuse at -c; two repaired file commands pass; empty/trivial/missing controls refuse,7/7 expected classifications. This is offline function replay, not live delivery. |
| Semantics not measured | utils/py/swarm_preflight.py eval_probes; utils/py/jog_run.py lint_probe | For command probes, preflight evaluates exit status; Jog checks selected command forms and paths. Neither establishes correspondence to the requested outcome. |
| External reference | Leonxlnx/unlazy@16671491 scripts/gate-lint.mjs | Non-executing lexical warnings for fixed-output checks, weak expectations, activity labels and unmeasured numbers. Author inspected the pinned file locally; consultant retrieval failed. Reference: https://github.com/Leonxlnx/unlazy/blob/16671491f6679ad9378f52604d3bc2415b4120c7/scripts/gate-lint.mjs . No imported code or installed hooks. |

## Diagnosis / existing gap

Determine whether a small advisory extension of existing Forge contract validation can catch useful preparation mistakes without adding another gate runner, contract ledger or approval system. Distinguish the concrete command-form disagreement from semantic relevance, which lexical lint cannot prove. GH1447 owns wording and the bounded historical replay; this spike owns follow-up design, not implementation.

## Plan

1. Trace existing jog_run.lint_probe, contract extraction and swarm_preflight.eval_probes plus their callers; distinguish authoring, parsing, working-contract promotion and ledger writers.
2. Consume GH1447’s replay/recommendation without rerunning it; cap additional research at8 named cases and30 minutes, with expected classifications recorded before evaluation. Include real retained contracts where available; label added controls synthetic: fixed-output checks, command-form mismatch, unrelated valid regression checks and valid specialized checks. Record false positives/negatives; do not execute inherited shell commands without inspection and existing isolation.
3. Evaluate the smallest extension to existing validators, including a shared command-shape rule if justified. Compare advisory warnings with hard refusals; preserve existing safety checks. Do not add a second linter program by default.
4. Produce a go/no-go recommendation with exact fix site, red controls, costs, rollout and rollback. Any implementation is a later authorized task.

## Blast radius

| Seam | Current owner | Proposed scope |
|---|---|---|
| Probe syntax/admission | utils/py/jog_run.py | Read-only investigation; no runtime writes in spike |
| Preparation evaluation | utils/py/swarm_preflight.py | Read-only consistency trace |
| Captures/contracts | Existing HQ/PRS writers | Idea capture only; no automatic admission |
| Future verification | Existing suites/manual TESTS-RESULTS evidence | No new suite/runner |

Recon712a73b4; integration base development@712a73b4. Codex builder and independent Codex relay reviewer if later picked up; this intake uses Codex/Agy advisory consult with actual returned seats disclosed.

## Dependencies

GH1447 evidence at8f2aa802 (TESTS-RESULTS/2026-11-12+GH-1447/{replay.py,replay-results.json,provenance.jsonl}) must be published before this investigation claims reproducible committed evidence. Related1439/1296/1386 and1414 remain distinct; no dependency on installing unlazy.

## Acceptance

- [ ] Produce a cited map of command-form and semantic boundaries; red control is the observed python -c disagreement, not an invented production failure.
- [ ] Compare useful warnings against retained invalid and legitimate contracts, including empty input refusal and fixed-output positive control; record false positives/negatives without treating valid syntax as delivery proof.
- [ ] Recommend the smallest existing extension or explicitly recommend no code; record a known fixed-output positive control and a legitimate specialized-check negative control before scoring any candidate heuristic. A parallel ledger/runner or semantic-proof claim violates scope rather than serving as usefulness evidence.
- [ ] Preserve all prior receipts and distinguish source-derived conclusions from executed observations; absent evidence is unresolved, never pass.

## Verification

Bounded manual checks under TESTS-RESULTS with provenance when picked up; existing relevant suites only if an implementation is later authorized. Intake spike has no build contract or admission claim.

## Non-goals

No unlazy installation/vendoring, Stop hook, new test suite/gate/runner, separate GATES.md source of truth, automatic approvals, fullgate rerun mandate, model dispatch, runtime changes or deployment during this spike.

## Risk and rollback

Easy read-only research; retain evidence and close with no-code recommendation if burden exceeds value. Any future executable parsing change needs proportionate independent review and negative controls before rollout. Do not weaken current refusals to make a replay green.

## PRS proposal

- pri 60: Retained preparation examples justify this study after GH1447; comparative recurrence remains unknown.
- sev 55: Weak acceptance checks can waste bounded runs and overstate delivery without proven data loss.
- appeal 50: Neutral operator appeal; no numeric preference supplied.
- effort 70: Existing validator seams and retained evidence make investigation relatively inexpensive.

Recon: 712a73b4f3b01c8acc2c5115d11f855c62a2e537 · base: development@712a73b4f3b01c8acc2c5115d11f855c62a2e537 · tier: spike · review: consult gh1447-lint-idea-141014 models=codex,degraded hash ffed1b164190bf7c657bf7958ba905cebb1a911da699456873e579eb189f4618

## Why

Determine whether existing contract validators can provide useful bounded advisory diagnostics without semantic overclaims or parallel machinery.

## Phase 0 — Explore & scope

### Checklist

- [ ] Eight-case report and sourced go/no-go recommendation.

### QA checklist — Phase 0

- [ ] Independent plan/final review and classified gate with nonempty provenance.

## Merge evidence

- PR #1449 merged 2026-11-12 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
