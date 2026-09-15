# GH-547 — supervised activity classification development screen

Question: can the downloaded ModernBERT checkpoint supply useful features to a small supervised classifier for Git/PR activity? This does not test next-action prediction, analyst reasoning, truth verification or operational permission.

Six mutually exclusive classes describe the primary event stated in one short activity message: bug_report, implementation, validation_failed, validation_passed, review_requested, merged. These are experimental labels, not Needle's 44-action taxonomy. Treat the messages as supplied observations; do not infer real GitHub state from them.

Freeze 48 hand-authored training messages and 24 separately worded test messages (8/4 per class) before fitting or inspecting results. No model-generated paraphrase expansion. Both splits come from the same author, intentionally contain obvious lexical cues, and are development data, not an independent production holdout. No tuning after scores are observed.

Models: majority baseline; word unigram/bigram TF-IDF + logistic regression; frozen ModernBERT attention-mask-aware mean-pooled encoder vectors + logistic regression. The encoder is not fine-tuned; fit the linear head on training labels only. Both learned heads use C=1, max_iter=2000, random_state=547. ModernBERT uses CPU, four threads, eager attention, evaluation mode, no dropout, batch size 8. No truncation: assert all texts fit the native context. Fit TF-IDF vocabulary only on training text. No test labels go into feature extraction or fitting.

Report accuracy, macro-F1, per-class recall, confusion matrices, each prediction, feature-extraction and fitting times. Two test inference passes use the same loaded encoder and must agree. These timings exclude external activity collection and are not independent quality trials or p95 estimates. No calibrated confidence or abstention claims.

Controls: reject an empty split, cross-split duplicate text and missing training class using deliberate mutations. Run a fixed shuffled-training-label ModernBERT head as a sanity comparator; no strict chance-performance assertion with this small sample.

Predeclared screen: ModernBERT accuracy >=80%, macro-F1 >=0.80, and recall >=0.50 in every class warrants a larger independent holdout. Compare with TF-IDF; if TF-IDF matches or wins, prefer the simpler option for this task pending real-data evidence. Never assign the historical LLM benchmark letter grade. Commit scripts/corpus/protocol before execution, then commit raw outputs and provenance. No product tests are claimed. No training on personal history, model-weight updates, network inference or actions on a repository.
