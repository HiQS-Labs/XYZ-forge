---
gh_issue: 1076
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1076
title: "GH-1076: consolidate selective-CI and batch-qualification policy"
status: In Progress
created: 2026-10-14
updated: 2026-10-14
owner: Codex (operator-authorized)
goal: "One canonical policy and existing deterministic consumers preserve qualification coverage; evaluate remaining batch and selective-Medium phases with evidence rather than assumed readiness."
complexity: 3
risk: 2
effort: 3
phases: 4
---

## Status

| What was just completed | What's next |
|---|---|
| Codex plan QA Approved round2/3; first PARKED seed-delivery review retained. Claude advisory complete, Agy partial at300s cap. Baseline started at f974fcee after GH1064 gate finished. | Implement the approved coverage-preserving scope; retain full while batch/Medium evidence remains insufficient. |

## Table of contents

- [Ground truth and scope](#ground-truth-and-scope)
- [Phase 1: retain baseline and approve plan](#phase-1-retain-baseline-and-approve-plan)
- [Phase 2: canonical policy and deterministic consumers](#phase-2-canonical-policy-and-deterministic-consumers)
- [Phase 3: batch and selective-Medium readiness](#phase-3-batch-and-selective-medium-readiness)
- [Phase 4: verification, benchmark and draft PR](#phase-4-verification-benchmark-and-draft-pr)
- [Risk, dependencies and rollback](#risk-dependencies-and-rollback)

## Ground truth and scope

Base development: `f974fcee15647aae6551fcc81b129f5a6127120b`. Spike:
https://github.com/HiQS-Labs/XYZ-forge/issues/1076#issuecomment-6186021918.
Canonical task clone is the existing clean full spike clone, reused on explicit operator authorization;
this overrides the default new-folder/location formula. Branch:
`chore/XYZ-forge-gh1076-ci-policy-2026-10-14`. Primary and other task clones remain untouched.

Recon already established at this unchanged base: ci-route owns path/area/suite selection; pre-push and
validate consume it; wave_reconcile select_qualification_gate translates tier1 to Small and all others
to full; current receipt reader permits exactly full/Small and replays Small's literal list at tested
commit. Promotion is separately fixed to exact-main full sequential. Existing non-shell stages remain.
Current receipt envelopes do not fingerprint installed environments or support candidate substitution.

Observed counterexample: GH988/GH989 markdown package addition/rename was machine-consumed by
xyz_mini_sync; the existing gh620 payload pin failed in hosted run37723297290, fixed by issue995.
Current docs precedence still emits tier1/no area for those historical paths. A Small+emitted-area
union therefore misses this known consumer. This is a historical counterexample, not a current
reproduced runtime failure or a statistically representative Medium catch-rate study.

Outcome sought: predictable, auditable selection and fewer avoidable qualification cycles while
preserving relevant failure detection. Smallest viable bet: one canonical prose contract, one
machine decision owner, explicit known content consumers, and evidence-driven readiness decisions.
Docs alone leave a duplicated hosted decision; a new router/cache/framework duplicates existing
machinery. Both are rejected. No new CI assertions, parameter rows, registry entries or stages.

PRS rating proposal: **75/45/50/40**, no override. Priority75 reflects Noel's explicit current
ordering; severity45 reflects policy/coverage ambiguity with a historical consumer miss, not an
observed current data-loss incident. Appeal50 is neutral. Cheapness40 reflects cross-consumer review,
long matched full-suite measurements and uncertain downstream phases. Recent examples are GH995's
single payload incident and GH1072/1073's separate proposed batch-state defects; recurrence trend is
unknown, not fabricated from issue count. Four-axis DB readback is authoritative.

## Phase 1: retain baseline and approve plan

1. Register this issue/doc through the RELEASES writer, rate/read back, and promote the doc before
   implementation. Run prior-art recon and confirm no GH1076 writer. → one owned issue row/plan.
2. Retain f974 baseline in a disposable full clone. Check for active host gates; GH1064 ci-local was
   active at initial inventory, so do not overlap it. When free, capture before identity, runtime/tool
   versions, load, command and full telemetry; run existing full `validate.sh` with explicit width4.
   → preserve rc/counts/skips/first failures/retries/wall time and after identity before comparison.
3. Consult actual Agy and Claude Code CLI on this plan/spike, then Codex relay plan QA with normal
   3-round cap. → preserve raw opinions/dispositions; no substituted identity or claimed quorum.

QA gate: approved scoped plan and retained pinned baseline; unavailable independent review or
exhausted caps are explicit blockers. Accepted-start admission follows plan approval, before code.

## Phase 2: canonical policy and deterministic consumers

4. Extend the existing `ROUTER.md` CI qualification policy section as the canonical explanatory contract (consult disposition: smaller existing owner, no new governance file). Replace duplicated
   normative CI/qualification/batch rules in AGENTS, SOP and ROUTER with pointers, preserving local
   command/resource guidance and role boundaries. The existing CI churn guidance points there; leave GH1064-owned merge-cleanup files untouched while its owner is active. Preserve script-owned parity tables.
5. Extend existing ci-route key/value output with versioned hosted-qualification decision metadata;
   current tier1 maps Small and other tiers full. Make existing wave selector consume that decision,
   retaining fixed command dispatch. Missing/unknown/duplicate/malformed decisions fail full.
   Old consumers may ignore additive fields; historical @1 receipt replay/list parsing is unchanged.
   A new consumer with an old router safely selects full, never guesses a new subset.
6. Explicitly include the existing skills-army publication-consumer area for its machine-consumed
   package text, before generic docs precedence. This increases known coverage rather than adding
   tests or reducing gates. Verify existing registry suites and historical add/rename paths through
   recorded manual classification/red controls; unknown/shared/global/safety remains full.

QA gate: unchanged current suite registries, hosted Medium/full and main/full; existing route,
registry, workflow and receipt checks plus manual red controls falsify the changed decisions. No new
tests or permanently registered benchmark machinery. No production/workflow/protection change.

## Phase 3: batch and selective-Medium readiness

7. Assess existing freeze, ordered member/base/candidate/landed identities, dependency/interaction
   scope, rollback suffix and receipt invalidation against the canonical policy. Preserve per-PR
   gates, caps, serial reconciliation and receipts-first bounded recovery. Broader fold authority
   requires its concrete supported workflow; no automatic batch scheduler or unchecked verdict cache.
   GH1072/GH1073 are in unmerged PR1069 and its owner is actively gating GH1064. Do not duplicate that
   writer or silently claim its state safe. Independently useful policy work proceeds; any necessary
   unresolved dependency remains named with exact state/evidence.
8. Evaluate a bounded Medium candidate using source consumer audit and historical full failure/
   changed-range pairs, separating package-contract regressions from environment/contended failures.
   Reuse existing registry/runner/receipt mechanisms. Unknown edge or relevant omitted failure keeps
   full selection. A reduced pilot requires reviewed complete selection (Small+area+consumers and
   non-shell stages), deterministic expected-list replay, historical receipt compatibility and current
   workflow/protection compatibility. Do not accept receipt-supplied lists without reconstruction.
   If evidence cannot support reduction, retain full and report the precise missing evidence; do not
   manufacture success, retire tests, or call every umbrella acceptance box complete.

QA gate: every completed capability has implementation and evidence; no unsafe batch authority or
unsupported Medium savings claim. Any needed new individual CI case is proposed to Noel, never added
silently. No merge/protection/deployment permission is inferred from end-to-end execution.

## Phase 4: verification, benchmark and draft PR

9. Commit coherent implementation, focused existing checks and recorded manual controls in separate
   disposable full clones with before/after identity. Run independent Codex final relay QA under the
   normal3-round cap; resolve bounded findings without scope inflation. Preserve raw failed results.
10. On the final approved implementation SHA run one required full gate at the same explicit width4
    as baseline, serial per host. Reuse that run as the after benchmark and normal push verification
    where the installed hook supports the existing receipt path; otherwise follow the normal hook
    without bypass and report any additional run honestly. Retain command, versions, counts, skips,
    failures, retries, wall time and environmental/load differences. One sample each is descriptive,
    not causal performance proof. Any first failure remains visible even if retry passes.
11. Commit required evidence with typed attribution; push through normal gates, open a **draft** PR
    against development linked with `Refs #1076` (umbrella stays open while work remains), and verify
    remote head and actual exact-head hosted jobs. Compare only naturally occurring equivalent hosted
    jobs if available; distinguish queue/execution, event, runner, OS, coverage and skipped/advisory.
    No dispatch/rerun is authorized to create a benchmark. Save findings back to GH1076.

QA gate: reviewed draft PR, verified remote SHA and disclosed exact-head hosted outcome; measured
before/after evidence with honest differences/limits. No merges or checkout teardown.

## Risk, dependencies and rollback

Easy to reverse: one scoped PR revert restores current selector/docs; no new persisted qualification
schema is required for the coverage-preserving step. Existing @1 historical receipts retain their
meaning. Wider reduced-selection or environment-equivalence contracts are not assumed reversible
merely because a branch is isolated. Runtime consumer failures return full, not a permissive cache.

Source radius: ci-route, pre-push/validate readers, wave selector and strict historical receipt reader,
promotion workflow (verification only), canonical operating docs and merge guidance; RELEASES/doc
intake and committed evidence. No new framework, installations, live Marathon/Jog, schedules,
protected-branch settings, test retirement, cleanup or unrelated runtime refactor. Dependencies:
GH1064/PR1069 active owner, GH1072/1073 unresolved; per-new-case approval; sufficient historical
coverage evidence and independent review. These constraints are not waived by the deadline.
