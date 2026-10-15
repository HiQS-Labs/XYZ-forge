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
| Configuration pivot implemented;13 existing focused suites pass. Supplemental final1/1 FAIL found drift wrongly entering proof fallback; two fatal-stop corrections verified by existing23-case suite and before/after manual control. | Retain original FAIL/counter; collect normal full-gate evidence for parent’s conditional procedural decision and publish GH1076/PR1079. No merge or activation. |

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
   versions, load, command and full telemetry; run existing full `validate.sh` with normal balanced width4 verified, without exporting worker overrides.
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
10. On the final approved implementation SHA run one required full gate at the same normal balanced width4
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

## Execution findings and remaining boundaries

- Codex plan QA Approved round2/3; first PARKED seed-delivery failure preserved. Admitted exact owned
  row via native accepted-start after approval, then promoted through RELEASES verbs. No override.
- Actual Claude Code completed conditional advisory; Agy returned partial source analysis at300s
  cap. No cross-model consensus claimed. Consultation synthesis: GH1076 comment6186698655.
- Canonical prose is now the existing ROUTER section (smaller consult disposition); runtime changes
  extend existing router and wave selector only. GH1064-owned merge-cleanup files remain untouched.
- Direct manual observations at6784bdda: historical package add/rename now tier2/full; ordinary docs
  Small, mapped code/full and safety/full. Missing/unknown/duplicate/malformed/inconsistent decisions
  return full. Removing the in-memory version comparison wrongly admits Small: witnessed red control.
  No CI case/assertion/parameter row, registry, workflow or receipt schema was changed.
- Historical study v2: all20original failed logs (30,300,983 bytes),16 qualification attempts
  across13distinct tested snapshots; zero newly validated mapped-Medium regression/change pairs.
  Pending-union and causal attribution remain explicit unknowns. Version1 is preserved, including
  the narrower failure list corrected by v2. No catch-rate or reduction readiness claim.
- Batch dependency refreshed: PR1069 stilld2e7369a, open; GH1072/1073 open. Its other owner's gate
  finished, not a handoff of implementation ownership. No duplicate batch writer or unsafe authority.
- Baseline first measurement inherited an exported maximum-worker setting that overrides nested
  mode-probe expectations. Source trace and direct print-mode differential confirm this configuration
  effect; retain the run/failures, then use the normal command with balanced width4 verified from
  telemetry for the matched pair. No test is patched to accommodate the measurement wrapper.

Reduced-Medium rollout and broader automated batch authority remain **not implemented/not ready**
for the specific evidence/ownership reasons above. The safe policy and consumer enforcement continue
through normal verification and draft publication; GH1076 is not closed by that PR.

Coverage correction before final QA: source tracing found the publisher-text precedence change also
removed existing `pdda_needed` metadata. The same classification loop now retains it for machine-
consumed text, so area coverage is additive to existing doc hygiene. Initial manual observations are
retained; the correction record names the prior false metadata and downstream T2_PDDA consumer.
No existing CI assertion was changed or new case added.

Parent adjudication accepted existing ROUTER as the canonical prose location; deterministic routing
retains its current script owner. Actual Agy timeout remains partial, not approval; no cap reset.

The discarded calibration completed rc1,408/409 at pinned f974 in1,455.57s. Its exported
XYZ_VALIDATE_MAX_JOBS=4 contaminated nested mode probes; gh544 remained failed on sequential retry.
Other first failures/retries remain in raw telemetry. Repository identity stayed unchanged. This run
is retained as failed calibration, not the matched before measurement or qualifying evidence.

Medium pilot unmet criteria: no eligible mapped-only changed-range/full-failure pair established;
complete pending unions and introduced-by-change causality are not proven by trigger diffs; direct
and downstream consumers, all non-shell stages, expected-list replay, historical receipt behavior
and current workflow/protection compatibility require reviewed evidence before reduced selection.
Current implementation retains full for Medium/unknown/global/safety and does not introduce savings.

Batch authority unmet criteria: GH1072/GH1073 fixes and PR1069 ownership/handoff are unresolved;
current freeze/ordered member/base/candidate/landed identity and receipt-invalidation semantics must
be proven together before expansion. Current policy records serial writer, receipts-first bounded
recovery, per-PR normal gates, suffix rollback and the expired exception; no batch dispatcher or fold
authority was added. The safe completed policy work does not certify the unresolved batch runtime.

Integration refreshed before final QA: development9061df4b adds merged PR1078's Markdown skill,
architecture pointer and intake/evidence. No runtime/test/workflow/registry changes relative to f974.
Task merge retains both GH1076/GH1077 ledger rows and operation/event histories, keeps the higher
generation header/settings, then rebuilds/verifies via the existing releases-merge-resolve writer.
Routine LEADERBOARD regeneration was restored to its committed bytes, per task-branch policy.
The matched after snapshot will include these unrelated documentation additions and the task's
review/evidence; source differences and their measurement limits will be disclosed.
PR1069 refreshed at4691b4a3 (OPEN), GH1072/GH1073 remain OPEN; no owner handoff or readiness inferred.

Focused verification69567090:10/10 existing suites returned0, repository HEAD/config/refs/status
identical before/after (focused-verification.json/.log). This covers routing/whole-tree drift,
workflow/envelope, receipt/premerge, auto-reconcile, publication recovery and skills-army publisher.
No individual CI case added or altered. Subsequent integration changes are documentation/ledger.
Final independent review and required exact-source full push gate remain pending.

Final Codex relay Approved round2/3 atb334e98d; round1 Should/FAIL preserved and corrected by
counting malformed duplicate tier values instead of silently discarding them. Manual before/after
and independent reviewer red control show malformed duplicate now full; ordinary Small unchanged.
Normal cap not reset. Ten-suite evidence predates this one-line correction; affected receipt and
reconciliation rerun and required normal full push gate remain pending after the serial baseline.

Final source freeze/handoff: subsequent measured gate receipts and remote/PR/hosted outcomes will be
committed under TESTS-RESULTS/2026-10-15+GH-1076/SUMMARY.md. Read that outcome with this plan rather
than treating a pending gate here as completed. Verification evidence commits do not alter source;
any later non-evidence source change invalidates the attributed final full run. The umbrella stays
In progress while reduced-Medium/batch prerequisites remain unmet; no early lifecycle completion.

## Continuation: concrete proof work after PR1079 publication

The parent requested completing feasible evidence rather than stopping at “unproved.” This remains
the approved existing-owner/consumer audit scope; no new tier, runner, CLI, receipt schema or hosted
coverage reduction is introduced. Source changes since the prior full gate invalidate that gate for
the new source; retain it historically and use the remaining normal final-review round3, then a
fresh required exact-source full push gate. Prior review rounds/counters are not reset.

Read-only source and real-data work now supplies:218 actual committed @1 historical receipts accepted
identically by baseline/current readers; two complete single-member naturally full-qualified mapped
Medium snapshots; exact six-member GH988/GH989 Small union and byte-equivalent known gh620 failure
inputs at the later full-red snapshot; direct and reverse coverage maps across406 registered suite
sources. Prior v1/v2 and the narrower initial v3 consumer proposal remain historical artifacts.

The reverse audit found three concrete consumer suites absent from the area's five: gh660 drift
checker called by sync, path-integrity reading every skill Markdown cross-folder link, and gh788
interpreter-pattern scanning all skills content including code examples. All already run in full.
The existing area now includes them, eight total. The existing route-count expectation changes5→8;
no assertion, method, parameter case or full/Small registry entry is added. Full fallback stays.
The proposed study union is Small72+area8=80 existing shell suites; no new Medium gate is active.

Current batch source4691b4a3 still reproduces both filed stale-snapshot and stale repaired-scope
observations, using the same already-published local JSON interleavings in this session's disposable
review clone. GH1074 fixes other history/resume paths; it does not refute either observation.
Existing gh436 and current production premerge receipt checks are retained separately. Five new
methods were removed; three pre-existing added assertions still need admission or removal by their
owner. PR1069 final review binds older9a64, and its author lists four post-review changes. No owner
handoff was established; live Claude processes in the primary checkout make absence of a running
gate insufficient proof of exclusive ownership. This session only reads immutable batch source.

The staged rollout's remaining actions must be concrete. A candidate-specific freeze contract,
80-suite posthoc projection, exact runner/receipt shape, workflow/protection readback, current gate
evidence and minimal external decisions are recorded under TESTS-RESULTS/2026-10-15+GH-1076/phase3.
No ready coupled fold is invented from held/draft/unreviewed PRs or shared ledger alone.


## Disabled profile completion — authorized 2026-10-15

Status: implementation pending the remaining normal plan round3/3. Original final3/3 is retained;
Noel separately approved exactly ONE extra final QA for this disabled scope, with no reset/retry.
Parent delegated exclusive1079 ownership; another coordinator owns1053/1082 and remote landings.
Read-only base refreshed to developmentdc7245b4d34e49b9adfba25cf5efbae08bf99c0e, integrated locally
at963061c1. Only ledger DB/dump conflicted. Native resolver passed, all10 ours-changed and27 incoming-
changed INSERT rows preserved; generation floor1664. Routine leaderboard retains incoming bytes.
1069 and1068 are merged, but this is not proof of their correctness. Current batch save still locks
only an already-loaded snapshot; repaired known rows remain append-only. This feature must not read
batch verdicts, sweep coverage or mutable batch membership as qualification authority. Existing
batch caller reads select_qualification_gate's gate/reason only; its ordinary full fallback remains.

### Bet, existing owners and boundaries

Outcome: finish the named inactive profile/phase-receipt capability, not reduce any current checks.
Smallest bet: extend utils/ci-route.sh and utils/py/wave_reconcile.py; use unchanged validate.sh,
existing sequential Small and skills-area commands, runner envelope/telemetry, gate_env, bounded
process execution, qualification clone and journal writer. No new module/runner/CLI/registry/test.
ROUTER remains prose owner. Prior recon maps/actual80-row evidence are reused with current source
reads; no new cross-model consultation or duplicate implementation sessions.

Recon: router registry35 and classification/hosted decision; wave select593/qualify627/receipt531/
committed574; validate Small selection924, PDDA1119, Python1439, envelope1465, summary1497. Existing
@1 consumer accepts recorded full/Small and only reads Small at the tested historical commit.
Main workflow's explicit sequentialfull is separate and untouched. New schema support is dormant;
current committed @1 receipt acceptance and selection must remain identical. Existing gate_env
clears fixture overrides; new runtime fingerprint stays inside the wave's existing receipt owner,
not a new telemetry stage or environment service. No current equivalent runtime-version helper was
found in bounded search: runner-envelope owns clone/tree/lock identity, not OS/tool/dependency versions.

Risk: Costly shared evidence contract, contained by a literal source-controlled false activation bit,
legacy coexistence and no environment override. Any failure leaves full selection and original
receipts untouched. Revert the two-file extension before any future activation; no migrated live
@2 data or rollback coordination is created while disabled. Future activation is a separate reviewed
policy/candidate decision, not granted by this task. Invalid/incomplete evidence cannot fall through
from @2 into @1 or generic PR-attribution success.

Alternatives: keep documentation only would not deliver requested disabled support; extend validate
with a new composite tier would duplicate runner semantics; concatenate telemetry would fabricate
one execution; a generic candidate cache/approval controller would expand authority and is rejected.

### One ordered implementation/verification sequence

1. Extend the existing router with named profile skills-army-content@1 and a literal false enable
   constant, emitting additive candidate/enabled metadata through existing push classification.
   A candidate consists ONLY of top-level, already tracked .md/.txt content under
   skills/3-weekly/skills-army-hq/. Metadata means path candidate, not approval. Reject mixed paths,
   code/shared publisher/checker/manifest/license behavior, operational/security/permission changes,
   adds/deletes/renames/modes/symlinks. Name-only router metadata cannot establish Git status or
   semantic review; the wave additionally checks actual raw diff modes/status and one complete landing.
   Enabled is false with no env/CLI override, so hosted_gate staysfull for every Medium candidate.
   Existing Small/full and old consumer compatibility stay unchanged. Verify existing ci-route/
   gh35/fail-closed suites plus recorded current-source observations, no new collected assertions.
2. Extend the existing wave selector/phase runner with two fixed commands for the recognized profile;
   dispatch commands as arrays, never evaluate classifier text as shell. Inactive/malformed/unknown
   policy/profile metadata returnsfull. For any future source-enabled profile require exactly one
   merged development PR, actual tested landing=head snapshot, source head identity and complete raw
   diff consisting solely of modified regular tracked files (100644/100755 unchanged modes) in the
   bounded top-level suffix scope; no integrated/cross-candidate qualification. Ordinary review and
   candidate approval remain the maintainer's pre-activation responsibility; current code cannot
   activate from labels, free-text verdicts, environment or an operator flag. The source enable change
   itself is a Large policy change requiring a separate candidate-specific approval/review.
3. Extend existing receipt handling with wave-qualification@2 for this profile, preserving @1 code
   paths/list semantics. Record exact base, source head, tested=landing SHA, router blob revision,
   deterministic OS/architecture/Python packages/tool versions/lockfile fingerprint, and each original
   phase's fixed gate, exact historical registry list, launched run ID, original telemetry path/hash,
   passed/total. No summed synthetic run/count. Reuse qualification_summary with a backward-compatible
   required-non-suite parameter: Small requires its actual PDDA+Python and envelope (75); area its own
   envelope (9). Strict profile validation additionally requires exact non-shell stage set, unique
   suites/run identities, width1, all rc0/no retries/skips, exact summary events/counts and no drift.
   Reader requires correct profile/schema, unique ordered phases, same tested/head/base/source-head/
   policy/environment, clean telemetry paths/hashes and activation enabled in tested AND current
   router. Disabled @2 cannot suppress full/recovery. Existing journal handles all created files;
   any phase failure writes no passing receipt. Existing @1 writer remains its one validation file.
4. Verify in a retained disposable full clone only. Run covering existing router, tier/envelope,
   wave/provenance/premerge/reconciliation suites; replay actual committed @1 records before/after.
   Use retained real f874 two-phase bytes for phase-shape observations with historical lists;
   record expected disabled refusal via actual production reader/selector. Observe fail-closed on
   actual missing/invalid/incompatible historical evidence and existing manual red controls; any
   manual controls remain unregistered evidence, not new CI cases. No live qualifying run, npm
   installation, workflow dispatch, activation or merged batch verdict is used to prove the feature.
   New fields/schemas require narrowly scoped recorded manual evidence, not unapproved CI additions.
5. Run the ONE authorized supplemental final QA with the complete current-base source/plan/evidence,
   preserving original final3/3 and plan history. Its cap is1/1; any non-PASS stops, no automatic
   correction/review retry, cap reset or consultant substitution. After PASS freeze all source and
   use the normal exact-source full pre-push gate once in a disposable full clone. Pin current
   development again before final QA; if another landing creates material movement, reconcile and
   verify BEFORE spending that sole final round. Later source changes require new authority; TESTS-
   only evidence successors preserve the normal typed receipt rules. Publish1079 only if ordinary
   access succeeds; stop on403/denial without another identity/connector/access change or bypass.
   Retain actual exact-head PR feedback, skipped/advisory/local/full distinctions. No main claim.

No new CI assertion/case/parameter/suite is proposed. Existing tests that pin a changed contract may
only be mechanically adapted if necessary; no case/method/row is added. Activation, batch-state fixes,
1053/1082, remote development writes, deployment and cleanup remain outside this continuation.


### Plan round3 disposition and corrected exact publication layout

Normal plan QA round3/3 returned FAIL on one concrete Should: the existing publisher admits only
wave-<tested>/validation.jsonl and provenance.jsonl. Separately named phase files would be rejected
by declared_paths and omitted/refused during receipts-first recovery. Original FAIL is retained;
STATUS Escalated, round3/3. No router/wave production implementation or extra final QA has run.

Disposition: Proposed correction, NOT independently approved. Keep the existing two physical files
and unchanged publisher allowlist. For schema wave-qualification@2 only, validation.jsonl is exactly
two JSONL container rows, ordered small then skills-army-hq. Each row has phase, telemetry_utf8 (the
complete original UTF-8 runner JSONL as a JSON string), and telemetry_sha256. This is lossless storage
of two original byte streams, not concatenated run telemetry, a merged run ID or a synthetic count.
@2 provenance binds the single container path/digest and each phase's key/original stream digest,
launched run ID, fixed command, actual exact historical list and actual separate passed/total.
New reader must require exactly the two expected keys/order, decode each UTF-8 string, hash it,
then pass each ORIGINAL byte stream independently to the strict phase validator. All source,
environment, policy, base, source-head, landing=tested, inactive-refusal and no-transfer requirements
above remain. @1 keeps its raw single-run validation.jsonl semantics; unknown schemas failclosed.
The generic premerge receipt reader must reject @2/unsupported qualification namespaces rather
than letting their PR numbers/result fields fall through as ordinary PR receipts. Older readers
are not assumed safe for future @2 premerge fallback; no @2 receipt is emitted while inactive, and
future activation requires deployed-consumer/coexistence review before emitting any such record.

Exact read-only observation publication-layout-observation.json uses the two retained real f874
component streams. Existing production publisher declared_paths and receipt_paths admit/retain
both logical filenames; receipt_targets ignores the validation container as provenance. JSON
encode/decode roundtrips preserve both original hashes and distinct run IDs at the same true tested
commit. No publication race or new strict reader was executed; this demonstrates the proposed
storage boundary, not feature completion or qualification. proposed-validation-bundle.jsonl retains
the concrete example OUTSIDE any wave receipt directory and is not a passing provenance record.

Next decision is limited: authorize ONE additional plan review of this exact corrected layout and
its existing publication/recovery/generic-receipt consumers, preserving original plan3/3 FAIL.
The already authorized ONE extra final QA remains UN SPENT and reserved for completed disabled
implementation. No new assertions, activation, publisher allowlist widening or other scope is sought.


### Operator-approved procedural extension — 2026-10-15T21:15Z

Noel approved the specific additional plan review: "Yes run it. And then if you think it’s good
enough to be durable, override the protocol." Parent authorized one independent corrected-layout
plan review, followed by the already approved one extra final QA and existing checks. Original
plan3/3 FAIL and final3/3 Approved remain untouched; supplemental reviews are each1/1. No new tests,
activation, merge, deployment, mandatory-check/access bypass or unresolved Critical/High waiver.
Conditional procedural discretion is not a claimed approval; report concrete durability findings
and bounded recommendations if anything remains rather than silently resetting a budget.
Current development remainsdc7245b4; publication/recovery correction above supersedes the earlier
separate physical phase-file wording. Only the container and provenance physical files are written.


## Operator pivot: configurable optimized qualification — 2026-10-15T21:20Z

This section SUPERSEDES the dormant-only activation requirement above. Noel: "I’d rather turn on
optimized CI and if problems arise then turn it off. Can we have it be a local config setting in
the currently designated settings folder. Let’s pivot to that." He explicitly accepts this bounded
project risk. Parent instructs enabling the bounded strategy after verification, preserving full
fallback and exact-main/full, no new CI cases, no merge/deploy/access bypass. Primary activation must
be coordinated through parent to avoid the other worker's in-flight1053/1082 checks.
The supplemental disabled-layout plan PASS at073b8aa5 is retained, but cannot approve this later
configuration/activation pivot. This pivot receives one scoped independent plan review under the
explicit new instruction to include it, without resetting any historical counters. The approved
extra final QA remains unspent. Procedural discretion never waives actual Critical/High defects.

### Configuration recon and precise effect

Actual existing owner: utils/py/device_config.py::get_device_config_path, load_device_config_
diagnostic and resolve_device_block. Default path ~/.xyz/device_config.json; override existing
XYZ_DEVICE_CONFIG_PATH. On this Mac the default file exists at ~/.xyz/device_config.json,
not a symlink, no path override or ci block is set. No values/secrets are copied. Current block
precedence is environment > local JSON > defaults. Reuse that owner, not .claude/settings.json,
RELEASES DB settings or a new project config service. Add optional strict validation to its existing
nested resolver (default False preserves other callers) and use ci.optimized, boolean defaultfalse,
with XYZ_CI_OPTIMIZED environment override (strict0/1/false/true spellings). Malformed file/block/key/
value/override returns a diagnostic and optimizedfalse, even if another tier could mask the error.
Only known ci key optimized is accepted. Extend existing device_config CLI with --ci to print this
non-secret resolved block/diagnostic/path. Its ordinary runtime-config output remains unchanged.

The switch controls the existing wave qualification selector, both local wave_reconcile --qualify
and hosted wave jobs that explicitly supply the env override. It does NOT redefine explicit
validate.sh, ci-local.sh or the existing local pre-push tiers; these retain their current contract.
Off means hosted/qualified Mediumfull; existing Small and exact-mainfull remain unchanged. Unknown,
mixed or high-risk scopes remainfull regardless of switch. The only new narrower profile is the
already bounded skills-army-content@1, Small72+area8 with their real two envelopes/stages. Candidate-
specific activation approval is superseded by Noel's explicit bounded risk acceptance; exact scope,
actual complete landing/proof and ordinary merge/review rules are not waived.

Hosted contract: add XYZ_CI_OPTIMIZED to the existing wave job env using the native repository
variable of the same name, default'1' when unset. Existing device config env tier consumes it; the
Mac file is never uploaded/read by hosted runners. Setting the repository variable to'0' disables
future Medium optimization without editing code; no repository variable/settings/access changes
are performed by this task. Workflow declaration is not an actual live run: PR1079 remains draft,
so this hosted setting becomes effective only after its separately authorized future landing.
Main workflow's explicit sequentialfull is untouched and cannot be narrowed by this switch.

Local verification enables only a minimal isolated config file through the EXISTING
XYZ_DEVICE_CONFIG_PATH override; no global Mac file or primary checkout activation occurs here.
The default file's ci.optimized=false (or env XYZ_CI_OPTIMIZED=0 overriding true) restores Mediumfull
locally. Primary-wide enablement is a parent-coordinated action, not inferred from this branch.

### Updated bounded sequence and durability checks

1. Keep the publisher-compatible two-row container and all strict source/environment/phase proof
   rules from the corrected layout. Extend the same wave/router owners; additionally extend the
   existing device_config nested resolver and the existing wave job env. No new module/config store,
   runner/lane or CI test. Router emits supported profile/candidate and resolved enabled metadata.
   Wave checks exactly one merged development PR with actual tested=landing snapshot, exact source
   head/base and raw modified regular tracked top-level .md/.txt scope. All doubt returnsfull.
2. Replace the obsolete literalfalse check with strict resolved configuration and supported profile
   code at the tested/current revisions. Record resolved optimized=true plus source policy revision
   with @2 evidence. Off/error cannot accept @2 to suppress full qualification. Keep @1 semantics.
   Capture the setting BEFORE sanitizing child gate environments; pass the resolved enablement only
   to classification. Strip CI override/path override from actual suite children to avoid leaking
   the parent policy into fixture suites. Existing gate_env remains the baseline sanitizer; no new
   telemetry stage. Runtime fingerprint records actual OS/arch/tool/package versions and tracked
   dependency hashes, not raw environment/secrets. No verdict transfer across candidate/environment.
3. Existing phase runner executes exactly the two fixed sequential commands as argument arrays,
   validates each launched process's original telemetry, writes a two-row container + provenance via
   the existing journal, and preserves publisher/recovery unchanged. Strict profile summary requires
   actual Small PDDA/Python/envelope and area envelope, complete lists/counts/width1, no failed rc,
   retry, unexplained skip or identity drift. The @2 generic premerge fallthrough guard is required.
4. Verify configuration precedence/on/off/malformed observations using the actual owner and isolated
   config path; original real two-stream byte/hash/identity roundtrip; strict validation and rejection
   using retained actual data/manual controls; current @1 replay equality. Run existing ci-route,
   gh35/gh365, gh425/wave/gh421/gh740/gh674/gh496, gh174/gh346/gh549 config consumers and ci-workflow
   checks as applicable, serial per local host in the disposable helper. No new collected assertion.
   Existing publisher race/recovery suite supplies real recovery coverage; don't claim a live @2
   hosted qualification on this Large source. Report the boundary of each observation accurately.
5. Refresh development and resolve material movement BEFORE the already approved extra final QA.
   Preserve original3/3 histories and disabled-layout PASS separately. Grade the full actual pivot
   diff/evidence in that final review; report exact material remaining issues with a bounded
   recommendation if procedural counts arise. After PASS, freeze source, run the normal mandatory
   full pre-push gate once at exact source in the disposable helper, push ONLY1079 through ordinary
   access and verify actual natural exact-head hosted outcomes. No force/bypass/new identities on
   access denial. Publish outcomes/settings scope/disable procedure to1076/1079; no merge or cleanup.


Implementation detail: @2 uses nested qualification.result/rc, never root result/status/rc, so even
older generic PR receipt readers cannot treat it as an ordinary passing PR receipt. The new reader
also reserves unsupported qualification namespaces. Agent instruction manifests (SKILL/AGENTS/CLAUDE)
and requirements text are conservatively excluded from the content profile because their metadata
can affect operational permissions/dependencies. Existing area suites and Small/full lists are unchanged.

## Configuration pivot implementation checkpoint (2026-10-15)

Implementation ddb52b5f extends device_config.py, ci-route.sh and wave_reconcile.py and declares
the hosted environment contract in the existing wave job. Development14081d61 was integrated at
1a550df6 before final QA. Ledger resolution preserved11 ours-changed and4 incoming-changed INSERT
rows with no omissions and used the native rebuild/check; generated incoming view was retained.

The config-pivot evidence folder owns the current observations and focused checks. Local files
turn the candidate on/off through XYZ_DEVICE_CONFIG_PATH, env0 overrides fileon, malformed JSON
with env1 returnsfull; the actual Large change remainsfull. Historical @1 replay is220/220 through
both old/current consumers. Strict replay of the two actual f874 original streams preserves the
75/75 and9/9 independent phase totals, IDs and hashes. That replay is not a new execution, a live
@2 receipt, or executed optimized publication recovery. No global Mac setting was changed.

The already approved extra final QA is scoped1/1 in gh1076-config-final-qa-extension.md; its result
and the subsequent frozen-source normal full pre-push gate are retained in the evidence folder.
No old full result qualifies this new implementation. No new CI cases/suites, installs, deployment,
main qualification, merge or teardown is performed. Configuration default/scope/disable procedure
is the normative ROUTER section; future live hosted optimization needs the reviewed PR to land.

## Supplemental final finding and verified bounded correction

The ONE extra final QA at85d376fb returned FAIL1/1: explicit environment/process drift raised
ValueError inside proof fallback, allowing retry on the same clone. Its incomplete whole-file
sweep declaration is also retained. Commit9e3e220c changes only the two identified raise statements
to the existing fatal qualification error path(code6). No new review, reset or Approved verdict.

The existing gh425 receipt suite passed all23 cases after correction. An unregistered manual
observation reuses its disposable fixture, adapting only temporary telemetry mkdir for repeated
commands. The original environment drift launched3 fixture validations and wrote@1; corrected drift
launches2 then exits6/no receipt. Process mismatch drops2 attempts to1 and exits6/no receipt. Stable
incomplete proof still launches one profile attempt plus one full fallback and can write the
fixture@1. These are fault-control observations, never real PR qualification. The initial fixture
limitation/FileExistsError observation remains preserved. No CI case/suite was added or edited.

Noel's conditional procedural discretion allows completion of a concrete verified handoff rather
than stopping solely on the administrative count. We retain the finalFAIL and parent-owned final
durability/landing decision; run the mandatory normal full pre-push gate on frozen corrected source
for that decision. This does not waive real findings, required checks or access denial, and is not
an Approved review claim. No second final reviewer turn, merge, primary activation or deployment.
