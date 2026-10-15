Current correction: the shared native inspection now preserves ignored content in both
ordinary and published cleanup. `all-native/` records the additional ordinary admission
RED, shared-guard manual47 + existing cleanup180 pass, and final manual48 covering real
Git exit0/incomplete enumeration. The initial scoped evidence below remains historical
at1fb2d9f4; it does not claim current ordinary-mode preservation was already present there.

# PR1061 published-worktree preservation correction

A clean Git status and a fully published HEAD do not preserve ignored worktree files.
A backed-up own synthetic native-Git fixture demonstrated `git worktree remove` returning
0 and deleting a clean worktree’s ignored operator-notes.txt. No existing checkout was
removed; the synthetic notes were retained outside the candidate.

The new published-closeout mode enumerates ignored files for linked worktrees in its
existing inspection owner. Nonempty results produce PRESERVE_IGNORED; a failed query
uses the existing unknown-query preservation path. Fresh inspection repeats the check.
Whole-clone Trash and ordinary merged-only behavior stay unchanged.

At source 1fb2d9f4, a separate full clone passed the unchanged existing cleanup suite
(180 tests) and45 recorded manual observations: the original41 cases plus ignored
content preservation, execute preservation, failed enumeration, and an in-memory
guard-removal red control. API/origin metadata is stubbed; actual Git ancestry,
fetch, native operations and fixture Trash run on isolated fixture repositories.
No CI test, parametrized case, suite or registry entry was added. Verification clone
HEAD/tree/origin/bare/config identity is unchanged, as verification-results records.

Original final QA is already2/3. This correction and upcoming canonical integration
refresh require the remaining third round, then a normal publication gate and fresh
exact-head checks. No review or repair cap is reset.
