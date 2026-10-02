# GH-927 verification

- Claude Code Fable (`claude-fable-5-1`), high effort: Round 1 requested a priority-handoff correction; Round 2 Approved the three skill files at `33cba144a005b293bfe1d616efb76416ae750020`. Static scenario QA, not executed behavioral tests. Relay receipt: `relay-system/2026-10-02/gh927-sanity-check.fable.md`.
- Final sanity-check and whack-a-mole metadata validation passed. An invalid-name scratch copy failed the same validator (red control). Relative sibling links resolve.
- Radar's unchanged description is 1336 characters (validator limit 1024); parked separately. No change to its metadata was made.
- Claude relay adapter: 37 passed, 0 failed, in a separate disposable full clone.
- Initial 72-suite Small-tier run exited 1: gh448, gh429, gh358 failed with the inherited XYZ_HARNESS override. All other selected suites and the runner identity check passed. Targeted reruns with XYZ_HARNESS, XYZ_ROOT and TICK_REPO_ROOT removed passed: gh448 18/18, gh429 15/15, gh358 8/8. The original run remains failed; no clean whole-tier rerun is claimed. Both logs and reruns are retained.
- HEAD, remotes and local Git config matched their pre-run values. Local checks are not hosted CI or promotion evidence.
- The reviewed skill content remains local on `feat/sanity-check-skill`; no installation, push, PR, or merge was performed in this draft-and-QA iteration.
