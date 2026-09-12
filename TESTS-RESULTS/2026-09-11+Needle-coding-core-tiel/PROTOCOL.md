# Tiel-Coder six-label next-action narrow-use probe

Regenerate the exact public OpenHands split from Needle's `experiment/coding-core-pilot` branch:
Nebius dataset revision `35455389ab51bf5e2306bfd436ef72d0f98bf882`, offset 0, resolved only,
100 trajectories maximum, 500 training actions, 100 holdout actions, and a 20% instance-hash
holdout. The expected holdout SHA-256 is `f016551eda2f9912c2ab81887669281452777ac103737f6e9b092044064a8587`.

Score Tiel-Coder zero-shot on all 100 holdout rows. Each independent request supplies the existing
`coding-core-q1` query and the six existing label names/descriptions, requires exactly one label,
uses temperature 0, seed 0, a 16-token output ceiling, no tools, and no repair/retry. llama.cpp runs
with MTP enabled and reasoning disabled because this is a label-emission use case. Retain private
row-level predictions outside Git; commit only aggregate metrics and non-private protocol/runner.

This is not the original trained-adapter experiment and must not inherit its model grade. It is a
narrow zero-shot use probe over a brittle 100-row development set from only two repository
instances, with zero `git` support. The set already informed earlier decisions. Comparisons to the
26% majority, 22% repeat-last, 37% Markov-1, 42% phase-backoff, and 27% tuned Needle adapter are
descriptive same-row references, not a fresh holdout or a causal model comparison.
