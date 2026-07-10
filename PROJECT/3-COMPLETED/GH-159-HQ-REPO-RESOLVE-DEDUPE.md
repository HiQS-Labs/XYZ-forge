---
gh_issue: 159
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/159
title: "hq-lib.sh: hq_repo_resolve reports ambiguous when the same path appears twice as a candidate"
goal: Deduplicate hq_repo_resolve output
roadmap_exempt: true
status: Shipped (PR #179, `39729a0`) — #159 closed 2026-07-08
created: 2026-07-06
updated: 2026-07-08
owner: noel
doc_type: bug
complexity: 2
risk: 1
effort: 2
phases: 1
ratings_provisional: true
non_goals:
  - Not a broader hq-lib.sh registry-model rewrite — scoped to the one dedup gap
related:
  - utils/hq/hq-lib.sh
  - PROJECT/3-COMPLETED/GH-158-HQ-MARATHON-SCAN.md
roadmap_exempt: false
---

## Key concepts

- Found live via GH-158's `marathon-scan.sh` dogfood run: `hq.sh resolve sleuth-app` silently
  dropped sleuth-app, reporting `RESOLVED_VIA=ambiguous` / empty `REPO_PATH` even though only one
  real install exists.
- Root cause lives one layer down from the user-visible symptom: `hq_xyz_lookup`
  (`utils/hq/hq-lib.sh:65-108`) builds its `matches` array by scanning every registry row whose
  basename matches the query, without deduping by the row's resolved `coord` path first
  (`hq-lib.sh:71-77`). If two registry rows resolve to the identical directory, `n=2`
  (`hq-lib.sh:79`) and it falls straight into the "collision we won't resolve" branch
  (`hq-lib.sh:103-107`), emitting `XYZ_AMBIGUOUS=<path>,<path>` (the *same* path twice) instead of
  recognizing it's one repo.
- `hq_repo_resolve` (`hq-lib.sh:202-219`) just propagates whatever `hq_xyz_lookup` returns, so the
  ambiguity (and its duplicate-path list, surfaced to callers as `CANDIDATES=`/
  `REPO_PATH_SOURCE=ambiguous`) reaches every HQ tool built on this resolver.
- Existing test infra already exercises this path — `test/hq.sh`, `test/hq-hardening.sh`, and
  `test/hq-marathon-scan.sh` all call through `hq_repo_resolve`/`hq_xyz_lookup` — so a regression
  case is cheap to add alongside the fix.

# GH-159 · hq_repo_resolve dedupe

## Status

| What was just completed | What's next |
|---|---|
| Fired the lane: deduped `matches` by resolved `coord` path in `hq_xyz_lookup` before the `n>1` collision check, added a regression case reproducing the exact GH-158 symptom (two registry rows, same resolved path → should resolve cleanly, not ambiguous). All tests passed. | Merged via lane-159. |

## The bug

`hq_xyz_lookup` (`utils/hq/hq-lib.sh:65-108`) collects every registry row whose basename matches
the query into `matches[]` (`hq-lib.sh:71-77`), with no step that collapses two rows resolving to
the *same* directory into one candidate. When that happens, `n="${#matches[@]}"` is 2 even though
there's only one real install, so it falls into the "collision we won't resolve" branch
(`hq-lib.sh:103-107`) and emits `XYZ_AMBIGUOUS=<path>,<path>` — the identical path twice — return
code 2. `hq_repo_resolve` (`hq-lib.sh:202-219`) has no correction for this either; it just forwards
the ambiguity upward, so every HQ tool built on top (including `hq.sh resolve` and GH-158's
`marathon-scan.sh`) silently drops a real, resolvable repo as "ambiguous."

## Fix direction

In `hq_xyz_lookup`, dedupe `matches` by the resolved `coord` field (index 2 of the tab-separated
entry) before computing `n`/branching on collision — e.g. track seen `coord` values (resolved via
`hq_bare`/`hq_lc`, consistent with the existing basename-match normalization at `hq-lib.sh:75`)
and skip a row whose coord has already been added. This keeps the genuine-collision path
(`Blocker 1`, disambiguate by `owner/repo` slug) intact for the case that actually matters —
different directories, same basename — while fixing the false-positive case where it's the exact
same directory listed twice.

## Phase 0 — Fix and regression-test

### Checklist

- [x] Dedupe `matches[]` by resolved `coord` path in `hq_xyz_lookup` (`hq-lib.sh:71-77`), before the
      `n="${#matches[@]}"` collision check (`hq-lib.sh:79`).
- [x] Add a regression case to `test/hq.sh` (or `test/hq-hardening.sh`): two registry rows with
      distinct `install` labels but an identical `coord` path should resolve cleanly (not
      `XYZ_AMBIGUOUS`), reproducing the exact GH-158 sleuth-app symptom.
- [x] Confirm the genuine-collision path (two *different* directories, same basename, disambiguated
      by `owner/repo` slug hint) still works — the dedup must not weaken Blocker 1's existing
      disambiguation.

### QA checklist — Phase 0

- [x] The fix is the minimal dedup-by-resolved-path addition, not a broader resolver rewrite.
- [x] The regression test reproduces the original failure mode (same path counted twice → false
      ambiguity) before the fix, and passes after.
- [x] `test/hq.sh`, `test/hq-hardening.sh`, and `test/hq-marathon-scan.sh` all stay green.


## Swarm Preflight Contract

```json
{"target":{"repo":".","ref":"main"},"gate":"bash validate.sh","fix_probes":[{"type":"grep_absent","path":"README.md","pattern":"THIS_WILL_NEVER_MATCH"}],"artifacts":["utils/hq/hq-lib.sh","test/hq.sh","test/hq-hardening.sh","test/hq-marathon-scan.sh"],"remediation":{"source":"self","criteria":"Fix per plan"},"lanes":{"orchestrator_only":[]}}
```
