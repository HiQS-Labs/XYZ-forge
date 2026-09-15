# Rebalance HiQS-Labs transfer screen — classifier not ready

**The existing synthetic-trained classifier does not transfer adequately to the sampled Rebalance feed.** ModernBERT and TF-IDF each classified only 5/15 supported records correctly (33.3%). Do not deploy this head on the feed. This is a failure of the tested training/taxonomy/input combination, not proof that fine-tuned ModernBERT cannot work.

Read only from Rebalance's local SQLite cache: latest 12 HiQS-Labs issue titles, 12 PR titles and 12 direct-commit subjects, ordered by their recorded activity times with deterministic tie breaking. Exact text deduplication reduced 36 rows to 33. No personal raw text was published. Expected labels were manually frozen and hashed before inference in commit 8c4f81c; model/features/training examples were unchanged from the synthetic screen.

| Measure | TF-IDF + linear head | Frozen ModernBERT + linear head |
|---|---:|---:|
| Supported cases correct | 5/15 | 5/15 |
| Accuracy on supported cases | 33.3% | 33.3% |
| Macro-F1 over the 3 represented truth classes | 0.407 | 0.356 |
| Bug-report recall | 0/3 | 3/3 |
| Implementation recall | 2/9 | 0/9 |
| Merge-text recall | 3/3 | 2/3 |

Taxonomy coverage: 15/33 unique rows (45.5%) could be assigned unambiguously to a supported category. Eighteen were planning, maintenance/reconciliation, unclear health shorthand or mixed-event titles. Neither classifier has an out-of-scope class or calibrated rejection: both forcibly assigned one of six labels to all 18. Their exclusion from accuracy must not be mistaken for successful model abstention. Only 3 of the 6 categories had truth support, so this is not a complete six-class test.

ModernBERT assigned eight implementation titles to bug_report and one to merged. Fourteen of the 18 out-of-scope titles were also assigned bug_report. Short conventional-commit/PR titles differ from the full-sentence synthetic training examples; that is a plausible explanation, not a cause established by this run. No input rewriting, retraining or threshold tuning was performed after seeing failures.

Two CPU passes over all 33 unique records took 0.612s and 0.602s, with identical predictions. These are warm batch timings, not p95 or complete collector latency. Speed is not the limiting result in this screen.

## Limits and next step

This is a convenience sample from a cached feed, not current GitHub attestation or an independent project/time-disjoint holdout. The same coordinator wrote the synthetic training corpus and reviewed the real sample; annotations are subjective, and some related PR/commit records may remain after exact deduplication. No independent semantic reviewer participated. Results do not measure future-action prediction, calibrated confidence, class-balanced production performance or operational safety. Private row-level labels and predictions remain at ~/.cache/xyz-modernbert-rebalance/ for local audit.

Recommended follow-up: define categories from actual feed usage (including planning, maintenance and unknown/mixed), independently annotate a larger real corpus, separate training/validation/test by session/repository/time, and compare a simple baseline again. Preserve metadata distinctions: use GitHub fields directly for issue/PR kind and recorded merged status rather than asking a text classifier to rediscover them. Apply learned classification only to semantics the metadata does not already establish. Do not tune on these 33 records and call them a new holdout.

Public artifacts contain only protocol, code, aggregate counts/timings and hashes; no database contents, titles, repository identities or row-level private predictions. Reproduction requires access to the retained local snapshot. The product suite was not run; this artifact-only branch publishes with the product pre-push gate bypass disclosed and does not qualify merge/promotion.
