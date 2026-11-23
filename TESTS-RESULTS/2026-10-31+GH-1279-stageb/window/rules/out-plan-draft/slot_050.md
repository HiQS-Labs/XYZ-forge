# Plan draft: #1280 ATE/fuzz the GH-1248 outer loop: smoke-first Mac Studio campaign

> draft; preflight and independent plan QA outstanding

- Request: `gh-1280-a0675a50f5b3` (tick `slot_050`)
- Draft status: **draft**
- Planner state: unregistered; flags: none
- Rating: none
- Capture doc: none (sha256 none)
- Issue sha256: a0675a50f5b3aaf5082533e0680c541ddea79fb9f251e777e6673fcbef170c8b (updated 2026-10-31T01:27:06Z)
- Dependencies: none

## Scope

_Source: issue#1280:L11 (Hypothesis and useful outcome)_

Existing ATE/Gen 4 machinery can find replayable robustness defects in the new outer-loop implementation that the recorded deterministic controls did not exercise, while preserving host/git identity and containing every effect to disposable state.

Useful outcomes include:

- a coverage map of CLI/input surfaces actually exercised;
- expected-refusal versus candidate-defect classifications with explicit denominators;
- semantically replayed counterexamples, or an honest zero-defect result;
- containment, idempotence, crash-recovery and process-cleanup evidence;
- a stop/go decision for a later stateful campaign or a separately approved fix.

A green campaign exit, elapsed time, mutation count, stderr hash or matching exit code alone is not success. No automatic repair, CI addition, issue filing, PR or production-readiness claim follows.

## Acceptance criteria

_Source: issue#1280:L113 (Acceptance criteria)_

- [ ] Exact source, target, fixture, seed/corpus, environment and driver identities were recorded; telemetry proves relevant outer-loop invocations.
- [ ] Smoke controls, including a witnessed negative control and cleanup, passed before the long window; the `relay-xyz` Codex contract review is recorded.
- [ ] Discovery stayed within all time/mutation/batch/corpus/timeout bounds and stopped at the declared no-new-signal limit or earlier safety stop.
- [ ] Host/git/ledger identity and canaries are unchanged; no unauthorized write or surviving descendant process exists.
- [ ] Expected refusals are separated from candidate defects, and every candidate has a semantic replay and accountable disposition with clean/failing controls.
- [ ] Stateful coverage is claimed only where reset, operation sequence and semantic predicate were actually exercised; generic CLI fuzzing is not mislabelled as state-machine proof.
- [ ] No synthesis, healing, model-per-mutant, automatic filing, production execution, commit or push occurred.
- [ ] The report includes exercised/excluded coverage and actual budgets; every cited result has committed `provenance.jsonl`.

## Open questions

_missing_

## Write set

- `utils/py/fuzz_engine.py` (issue#1280:L27)
- `utils/py/adaptive_ate.py` (issue#1280:L28)
- `utils/ate/scripts/run_variations.py` (issue#1280:L29)
- `utils/py/domain_oracles.py` (issue#1280:L30)
- `utils/py/gen4_campaign.py` (issue#1280:L31)
- `skills/4-occasional/ate/SKILL.md` (issue#1280:L33)
- `skills/4-occasional/defect-campaign/SKILL.md` (issue#1280:L33)
- `utils/py/self_healer.py` (issue#1280:L35)
- `utils/ate/scripts/compile_issue.py` (issue#1280:L52)
- `validate.sh` (issue#1280:L53)
- `ci-local.sh` (issue#1280:L53)
- `utils/py/harness.py` (issue#1280:L65)

## Unresolved file names

- `find-harness.sh` (issue#1280:L46; 2 tracked files share this name)

## Contract probes

- none
