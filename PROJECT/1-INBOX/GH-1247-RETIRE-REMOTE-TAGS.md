---
title: merge-cleanup treats a local tag that origin already holds as unpushed, so published task clones are never retired
status: Proposed (1-INBOX — not yet active)
created: 2026-10-28
owner: noelsaw1
gh_issue: 1247
source: https://github.com/HiQS-Labs/XYZ-forge/issues/1247
doc_type: bugfix
complexity: 2
risk: 2
effort: 2
phases: 1
ratings_provisional: true
reported_from: LTVera-Pandas
harness_commit: 93f41cb8
non_goals:
  - Changing how branches, detached HEAD, stashes or dirty files are judged.
  - Treating a local-only tag, or one whose object differs from origin's, as safe.
  - Refreshing the Skills Army deployed copy of merge-cleanup (a separate operator step).
related:
  - https://github.com/HiQS-Labs/XYZ-forge/issues/1193
  - https://github.com/HiQS-Labs/XYZ-forge/pull/1198
  - https://github.com/HiQS-Labs/XYZ-forge/issues/722
goal: >
  A start-task clone whose only non-integration refs are tags that origin holds at the same
  object id is retired by --retire-published-pr (and reads SAFE_REMOVE in the audit), while a
  local-only or diverged tag still preserves the checkout and a failed lookup still fails closed.
---

# GH-1247 — merge-cleanup treats origin-held tags as unpushed

> **1-INBOX capture**, not the active-work doc — no `## Status` table yet. On promotion to
> `PROJECT/2-WORKING/`, add the status table + per-phase QA gates and carry `gh_issue` forward
> (`PROJECT/PDDA.md` → GitHub issue intake).

## Symptom

`merge_cleanup.py --retire-published-pr` preserves a fully published task clone as `PRESERVE_UNPUSHED`
whenever the repository has a tag not reachable from the integration branch, even when `origin` holds that
exact tag at the same object id.

## Environment

- **Observed from:** `LTVera-Pandas` (vendored `.xyz/`; driver run from the XYZ-forge checkout)
- **Harness commit:** `93f41cb8` (includes the #1198 safe-root fix)
- **Worker/CLI:** n/a (`merge_cleanup.py`)
- **Runtime:** Python
- **Sandbox:** off

## Reproduction

1. Clone a repository that has tags off its integration branch (here `archive/merge-group-1-2026-10-09` and
   `archive/merge-group-2-2026-10-09`, both present on `origin`).
2. Publish a PR from that clone so the branch head equals the PR head and `origin`; leave it clean, no stashes.
3. `python3 skills/2-daily/merge-cleanup/scripts/merge_cleanup.py --primary <primary> --retire-published-pr <n> --checkout <clone>`

**Expected:** the tags are recognised as recoverable from `origin` and the clone is retired.
**Observed:** `PRESERVE_UNPUSHED`, naming both tags; the clone is skipped.
**Frequency:** every time, for any repo with tags off the integration branch.

```text
PRESERVE_UNPUSHED | Unlanded local refs:
refs/tags/archive/merge-group-1-2026-10-09 @ dc965a88c5: not reachable from origin/development; no merged PR has this head
refs/tags/archive/merge-group-2-2026-10-09 @ e87ed4fe37: not reachable from origin/development; no merged PR has this head
```

`git ls-remote --tags origin 'archive/*'` returns both tags at the identical object ids.

## Cause (from reading the code, not yet confirmed in this repo)

`checkout_ref_provenance` in `skills/2-daily/merge-cleanup/scripts/scan_clones.py` (around lines 540-555)
collects every ref except `refs/remotes/*` and `refs/stash`, so cloned tags count as local refs. Each must then
be an ancestor of `origin/<integration>`, inside the published PR head, or a merged PR's head. Nothing checks
whether `origin` holds the same ref.

## Impact

Every start-task clone of an affected repo is unretirable, so clones accumulate on disk. Not blocking:
the checkout is preserved and can be removed by hand.

## Phase 0 — Diagnose & scope

> Discovery phase: its findings are written **back into this doc** before its QA gate can pass
> (`PROJECT/PDDA.md` → Discovery & spike phases).

### Checklist
- [ ] Reproduce it in the intake repo (not just in the reporting repo)
- [ ] Locate the responsible script/path — name the concrete write-set
- [ ] Decide fix vs. guard-and-document; reuse an existing code path before adding one (`/ponytail`)
- [ ] Set/correct the triage ratings; clear `ratings_provisional` once real

### QA checklist — Phase 0
- [ ] The repro is confirmed from the report, not assumed
- [ ] An existing suite, or a recorded manual check, covers the failure path before the fix lands (no new test suites: `AGENTS.md` *No new tests*, GH-831)
- [ ] The fix composes with the existing harness rather than adding a parallel path
