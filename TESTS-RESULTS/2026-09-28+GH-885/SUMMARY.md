# GH-885 Skills Fast-Lane Measurements

Recorded: 2026-09-28
Clone: `/Users/noelsaw/Documents/GH Repos/XYZ-forge-measurements-885-20260928`
Commit: `c7ea57fded7a8810547cd1b6dd86d31ab73dfd5e`

## Measurement 3: repeated operations across skill scripts

Inventory method: tracked files under `skills/**`; markdown, fixtures, and test-only files excluded from implementation counts. Pattern counts are by unique skill directory, not file count.

- Skill directories in the clone: 63.
- Skill directories shipping non-markdown implementation files: 35.
- Repeated JSON/state handling: 8 skills.
  - `standup`, `agent-chorus`, `merge-cleanup`, `10days`, `skills-army-hq`, `ci-doctor`, `rpr`, `vscode-color`
- Repeated GitHub issue/API handling: 3 skills.
  - `standup`, `relay-to-issue`, `10days`
- Repeated clone/worktree helper handling: 5 skills.
  - `relay-xyz`, `agent-chorus`, `file-xyz-bug`, `merge-cleanup`, `ci-doctor`
- Repeated release/ledger calls: 2 skills, below the issue's threshold of three.
  - `standup`, `merge-cleanup`
- Skills reaching outside their own folder into Forge code or runtime locators: 9.
  - `relay-xyz`, `standup`, `agent-chorus`, `file-xyz-bug`, `hq`, `merge-cleanup`, `review-xyz`, `skills-army-hq`, `vscode-color`

## Interpretation

The inventory supports the issue's shared-library decision rule for JSON/state and clone/worktree helpers: each appears in at least three skills. GitHub issue/API handling also crosses the threshold. Ledger calls do not yet cross it. The external-coupling list confirms that portability risk is concentrated in a small set of integration-heavy skills.

The count is 35 rather than the issue's preliminary estimate of 34 because this is a current-HEAD inventory with implementation files, excluding fixtures and tests by the method above.

## Measurement 2: elapsed time for one real skill change

**Pending.** GH-885 defines this as the *next* real skill change through the normal path. This measurement cannot be honestly reconstructed from this inventory run. The required phases are intake/capture, plan and QA relay, implementation, push gate, PR review/merge, hosted reconcile including queue time, and ledger/closeout. No such change was active during this run.

## Reproduction

See `provenance.jsonl` for the clone identity and commands used. The raw command output was retained in the session run and the counts above were checked independently by unique skill directory.
