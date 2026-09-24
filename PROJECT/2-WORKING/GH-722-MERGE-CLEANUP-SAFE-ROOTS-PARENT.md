---
gh_issue: 722
source: https://github.com/HiQS-Labs/XYZ-forge/issues/722
title: "merge-cleanup: SAFE_ROOTS never includes the primary's own parent, so the SOP's sibling task clones (../XYZ-forge-<topic>) are invisible to the default audit and teardown"
status: Active (2-WORKING)
created: 2026-09-21
updated: 2026-09-22
owner: unassigned
doc_type: capture
complexity: 2
risk: 2
effort: 1
rating: "pri/sev/appeal/effort 60/60/90/60 · calc 270"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  merge-cleanup's default scan includes the primary's own parent directory (subject to
  NEVER_DELETE), prints the roots it scanned, and keeps the WORKTREE-SAFETY §16.1 parity test
  honest.
---

# GH-722 — merge-cleanup: SAFE_ROOTS never includes the primary's own parent, so the SOP's sibling task clones (../XYZ-forge-<topic>) are invisible to the default audit and teardown

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

`skills/merge-cleanup/scripts/merge_cleanup.py:994` and `scan_clones.py:1268` fall back to
`DEFAULT_SAFE_ROOTS` only; SOP.md (`:22/:86/:210`) creates task clones as siblings of the primary
(`../XYZ-forge-<topic>`), so on a device whose primary lives under `~/Documents/GitHub Repos` the
default audit reported 1 checkout while 16 sat next to it. The Phase 1 header (`:1034`) prints no
roots, so an empty table reads as clean. `test/gh534_phase_a_tests.py:123` pins §16.1 parity. No
commit or PR references #722.

## Acceptance

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

## Swarm Preflight Contract

```json
{
  "target": {
    "repo": ".",
    "ref": "development"
  },
  "gate": "bash validate.sh",
  "fix_probes": [
    {
      "type": "grep_present",
      "path": "skills/merge-cleanup/scripts/merge_cleanup.py",
      "pattern": "if args\\.root else DEFAULT_SAFE_ROOTS"
    },
    {
      "type": "grep_absent",
      "path": "skills/merge-cleanup/scripts/merge_cleanup.py",
      "pattern": "primary_repo\\.parent"
    }
  ],
  "artifacts": [
    "skills/merge-cleanup/scripts/merge_cleanup.py",
    "skills/merge-cleanup/scripts/scan_clones.py",
    "WORKTREE-SAFETY.md",
    "test/gh534_phase_a_tests.py",
    "skills/merge-cleanup/SKILL.md"
  ],
  "remediation": {
    "source": "issue#722",
    "criteria": "Add dirname(primary) to merge-cleanup's scan roots under NEVER_DELETE, print scanned roots, keep §16.1 parity honest"
  },
  "lanes": {
    "agy_safe": [
      "skills/merge-cleanup/scripts/merge_cleanup.py",
      "skills/merge-cleanup/scripts/scan_clones.py",
      "WORKTREE-SAFETY.md",
      "test/gh534_phase_a_tests.py",
      "skills/merge-cleanup/SKILL.md"
    ],
    "orchestrator_only": []
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.

## Merge evidence

- PR #753 merged 2026-09-24 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).
