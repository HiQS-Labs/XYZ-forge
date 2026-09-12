# Tiel-Coder six-label next-action narrow-use report

## Decision

**Stop this zero-shot use configuration.** Tiel-Coder produced a valid label on every row but scored
19/100, below the same-row majority (26%), repeat-last (22%), Markov-1 (37%), phase-backoff (42%),
and tuned Needle adapter (27%) references. It overpredicted `edit` on 71 of 100 rows.

## Result

| Candidate | Top-1 |
|---|---:|
| Tiel-Coder zero-shot | **19%** |
| Majority | 26% |
| Repeat-last | 22% |
| Tuned Needle adapter | 27% |
| Markov-1 | 37% |
| Phase-backoff | 42% |

All 100 outputs were exact members of the six-label vocabulary; none required repair. Per-label
recall was `edit` 68.42%, `read` 10.34%, `run_command` 3.85%, `run_tests` 14.29%, and `search`
5.26%. The holdout contains no `git` targets, so `git` recall is not evaluated. Warm sequential
request latency was 0.927 s mean, 0.922 s median, and 0.967 s p95; model-load time is excluded.

## Interpretation and limits

This is a narrow zero-shot label-emission probe, not a trained Tiel-Coder classifier or complete
benchmark. It uses a reused development set of only 100 actions from two repository instances,
contains no `git` examples, and has already influenced prior decisions. The prior comparators use
different mechanisms and training, so their same-row percentages are descriptive references rather
than a causal model ranking. No confidence calibration, top-3, private-workflow transfer, governance
labels, production usefulness, cold-start footprint, or autonomous action safety was tested.

Reasoning was deliberately disabled and output capped at 16 tokens to test the narrow classifier
use case. This result does not contradict the model's general coding specialization; it says only
that this fixed zero-shot prompt is not competitive for this particular next-action task.
