---
name: ate
description: "Choose and supervise XYZ Forge ATE variation, adaptive pairwise or mutational fuzzing tools. Use for ATE, CLI flag grids, local-model classification, or bounded exploratory campaigns; use defect-campaign for Radar-selected discovery."
---

# ATE / fuzzing — entry points and limits

This map describes current `development` (source checked at `7eeae804`, 2026-10-21),
not a promise about released tag `0.9.0`. Pin the checkout used for a run and inspect its CLI.
Historical Gen 3/4 plans, module-header promises and example-grid comments are not acceptance evidence.
For Radar-selected discovery, follow [defect-campaign](../defect-campaign/SKILL.md): bounded approval,
semantic replay and accountable disposition; synthesis, healing and automatic filing stay off.
That workflow does not authorize new CI cases or remediation.

## Choose an entry point

Paths below are relative to the full Forge checkout; `utils/py/` tools have separate CLIs.

| Entry point | Input / purpose | Output / boundary |
|---|---|---|
| `utils/ate/scripts/run_variations.py` | Variation YAML: `model`, `message`, `variation_keys` naming top-level value lists, argv-list `command_template`; absent custom keys, uses Aider `edit_formats/map_tokens/auto_commits` | Cycled Cartesian grid; `error_log.jsonl`, `control.json`; optional issue rollup |
| `utils/py/adaptive_ate.py` | Different YAML/JSON schema: `flags` mapping to lists, `conflicts` mappings, `requires: [{if: {...}, then: {...}}]`, `command` string containing `{flags}` | `generate` / `coverage` / `run` / `classify`; pairwise coverage and Tier-1 telemetry; optional anomaly command |
| `utils/py/fuzz_engine.py` | Target string with `{mutant}`, base argv, seed and corpus | `plan` / `fuzz` / `replay`; output-signature feedback, not code coverage |
| `utils/py/domain_oracles.py` | Explicit command, work root and applicable host/receipt/recovery inputs | Observations: zero-state, containment, idempotence, crash-recovery; not an OS sandbox |
| `utils/py/gen4_campaign.py` | `--mode run`, approved duration/mutation bounds and disposable full clone; optional target-list JSON | Batches, telemetry, campaign report, candidate clusters; synthesis defaults ON (`--no-synth` disables it) |
| `utils/py/repro_builder.py` / `repro_synth.py` | Single failure record / Gen 4 telemetry JSONL | Candidate repro scripts / signature-cluster synthesis and minimization; human semantic verification still required |
| `utils/py/self_healer.py` | Explicit sandbox root, generator command and regression command | Opt-in candidate content/diff handoff; no autonomous full-suite-qualified repair guarantee |

Legacy/offline tools are separate: `utils/fuzzing/fuzz-loop.sh` enumerates fixed synthetic scripts;
`active_explorer.py`, `metamorphic_oracle.py` and `differential_oracle.py` expose older probe/oracle
interfaces. `calibrate_tier1.py` is an offline labelled-benchmark tool, not a runtime supervisor.
`checkin.py` summarizes logs and can request abort; `compile_issue.py` renders/files a rollup.

## Full-checkout variation example

Do not use the standalone installation recipe: `utils/ate/install.sh` copies `utils/ate/`,
but `run_variations.py` imports sibling `utils/py/proc_group.py`, which is not copied.
Keep the full checkout. All three `{harness_root}` templates (`variations.tool-density.yaml`,
`variations.tool-calling.yaml`, `variations.turn-shims.yaml`) resolve that placeholder from the
script's location; copying the runner changes that root and does not bundle their targets.

```bash
# From the full Forge checkout; use an ABSOLUTE path to a disposable scratch git repo.
# The scratch repo must contain only expendable data. Inspect/edit the grid before running.
python3 utils/ate/scripts/run_variations.py \
  --repo /absolute/path/to/disposable-scratch \
  --variations utils/ate/variations.example.yaml --minutes 5
# In a separately scheduled/manual supervisor (there is no implicit check-in loop):
python3 utils/ate/scripts/checkin.py --log error_log.jsonl --control control.json --tail 20
# To request abort before the next iteration:
python3 utils/ate/scripts/checkin.py --control control.json --abort "reason"
```

The Aider preset needs its target CLI/provider configuration; these are instructions, not an install.
Add an exact `--lmstudio-model` identifier to use local-model classification (default endpoint
`http://localhost:1234/v1`). Without it, or with `--mock-classifier`, only exit 0 passes and
`expects_edits` is ignored. With a model, `expects_edits: false` changes the diagnostic no-edit
prompt, not an expected-exit-code list. The turn-shim grid's comment about exit-2 usage passing
is an intended CLI contract, not runner behavior: exit 2 is still classified as failure by the
exit-code classifier and is nonzero-error evidence in the diagnostic model prompt. Triage it.
The tool-density/calling templates are diagnostic targets; review their edit expectation too.

Every variation hard-resets and cleans `--repo`, including uncommitted/ignored files (with log/control
name exclusions); it can auto-create a base commit. The harness repo is refused; repos with remotes
require `--allow-destructive-reset`. These guards do not make valuable scratch contents safe.
The runner resets stale control to `continue` at startup, polls before iterations, and stops at the
time budget or roughly 20 grid passes (cap checked after execution). Per-variation timeout defaults
to 180 seconds with bounded process-group cleanup; the budget is not a strict total wall-clock cap.
Check-ins require an actual supervising session/scheduler. `checkin.py` has no cross-call memory.

## Exit and filing contracts

| Runner result | Meaning |
|---|---|
| `0` without `--gh-repo` | At least one variation attempted and normal loop end; findings may exist |
| `2` | Repo guard refusal, empty grid or no attempted variation (also CLI usage errors) |
| `127` | Caught harness spawn failure; failure record written, no filing handoff |
| `128 + signal` | Cancellation via signal handler; KeyboardInterrupt during harness launch returns 130; filing may not occur |
| Filing result with `--gh-repo` | Normal loop end propagates `compile_issue.py`: 0 filed/dry-run rendered, 3 empty log, 1 filing failure |

A child killed by a signal is recorded with a negative subprocess return code; a timeout has
`exit_code: null` and a high/timeout classification. These are findings, not the runner's final
exit status. Other uncaught errors can terminate the runner; the table is not an exhaustive error taxonomy.
Filing is opt-in via `--gh-repo OWNER/REPO`; `--dry-run-issue` only renders. The issue compiler's
`gh` call is bounded (120s default, `ATE_GH_TIMEOUT_S` override), preserving `issue_body.md` on failure.
Omit filing for discovery workflows that require review before external writes.

## Gen 4 interpretation and safety

Seeded planning requires the same source, argv, seed, corpus snapshot/order and environment;
subprocess timing, host state and models can still change outcomes. `fuzz()` constructs its whole
plan before execution: feedback updates the corpus for later batches/invocations, not current
parent selection. Twin comparison checks exit code and normalized stderr digest, not stdout,
side effects or semantic equivalence. Pairwise coverage/reduction depends on the grid and constraints.
Shipped calibration records 50 pass / 24 fail inputs, 9 anomalies, FN=0/FP=0 on that benchmark;
it is not a general false-negative or performance guarantee (`utils/ate/tier1-calibration.json`).

Campaign defaults contain nine targets, deliberately excluding `validate.sh`; this is not a full-suite
campaign. `--no-synth` is valid; `--synth` is not. Campaign `--tier2-cmd` is accepted but unwired;
adaptive ATE's separate `--tier2-cmd` runs an anomaly command. Bounded registered Gen 4 self-tests
can run in hosted validation; exploratory multi-hour campaigns require separate approval.
Campaign replay accepts matching stderr digest OR exit code; synthesis may fall back to exit-code-only
verification. Clustering uses stderr digest without target identity: clusters can combine unrelated
failures. Generated scripts pass while their failure predicate reproduces; review and invert the
appropriate assertion when fixing a defect. They are not automatically committed regression coverage.

Domain oracles observe selected state; bounded `lsof` checks can skip on missing tools/errors.
Campaigns record host violations after batches rather than immediately aborting. Time checks occur
between batches; replay/synthesis/healing add postprocessing time. Exit 0 requires no recorded host
violations and valid telemetry, not zero findings, zero sandbox contamination or semantic correctness.
Keep campaigns in disposable full clones with independent supervision and explicit stop/cleanup plans.
The opt-in campaign repair handoff targets `validate.sh` with regression command
`bash validate.sh --print-mode` (runs no suite); `self_healer.py` uses ordinary open/write for apply
and rollback, not atomic `os.replace`. It requires separate qualification before accepting any repair;
path checks and an emitted diff do not prove full containment, successful handoff or full-gate attestation.
