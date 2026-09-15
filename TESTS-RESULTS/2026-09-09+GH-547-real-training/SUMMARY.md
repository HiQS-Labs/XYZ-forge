# Real-activity training, blinded independent holdout — still not sufficient

**ModernBERT scored 10/25 (40%); TF-IDF and the training-majority baseline each scored 9/25 (36%).** One additional correct answer on this small holdout does not demonstrate a reliable advantage. The tested classifier is not ready for operational use.

This round replaces the synthetic sentence corpus with real Rebalance HiQS-Labs issue/PR titles and changes the task to described work intent. Categories: defect, capability, investigation, maintenance, planning, unclear. GitHub metadata should still supply source type and recorded lifecycle status. This is not next-action prediction or fact verification.

## Dataset and independent labels

72 training records, 18 diagnostic validation records, 25 held-out records. Training class counts: defect29, capability12, investigation8, maintenance10, planning3, unclear10. Title normalization removed exact duplicates; explicit same-repository issue-number references joined families; one representative per family was selected. Temporal pools were sampled without labels, then five exact titles previously used in the transfer screen were removed from the holdout without replacement. Direct commits were excluded to reduce PR/commit duplication. Implicit relationships can remain.

Training creation range: 2026-07-28 through 2026-09-01; validation: 2026-09-01 through 2026-09-06; holdout: 2026-09-06 through 2026-09-10, in UTC, with exact nonoverlapping timestamps in results.json. These are creation-time splits, not a historical reconstruction of title wording at that time; cached titles may have been edited later.

The coordinator labeled training/validation. A separate model sub-agent labeled only the taxonomy and holdout, without training labels or predictions. Its 25 labels and rationales were frozen before inference; 16 high confidence and 9 medium confidence. This is independent model-based annotation, not human gold labels. No labels were revised in response to predictions. Raw data, labels, rationales and per-case predictions remain local at ~/.cache/xyz-modernbert-real-v2; the public archive contains hashes and aggregate evidence only.

## Fixed-model results

Encoder weights remained frozen; only logistic-regression heads trained. Both learned methods used fixed C=1, max_iter=2000 and random_state=547. No class weighting, hyperparameter search, prompt, answer generation or test-set tuning.

| Method | Validation /18 | Holdout /25 | Holdout accuracy | Macro-F1, fixed six classes |
|---|---:|---:|---:|---:|
| Training-majority class | 7 | 9 | 36% | 0.088 |
| TF-IDF + logistic regression | 7 | 9 | 36% | 0.088 |
| Frozen ModernBERT + logistic regression | 8 | 10 | 40% | 0.183 |
| ModernBERT shuffled-training-label control | — | 6 | 24% | 0.074 |

Macro-F1 over only the five classes actually represented in holdout: ModernBERT0.219; TF-IDF0.106. There are no unclear truth examples, so unknown detection remains untested. ModernBERT recall: defects8/9, capabilities2/4, investigation0/1, maintenance0/6, planning0/5. TF-IDF predicted defect for every holdout row.

On the 16 high-confidence reviewer labels, both models got9/16 (56.25%). This sensitivity view does not replace the headline25-case result. Class imbalance, only three planning training examples, short ambiguous titles and annotation consistency are plausible limitations; this run does not isolate their causal contributions.

## Runtime and checks

ModernBERT training encoding plus head fit took4.066s. Two full25-record holdout encoding/prediction passes took0.814s and0.827s on CPU, four threads, batch8, with identical predictions. TF-IDF fitting plus both validation/holdout predictions took0.040s. These timings cover different operations and are not a serving speed ratio, cold-start latency or p95.

Nonempty-split and cross-split-duplicate controls were deliberately broken and rejected. Exact label-ID coverage, frozen input hashes and native token-limit checks passed. Shuffled labels performed worse than the unshuffled model. All raw prediction output used for grading is local; aggregate confusion matrices and provenance are committed. Input scripts/protocol/hashes were frozen in c43f4b4 before the run. No independent runtime/code review or full product suite is claimed.

## Decision

Do not deploy this classifier. This supplies the requested real training examples and independently labeled holdout, but their size and annotation quality are insufficient for operational confidence. The task/taxonomy and corpus changed from the earlier experiment, so 40% versus33.3% is not evidence of causal improvement from real-data training.

Before another scored holdout: obtain human adjudication of ambiguous labels, define clearer class boundaries, increase per-class training coverage, and use validation-only experiments for balanced weighting/feature normalization or encoder fine-tuning. Freeze a fresh holdout afterward; do not recycle these observed25 cases as unseen evidence. Consider reducing the learned task to a smaller useful distinction if the feed does not support six reliable classes. Known GitHub lifecycle fields need no learned classifier.

This remains artifact-only archive work, with published evidence on the experiment branch. Publication bypasses the local product pre-push gate; no merge/promotion readiness is asserted. No personal raw records were uploaded.
