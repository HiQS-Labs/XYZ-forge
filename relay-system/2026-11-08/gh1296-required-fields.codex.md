# Independent final review — GH-1296 required fields

Reviewed runtime: `a1a0b6875d46135d0de8b43c18a1cb813793824d`.

The 15-line repair in `utils/py/harness.py:1307-1331` matches the existing required-field type checks in `utils/py/swarm_preflight.py:102-110` and exact new-artifact path/probe matching at `:1332-1336`. It extends the existing blocker helper consumed by `make_packet` at harness.py:1425; no runtime, suite or gate machinery was added by this reviewer. Easy to reverse; blast radius is packet eligibility for incomplete contracts and new artifacts lacking their required absence probe.

Independent AST extraction of the actual committed helper reproduced the baseline artifacts-only false-ready result at `242784372df15472e033003c0f0e36fcfd19f42f`. All nine candidate controls passed, including valid existing and new-artifact contracts. This is helper-level evidence, not a fresh whole-packet or historical replay. Results: `TESTS-RESULTS/2026-11-08+GH-1296-review/independent-required-fields.json`. The new checks do not reject contracts valid under those existing preflight requirements. Other preflight conditions remain outside this bounded check; an empty blocker list is not universal launch readiness.

No blocking code findings. Historical evidence remains unchanged and retains its original SHA coverage. The preliminary review's source-link addendum and expanded CHANGELOG accurately preserve that history. Raw preflight text stored under a `.json` name remains historical raw text, not machine-readable JSON; this naming observation is acknowledged, not silently repaired or represented as a new replay. Active-document promotion remains the parent's coordinated follow-up. GH-1296 must remain open because the original GH-1279 replay inputs are unavailable. Original repair round 2 and this missing-fields finding's first repair are not reset.

No merge, push, watch, issue closure, primary checkout edits, or child delegation performed. Published-head checks are not claimed for this unpublished candidate.

## Verdict: Approved

Full `bash validate.sh --parallel 4` passed 409/409, exit 0, at the exact reviewed SHA above using Python 3.13.15 with required dependencies. Separate full clone: `/tmp/gh1296-required-fields-gate-20261108`; retained, clean, non-bare, canonical origin, unchanged HEAD, no local fixture identity. Evidence: `required-fields-full-gate.log`, `required-fields-full-gate-receipt.json`, `required-fields-clone-state.json`, and appended `provenance.jsonl` in the review evidence directory. Exact-SHA receipt copied to the task clone's standard `.xyz/receipts/` cache. It must not be relabeled as covering the later evidence-only commit. This is full validation, not promotion qualification.

PR1324 gate process exited; its host slot is released. A separate gate PID 15582 remained in `/Users/noelsaw/Documents/GitHub/XYZ-forge-pr1024-gate-sol` at handoff inspection; not ours and not terminated. Parent should coordinate that existing load before starting #1254.
