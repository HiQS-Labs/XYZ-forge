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
