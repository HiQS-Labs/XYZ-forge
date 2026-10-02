# Recon Map — existence and gate scope of four failed checks

Source: frozen development landing 9ecb344f126c613d7fcc8a0f5d22145a954c6d31. GitHub refreshed in this assessment: development 1b40d57c36c70eb045341ec95403de93ba056b92; compare shows one reconciliation commit, no examined runtime/test changes. This is a bounded operator-requested value assessment, not the October 8 full-suite audit. No tests or gates launched, no source changes made.

## Triangulate card
SUBJECT: whether four failed checks justify blocking relay, consult, and marathon work.
CELL: reversible x crossing -> recon-lite + falsify. Registry removal is reversible; it reduces coverage across landings and must remain explicit. No authority or runtime-state migration proposed.
GROUND: main lane traced completion telemetry and ATE oracles; two read-only lanes traced live relay and installation registry consumers. Graph Verify project Users-noelsaw-Documents-GH-Repos-XYZ-forge generation2026-09-30T07:57:23Z; graph was a lead, frozen source confirmed material claims. Coverage no recorded gaps for main paths; vendor line285 parse gap read by registry lane. Graph omissions for nested Python emitters required source fallback.
FALSIFY: 'all four are core workflow correctness checks' disproved by real consumers. 'All are useless invented tests' also disproved: one real model compatibility exercise, a demonstrated completion lost-update, real registry consumers, and a real optional Gen4 campaign consumer exist.
SMALLEST: retain valuable scoped coverage; stop equating full-registry membership with product severity. No replacement framework or new tests.
UNKNOWNS: exact historical relay exit6, missing registry writer outcome, and zero-state changed path/holder remain unknown. No claim they are harmless; unknown attribution does not establish critical-path importance.

## 1. relay-self-sufficiency.sh
- Source test/relay-self-sufficiency.sh:4-18,95-156; test/fixtures/minimal-relay.md:8-38.
- One real agy/Codex leaf-shim turn on a fixed tiny fixture, RELAY_WORKTREE_ISOLATION=0. Not the generated scaffold, relay supervisor, consult orchestration, or marathon sequencing/recovery.
- Unique value: real installed CLI/model follows the turn prompt. Deterministic stub suites cannot substitute completely for this live compatibility observation.
- Weakness: assertion A seeds release away from claude-a at106-108, then tests claimer !=claude-a at146-149. This does not independently prove a correct claim/release cycle. No mutation experiment was run here; direct logic finding.
- Existing behavioral coverage: test/agy-turn.sh:111-156 (good turn, containment, committed off-lane edits, spaces, empty output); test/codex-turn.sh:84-126 (token commands, peer handoff, ownership refusal, containment); test/consult.sh:50-95 (WIP preservation, advisor containment, cleanup, partial/all failures).
- Policy: relay-automation/README.md:45-71 and source header: four normal wrappers default-skip; changed shims/shared prompt/fixture owe recorded live evidence. Direct validate does not inherit the wrapper default.
- Verdict: existence justified as targeted live compatibility check. Universal blocker not justified. Preserve meaningful containment and attestation checks; do not call exit6 an off-lane edit without its guard evidence.

## 2. xyz-completion.sh
- test/xyz-completion.sh:1-12,146-197 tests real completion writer concurrent atomic record preservation. Sixteen successful writers/15 records led to controlled stale-lock successor deletion repro and repair #909/#910.
- Real callers: utils/py/relay_drive.py:489-504 and utils/py/marathon_drive.py:1323-1335. Emitters invoke subprocess and do not use its return code to decide approval/advancement. Relay successful terminal status is bound to attestation before emit at734-754; marathon bind_candidate and durable approval fields precede emit at2710-2738.
- relay-automation/README.md:146-186 defines XYZ.json as human-facing completion telemetry. Tick events/attestation/gate receipts are separate state. Consult source has no direct writer reference in the examined entry point.
- Harm: missing completion history/status reporting, not demonstrated source-code loss or lost approval state. Important data-integrity defect, not a proven execution-critical outage. Fixed already.
- Existing related suite gh358-lock-instrumentation tests instrumentation/budgets; it is not a replacement for this actual concurrent writer assertion.
- Verdict: keep regression coverage; strong existence justification. Prioritize it for telemetry/shared writer changes. No basis to delete a useful deterministic check merely because it exposed a real defect.

## 3. registry-lock-concurrency.sh
- test/registry-lock-concurrency.sh:20-55 launches16 concurrent install.sh calls twice, not relay turns. Stdout/stderr discarded; waits ignored. Missing row alone cannot distinguish process failure, permitted lock timeout, or lost update.
- install.sh:192-208,297-333: registry best effort, --no-register supported, lock timeout may skip registration while install remains usable.
- Consumers: relay-automation/xyz-sync.sh:167-204 bulk update selection; marathon-ls.sh:174-200 cross-repo listing; utils/collect-relay-system.sh:49-86 aggregation; utils/hq/hq-lib.sh:243-263 lookup plus filesystem fallback.
- Runtime location: skills/1-hourly/relay-xyz/find-harness.sh:120-181 resolves explicit/local/self paths; start-marathon skill135-153 uses it; consult skill46-65 uses git root/local .xyz. These paths do not require a registry row.
- Loss can hide an install from future updates, an operational risk. It does not directly corrupt or halt an in-flight marathon.
- Modern xyz-vendor.sh:396-419 is a separate writer, not exercised by this test. test/xyz-vendor.sh:98,277-282,341 has registration/idempotence/no-register/removal but not concurrent coverage.
- Verdict: legitimate installer stress check, low routine workflow priority. Retain targeted/manual coverage; recommend removing universal blocker role under existing non-Small policy. Reduced concurrency coverage must be disclosed.
- Historical GH72 citation belongs to migrated numbering; current public #72 is unrelated. Original red receipt not recovered; do not fabricate a current issue link.

## 4. gh-gen4-phase1-domain-oracles.sh
- test/gh-gen4-phase1-domain-oracles.sh:30-40 invokes embedded module self-tests,53-131 repeats positive/negative CLI controls,152-156 checks validate --print-mode against shared ROOT while discarding stdout/stderr.
- Crash recovery uses test-written holder.py/recover_good.py/recover_naive.py (105-129), not marathon recovery. Passing this proves an oracle distinguishes synthetic examples, not that a marathon recovers correctly.
- utils/py/domain_oracles.py:203-232 before/after tree digest + handle scan does not attribute concurrent activity. Its body run_suite446-531 separately repeats toy +/- examples. The last real-root assertion can be affected by other suites; exact historical failure remains unknown.
- Real consumer utils/py/gen4_campaign.py:46 imports host_identity;72 fuzzes the oracle CLI. This is Gen4 tooling, not relay/consult/marathon entry-point enforcement. Main ATE skill invokes run_variations.py; #909 evidence uses ate_variations, not this oracle as acceptance.
- The shared Python module must not be deleted just to retire the gate suite: campaign depends on it.
- Verdict: optional ATE-tooling self-test earns targeted coverage, not a universal release block. Recommend unregister/exempt this non-Small flaky suite while retaining its file/module. Loss of CLI self-test coverage on unrelated changes is explicit, not a claim other tests are identical.

## Measured cost and priority limits
Accepted local development run at57bd97af had durations: completion7.134s, registry2.892s, live relay57.030s, domain oracle7.862s (existing committed provenance5b4c6e2a). These are overlapping worker durations, not additive wall-time savings or current benchmarks. Main problem is false/opaque blocking and repeated full-run investigations, not these four suites monopolizing execution time.
All four absent from SUBSYSTEM_TESTS_small at utils/ci-route.sh:38. Telemetry and ATE suites are separately in focused subsystem lists at27-28. Small membership is policy classification, not itself proof of importance. Medium/Large hosted qualification still runs full registry; this assessment does not silently change that contract or reinterpret old failures as clean.

## Recommendation and boundary
One directly samples live core behavior, one protects supporting completion telemetry, two protect secondary installation/ATE tooling. None of the four observations establishes an unresolved current corruption of code, approval, or marathon resume state. The evidence does not rule such defects out; the priority burden is unmet.
Preserve core worktree/allowlist safety, token ownership, attestation-to-commit binding, pause/resume and failure escalation coverage. Use existing scoped suites and representative skill-driven work. No wholesale rewrite, new gate machinery, or broad automatic audit. Narrow registry changes need their normal review/evidence; no test registration changed in this assessment.
