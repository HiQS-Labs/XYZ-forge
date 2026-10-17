# Recon Map — GH-1100 Jog dispatch roots

Commit: ccb900746c5c2d011522299246f111ce0a49db0f · Mode: graph + direct source · Lanes A–D bounded in the main context.

## Subject and change class
Local correction to Jog's existing Marathon invocation adapter, with containment implications.

## Seams and call paths
- `utils/py/jog_run.py:1741` (`jog_run_main`) and `:863` (retry-build) call `run_marathon_phase` at :514. It chooses local preflight and pins SWARM_PREFLIGHT_ROOT, loads the packet, applies `_marathon_argv_from_invocation` at :577 and dispatches at :608.
- Gate retry at :743 loads the same stored packet and uses the same argv adapter at :792, then dispatches at :802. Both paths merge packet env over ambient env.
- `utils/py/swarm_preflight.py:1085` builds the invocation; :1110 omits target-root when target and root match. The structured target_root and harness_root remain explicit.
- `utils/py/harness_paths.py:31` resolves harness_home, preferring XYZ_HARNESS over a non-vendored script location; repo_root at :83 follows it. Vendored .xyz script location wins over ambient env.
- `utils/py/marathon_drive.py:1121` resolves harness tooling and root; MARATHON_ROOT overrides repo_root. Phase directories default under root at :1368; branch/artifact work uses target_root or root. Explicit target alone does not pin coordination/phase output.

## State, contracts and downstream checks
Invocation@1 is read through load_marathon_invocation; argv[0] must be an absolute executable, harness_root/target_root existing directories. `harness_home` is emitted but not required by the loader. Deriving the selected harness as the parent of relay-automation from validated argv[0] avoids a new required field. Preserve lexical .xyz paths.
The existing Marathon parser accepts --target-root; this constrains the code repo. Its existing MARATHON_ROOT and XYZ_HARNESS inputs select coordination root and tools. No new flags, schema, writer or state values are needed. Results remain owned by Marathon and projected by Jog. Retry-build enters the run path; gate retry reuses its stored packet and must receive identical root policy. No new retry loop is introduced.

## Build, failure, rollback
Existing `test/gh280-jog-marathon-adapter.sh` covers root and vendored dispatch plus retries. Its parse gap at :628–629 was read directly. `utils/ci-route.sh` classifies jog_run.py as full gate. Mutation-heavy suites run in a separate full clone; identity is compared before/after.
Rollback is a code revert before dispatch; no schema/data migration. No actual builder is launched against the primary during reproduction.

## Evidence and limitations
Graph project XYZ-forge generation 2026-09-01T15:54:30Z is stale: search/trace used as leads, all material edges read from current clone. Bounded Verify tier, no exhaustive graph claim. `TESTS-RESULTS/2026-10-16+GH-1100/red-control.txt` records an intercepted real run_marathon_phase dispatch: cwd task clone, argv missing target-root, env/resolver selecting primary. Subprocess/state writes mocked to prevent the incident.
Prior-art #1099 is already in base; #1100 explicitly reports the residual failure after it. No duplicate implementation intake created. Broader caller populations and external installations were not audited.

## Current-state radius
Jog run/retry-build/retry-gate adapters, root/vendored preflight packets, Marathon tooling and phase/coordination root; no kernel, resolver precedence or standalone preflight behavior changes.
