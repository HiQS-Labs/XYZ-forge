# GH-927 verification

- Claude Code Fable (`claude-fable-5-1`), high effort: Round 1 requested a priority-handoff correction; Round 2 Approved the three skill files at `33cba144a005b293bfe1d616efb76416ae750020`. Static scenario QA, not executed behavioral tests. Relay receipt: `relay-system/2026-10-02/gh927-sanity-check.fable.md`.
- Final sanity-check and whack-a-mole metadata validation passed. An invalid-name scratch copy failed the same validator (red control). Relative sibling links resolve.
- Radar's unchanged description is 1336 characters (validator limit 1024); parked separately. No change to its metadata was made.
- Claude relay adapter: 37 passed, 0 failed, in a separate disposable full clone.
- Initial 72-suite Small-tier run exited 1: gh448, gh429, gh358 failed with the inherited XYZ_HARNESS override. All other selected suites and the runner identity check passed. Targeted reruns with XYZ_HARNESS, XYZ_ROOT and TICK_REPO_ROOT removed passed: gh448 18/18, gh429 15/15, gh358 8/8. The original run remains failed; no clean whole-tier rerun is claimed. Both logs and reruns are retained.
- HEAD, remotes and local Git config matched their pre-run values. Local checks are not hosted CI or promotion evidence.
- Publication was subsequently authorized. This PR contains the Markdown skill, four reciprocal sibling pointers, task intake, and QA evidence; installation and merging are outside this task.

## Additional independent QA — GLM

Command Code profile `glm 5.3 max` resolved to `zai-org/glm-5.3`, max effort, self routing. The relay returned Approved in one round (exit 0), reviewing `cf4129bf95a8f77b31fba1525739774639353fe3`. It read all three skill files and reused-skill references; no prior reviewer verdict was supplied as evidence. Receipt: `relay-system/2026-10-02/gh927-sanity-check.glm.md`. The Command Code adapter passed 21/21 checks in a separate full clone.

No blockers or required changes. One optional wording nit remains: explicitly require a reused disposition to cover the cluster/shared mechanism, not merely one member; add “same scope and evidence” to Radar's reciprocal pointer. Both reviews consider this bounded by existing evidence and approval rules. The skill content was not changed during this additional review, preserving the reviewed version. Provider token usage was unavailable for the GLM turn; no token total is inferred from the driver's aggregate lower-bound summary.

## CI linkage QA — Sol

The operator subsequently requested reciprocal ci-debug / ci-optimize pointers. `gpt-6.1-sol`, high effort, Approved only the 38 added linkage lines at `d2f9038d5e981de15e69e244a0aa2598e70792d0`, with no findings or nits. Receipt: `relay-system/2026-10-02/gh927-ci-linkages.sol.md`. Earlier Fable and GLM reviews cover the original full skill content; Sol covers this later delta, not a new full review.

`linkage-validation.json` records final skill hashes: sanity-check, ci-debug, ci-optimize, and whack-a-mole pass metadata validation; Radar retains its baseline description-length failure. All nine relative skill links across the five files resolve. The push classifier selects the deterministic documentation gate (`route=docs`, `tier=1`); the earlier whole Small-tier run is not claimed green.
