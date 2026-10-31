# Plan draft: #722 merge-cleanup: SAFE_ROOTS never includes the primary's own parent, so the SOP's sibling task clones (../XYZ-forge-<topic>) are invisible to the default audit and teardown

> draft; preflight and independent plan QA outstanding

- Request: `gh-722-991d1d92ddfa` (tick `slot_012`)
- Draft status: **ready**
- Planner state: ready; flags: none
- Rating: 60/60/90/60
- Capture doc: PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md (sha256 19ab7707c0e9d9aa55fecddfc9532a0bdadaa3d50544f83175a10838518f0e17)
- Issue sha256: 991d1d92ddfa7f65cd1364f12e2e3a8ccbeb9a6a9b243db8588439c90bbb3e4c (updated 2026-09-21T02:17:29Z)
- Dependencies: none

## Scope

_Source: PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md:L17 (frontmatter goal)_

merge-cleanup's default scan includes the primary's own parent directory (subject to NEVER_DELETE), prints the roots it scanned, and keeps the WORKTREE-SAFETY §16.1 parity test honest.

_Source: codex-authored (codex-authored)_

Verify the current issue status and scan-root behavior, then include the primary checkout's parent in default scan roots when permitted.

_Source: codex-authored (codex-authored)_

Report skipped protected roots and show the roots actually scanned in the Phase 1 header.

_Source: codex-authored (codex-authored)_

Keep the safety documentation, parity test, and merge-cleanup skill documentation consistent with the derived root.

## Acceptance criteria

_Source: PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md:L40 (Acceptance)_

Authored by `/10days` — the tracking issue has no `## Acceptance` section swarm-preflight recognises, so there is no block to copy verbatim. These criteria transcribe the issue's fix / expected-behaviour text.

- [ ] `dirname(--primary)` is added to the scan roots, still subject to `NEVER_DELETE`: a primary
      directly under `$HOME`, `~/Documents` or `~/Desktop` does not turn that directory into a
      scan root and is reported as skipped instead.
- [ ] `WORKTREE-SAFETY.md` §16.1 either documents the derived root or the parity test in
      `test/gh534_phase_a_tests.py` explicitly excludes it from the pinned list; the parity test
      stays green and a regression covers the derived root and the NEVER_DELETE skip.
- [ ] The Phase 1 header prints the roots that were actually scanned.
- [ ] `skills/merge-cleanup/SKILL.md` mentions the derived sibling root.
- [ ] `bash validate.sh` exits 0.
- [ ] `bash test/gh436-merge-cleanup.sh` stays green: `TestMergeCleanupOrchestration` asserts the exact `teardown_checkout(candidate, dry_run=...)` call — do not add a `safe_roots=` kwarg to that call (marathon attempt 1 on 2026-09-22 did and failed `test_ready_primary_allows_zero_pr_cleanup` / `test_operator_can_explicitly_defer_unready_primary_cleanup`); thread the derived root through module state or the scan call instead. Run that suite before handing off.

_Source: codex-authored (codex-authored)_

Sibling task clones under the primary's permitted parent are discovered by the default scan.

_Source: codex-authored (codex-authored)_

A primary directly under $HOME, ~/Documents, or ~/Desktop does not cause that protected directory to be scanned; the skipped root is reported.

_Source: codex-authored (codex-authored)_

The Phase 1 header identifies the roots actually scanned.

_Source: codex-authored (codex-authored)_

Regression coverage checks the derived root, protected-root skips, and safety documentation parity.

_Source: codex-authored (codex-authored)_

bash validate.sh and bash test/gh436-merge-cleanup.sh pass, preserving the existing teardown_checkout call contract.

## Open questions

_Source: codex-authored (codex-authored)_

Has the issue already been resolved since the documented 2026-09-21 verification?

## Write set

- `skills/merge-cleanup/scripts/merge_cleanup.py` (PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md:preflight-contract)
- `skills/merge-cleanup/scripts/scan_clones.py` (PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md:preflight-contract)
- `WORKTREE-SAFETY.md` (PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md:preflight-contract)
- `test/gh534_phase_a_tests.py` (PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md:preflight-contract)
- `skills/merge-cleanup/SKILL.md` (PROJECT/2-WORKING/GH-722-MERGE-CLEANUP-SAFE-ROOTS-PARENT.md:preflight-contract)

## Unresolved file names

- none

## Contract probes

- grep_present `skills/merge-cleanup/scripts/merge_cleanup.py`: blocked
- grep_absent `skills/merge-cleanup/scripts/merge_cleanup.py`: unfixed

## Existing preflight contract

```json
{
  "artifacts": [
    "skills/merge-cleanup/scripts/merge_cleanup.py",
    "skills/merge-cleanup/scripts/scan_clones.py",
    "WORKTREE-SAFETY.md",
    "test/gh534_phase_a_tests.py",
    "skills/merge-cleanup/SKILL.md"
  ],
  "fix_probes": [
    {
      "path": "skills/merge-cleanup/scripts/merge_cleanup.py",
      "pattern": "if args\\.root else DEFAULT_SAFE_ROOTS",
      "type": "grep_present"
    },
    {
      "path": "skills/merge-cleanup/scripts/merge_cleanup.py",
      "pattern": "primary_repo\\.parent",
      "type": "grep_absent"
    }
  ],
  "gate": "bash validate.sh",
  "lanes": {
    "agy_safe": [
      "skills/merge-cleanup/scripts/merge_cleanup.py",
      "skills/merge-cleanup/scripts/scan_clones.py",
      "WORKTREE-SAFETY.md",
      "test/gh534_phase_a_tests.py",
      "skills/merge-cleanup/SKILL.md"
    ],
    "orchestrator_only": []
  },
  "remediation": {
    "criteria": "Add dirname(primary) to merge-cleanup's scan roots under NEVER_DELETE, print scanned roots, keep \u00a716.1 parity honest",
    "source": "issue#722"
  },
  "target": {
    "ref": "development",
    "repo": "."
  }
}
```
