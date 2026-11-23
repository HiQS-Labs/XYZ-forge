# Independent native advisor — plan

Recommendation: bounded validated native inventory only when pages are cheaper; no demonstrated
safe command-local reuse point. Reconciliation selects every nonterminal row, observes native then
closure state, and rechecks changed rows transactionally. The merge gate launches one subprocess;
dry-run and execution are separate freshness boundaries. Unique repo/number rows defeat memoization.

Blocking considerations: sparse inventory overhead, malformed/duplicate/missing entries, requested
PRs, API errors, widened observation skew and shared validator parity. Keep no persistent cache.
A page cap must not imply complete coverage. Missing IDs require authoritative singleton reads.

A failure-only optimization could skip network after an already-red semantic gate, but it does not
establish reduction in successful repeated sweeps and is outside the selected fix.

No edits, network requests, or tests were performed by this advisor. Reconciled decisions and
source-grounded rejection of crossprovider claims are in the measurement SUMMARY.
