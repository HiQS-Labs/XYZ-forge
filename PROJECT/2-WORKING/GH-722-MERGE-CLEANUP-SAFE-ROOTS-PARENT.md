---
gh_issue: 722
source: https://github.com/HiQS-Labs/XYZ-forge/issues/722
title: "merge-cleanup: SAFE_ROOTS never includes the primary's own parent, so the SOP's sibling task clones (../XYZ-forge-<topic>) are invisible to the default audit and teardown"
status: Active (2-WORKING)
created: 2026-09-21
updated: 2026-10-29
owner: noelsaw1
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
| 2026-10-29: picked up by /start-task in `XYZ-forge-gh722-merge-cleanup-safe-roots-parent-2026-10-29` (base 0628da70). #1198 already widened the retire mode only; plan below covers the default scan and Phase 6. | Codex plan QA, then implement. |

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
- [ ] `WORKTREE-SAFETY.md` §16.1 documents the derived root next to the pinned list (the list
      itself is unchanged, so the parity test stays green). No new test (GH-831): the derived root
      and the NEVER_DELETE skip are witnessed by a manual check under `TESTS-RESULTS/`.
- [ ] The Phase 1 header prints the roots that were actually scanned.
- [ ] `skills/merge-cleanup/SKILL.md` mentions the derived sibling root.
- [ ] `bash validate.sh` exits 0.
- [ ] `bash test/gh436-merge-cleanup.sh` stays green. (Superseded 2026-10-29: #1198 already gave `teardown_checkout` a `safe_roots` kwarg, so Phase 6 passes it and the one exact-call assertion is updated to stay truthful.)
- [ ] (2026-10-29) A clean, landed checkout in the primary's parent folder whose `origin` differs from the primary's stays `PRESERVE_UNSAFE_ROOT`; the default scan does not inspect foreign-origin entries of that folder at all.

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

## Merge evidence

- PR #1198 merged 2026-10-28 — linked issue still OPEN; doc stays active by design (GH-202: promotion requires the issue to be closed).


## Plan (2026-10-29, /start-task)

**Observed.** `DEFAULT_SAFE_ROOTS` (`skills/2-daily/merge-cleanup/scripts/scan_clones.py:26`) never includes `~/Documents/GitHub Repos`, where GH-970 puts task clones as siblings of the primary. #1198 added `published_retirement_roots(primary)` (`scan_clones.py:53`) and used it for `--retire-published-pr` only (`merge_cleanup.py:1690`, `scan_clones.py:945`). The default scan roots (`merge_cleanup.py:1818`, `scan_clones.py:1421`), the inspection safe-root check (`scan_clones.py:946`) and Phase 6 teardown (`merge_cleanup.py:2178`) still use the fixed list, so a clone whose PR branch was deleted on merge, or a landing clone with no PR, can never be retired there (live case: three LTVera clones beside `LTVera-Pandas`).

**Recon finding that shapes the fix.** The parent folder holds unrelated repositories. The disposition ladder (`scan_clones.py:1036-1130`) has no origin check, so a clean, fully landed checkout of another project would become `SAFE_REMOVE_CLONE` once its folder is a safe root. Retire mode already refuses a foreign origin (`merge_cleanup.py:1712`); the default path must do the same.

**Outcome sought.** `merge-cleanup` run against a primary finds and can retire its own sibling task clones without `--root`, and never treats another project's checkout as removable.

**Smallest change (existing subsystem: `scan_clones.py` roots + `inspect_checkout`, canonical writer unchanged).**
1. `scan_clones.py`: rename `published_retirement_roots` to `primary_safe_roots(primary)` (same body; docstring now covers every mode). Add `same_origin(a, b)` using the existing `_normalize_remote`.
2. `inspect_checkout`: use `primary_safe_roots(primary)` for the safe-root check only when the checkout's origin matches the primary's; otherwise keep `DEFAULT_SAFE_ROOTS`. Retire mode is unchanged in effect (it already enforces origin).
3. Default scan roots (both `main`s): `DEFAULT_SAFE_ROOTS` + the parent. `scan_directories` skips foreign-origin entries of that derived root, so the default audit does not fetch into unrelated repos. Explicit `--root` keeps today's behaviour.
4. Phase 6: `teardown_checkout(c, dry_run=..., safe_roots=primary_safe_roots(primary))`; update the one exact-call assertion in `test/gh436-merge-cleanup.py:711`.
5. Phase 1 header (both `main`s) prints the scanned roots, and names the parent as skipped when it is a `NEVER_DELETE` root.
6. Docs: `WORKTREE-SAFETY.md` §16.1 paragraph after the pinned list, and `skills/2-daily/merge-cleanup/SKILL.md` Phase 1 and retire sections: the parent folder counts for same-origin checkouts in every mode.

**Non-goals.** No change to `DEFAULT_SAFE_ROOTS` or `NEVER_DELETE`, to the disposition ladder's other rungs, to retire-mode rules, or to `--root` semantics. No new suite or registry entry (GH-831).

**Alternatives rejected.** Adding `~/Documents/GitHub Repos` to `DEFAULT_SAFE_ROOTS`: device-specific and breaks for any other primary location. Telling operators to pass `--root`: the workaround still fails at teardown, because deletion safety ignores `--root`.

**Verification.** Existing suites `bash test/gh436-merge-cleanup.sh` and the GH-534 phase A/C suites (via their `validate.sh` route), then the full gate once on the final commit (routes as code). Smoke under `TESTS-RESULTS/2026-10-29+GH-722/`: (a) main path, `--scan-only` dry run against the LTVera landing clone as primary lists the three sibling clones and prints the roots; foreign-origin repos in the same folder are absent; (b) adjacent path, a throwaway primary placed directly under a `NEVER_DELETE`-equivalent parent is reported as skipped (via a temp HOME). Red control: before the change, (a) lists only the primary.

**Rollback.** Revert the single PR; behaviour returns to the fixed list.
