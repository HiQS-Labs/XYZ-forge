---
title: "GH-822: 2026-09-25 post-merge review — promote development to main and publish 0.9.0 Cargo"
status: Active
gh_issue: 822
source: https://github.com/HiQS-Labs/XYZ-forge/issues/822
doc_type: feedback
created: 2026-09-25
updated: 2026-09-25
owner: operator (via /start-task)
goal: >
  Promote development to main with GH-509 hosted macOS evidence for the exact commit, then publish the
  ledger's 0.9.0 "Cargo" as the first GitHub Release on that commit.
related:
  - "#823 / PR #824 — boundary-macos cap 45 -> 120 (the one code blocker), merged 61f09827"
  - "#796 — integration batch whose landings (#794, #795, #765) the review covered"
  - "#105 — 0.9.0 Cargo tracking issue"
---

# GH-822 — promote development to main and publish 0.9.0 Cargo

## Status

| What was just completed | What's next |
|---|---|
| #823 merged via PR #824 (`61f09827`) and was reconciled by the hosted lane (`a2de2359`), with hosted macOS qualification of `61f09827` at 422/422 (`validate.sh --sequential`, run 36162614517). This PR adds the GH-784 promotion QA receipt and trims 0.9.0 Cargo. | Merge this PR and wait for its reconcile, then recut `main`, watch `boundary-macos`, and publish the `0.9.0` Release. |

## Scope

The review itself lives in [#822](https://github.com/HiQS-Labs/XYZ-forge/issues/822): the last-12-hour merges are
compatible, with no conflicts and no regressions found. It named two promotion blockers, #823 (done) and a
GH-784 promotion QA receipt (`AGENTS.md:302`, this PR). Operator decisions on 2026-09-25:

- **Recut `main` from `development`.** Old `main` (`29144118`) is a strict ancestor with no commits of its own,
  so a fast-forward push gives the same result as deleting and recreating it.
- **Publish a GitHub Release, not a bare tag**, through the `/releases` Publish subroutine, as 0.9.0 "Cargo"
  after trimming its unfinished items.

## Cargo trim (ledger, this PR)

The manifest had 6 `dialed_in` items; the rest were already shipped or cut.

- #663 was closed as completed on 2026-09-17 by `4481ab48` (`fix(GH-663)`), so it is recorded `shipped` with that evidence.
- #342, #255, #256, #275 and #345 are still open, so they are **cut** from Cargo and **dialed into 0.6.0 "Front-Door"**,
  the next unshipped release by target date (`releases next`).

The exit criterion (a vendored repo runs `releases init/add` and `export_timeline.py --preview` from `.xyz/`,
and `xyz-sync.sh update` preserves its ledger) is covered by gh105-vendor-releases-addon, gh107-timeline-json-seam,
gh103-timeline-exporter, gh349-releases-roadmap-vendored, gh197-vendor-tier-split and gh312-vendor-preserves-state.
All six passed in the 2026-09-25 qualifying `ci-local.sh` run on `9ab269c8`.

## Promotion steps (after this PR is reconciled)

1. Choose the SHA `P` = the `development` tip after this PR's reconcile. Hold other merges until step 3 finishes.
2. `gh api -X DELETE repos/HiQS-Labs/XYZ-forge/branches/main/protection/enforce_admins`;
   `git push origin P:refs/heads/main`; `gh api -X POST …/enforce_admins`. → expect `main` = `development` = `P`,
   and protection restored with `enforce_admins: true`.
3. Watch `boundary-macos` on that push. → expect `MACOS-BOUNDARY: green P` in the job summary.
4. `/releases` Publish: `gh release create 0.9.0 --target P --title … --notes …` from the Cargo block, marked
   Latest. Then write back `releases update --gh-release-url` and `releases ship --evidence` in a small follow-up PR.
5. If step 3 is red, do not publish. Fix forward on `development` and promote again; never force-push `main`.

**Reversibility:** Costly but recoverable. `main` can be moved back only by a force push, which protection
forbids, so a bad promotion is fixed forward. The Release and its tag can be deleted and re-created.
**Blast radius:** nothing in the repo consumes this repo's `main` (the default branch is `development`), and the
Release is the first published.

## Rating

`rated 85/55/50/70` (2026-09-25).

- **Priority 85:** the operator is promoting now.
- **Severity 55:** `main` is 1,799 commits and 5.5 weeks stale, and no Release has ever been published. It blocks
  no development work.
- **Appeal 50:** neutral.
- **Effort 70:** mostly hosted waits and ledger verbs, little code.
