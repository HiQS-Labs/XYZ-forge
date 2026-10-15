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
and its existing five suites. Existing PDDA metadata must remain true alongside this additive area.
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
first faulty metadata. No CI test/assertion/parameter/registry/workflow changed. Pinned full before
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
