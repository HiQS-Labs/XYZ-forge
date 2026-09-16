# GH-649 focused verification

2026-09-16, macOS, disposable full clone; no live consumers changed.
Final migration fixture tested commit 8a39cee172554058e42bb675affc5db787baaabf.
Earlier imported and existing core suites ran during b3fa0217–8a39cee1; subsequent
changes were confined to the migration fixture, manifest and sync engine.

| Suite | Result |
|---|---|
| gh649-pdda-migration | All seven groups passed: resolver, install/upgrade, modes, invalid manifests, vendored source, cutover preservation, backup/restore |
| pdda-changelog | 18 passed, 0 failed |
| pdda-install-startup-docs | 40 passed, 0 failed |
| pdda-roadmap-coverage | 11 passed, 0 failed |
| pdda-local-checks | 13 passed, 0 failed |
| gh365-pdda-gov-scan | 22 passed, 0 failed |
| gh414-comment-reference-check | 12 passed, 0 failed |
| pdda-repo-contract | Exit 0; zero errors; 257 warnings (239 unavailable historical issue states, 18 governance references) |
| codex-turn | 43 passed, 0 failed before plan relay |

Negative controls: old Forge changelog parser gave 10 pass / 8 fail before the
upstream fix; final parser gives 18/0. Migration fixture rejects a missing source
installer, missing/empty manifests, and an invalid full-mode project. Installer suite
rejects poisoned startup templates while preserving operator-owned files.

Debug ledger: initial upgrade assertion wrongly required an unchanged append-only
activity log; changed to verify the original byte prefix. Minimal sync fixture then
reproduced Bash 3 empty-array nounset failure in imported manifest helper; guarded
array expansion fixes it. Added nested-source control for ignored vendored payloads.
No benchmark or independent-demand claim follows from these tests.

Identity after focused runs: core.bare=false; origin remains the local task clone;
HEAD=8a39cee172554058e42bb675affc5db787baaabf; tracked tree clean. Full gate and final
Codex relay review remain required before merge. Logs here contain actual outputs.
