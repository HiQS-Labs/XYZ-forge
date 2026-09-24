---
gh_issue: 736
source: https://github.com/HiQS-Labs/XYZ-forge/issues/736
title: "merge-cleanup: --exclude never drops a PR, UNKNOWN mergeability stops every run after a landing, stacked PRs are auto-closed when their base lands with --delete-branch"
status: Complete
created: 2026-09-21
updated: 2026-09-24
owner: unassigned
doc_type: capture
complexity: 2
risk: 2
effort: 2
rating: "pri/sev/appeal/effort 60/60/80/60 · calc 260"
rating_ovr: null
is_manual_override: false
ratings_provisional: true
goal: >
  merge-cleanup honours --exclude for PRs, polls a transient UNKNOWN mergeability instead of
  stopping the run after every landing, and does not auto-close stacked PRs when their base lands
  with --delete-branch.
---

# GH-736 — merge-cleanup: --exclude never drops a PR, UNKNOWN mergeability stops every run after a landing, stacked PRs are auto-closed when their base lands with --delete-branch

## Status

| What was just completed | What's next |
|---|---|
| Queued by the 2026-09-21 `/10days` sweep: validity, reproducibility and not-already-done verified against HEAD e565c0fe (see Why); contract auto-drafted. | Marathon lane fires from `marathon/10days-2026-09-21` via `swarm-preflight → marathon-drive`, scoped by the contract's `artifacts`. |

## Why

All three gaps reproduce at HEAD in `skills/merge-cleanup/scripts/merge_cleanup.py`: `--exclude`
only reaches `scan_directories` (`:1032`) / `refresh_for_teardown` (`:1152`) while the R2-2 refusal
at `:1127` tells the operator to "exclude them"; a `mergeable` that is neither MERGEABLE nor
CONFLICTING exits 2 at `:797-799` with no poll although `_sleep` and `refresh_pr_with_retry` exist;
`gh pr merge … --delete-branch` at `:149` is unconditional, so a PR stacked on the landed PR's head
is auto-closed by GitHub. The issue supplies patches for 1 and 2; 3 is a design call resolved here
as retarget-or-withhold. No commit or PR references #736.

## Acceptance

Authored by `/10days` — the tracking issue has no `## Acceptance` section swarm-preflight recognises, so there is no block to copy verbatim. These criteria transcribe the issue's fix / expected-behaviour text.

- [ ] `--exclude <N>` drops PR N from `ordered_prs` before the R2-2 base check, logging `excluded by
      --exclude; not sequenced this run`; the `--exclude` help text says it applies to PRs as
      well as checkouts.
- [ ] In Phase 5, a `mergeable` that is neither `MERGEABLE` nor `CONFLICTING` is polled up to
      `MERGEABLE_POLL_ATTEMPTS=6` × `MERGEABLE_POLL_S=15` via `_sleep` + `refresh_pr_with_retry`
      before the existing fail-closed stop; a persistent UNKNOWN still stops the run.
- [ ] Before a base PR is landed with `--delete-branch`, any open PR whose `baseRefName` is that PR's
      head is retargeted to the integration branch (`gh pr edit N --base <integration>`), or
      `--delete-branch` is withheld while such a dependent is open; the choice is logged.
- [ ] Unit pins in `test/gh436-merge-cleanup.py` cover all three (exclude drops the PR; UNKNOWN then
      MERGEABLE lands; UNKNOWN×7 stops; stacked PR is retargeted or the branch delete is
      withheld).
- [ ] `skills/merge-cleanup/SKILL.md` example 6 and the Phase 5 text match the shipped behaviour.
- [ ] `bash validate.sh` exits 0.
- [ ] `bash test/gh436-merge-cleanup.sh` stays green INCLUDING `gh534_phase_a_tests.TestA5FreshInspection`, whose `fake_merge()` stub does not accept a `delete_branch` kwarg — do not add new keyword arguments to the `execute_pr_merge(...)` call in `land_prs` (marathon attempt 1 on 2026-09-22 passed `delete_branch=` and raised `TypeError: fake_merge() got an unexpected keyword argument 'delete_branch'` in 5 tests); carry the withhold decision through module state or a separate call instead. Run that suite before handing off.

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
      "pattern": "help=\"Pattern or branch to exclude from cleanup\""
    },
    {
      "type": "grep_present",
      "path": "skills/merge-cleanup/scripts/merge_cleanup.py",
      "pattern": "res = _gh\\(\\[\"pr\", \"merge\", str\\(pr_num\\), f\"--\\{strategy\\}\", \"--delete-branch\"\\], repo_path, timeout=600\\)"
    }
  ],
  "artifacts": [
    "skills/merge-cleanup/scripts/merge_cleanup.py",
    "test/gh436-merge-cleanup.py",
    "skills/merge-cleanup/SKILL.md"
  ],
  "remediation": {
    "source": "issue#736",
    "criteria": "--exclude drops PRs, bounded UNKNOWN-mergeability poll, retarget-or-withhold for stacked PRs; unit pins for all three"
  },
  "lanes": {
    "agy_safe": [
      "skills/merge-cleanup/scripts/merge_cleanup.py",
      "test/gh436-merge-cleanup.py",
      "skills/merge-cleanup/SKILL.md"
    ],
    "orchestrator_only": []
  }
}
```

Contract auto-drafted by /10days from the issue text — artifacts/lanes not yet operator-verified. Fix probes detect the BUG (`grep_present` = bug still there, `grep_absent` = fix landed), per swarm-preflight polarity.
