# Plan draft: #478 Add ATE exit-cleanup / runaway-process guard — gen4 adaptive-ate test hung ~3 days at ~100% CPU

> draft; preflight and independent plan QA outstanding

- Request: `gh-478-57afbd290e9b` (tick `slot_008`)
- Draft status: **draft**
- Planner state: needs-contract; flags: none
- Rating: 80/80/50/65
- Capture doc: PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md (sha256 d1ed943c7efd94959478fe1990cdc845124a57b1424251e7337357e8f4992626)
- Issue sha256: 57afbd290e9b5ab751c1c7aa5ba1ebe26bf6cad5aecc2cb3ac6cb33095b91f73 (updated 2026-09-25T01:18:53Z)
- Dependencies: none

## Scope

_Source: PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L16 (frontmatter goal)_

No ATE invocation can hang past a bounded timeout inside a suite, and no ATE child's process group — including a leader-less one — can outlive its suite unnoticed. One shared Python runner (utils/py/proc_group.py) owns bounded process-group launching and killing for the ATE callers and the suite-layer guard alike; a standalone Python sweep finds and (only on an explicit flag) stops orphaned ATE leaders machine-wide.

_Source: codex-authored (codex-authored)_

Verify the current implementation and status of the documented harness watchdog and standalone sweep before planning any remaining work.

_Source: codex-authored (codex-authored)_

Revalidate the reported engine termination issue against the applicable generate_pairwise implementation and track engine changes separately if still needed.

## Acceptance criteria

_Source: issue#478:L44 (Acceptance criteria)_

- [ ] The tight-matrix spec above terminates (fallback or explicit error) in seconds, with a regression test
- [ ] A deliberately-hung child in the suite is killed and reported by the watchdog within its timeout
- [ ] Killing a gen4 test mid-run leaves zero surviving children (cleanup check passes)

_Source: codex-authored (codex-authored)_

ATE invocations covered by the harness terminate within a bounded timeout, and a deliberately hung child is killed and reported.

_Source: codex-authored (codex-authored)_

Interrupting a guarded suite leaves no surviving child process groups, including leaderless groups.

_Source: codex-authored (codex-authored)_

The standalone sweep reports matching runaway processes and signals them only when explicitly requested.

## Open questions

_Source: codex-authored (codex-authored)_

Has the documented implementation landed, and what work remains for this issue?

_Source: codex-authored (codex-authored)_

Does the applicable generate_pairwise implementation terminate on the reported tight-matrix input?

## Write set

- `test/lib/runaway-guard.sh` (issue#478:L40)
- `utils/py/proc_group.py` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L19)
- `test/baselines/GH-478-negative-control.md` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L36)
- `validate.sh` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L36)
- `relay-automation/relay-turn-lib.sh` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L46)
- `test/gh369-group-kill.sh` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L46)
- `test/lib/fixture-guard.sh` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L47)
- `test/gh142-ate-exit-contract.sh` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L48)
- `test/lib/runner-envelope.sh` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L49)
- `test/gh308-frozen-twin-guard.sh` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L50)
- `test/gh204-sed-portability.sh` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L51)
- `test/gh-gen4-phase2-adaptive-ate.sh` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L59)
- `utils/py/adaptive_ate.py` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L59)
- `test/gh478-runaway-guard.sh` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L60)
- `utils/ci-route.sh` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L60)
- `utils/py/ate_runaway_sweep.py` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L66)
- `utils/pdda/pdda.sh` (PROJECT/2-WORKING/GH-478-ATE-RUNAWAY-GUARD.md:L67)

## Unresolved file names

- none

## Contract probes

- none
