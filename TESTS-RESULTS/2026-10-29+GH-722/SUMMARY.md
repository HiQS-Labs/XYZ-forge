# GH-722 manual check (2026-10-29, commit 3f5820f3)

Fixtures: a scratch HOME holding bare remotes `proj` and `other`; under `<HOME>/sib/` the primary `proj`, a same-origin task clone `proj-task`, a foreign-origin clone `other`, and `proj-noorigin` (origin remote removed); plus `<HOME>/proj2` whose parent is HOME. `<HOME>/sib` is not one of the listed safe roots. All runs are dry runs; nothing was removed. Commands, exit codes and hashes are in `provenance.jsonl`.

| Case | Result |
|---|---|
| a1 default scan (main path) | Lists `proj-task` as SAFE_REMOVE_CLONE; `other` and `proj-noorigin` are not inspected; header prints the roots, naming `<HOME>/sib` as origin-filtered. |
| a2 red control, base 0628da70 | Lists only the primary: the sibling is invisible before the fix. |
| b1 default teardown dry run | Phase 6: "Would remove verified standalone clone: <HOME>/sib/proj-task", nothing else. |
| b2 explicit `--root <HOME>/sib` teardown dry run | `other` PRESERVE_UNSAFE_ROOT, `proj-noorigin` preserved; Phase 6 again removes only `proj-task` after re-inspection. |
| b3 red control, origin condition removed | Phase 6 would also remove `other`: the origin gate is what protects a foreign checkout. |
| c1 fail closed | `same_origin` is False for `proj-noorigin` and `safe_deletable` is False ("not strictly within SAFE_ROOTS"), independent of the fetch failure that also preserves it. |
| d1 NEVER_DELETE parent | Header: "(skipped <HOME>: NEVER_DELETE root)"; only the listed roots are scanned. |

Teardown runs used the existing `MERGE_CLEANUP_GH_BIN` seam with a stub printing `[]`, because the scratch HOME has no gh login and the fixture remotes are local paths. Without it, PR discovery refuses with exit 2 before Phase 6, as designed.
