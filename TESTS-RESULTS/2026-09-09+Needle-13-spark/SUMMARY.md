# Codex Spark HIGH and XHIGH — Needle #13

Provisional overall grade: **C for HIGH; C for XHIGH**. Both configurations delivered useful advisory review, but required material source and semantic corrections. XHIGH did not demonstrate improvement: its second repeat incorrectly held A05, which permits future draft membership without authorizing active admission. Historical grades are unchanged.

Inputs were frozen before inference in `1d69c0f`. The user requested the two effort configurations; two repeats each follow the established methodology (the frozen protocol's wording “explicitly requests four calls” was stronger than the literal request). Four fresh sequential calls used the identical 116,698-byte prompt and 111,980-byte source packet; only the selected effort and output paths varied. No answer key, earlier answers, repair, retry, or tuning was supplied.

| Run | Original case grader | False ACCEPT / HOLD | Wall seconds | Input | Cached input | Output | Reasoning output |
|---|---|---|---:|---:|---:|---:|---:|
| HIGH r1 | 16/16 | 0 / 0 | 17.306 | 50,223 | 3,968 | 13,333 | 8,463 |
| HIGH r2 | 16/16 | 0 / 0 | 22.401 | 50,226 | 7,808 | 19,867 | 16,667 |
| XHIGH r1 | 16/16 | 0 / 0 | 35.986 | 50,223 | 3,584 | 20,129 | 16,985 |
| XHIGH r2 | 15/16 | 0 / 1 (A05) | 22.955 | 50,226 | 12,288 | 16,763 | 14,374 |

Raw CLI usage fields are reproduced without adding reasoning to output or deriving prices. All four outputs satisfy the requested response schema; the fourth fails the original decision pass criterion. Two repeats are not 32 independent cases per configuration. The grader does not assess the six technical answers.

## Source-reviewed findings

Both configurations correctly keep bug-only issues ineligible, distinguish main's logging-only hook from 710c detached inference, identify atomic replacement as insufficient protection against stale workers, and reserve queue authority for deterministic code. Their parked-row warnings agree with `utils/py/releases_app.py:3895` and `:3912`; the delayed-worker concern agrees with `input/needle-710c-oracle_stop_hook.py:122` and `input/needle-710c-oracle_infer.py:58`. These are useful hypotheses grounded in supplied code, not executed race proofs.

HIGH requires material corrections. Both answers cite impossible coordinates in the one-line issue snapshots (for example `xyz-522.json:33`, `needle-13.json:73`) and construct nonexistent input-prefixed paths for repository files. HIGH r1's top-one versus up-to-three discrepancy is a valid alternative finding: serializer system instructions at `needle-main-serialize.py:51` and inference comment/slice at `needle-710c-oracle_infer.py:45–48` differ. However, a call-object container alone does not violate an arguments-free label contract. HIGH r2 does not name a concrete current documentation/code inconsistency, and its claim that the same artifact cannot support both usefulness and accuracy evidence is too categorical: distinct outcomes can be assessed from shared eligible context.

XHIGH repeats impossible issue coordinates and does not clearly resolve the requested current contract inconsistency. In r2, calling `no_action` a first-class abstention blurs semantic no-action with confidence abstention or absent observation, even though Q5 later requests that distinction. The supplied serializer maps semantic `no_action` to an empty answers list (`needle-main-serialize.py:109`), while the label text calls it abstention (`needle-main-labels-v1.json:331–332`); empty output alone is not automatic credit. XHIGH r1's universal no-input-change/no-output-change control would require deterministic model behavior or caching, neither established here. R2 additionally omits a clear stronger-model baseline in Q5 and incorrectly rejects A05 by confusing a permitted future draft with active enrollment.

Both offer sensible boundary, holdout, state, and false-accept checks, but sharing a replay framework does not make the projects' targets, context schemas, or prediction boundaries identical. Statements that no API calls occurred should be understood only as no live product workflow was executed: these four trials were real Codex model calls. Parent and helper reviewed the named material findings and agree on C/C; this is an unblinded, provisional task grade, not a calibrated general model ranking.

## Execution and proof limits

Actual Codex CLI selected `gpt-5.3-codex-spark` with `high` or `xhigh`; receipts record the requested selection, not independent backend attestation. Existing consult machinery used an experiment-only CODEX_BIN adapter, read-only sandbox, approval never, ephemeral conversations, and ignore-user-config. Outer/inner limits were 900/870 seconds. There was no temperature, system-role override, or 6,000-token output ceiling. These outputs materially exceed the older API ceiling, so strict cross-transport budget parity is absent.

All four JSONL traces contain the same nonfatal skill-description truncation error followed by an agent answer and completed turn. Project instruction context also exists despite ignore-user-config; Spark's model-dependent template and context handling differ from prior model trials. No tool-execution items were observed. Four distinct thread IDs and identical prompt bytes were verified. Event/answer checks reject empty events, changed answers, and missing completion; frozen original grader controls reject empty, duplicate, missing, and flipped decisions. Raw answers, events, stderr, receipts, hashes and provenance are retained. No product code, production queue, private corpus, or race test was executed.

Relay snapshots: `spark-high-r1-134230`, `spark-high-r2-134324`, `spark-xhigh-r1-134510`, `spark-xhigh-r2-134558`, all under `relay-system/2026-09-09/`. The credential scan checks known runtime key literals and common credential patterns, not every possible secret. Parent owns committing and publishing these artifacts.
