# Metamorphic linked-worktree configuration visibility

PR953's Fable review S1 identifies an existing gap in
`utils/py/metamorphic_oracle.py::_capture_repo_state`: it hashes `.git/config`
directly, so a linked worktree with a `.git` file has no configuration hash.
Source: `relay-system/2026-10-03/gh949-fable-qa.md`, S1; the source still follows
that path. The adjacent domain oracle resolves common and worktree Git metadata.

The reviewer explicitly classified this as nonblocking and outside F3's
`host_identity` acceptance scope. PR953's resumed repair addresses B1 cancellation
without expanding state-snapshot semantics. Next triage check: reproduce a config
mutation through `check_zero_mutation` in a disposable full clone and linked fixture,
then decide whether to reuse the domain oracle's existing metadata resolution.
