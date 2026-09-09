# RELAY — GH-523 merge-cleanup Phase 0 (primary checkout first)

STATUS: In progress
NEXT: codex
ROUND: 1

## Body

### Context

`/merge-cleanup` is the standing landing path for this repo: it audits every checkout, sequences
open PRs topologically, merges them, fast-forwards the primary, and runs governance reconciliation
there. A run on 2026-09-09 reported the full PR matrix and merge order **without ever establishing
whether the operator's own on-disk checkout could receive any of it**. This branch fixes that.

The change under review is commit `5710f6f4` on `fix/merge-cleanup-primary-first`, closing #523.

### What changed

1. `skills/merge-cleanup/scripts/scan_clones.py`
   - `scan_directories` now force-includes the primary checkout **by identity** and reports it
     first, whatever `--prefix` and `SAFE_ROOTS` say. Previously the `PRIMARY_CHECKOUT` tag was
     applied inside the discovery loop, so a primary outside those roots or under a non-matching
     prefix vanished from the audit entirely while `main()` went on merging PRs into it.
   - New `inspect_primary_landing(primary_repo, integration_branch="development")` answers the
     four questions that decide whether a landing is possible: current branch vs integration
     branch, working-tree cleanliness, local commits on the integration branch that `origin` lacks,
     and whether HEAD can fast-forward to `origin/<integration>`. It never raises.
   - New `format_primary_landing()` renders the Phase 0 verdict.

2. `skills/merge-cleanup/scripts/merge_cleanup.py`
   - Prints `PHASE 0: PRIMARY ON-DISK CHECKOUT` **before** the Phase 1-3 audit and before any
     `gh` call.
   - **Refuses to merge** (returns 2) when the primary is not landing-ready, unless
     `--allow-unready-primary` is passed. New `--integration-branch` defaults to `development`.
   - `main()`'s return code now propagates via `sys.exit(main() or 0)`.

3. `skills/merge-cleanup/SKILL.md` — documents Phase 0 as first and by-identity, renames the
   ladder 6-Phase → 7-Phase, adds a "No Blind Landing" safety guarantee, and states that
   not-ready is a refusal rather than a warning discovered at merge time.

4. `test/gh436-merge-cleanup.py` — 7 new cases in `TestPrimaryCheckoutIsInspectedFirst`.

### Evidence

Suite: 18/18 (`python3 test/gh436-merge-cleanup.py`).

Red controls, both observed:

| Mutation | Result |
|---|---|
| force-include removed | `AssertionError: 'primary' not found in [] : primary vanished from the audit: []` |
| `landing_ready` hardcoded `True` | 3 FAILs: dirty tree, feature branch, unpushed commits |

Against the live primary, Phase 0 reports:

```
branch: fix/gh502-security-dialog-detector  (integration: development)
clean: no (2 path(s))
landing: NOT READY
  - on 'fix/gh502-...', not the integration branch 'development'
  - 2 uncommitted path(s)
  - 4 local commit(s) on 'development' are not on origin
```

### Questions for the reviewer

Please review the actual files on disk, not this summary.

1. **Does Phase 0 actually run first in every path through `merge_cleanup.main()`?** In particular
   `--reconcile-pr`, `--scan-only`, `--prs-only`, and `--teardown-only`. Is there any route that
   still mutates the primary — merge, fast-forward, or reconciliation — without the Phase 0
   verdict having been computed?

2. **Is the merge refusal placed correctly?** It gates on `args.execute`, so a dry run still
   prints the sequence. Is that the right boundary, or should a dry run also say plainly that this
   sequence would be refused?

3. **Is `landing_ready` the right predicate?** It is
   `on_integration_branch and is_clean and not unpushed_on_integration`. `can_ff` is computed but
   deliberately not part of the verdict. Is that a gap — can a checkout satisfy all three and
   still fail `git merge --ff-only origin/development`?

4. **Are the blockers complete for a landing?** Unpopped stashes and in-progress operations
   (rebase/merge/cherry-pick state, detached HEAD) are not currently blockers. Which of those
   would actually break the landing or lose work, and which are noise?

5. **Failure modes of `inspect_primary_landing`.** It must never raise — a bad primary path, a
   missing `origin` remote, a repo with no commits, a branch with no upstream. Does any input make
   it throw, or silently report ready when it is not?

6. **Does the SKILL.md text actually change agent behaviour?** The skill is read by an agent, not
   executed. Is Phase 0 stated early and unambiguously enough that a session following the doc
   reports the operator's own checkout before the PR table, or does the PR-centric framing
   elsewhere in the doc still dominate?

7. **Scope discipline.** Is anything here a second system rather than an extension of the existing
   one? Is any of it out of scope for #523?

---

## ▶ TAKE YOUR TURN

You are the **reviewer**. Read the four changed files under
`skills/merge-cleanup/` and `test/gh436-merge-cleanup.py` at HEAD, plus `git show 5710f6f4` for
the diff. Cite file:line for every finding. Rank each finding Blocking / Should-fix / Low.
Append your review block below, then set STATUS and hand the token back.
