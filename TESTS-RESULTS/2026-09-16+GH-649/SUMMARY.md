# GH-649 focused verification

2026-09-16, macOS, disposable full clone; no live consumers changed.
All seven focused suites reran with authentic per-command receipts at clean source
71c06a876c912160a988dd6dbcab7a3ed2af262e. The following 716fbcfb change only
clarifies two documentation sentences. Full validation will cover that final text.
Each provenance.jsonl line records execution time, command, source commit, dirty-diff
hash, exit code, duration, repository identity result and raw log hash. Raw logs are
retained verbatim; the commit alias mirrors source_head for Forge receipt attribution.

| Suite | Result |
|---|---|
| gh649-pdda-migration | All eight groups passed: resolver, install/upgrade, modes, invalid manifests, vendored source, cutover preservation, backup/restore, failed-copy/rename preservation |
| pdda-changelog | 18 passed, 0 failed |
| pdda-install-startup-docs | 40 passed, 0 failed |
| pdda-roadmap-coverage | 11 passed, 0 failed |
| pdda-local-checks | 13 passed, 0 failed |
| gh365-pdda-gov-scan | 22 passed, 0 failed |
| gh414-comment-reference-check | 12 passed, 0 failed |

Negative controls are retained with nonzero receipts: installer-full-red.log reproduces
swallowed full-mode failure; sync-write-red.log skips that already reproduced installer
assertion to reach the failed-copy/stamp defect; changelog-parser-red.log transposes the
two original parser lines and observes the regression suite fail. Final focused runs
pass. Missing installer, missing/empty manifest, invalid document, poisoned template,
and injected copy/rename failures also execute as expected rejection cases.

Debug ledger: initial upgrade assertion wrongly required an unchanged append-only
activity log; changed to verify original bytes survive. Minimal manifest reproduced
Bash 3 empty-array nounset failure; guarded expansion fixes it. Review found swallowed
installer and sync failures; both were reproduced before correction. Earlier exploratory
runs are superseded by these receipts for acceptance purposes.

Identity after the focused reruns: core.bare=false; origin remains the local task clone;
HEAD=71c06a876c912160a988dd6dbcab7a3ed2af262e; tracked tree clean. Full gate and final
Codex review remain required before merge. No live consumers or registries changed.
