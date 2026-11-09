# GH1358 checkpoint connection — implementation evidence

Candidate: opt-in `releases jog run --max-tasks 1 --checkpoint-root <publication-clone>`.
Existing supervisor lock covers ledger commit and exact-SHA normal push. A retained journal
recovers publication before new queue dispatch. Default invocation is unchanged.

- Existing gh280 adapter: 227 pass, 0 fail in separate disposable full clone.
- Manual publication controls: two successive ledger mutations, rejected push recovery with
  unchanged commit, unrelated-file refusal, extra publication-clone commit refusal: PASS.
- These controls use a local bare remote and supported ledger CLI, not raw SQL. They are
  component integration evidence, not deployed-autonomy or build-throughput evidence.
- Independent plan QA approved after two concrete implementation corrections; see
  `relay-system/2026-11-08/gh1358-checkpoint-plan.codex.md`.
- Launchd main path and interrupted-run recovery published two checkpoints across three wakes; normal full pre-push gate passed 409/409 in 538 seconds at 7046047d6. No whole-issue qualification.

Retain all disposable control/deployment clones; they contain local-only evidence. No reset,
force push, production primary mutation, exhausted-counter reset or merge occurred.

## Scheduled outcome

Actual source: runtime files from 7c375a022, independently compared to deployed copies.
Local deployment: `rehearsal.plist` and `deployment.json`; normal push hooks installed and
checked in the dedicated publication full clone. Transport rewrite points only these clones
to a local bare remote; canonical primary and hosted development are untouched.

1. Wake 1: GH1345 lacked an active preflight contract, parked without build; checkpoint
   d91ef4db2fadc2118902f1f6c94d94096dbb8c3e published by normal hook. This is an ineligible
   refusal, not a specific delivered-state classification.
2. Wake 2: scheduler independently advanced to GH1296, which passed preflight and entered
   agy. Labeling it held was wrong. Its residual acceptance needs the unavailable original
   historical backlog, so this was unsuitable workload selection. Stopped only positively
   identified owned PIDs (receipt retained). No PR produced or merge authorized.
3. Wake 3: scheduler cold-start reconciled the orphan and parked missing-result execution,
   then published 26543a0018c6d15767a20be4b382bc0cd0acef38. GH1296 attempt_count remains 1;
   no duplicate refire. Both ledger and publication clones clean. Final launchd exit 0.

GH1344 was parked before scheduling, preserving attempt_count 1 from the copied ledger and
its externally exhausted budget. Nothing retries it. Three actual scheduled wakes, two
published checkpoints, one interrupted attempt, zero successful builds/PR-ready outcomes.
No manual Git rescue between wakes. This does **not** establish two uninterrupted successful
work wakes, independent eligible build progression, or a complete transition rehearsal.

The run is agent-assisted: one workload-selection repair and an owned SIGTERM interruption.
The reported three-round budget refers to independent QA; actual Marathon used its default
five relay rounds, witnessed in logs, with 900-second turn ceilings. It was stopped during
its first builder turn; token/cost usage is unknown, not zero. No Phase B/idle soak.

Schedule was disabled, then booted out after recovery exit 0. Resume requires deliberate
`launchctl enable gui/<uid>/com.xyz-forge.gh1358-checkpoint-rehearsal` and bootstrap of the
retained plist **after workload selection is corrected**. Do not restart GH1296 or reset
counters. Retain the clones and isolated turn worktree; they contain local-only evidence.

## Transition accounting

| Required transition | New observation / remaining gap |
|---|---|
| No-row discovery → pickup → add | Not integrated; manual task intake is not this witness |
| Delivered/stale refusal | GH1345 preflight-contract refusal only; delivered classifier unproven |
| Held → independent advance | Next pending row did advance, but GH1296 eligibility was wrong |
| Owned interruption → cold-start park | Observed through scheduled wake, no duplicate refire |
| Supervisor loss → scheduled cold resume | Observed after owned SIGTERM; host-loss observer absent |
| Changed approval → refusal | Existing prior evidence only, no new deployed witness |
| Approved merge → reconcile → land → next | Not exercised; per-PR approval preserved |

Remaining integration belongs to the existing #1175/#1200 admission/composition, #1188
observer, and #1208 landing owners. This PR provides the #1207 checkpoint connection without
claiming those owners or the whole campaign are complete.

Live planner discovery was also exercised: 607 items, 5 active, 217 held, GitHub live, exit 4 (drift). The report is retained; planner output alone is not proof of workload eligibility or scheduled admission.

Ready partial-delivery PR: https://github.com/HiQS-Labs/XYZ-forge/pull/1370. Independent final QA approved the checkpoint feature; normal full gate passed 409/409 at 7046047d6. Subsequent documentation/evidence-only commits do not change the tested runtime.
