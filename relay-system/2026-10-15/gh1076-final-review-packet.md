# GH1076 final implementation QA

Review the completed coverage-preserving policy/consumer implementation, not a claim that all
umbrella rollout criteria have passed. Canonical plan: PROJECT/2-WORKING/GH-1076-CI-POLICY.md.
Integration base: 9061df4bb3530670f3a3ba2dcae322ae5082cf13 (PR1078 docs integrated).
Original spike/benchmark base: f974fcee15647aae6551fcc81b129f5a6127120b.

## Required scope

Read the complete changed utils/ci-route.sh and relevant selector/receipt consumers in
utils/py/wave_reconcile.py, all changed policy text (ROUTER.md, AGENTS.md, SOP.md,
docs/CI-CHURN-RECOVERY-SOP.md), canonical plan and CHANGELOG. Inspect the task diff against
9061df4b, existing callers in validate.sh, githooks/pre-push, hosted workflows and publisher.
Use whole-file review for the seeded packet and inspect source contexts for the actual runtime.
No linked-worktree suite execution or source/fixture writes: mutation-heavy verification belongs
in disposable full clones. Read existing tests and committed evidence; narrow nonmutating probes
are allowed. Write only the relay thread. No new CI cases/tests/assertions/parameters permitted.

## Acceptance map / falsifiers

1. Existing ci-route remains one executable selection owner. Versioned additive hosted_gate output
is consumed by existing wave selector using fixed Small/full commands. Unsupported/missing/duplicate/
malformed/inconsistent Small decisions fail full. Old @1 historical receipts/list reader remain
valid for historical recorded snapshots, not latest HEAD. Existing Medium and main/full unchanged.
2. Existing skills-army publisher text input is mapped before generic prose, reusing subsystem_of
and its existing suites (now eight after the bounded consumer audit below). Existing PDDA metadata must remain true alongside this additive area.
Unknown/shared/safety/full inputs remain conservative. No parallel runner/map/schema/CI machinery.
3. Canonical explanatory policy is ROUTER; AGENTS/SOP/churn point there. No expired batching
exception becomes authority. Local/self-check vs hosted development vs exact-main qualification,
PR smoke/advisory/skipped outcomes, receipt limitations and first failures remain explicit.
4. Full umbrella readiness is honestly scoped: completed policy/consumer correction and historical
study, explicit unmet reduced-Medium and batch evidence/dependency criteria. Do not demand unsupported
coverage reduction or speculative controllers to make an unchecked box green. No active GH1064
merge-batch implementation overlap; PR1069 ownership, GH1072/73 remain external to this diff.
5. Existing focused checks and manual observation/red-control evidence support actual runtime
changes. Review manually recorded unsupported-version red control and PDDA correction, retaining
first faulty metadata. No new CI test/assertion/parameter/workflow added. The existing area selection and one count expectation are adapted as described below. Pinned full before
and required final push-gate after are measurements, not new registered CI cases.
6. Persisted task rating75/45/50/40, exact accepted-start row and normal review cap preserved;
consult actual Claude completed / Agy timed out partial, no quorum or reset. Retained v1/v2 study
correctly distinguishes tested vs event/trigger identities, failed qualification vs publication.

## Evidence and pending gates

TESTS-RESULTS/2026-10-15+GH-1076 contains manual-policy-observations.json,
manual-pdda-preservation-correction.json, consult outputs/provenance/synthesis, historical study v1
and v2, task-rating-readback and calibration raw log/identity/telemetry. Calibration408/409 rc1
is NOT the matched baseline: my exported MAX_JOBS contaminated nested existing mode probes.
It remains retained, not converted to PASS. Corrected matched baseline uses normal balanced width4,
serial host gates; same effective existing full command for final push-gate measurement.
Focused verification at69567090 (same runtime as current; subsequent changes docs/evidence/ledger)
is retained separately. Required final full push gate remains owed after final review/source freeze;
do not assert it ran from declarations. No equivalent natural hosted baseline CI exists at f974;
no dispatch/rerun authorized. PR smoke will not prove full macOS/main qualification or savings.

## Operational envelope

Actual Mac Studio maintainer repo; surgical reversible existing two-file runtime extension plus
policy consolidation and existing governance/evidence. Grade against the stated requirements,
commensurate complexity and observed failures. No unrequested enterprise framework, test expansion,
security changes, live Marathon/Jog, installations, merge/deploy/protection changes. Findings need
concrete input, affected behavior, evidence/falsifier and severity. Unknowns stay unverified rather
than invented defects or approval. Review the whole packet and relevant source; report whether
scope/evidence is sufficient for a draft PR subject to the pending normal full push gate.


## Continuation: cumulative final Round 3/3, no budget reset

The original Round1 FAIL, Round2 PASS, attestation and completed execution token remain untouched.
The normal relay driver says a spent token needs a fresh execution token (utils/py/relay_drive.py:810).
RELAY-GH1076-FINAL-R3-20261015 is only an execution token for the ONE REMAINING final round3;
it does not grant three more rounds. Review once. On failure or incomplete review, stop at the
original cap and report the remaining blocker; do not reset, force, extend, or retry the review.

Read the entire packet and current relevant source plus continuation evidence. Source f874fa8d
adds three already-existing consumer suites to SUBSYSTEM_TESTS_skills_army_hq (5 to8): gh660
executes the canonical drift checker called by sync.py; path-integrity reads all skill Markdown
links; gh788 scans all skill content for interpreter examples. The prior78 proposal omitted the
latter two. Small72 plus area8 now projects80 distinct shell suites; full406 and Small72 registries
are unchanged. test/ci-route.sh changes ONLY its existing count expectation5 to8 and existing label.
No new assertion/condition/method/fixture/row/parameter is introduced. ROUTER, CHANGELOG and the
canonical plan describe this coverage increase. Hosted Medium remains full; no new runner, lane,
receipt schema, Medium profile or activation exists. Review the actual diff rather than the old
Round2 statement that no tests or registry changed, which described the earlier snapshot.

TESTS-RESULTS/2026-10-15+GH-1076/phase3 contains the completed continuation proof:
- Consumer and reverse audits of all406 shell source bodies, exact source edges and exclusions.
- Historical attribution-v3: two actual single-member mapped Medium full409/409 passes, complete
  pending ranges and original logs; exact6-member Small75 omission with relevant source identical
  to the later known gh620 full-red mismatch, bounded inference only. Later seven-member recovery
  is one mixed Large snapshot. v1/v2 and original failures remain preserved.
- expected-selection-replay-v3 derives lists from the existing router and projects actual rows;
  all80 appear rc0 in both historical Medium full snapshots and the earlier local full. Filtered
  full rows omit actual tier2 PDDA and cannot become synthetic reduced qualification.
- historical-receipt-compatibility compares218 actual committed @1 records through baseline/current
  production readers, zero behavior differences; no generated fixtures or new collected cases.
- Current PR1069 source4691 remains separately owned: existing180-test gh436 PASS in a disposable
  full clone, unchanged identity; current production typed premerge receipt check fails. Three new
  assertions remain independently unadmitted; five removed test methods are no longer blockers.
  GH1072 whole-RMW-lock and GH1073/1075 repaired-scope/invalidation gaps are traced, not fixed here.
- Historical PR936 reconstructs a real approved human fold, original member heads/base/transformations,
  retained failed combined review, same candidate/landed tree and actual-landed hosted full413/413.
  This disproves a blanket dependency on mutable PR1069 state for a manual frozen fold.
- Protection API reports Branch not protected and empty effective rules/rulesets; policy still binds.
- READINESS-v3 and frozen-pilot-proposal-v3 give the exact feasible completion path: current queue
  has no evidenced ready approved coupled group. A named content-only coverage profile requires
  the separate qualifying-coverage choice expressly retained by GH1076; future existing-owner
  profile/phase-reader implementation is openly remaining, not claimed shipped or data-blocked.
  No blanket cap waiver or new CI case admission is inferred from the parent continuation.

consumer-focused.json/log records all SIX affected existing commands rc0 at f874, identical clone
head/status/refs/config before and after. The two existing sequential component commands are still
running serially in another disposable full clone; their actual outcomes will be retained separately
under TESTS only. They are not a new Medium gate and cannot substitute for the required final full.
The old local full at d1ca36b5 does NOT qualify f874's new source. A fresh normal exact-source full
push gate remains owed after this final approval and source freeze. The pinned clean f974 baseline
and earlier after are retained; no causal speedup or stable-main claim is permitted.

Reviewer: narrow nonmutating probes/source reads only, no suites or source edits in your linked
worktree. Sweep relevant pre-existing code as the relay contract requires; identify any concrete
new defect. Approval covers this safe coverage-preserving source and evidence for draft1079,
subject to fresh full and normal exact-head hosted feedback; it does not approve reduced Medium,
automatic batch authority, any merge/deployment, new CI cases, or umbrella closure.
