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
| gh649-pdda-migration | All nine groups passed: resolver, install/upgrade, modes, invalid manifests, vendored source, cutover preservation, backup/restore, failed-copy/rename preservation, failed deletion tracking |
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

Round 2 follow-up: delete-backup-red.log reproduces the same swallowed failure in the
delete phase. The final migration fixture reran successfully at clean f3b53ebb after
explicit backup/removal guards. It covers both failed backup and failed removal,
retained target bytes and old manifest snapshot. Earlier successful migration output
is retained as migration-before-delete.log so every receipt hash remains verifiable.
The remaining six suites are unchanged by this sync-only correction.

The first full run at de5a871e completed with six test-integration failures (retained
as validate-initial.log): fixture adoption, temporary-directory validation, two checks
for early-exit grep pipelines, generated-consumer path classification, and the PDDA
subsystem census. All corrections are test-only; the approved production scripts,
manifest, templates and runtime are byte-identical. Focused guard/imported-suite
rechecks pass. A final full run at f49d51af is in progress in another disposable clone;
the failed run is not counted as passing validation. Both clone identities are retained.

Final full gate at f49d51af8a8323024fc380c7b9faf0325bdb445b exited 0 in 1144 seconds: 390/390 checks passed, including 21 Python cases and clone/environment invariants. The unchanged gh53 merge fixture failed with duplicate generation settings under parallel execution and passed the runner’s isolated retry; the first failure log and final runner verdict are retained. The runner removed its per-suite retry scratch log at exit, so no separate raw retry log is available. This is a passing local gate, not ci-local promotion qualification. Final Codex implementation review approved round 3; subsequent changes are test integration and documentation only. All final-focused and full-run receipts retain their actual tested source commits; final-* log names distinguish them from earlier evidence. No live consumer or registry was changed.

Landing integration: development advanced to 5647eadb with GH-654 during publication. Merge 304b52dd preserves both ledger histories, keeps the higher generation and uses the canonical rebuild resolver (zero errors; eight existing migration-debt warnings). PDDA code is unchanged. Six focused combined-branch suites pass: GH-654, GH-649, installer startup, GH-53 merge resolution, path integrity and bidirectional registry. The 390-check full run predates this integration; no claim is made of a repeated full gate or promotion qualification on the merged head. Resolver-generated leaderboard changes accompany the real ledger conflict, not a routine task view refresh.
