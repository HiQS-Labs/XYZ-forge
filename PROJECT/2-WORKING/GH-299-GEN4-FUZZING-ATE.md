---
title: "GH-299: Gen 4 ATE & True Evolutionary Fuzzing — High-ROI Phasing: Semantic Invariant Oracles, Constraint-Aware Pairwise ATE, and Feedback-Guided Fuzzing"
status: Active
created: 2026-08-28
updated: 2026-10-21
owner: orchestrator (Claude Code)
gh_issue: 299
source: https://github.com/HiQS-Labs/XYZ-forge/issues/299
branch: feat/gh299-gen4-ate
doc_type: plan
effort: 3
complexity: 3
risk: 2
phases: 5
rating: "pri/sev/appeal/effort 90/75/95/40 · calc 320"
related:
  - https://github.com/HiQS-Suite/XYZ-forge/issues/141
  - https://github.com/HiQS-Suite/XYZ-forge/issues/155
  - https://github.com/HiQS-Labs/XYZ-forge/issues/174
  - https://github.com/HiQS-Labs/XYZ-forge/issues/182
  - https://github.com/HiQS-Labs/XYZ-forge/issues/201
  - https://github.com/HiQS-Labs/XYZ-forge/issues/298
  - https://github.com/HiQS-Labs/XYZ-forge/issues/299
goal: >
  Deliver the highest-ROI, lowest-friction evolution of XYZ Forge testing: prioritize host containment and
  pairwise combinatorial reduction upfront (80% value in initial phases), followed by high-throughput
  feedback-guided fuzzing, clustered hermetic reproducer synthesis, and sandboxed self-healing.
---

# GH-299 — Gen 4 ATE/fuzzing historical implementation plan

Current entry points, schemas and safety limits are maintained in the
[ATE skill](../../skills/4-occasional/ate/SKILL.md). This document preserves the historical
plan/report context; it does not attest current behavior or certify a campaign.

## Status

| What was just completed | What's next |
|---|---|
| Historical 2026-09-04 report: five phases on feat/gh299-gen4-ate; PR not yet merged; multi-hour soak assigned to Agy “tonight” | Historical next step was soak → relay QA → PR review. For current operation use the ATE map and live issue/PR state, not that date-relative instruction |

## Historical QA reports (2026-09-04; not rerun for the docs correction)

| Phase | Recorded report and limits |
|---|---|
| 1 — domain oracles | 17/17 positive/negative controls reported; observations of selected state, not OS-enforced containment |
| 2 — pairwise/classifier | 18/18 reported; 13 cases versus 13,824 Cartesian, 327/327 valid pairs, FN=0/FP=0. These reductions are specific to that grid. The plan's “50/20” benchmark label was inaccurate: shipped calibration has 50 pass / 24 fail inputs and 9 anomalies |
| 3 — mutational engine | 20/20 reported; byte-identical seeded plans, 150 mutants, corpus-cap and parity controls. Plan equality does not guarantee identical execution outcomes |
| 4 — synthesis | 17/17 reported; 14 counterexamples → 2 signature clusters → 2 minimized scripts (6→3 argv); “50 same-cause rows → 1 suite” was a planted-fixture report, not semantic clustering proof |
| 5 — campaign | Bounded suite 17/17 reported; retained campaign: 400 mutations / nine targets / parity on, 259s (92.6/min), zero recorded host violations, zero failed replay predicates, 43 Tier-1 anomalies (34 parity + 9 non-parity), two clusters → one script, one sandbox-contamination event reset/recorded. A >10,000-mutation multi-hour soak was still owed in this report |

Historical campaign artifacts: `TESTS-RESULTS/2026-09-04+GH-299/campaign/`.
Reported “false positives” count failed replay predicates; it is not proof that every accepted
candidate represents the original defect. This correction adds no new campaign or benchmark evidence.

## Planned pillars versus current implementation

1. **Telemetry and domain oracles:** `telemetry_schema.py` and `domain_oracles.py` provide selected
   state/identity observations. Hashes, path checks and bounded/skippable `lsof` are not a sandbox.
2. **Adaptive ATE:** constraint-aware pairwise generation and heuristic Tier-1 classification.
   Historical ~85%/~90% reduction, <5ms and >95% model-free targets were goals/benchmarks, not
   universal guarantees. Adaptive run mode can send anomalies to a configured command.
3. **Fuzz engine:** seeded token mutation with output-based feedback and a default 500-entry corpus.
   Execution plans precede execution; feedback seeds later calls. Pin source, argv, corpus and
   environment for replay attempts; timing and external state remain nondeterministic. Twin parity
   compares exit/stderr signatures, not semantic equivalence or coverage of program branches.
4. **Reproducer synthesis:** candidate stderr-signature clusters omit target identity. Campaign replay
   accepts digest OR exit code; synthesis can retry with an exit-code-only predicate. Minimized scripts
   need semantic replay and review; they are not automatically committed fixes or approved new tests.
5. **Campaign/repair handoff:** nine default harness targets exclude `validate.sh`; this does not
   campaign the full test registry. Synthesis defaults on (`--no-synth` disables; no `--synth` flag).
   Campaign `--tier2-cmd` is accepted but unused. Bounded registered Gen 4 tests may run in hosted
   validation; multi-hour exploratory campaigns are a separate activity.

The historical atomic-write/full-attestation design was not implemented as promised:
`self_healer.py` uses ordinary open/write for apply and rollback; `gen4_campaign.py` hardcodes repair
target `validate.sh` and regression command `bash validate.sh --print-mode`, which runs no tests.
The generator and diff handoff are opt-in and can be refused by path checks. No autonomous,
verified repair or automatic PR guarantee follows. Keep full regression qualification and review
as separate requirements, not waived safeguards.

Campaign budgets are checked between batches; postprocessing can overrun them. Host violations
are recorded, not immediate abort triggers; exit 0 does not mean no findings. Destructive scratch
resets require expendable standalone full clones and an independent supervisor/cleanup plan.
For current bounded discovery and remediation boundaries see
[defect-campaign](../../skills/4-occasional/defect-campaign/SKILL.md).

## Merge evidence

- PR #441 merged 2026-09-05; PR #476 merged 2026-09-07. Linked #299 remains open;
  this active document's historical September 4 “not merged” status is not the current PR state.

## Lessons Learned (For Future Agents)

- Historical plans and fixture benchmarks do not establish current execution or safety contracts.
- Packaging, replay predicates, clustering identity and repair qualification remain separate code
  follow-ups in #1174; this docs correction changes no executable behavior.
