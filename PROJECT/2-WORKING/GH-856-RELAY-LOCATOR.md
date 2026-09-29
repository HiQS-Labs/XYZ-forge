---
gh_issue: 856
source: https://github.com/HiQS-Labs/XYZ-forge/issues/856
title: "Locate the relay harness from a deployed relay-xyz skill"
status: Active (2-WORKING — plan review)
created: 2026-09-27
updated: 2026-09-29
owner: Codex
doc_type: bugfix
branch: fix/gh856-relay-locator
complexity: 3
risk: 2
effort: 3
phases: 1
non_goals:
  - No new locator or test suite; extend the shipped script and registered tests.
  - No implicit network fetch or automatic git branch switch during readiness checks.
  - No machine-specific path committed to the repository.
goal: >
  A deployed relay-xyz skill finds the canonical harness on each supported Mac,
  and its readiness check reports stale clones and held locks accurately.
---

# GH-856: Relay harness locator

## Status

| What was just completed | What's next |
|---|---|
| Fresh full clone at `c7ea57fd`, issue captured and parked, locator failures reproduced, and current resolver/test seams traced. | Review this plan with Codex; then implement the scoped resolver change and verify it in a disposable full clone. |

## Rating — 2026-09-29: `86/82/50/55` (priority/severity/appeal/effort)

- **Severity 82:** A copied skill cannot start Path A from an unrelated checkout on four reported Macs. A manual override can select a stale clone without a readiness warning; work is recoverable but can land in the wrong clone.
- **Priority 86:** The operator is blocked on a Codex relay now. Issue #856 is one distinct new report in 2026-09-16–29. Issues #394 and #395 in the preceding 2026-09-02–15 window report adjacent resolver failures; #396 tracks that family. This is not evidence that incident frequency increased.
- **Appeal 50:** Neutral; the operator gave no desirability score.
- **Effort 55:** A bounded Bash resolver change plus fixtures in existing suites, with cross-platform and deployment-path verification. Higher means cheaper.

## Recon — observed at `c7ea57fd`

- The installed copy under `Deployed Skills/relay-xyz` cannot find a harness when called from an unrelated repository with `XYZ_HARNESS` and `XYZ_REPO_ROOT` unset: `find-harness: relay-automation/ harness not found` (exit 1). With an explicit harness override, `--check` exits 0 but prints `driver_lock_path_for_repo: command not found`.
- `skills/1-hourly/relay-xyz/find-harness.sh:95-105` follows a file symlink, then sources `harness-paths.sh` relative to the skill location. A copied skill has no sibling `relay-automation/`, so the library and its `driver-lock-lib.sh` dependency never load. The lock warning at `:346` then calls an undefined function.
- The locator tries override, caller `.xyz`, main-worktree `.xyz`, current git root, then a self-relative harness (`:120-183`). Its vendored drift comparison repeats the self-relative assumption (`:196-220`). Outputs are `--root`, `--env`, and advisory `--check`; `--env` feeds the relay driver and tick through exported paths.
- `relay-automation/harness-paths.sh` sources `driver-lock-lib.sh` from beside itself. Loading that one library from the **resolved** `$HARNESS` supplies the shared lock resolver without a second implementation.
- Existing `test/find-harness.sh` and `test/gh396-find-harness-roots.sh` cover caller, worktree, override, self, and vendored precedence. The copied deployment and selected-clone freshness cases are missing. Extend those suites; AGENTS.md forbids adding a suite or registry entry.
- Issue #856 has no PR or existing project doc. Related open #394/#395/#396 address override and vendored root behavior; keep their contracts intact and link them rather than silently taking their whole scope.

## Plan

1. Extend the existing locator with an optional single-path per-device config (`${XDG_CONFIG_HOME:-$HOME/.config}/xyz/harness`) and a bounded list of documented XYZ-forge clone locations. Apply these only after the existing override, vendored, git-root, and script-relative choices. Search exact `XYZ-forge` directories and accept only the canonical `HiQS-Labs/XYZ-forge` origin. If several candidates remain, prefer a unique `development` checkout; otherwise show them and refuse to guess. Treat a stale or invalid config as a diagnostic and continue to the search.
2. After `$HARNESS` is chosen, source its `relay-automation/harness-paths.sh`. Reuse the same canonical-clone lookup for vendored drift comparison. Keep `driver_lock_path_for_repo` behind an availability check so a genuinely old vendored bundle yields an explicit advisory instead of a shell error.
3. In `--check`, compare a non-vendored git harness to its cached upstream without fetching. Warn on a non-`development` branch and on a positive behind count. Show the last local `FETCH_HEAD` timestamp, or `unknown` when unavailable; do not confuse a commit date with a fetch time. Preserve exit 0 for an otherwise usable harness.
4. Update the locator's actionable failure message and the immediately relevant `relay-xyz` skill/install wording to say `XYZ-forge`. Keep all command paths quoted for spaces and Bash 3.2 compatibility.
5. Extend the registered `find-harness` tests with copied-skill, config/search/ambiguity, lock warning, and behind-clone controls. Run the focused suites in a disposable full clone. Run one final qualifying gate on the final approved commit and record its receipt. Update CHANGELOG under PDDA rules.

## Acceptance and falsifiers

- **Copied-skill red control, witnessed now:** from a foreign repository with both override variables unset, the currently deployed copy exits 1. A copied fixture after the fix resolves a unique canonical clone with `via=config` or `via=search` and emits usable `--env` exports.
- **Missing-library red control, witnessed now:** override plus foreign cwd prints `driver_lock_path_for_repo: command not found`. After the fix, a fixture with a held driver lock prints the held-lock warning without that error.
- **Ambiguity control:** two equally qualified canonical clones cause a named refusal. A task clone named `XYZ-forge-gh856` cannot win the search. Invalid config cannot suppress a valid unique search result.
- **Freshness control:** a fixture clone one commit behind its cached upstream prints the count and local fetch time, then exits 0. A current `development` clone has no false stale warning. No check initiates a fetch.
- Existing override, vendored, worktree, git-root, and self-relative cases retain their exact root and tick behavior in the registered suites. No new suite or registry entry appears in the diff.

## Risk and rollback

Discovery can select the wrong clone when multiple copies exist. Origin validation, an exact directory name, and ambiguity refusal constrain that risk. The config file is read-only and explicit override remains highest precedence. Revert the locator commit to restore the previous behavior; `XYZ_HARNESS` remains the immediate workaround. Four-device confirmation and Skills Army redeployment occur after merge and are not claimed by this local PR.

## Observed failure

The copied Skills Army HQ deployment of `relay-xyz` cannot resolve the harness
from a foreign repository without `XYZ_HARNESS`. Its script-relative fallback
assumes the skill remains inside XYZ-forge. With an override, `--check` attempts
to call `driver_lock_path_for_repo` without loading its library.

## Requested result

- Resolve the canonical XYZ-forge clone from a deployed copy while preserving
  explicit override, vendored harness, and current-repository precedence.
- Keep discovery unambiguous across similarly named task clones and different
  Mac repository roots; report candidates and an actionable remedy on failure.
- Source shared path and lock functions from the resolved harness.
- Warn when the chosen harness is behind its cached upstream or on an unexpected
  branch, without making the readiness check a network-dependent gate.
- Verify the copied-skill scenario and existing locator behavior on the
  repository's registered suites, then refresh the deployed skill after landing.

The [GitHub issue](https://github.com/HiQS-Labs/XYZ-forge/issues/856) holds the
full cross-device observations and acceptance criteria.
