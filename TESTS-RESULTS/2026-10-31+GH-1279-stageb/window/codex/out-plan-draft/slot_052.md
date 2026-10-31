# Plan draft: #1280 ATE/fuzz the GH-1248 outer loop: smoke-first Mac Studio campaign

> draft; preflight and independent plan QA outstanding

- Request: `gh-1280-a0675a50f5b3` (tick `slot_052`)
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

_Source: codex-authored (codex-authored)_

Verify the current GH-1248 outer-loop implementation and existing ATE assets before planning a smoke-first campaign on the Mac Studio.

_Source: codex-authored (codex-authored)_

Plan a bounded smoke in disposable full clones and expendable scratch repositories, followed by a long window only if the smoke and independent review gates pass.

_Source: codex-authored (codex-authored)_

Plan semantic replay, candidate disposition, cleanup evidence, and a final report without automatic repair or filing.

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

_Source: codex-authored (codex-authored)_

The smoke is limited to 20 minutes of discovery and 10 minutes of replay and cleanup, with at most 200 mutations, 25 per batch, 30 seconds per command, and a corpus cap of 100.

_Source: codex-authored (codex-authored)_

The smoke demonstrates target coverage, useful oracles, fixture reset, process cleanup, and honest classification before the long window opens.

_Source: codex-authored (codex-authored)_

The exact development SHA, environment, target list, seeds, corpus, and versions are recorded; an independent foreground supervisor enforces hard-stop and cleanup checks.

_Source: codex-authored (codex-authored)_

Codex review is bound to exact artifact hashes for the frozen long-run contract and final dispositions; if review cannot run, the long window remains closed.

_Source: codex-authored (codex-authored)_

The report records exercised surfaces, classification denominators, replay evidence or an honest zero-defect result, and a stop/go decision.

## Open questions

_Source: codex-authored (codex-authored)_

What are the remaining smoke tracks and long-run conditions beyond the truncated issue body?

_Source: codex-authored (codex-authored)_

What has changed in GH-1248 and the existing campaign machinery since the issue was written?

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
