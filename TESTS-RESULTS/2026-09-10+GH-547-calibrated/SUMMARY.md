# Needle #31 — calibrated HiQS work classification results

**Steps1–4 completed, but neither classifier is deployment-ready.** The operator-calibrated purpose task yields ModernBERT23/40 versus TF-IDF20/40; area classification remains weak and validation-selected rejection policies do not provide useful reliable coverage. This is a side experiment for work classification, not next-action prediction.

## Data and labeling

136 real training records,32 validation records,40 fresh held-out records from cached HiQS-Labs issues/PRs. Titles plus up to1800description characters and repository context are inputs.134of208 descriptions were truncated at collection; full descriptions beyond that boundary were not available to annotators or models. Activity lifecycle metadata is excluded from classifier input. Exact titles and explicit issue-reference families were handled before temporal splitting; implicit relationships and later edits remain possible. Previously evaluated exact titles were excluded from holdout.

Training purpose support after targeted real-data enrichment: Bug fix45, Feature/enhancement23, Research/evaluation16, Documentation15, Testing/validation12, Maintenance9, Planning/design8, Merge/closeout8. Enrichment keywords selected candidates only; annotators supplied labels. Eight extra older candidates were reviewed before fitting to resolve a planning deficit. One belongs to a train-only family already represented; none crossed into validation/holdout.

Two model annotators labeled disjoint training/validation batches from title+description. A third independent model reviewer labeled only taxonomy+holdout, blinded to training labels and predictions. These are model annotations guided by the operator's human calibration, not human gold truth for208records. Additional component-area vocabulary beyond CI/CD and Skills is provisional. Null primary labels preserve unresolved/unsupported areas. Holdout has2null areas, no null purposes, and no maintenance-purpose examples. Secondary labels are very sparse.

## Primary scores (before rejection)

| Output | Majority baseline | TF-IDF + logistic heads | Frozen ModernBERT + logistic heads |
|---|---:|---:|---:|
| Purpose correct /40 |17/40|20/40|23/40|
| Purpose accuracy |42.5%|50.0%|57.5%|
| Purpose macro-F1 |see results.json|0.430|0.370|
| Area correct /38 labeled |4/38|12/38|10/38|
| Area accuracy |10.5%|31.6%|26.3%|
| Area macro-F1 |see results.json|0.206|0.221|

Purpose macro-F1 includes all eight trained categories (maintenance has zero held-out truth support). Area macro-F1 includes the union of training/held-out labeled components. Null-truth rows are excluded from raw classification metrics but included in rejection coverage and false-accept checks. Higher ModernBERT purpose accuracy does not mean better class-balanced performance: TF-IDF has higher purpose macro-F1. Area results show the reverse accuracy/F1 ordering; neither is adequate.

The temporal holdout has substantial class shift: model_inference has only1training example but10holdout examples. Ingestion/sync has2training examples;21training area labels are null. This particularly limits the area experiment. No causal claim that adding calibrated data improved the previous40% run: taxonomy, samples, descriptions, normalization, class weights and model selection changed.

## Uncertainty and optional secondary labels

Validation-only hyperparameter grid: C0.1/1/10/100, class_weight none/balanced, choose highest macro-F1 with deterministic tie-breaking. ModernBERT features are L2-normalized. No encoder fine-tuning or held-out tuning. Primary selections: TF-IDF purpose/area C0.1 balanced; ModernBERT purpose C10 balanced, area C100 unweighted.

Rejection thresholds require at least5accepted validation records and80% correctness, counting accepted null truths as errors. This is an empirical threshold, not calibrated probability or a production guarantee.

- Both purpose models and TF-IDF area found no qualifying threshold: **reject all, zero coverage, accepted accuracy undefined**. This is not a successful high-accuracy result.
- ModernBERT area selected threshold0.60: validation5/5accepted correct; holdout accepted4/40 and only1/4correct (25%), no accepted null-truth cases. The validation precision did not transfer; do not deploy this rejection policy.
- Secondary heads met training support only for purpose Documentation and five area labels. Scored micro precision/recall/F1 were0. Some secondary labels had insufficient training positives; others appeared only in holdout and were listed as unsupported. Only2known purpose-secondary positives and1known area-secondary positive entered the respective scoring matrices, with additional unseen labels excluded and reported. These numbers do not establish meaningful secondary-label quality.

## Runtime, controls and preservation

CPU4threads, batch4, eager attention. ModernBERT encoding took56.85s training,13.49s validation,17.11s for the40-record holdout. These are full batch feature-extraction durations, excluding model imports/collector time. Repeated predictions over the same held-out feature matrix were identical; this checks head repeatability, not two complete independent encoder runs. The TF-IDF feature stage took0.164s. Parameter-search timings and library versions are preserved in results.json; no p95 or complete real-time service claim.

Empty data, missing label ID, cross-split duplicate text and invalid-purpose mutations were rejected. ID coverage, nonempty inputs, frozen hashes and native token limits passed. Input/code/protocol freeze:47baf02. No holdout label was changed in response to predictions. Fitted primary heads/vectorizer, original examples and per-record predictions remain local at ~/.cache/xyz-modernbert-calibrated. Public outputs contain only aggregates, code, hashes and provenance, not private source text. Reproduction requires the retained private snapshot; collect.py alone cannot reproduce labels or a changing live database.

## Decision and next work

All requested stages were executed and results retained, including failure. Keep this as an experimental branch; do not plug these heads into an operational classifier. Purpose shows limited signal; areas, secondary labels and rejection need materially better data/definitions. The next useful work is human checking of ambiguous annotations and sufficient per-component area examples, with validation experiments before freezing a new test set. A full encoder fine-tune could be investigated later but is not implied by this run. Do not reuse this now-observed holdout as unseen evidence.

The recorded benchmark was run directly in a dedicated full clone. No product-runtime files changed, no full product suite ran, and publication uses a disclosed pre-push product-gate bypass. This is not merge/promotion evidence. Canonical side-experiment issue: https://github.com/HiQS-Labs/Needle-fork/issues/31 ; human calibration: #29; prior XYZ experiment archive: HiQS-Labs/XYZ-forge#547.
