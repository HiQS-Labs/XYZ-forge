---
gh_issue: 201
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/201
title: "swe-diagram: add Git history lane visualization"
status: "SHIPPED — closed 2026-07-21, see GitHub issue comment for evidence (commit 6df5bfc, merged PR #244)."
created: 2026-07-14
updated: 2026-07-14
owner: noel
goal: Add deterministic Git-history lanes and render the newest 20 commits reachable across all branch refs.
doc_type: feedback
effort: 3
complexity: 3
risk: 1
phases: 1
---

# GH-201 · swe-diagram Git history lanes

## Status

| What was just completed | What's next |
|---|---|
| Git-lane renderer, local generator, focused/forward tests, skill guidance, and the real 20-commit example completed on 2026-07-14. | Review and publish the uncommitted implementation when the operator is ready. |
| **2026-07-21:** shipped via commit `6df5bfc`, merged PR [#244](https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/pull/244); issue #201 closed on GitHub. | Promoted to `3-COMPLETED`. Nothing further for this doc. |

## Scope and acceptance

- [x] `layout: "git-lanes"` renders fixed branch rows and chronological commits left to right.
- [x] First-parent ancestry and merge-parent edges are visually distinct.
- [x] A bundled generator produces valid diagram JSON from local Git without network access.
- [x] Current-ref limitations are explicit: deleted branch names and squash/rebase provenance are not
      reconstructed from Git alone.
- [x] Focused fixtures cover branch ordering, commit limits, lane assignment, and merge edges.
- [x] `ARCHITECTURE/git-history-diagram.json` and `.html` show the newest 20 commits across all branch refs.
- [x] The existing three architecture layouts remain unchanged.

## Verification

1. Run generator fixtures and `test/swe-diagram.sh`. -> expect all focused checks to pass.
2. Generate and build the real 20-commit example. -> expect valid JSON with resolved endpoints.
3. Inspect the HTML in headless Chrome. -> expect readable stacked lanes and merge paths.
4. Run skill validation, an isolated forward test, `./validate.sh`, and `utils/pdda/pdda.sh run`.
   -> expect touched-surface gates to pass and the known full-suite baseline to remain no worse.

## Outcome

- Focused diagram suite: 29 pass, 0 fail. The synthetic Git fixture proves lane ordering, the total
  commit cap, branch-cut edges, two-parent merge edges, and resolved endpoints.
- Real example: 20 commits, 3 visible lanes, and 19 edges (18 ancestry, 1 branch cut, 0 merge edges).
  The selected newest-20 window contains no merge commit; the fixture and independent forward test
  cover that path without fabricating history in the example.
- Headless Chrome rendered the real self-contained HTML successfully; stacked lanes, chronological
  cards, and the branch-cut path were visually inspected.
- Independent forward test: 7 commits across `main`, `development`, and `feature/reporting`, with 2
  branch cuts and 2 non-fast-forward merges; JSON ancestry and the rendered HTML both passed.
- Full `./validate.sh`: 109/112. The new `swe-diagram.sh` gate passed 29/29. Two failures are the
  documented missing local dependencies (`acorn`, `pytest`); `worktree-isolation.sh` also fails its
  moved-ROOT-HEAD case on current `main` and fails again in isolation. That unrelated regression was
  not changed as part of GH-201.
