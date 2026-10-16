# GH1076 configuration pivot — supplemental final implementation QA

Noel authorized ONE extra final QA and then explicitly superseded dormant-only activation with the
local on/off configuration pivot, including it in the new plan review. This is that single extra
final review, cap1/1; original plan3/3 FAIL, final3/3 PASS and both scoped supplemental plan PASSes
remain intact. Do not reset, repeat, merge, deploy, install or alter access. No new CI tests/cases.
The configuration plan review is `gh1076-config-pivot-plan-qa.md`, Approved1/1 at2c40a76f. The complete
canonical plan is PROJECT/2-WORKING/GH-1076-CI-POLICY.md; its latest pivot supersedes dormant-only scope.

Review the complete current PR diff against origin/development, not only the latest commit, and
sweep each touched source/doc file. Primary runtime files: utils/ci-route.sh,
utils/py/wave_reconcile.py, utils/py/device_config.py, .github/workflows/wave-reconcile.yml. Read
actual consumers/publisher/runner seams to establish the contracts. Assess the existing Small
policy, area consumer coverage fixes, generic receipt hardening and the new narrow content profile
as one implementation. Scope includes pre-existing concrete defects in touched files.

Definition of done for this review: no unresolved material correctness/contract defect; existing
configuration owner/path/precedence/default retained with optional strict ci resolution; on/off/error
behavior as documented; high-risk/Large/mixed/unknown changes remain full; exact-main macOS/full
unchanged; only one complete merged development PR at its true tested landing can select profile;
source/base/policy/config/runtime/registry/process identity and separate actual Small+area phases
bound; original phase bytes/hashes/counts retained in the existing two-file publisher layout;
failures/identity drift stop, proof insufficiency gets bounded full fallback; @1 compatibility and
legacy generic premerge namespace safety preserved. Accepted selective-testing risk alone is not
a blocker. No generic batch cache, new registry/module/runner/lane/test or protocol bypass.

Local setting owner is device_config.py, default ~/.xyz/device_config.json, nested ci.optimized
boolean, library defaultfalse; existing XYZ_DEVICE_CONFIG_PATH redirects only isolated verification;
XYZ_CI_OPTIMIZED overrides file. Primary global config was not edited. Hosted workflow explicitly
provides XYZ_CI_OPTIMIZED from vars or '1'; repo var '0' disables future hosted optimization. A Mac
file never changes hosted config; workflow is not live until separately authorized landing. Local
pre-push/explicit validate/ci-local selection stays unchanged. No main qualification claim.

Evidence: TESTS-RESULTS/2026-10-15+GH-1076/config-pivot/ contains current focused existing-check
results, unregistered on/off/env/malformed controls, actual historical two-phase strict replay,
old/current committed @1 replay and current-base ledger preservation. Older evidence is historical
only. f874 Small75/75 and area9/9 are distinct real original runs, not current execution or an @2
qualification. Current PR is Large and must get full. No eligible post-policy merged source exists
here for a live @2 writer run; do not fabricate one or infer production race recovery from a pure
publisher-layout probe. Existing publisher/reconciliation suites cover their existing behavior.

The frozen-source normal full pre-push gate happens AFTER this review per start-task; no current
full PASS is claimed yet. Review may approve source for that gate while identifying bounded live
rollout limitations honestly. Read-only inspection/probes only in relay worktree; do not execute
validate.sh, test/*.sh, pytest, fixtures, npmci or Git commands there. Scratch only .relay-scratch/.
Append only the relay. For material findings retain actual input, scope, falsifier and concrete
bounded correction; distinguish missing evidence from an observed defect. Exact-base is recorded
in config-pivot/base-ledger-preservation.json and the merge commits. Independent reviewer should
not activate primary settings, touch other coordinators or perform a remote write.
