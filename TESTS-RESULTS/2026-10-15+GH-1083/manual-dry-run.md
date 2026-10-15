# Bounded manual radar dry run

Input: dry-run-input.md and dated live-facts.json. Candidate skill: commit 033b83a2. This is a manual application of instruction decisions, not an executable suite, full radar scan or guarantee about every future model response. No Sink A/B writes, GitHub mutations or repairs were performed by this exercise.

| Case | Applied result | Assessment |
|---|---|---|
| A | Live #1083 is open with no milestone. Controlled completed/Q4 doc claims are doc drift; no closure or assigned membership may be inferred. | Pass |
| B | PR #1078 is merged into development (recorded merge time/SHA); sampled open PRs remain in flight. A release note or old strike-through does not establish their landing or target retirement. Merge is not deployment; quiet/fix requirements still apply. | Pass |
| C | Deliberate GitHub classification yields Transform despite conflicting doc Grow, with doc drift. #1083's quoted classifier example is not its classification. Only checked records enter adoption coverage; unqueried scope is unknown. | Pass |
| D | Adopted GitHub v2 governs at 20%; the v1 doc is stale and v3 is draft. This exception preserves adopted operating policy, not arbitrary doc precedence. With adoption/version unreadable, report unverified policy and lower confidence, not known adoption or a convenient threshold. | Pass |
| E | Resolving two references is insufficient kinship; explicit context-only evidence rejects that cluster. Unavailable relationship evidence leaves an unverified candidate hint, not verified kinship or a clean negative sweep. | Pass |
| F | Whole report degraded; doc RGT/context can be labelled doc-reported/unverified fallback. No doc-only retirement, quiet/solved credit or inaccessible live checklist update. Sink A is preview-only pending existing confirmation. | Pass |
| G | Only documentation hints/context and normal Sink A location are lost. GitHub kinship and explicit RGT continue; offer repo-root Sink A, retaining confirmation. | Pass |
| H | Known issue facts remain verified; unreadable history is unknown, truncated lists cannot prove completeness or zero adoption/reopens. Whole report partially verified with affected claims named; no unsupported quiet/solved credit. | Pass |

## Textual red controls against the baseline

These are directly observed contradictory instructions from dc7245b4, not a claim that an old model was executed or would always obey them. The baseline RGT rule selects doc-only declaration instead of C's GitHub declaration; its blanket SOP doc-wins rule selects stale doc v1 in D; its degradation table omits whole-report loss of authority in F/H and removes RGT overrides when only PROJECT is absent in G. The new rules resolve those specific contradictions; unavailable evidence does not count as a negative result.

```text
| **Transform** | **only** an explicit `rgt: transform` on the governing `PROJECT/**` doc. **Always report `rgt:` adoption alongside the figure** — at zero adopting docs, "Transform 0%" means *nobody has declared anything*, not *no transformative work happened*, and the number cannot become non-zero until the key is adopted. Print it as `0% (rgt: adoption: N docs)` so the distinction is never left to the reader. |
If a doc and an issue disagree, the doc wins; note the issue.
| `gh` / auth | Lens 2 signals 3-5, open-PR collision check, Lens 3 joins, Sink B | Lenses 1-2 (signals 1-2), Sink A; state that no in-flight-work check or live checklist was available this run |
| `PROJECT/**` | Lens 2 signal 1, `rgt:` overrides, Sink A's normal location | Lenses 1-3 from git + `gh`; offer repo-root fallback for Sink A |
```

Independent final QA will apply the same input cases itself and compare this report. Normal publication docs gate remains pending. No runtime suite is needed for the classified docs-only payload.
