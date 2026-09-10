# ModernBERT as a supervised Git/PR activity classifier

**Preliminary screen passed: 20/24 correct, macro-F1 0.833.** Frozen ModernBERT features plus a trained logistic-regression head outperformed the untuned TF-IDF baseline on this small synthetic development corpus. This supports a larger real-data experiment; it does not establish production reliability or next-action prediction.

Inputs, protocol and runner were committed before fitting at `b4e9c8f`. No prompt, generated answer, random task head or post-result tuning was used. ModernBERT's encoder weights stayed unchanged; only a six-class linear head was trained. Six categories: bug reports, implementation changes, failed validation, passed validation, review requests and completed merges. The unit is a short supplied activity message, not a live-state verification or a history-to-future-action pair.

| Model | Correct /24 | Accuracy | Macro-F1 |
|---|---:|---:|---:|
| Majority-class baseline | 4 | 16.7% | 0.048 |
| TF-IDF + logistic regression | 16 | 66.7% | 0.607 |
| Frozen ModernBERT + logistic regression | 20 | 83.3% | 0.833 |
| ModernBERT + shuffled training labels (control) | 6 | 25.0% | 0.220 |

ModernBERT per-class recall: bug_report 4/4; implementation 2/4; merged 4/4; review_requested 3/4; validation_failed 4/4; validation_passed 3/4. The predeclared screen required accuracy >=80%, macro-F1 >=0.80 and recall >=0.50 in every class; it passed, with implementation recall exactly at the floor.

## Errors worth retaining

- “The submitted diff changes an off-by-one comparison in the scheduler.” → bug_report, expected implementation.
- “A source edit now preserves the original exception when cleanup fails.” → bug_report, expected implementation.
- “The smoke run returned zero after confirming that the server responded correctly.” → validation_failed, expected validation_passed.
- “The developer invites a teammate to inspect the changes before landing.” → bug_report, expected review_requested.

These errors show sensitivity to defect-related vocabulary and indirect event wording. They are observations, not causal diagnoses. No corrections were fed back into training.

## Runtime and controls

CPU, four PyTorch threads, batch size eight. Training-text encoding: 1.166s; linear-head fit: 0.078s. Each complete 24-message test pass, including encoding and prediction, took 0.287s / 0.289s and produced identical predictions. These are batch timings on a warm process, not individual request latency or p95. Model/tokenizer load was 0.450s, excluding imports/process startup. TF-IDF fit plus prediction took 0.014s; its timing includes different work and should not be read as an apples-to-apples serving ratio.

The empty-test, missing-training-class and cross-split duplicate controls all failed as intended. Shuffled labels produced substantially poorer results. All messages fit the model context; no truncation. The model load report lists the masked-token head as unused, as expected when extracting encoder features; no missing encoder weights were reported. Versions, hashes, per-case predictions, confusion matrices and provenance are retained in results.json, runtime.log and provenance.jsonl.

## What this does and does not establish

This is a useful feasibility result for **classifying the type of activity described in text**. Both splits were hand-authored by the same experiment coordinator: 48 training messages and 24 separately worded test messages. They contain obvious lexical cues, cover only six classes and are not independently sampled production data. No statistical superiority, calibrated confidence, abstention quality, robustness to mixed/negated events or safe operational authority is established. No independent reviewer participated in this screen. Two inference passes check repeatability, not two independent datasets. The TF-IDF baseline was deliberately untuned; a stronger simple baseline may close the gap.

Recommended next test: freeze independently labeled, de-identified real activity messages with session/project/time separation; include mixed events, negation, unknown categories and realistic class imbalance; compare the same candidates before considering encoder fine-tuning. Use a separate validation split for confidence/abstention thresholds, then one untouched test set. Do not recycle these observed test examples as a fresh holdout.

For Needle next-action prediction, change the supervised target to the next observed action and use only preceding context. That requires a different dataset and evaluation, not relabeling this screen as prediction accuracy.

Reproduction: run run.py with the isolated environment and pinned ModernBERT checkpoint documented in the companion compatibility spike. This is an artifact-only archive branch; the directly executed classifier experiment is focused evidence. No full product suite ran; publication skips the local product pre-push gate and conveys no merge/promotion readiness.
