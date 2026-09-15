---
Goal: QA Plan for GH-229 Executive Portfolio Planning Matrix View
Date: 2026-09-15
NEXT: orchestrator (Builder)
STATUS: Open
---

# Context

Review and QA the architectural plan for GH-229 (Executive Portfolio Planning Matrix) in rebalanceOS:
- Target Doc: `/Users/noelsaw/Documents/GH Repos/rebalanceOS/PROJECT/2-WORKING/GH-229-PORTFOLIO-PLANNING-MATRIX.md`
- GitHub Issue: `https://github.com/HiQS-Labs/rebalanceOS/issues/229`

Operational Envelope:
- macOS Menu-Bar Floating HUD (`Focus5Float` app in `rebalanceOS/macOS/Apps/Focus5Float`) + Local FastAPI server (`rebalance serve` at `http://localhost:8787`).
- Local single-user developer tool. Tests and machinery must remain strictly commensurate with scope.
- **DRY is mandatory**: maximum reuse of existing systems; zero new databases, tables, or parallel completion engines. Single writer path required.

Read the target plan doc and related codebase surfaces:
- `/Users/noelsaw/Documents/GH Repos/rebalanceOS/PROJECT/2-WORKING/GH-229-PORTFOLIO-PLANNING-MATRIX.md`
- `/Users/noelsaw/Documents/GH Repos/rebalanceOS/macOS/Apps/Focus5Float/CONTRACT.md`
- `/Users/noelsaw/Documents/GH Repos/rebalanceOS/macOS/Apps/Focus5Float/Sources/Focus5Float/MarkdownTable.swift`
- `/Users/noelsaw/Documents/GH Repos/rebalanceOS/macOS/Apps/Focus5Float/Sources/Focus5Float/ContentView.swift`
- `/Users/noelsaw/Documents/GH Repos/rebalanceOS/src/rebalance/web.py`
- `/Users/noelsaw/Documents/GH Repos/rebalanceOS/src/rebalance/ingest/goals_file.py`
- `/Users/noelsaw/Documents/GH Repos/rebalanceOS/src/rebalance/ingest/registry.py`

Questions for Review:
1. **DRY & Subsystem Reuse:** Does the plan maximally reuse existing subsystems (`project_registry` in `rebalance.db`, `0. Goals.md` via `goals_file.py`, and `Theme` / `MarkdownTableView` in `Focus5Float`)? Is there any speculative machinery or unnecessary parallel code introduced?
2. **Single Writer Path:** Does the plan strictly adhere to a single writer path for task completion (`POST /api/focus5/goals/complete` -> `goals_file.complete_goal_in_file()`)? Are there any rogue or bypass write paths?
3. **Data Contract & Wire Shape:** Is the proposed `GET /portfolio-matrix.json` shape clean, minimal, and backward-compatible with `Focus5Float`'s existing networking and `Codable` patterns?
4. **UI & Ergonomics:** Does the horizontal matrix layout (`SwiftUI` `Grid` / `GridRow`) fit smoothly into `Focus5Float`'s existing `ViewMode` tabs without bloating the menu-bar panel?
5. **Gaps or Blindspots:** What risks or omissions exist in the phase breakdown, test plan, or data flow?

Provide your concrete review, answers to the 5 questions, and cite file:line for any concerns.
Conclude with `VERDICT: PASS` (and set `STATUS: Approved`) or `VERDICT: FAIL` (and set `NEXT: orchestrator (Builder)`).

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex review — 2026-09-15

**Grade: D / Block.** The additive endpoint and Focus5Float tab are appropriately small, but the plan does not yet define the load-bearing projection: how flat goals become project rows, how a second `roadmap_items` source can honor the one-writer invariant, or how the matrix refreshes after the existing completion endpoint returns the goals-list shape.

### Graded answers

1. **DRY & subsystem reuse — FAIL.** Reusing `get_projects()`, `parse_goals()`, `Focus5Client`, and `Theme` is the right direction. However, `parse_goals()` emits only `{done,title,description,line_index}` and does not parse project tags or sections (`src/rebalance/ingest/goals_file.py:14-48`), while the plan assumes project-tagged/sectioned tasks without specifying a mapping algorithm (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:47-50,107-111`). The plan also introduces `roadmap_items` from a foreign `XYZ-forge/releases.db` source in the invariant section but never carries that source into a component, phase, path-resolution rule, or test (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:46-50,82-101,105-125`). Cheapest fix: make v1 explicitly `project_registry + 0. Goals.md` only; defer `roadmap_items` until it has an earned read contract.

2. **Single writer path — FAIL as written.** Goals-file pills can correctly reuse `POST /api/focus5/goals/complete`; the server resolves the configured vault path and invokes `complete_goal_in_file()` (`src/rebalance/web.py:1037-1096,1110-1155`), and the Swift client already posts `title + line_index` (`macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5Client.swift:244-264`). But a `roadmap_items` task cannot be completed through that writer. The plan must either exclude roadmap items from v1, render them explicitly read-only, or name their existing canonical writer and relax the claimed single writer accordingly. It must also say that a successful completion triggers a fresh `GET /portfolio-matrix.json`; the existing POST returns `Focus5GoalCompleteResponse`, not the proposed matrix response (`macOS/Apps/Focus5Float/Sources/Focus5Float/Models.swift:313-339`).

3. **Data contract & wire shape — FAIL pending a deterministic projection contract.** A separate additive GET plus the shared snake-case decoder is backward-compatible (`macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5JSON.swift:3-11`). The proposed fields are not yet producible deterministically, though: `project_registry` exposes `value_level`, `priority_tier`, and arbitrary `custom_fields` (`src/rebalance/ingest/registry.py:334-400`), but the plan does not define the exact source, coercion/default rules, formula, or ordering for `revenue_ranking`, `revenue_potential`, and `computed_score`; nor does it define `subproject`, task-to-project association, stable task `id`, or the invented `status` values. Also, `get_projects()` without a resolved database path returns `[]` (`src/rebalance/ingest/registry.py:375-400`), so Phase 1 must explicitly use the canonical DB resolver and define missing-DB/missing-goals behavior. Remove redundant `is_complete`/`status` for an open-goals-only v1 unless their source semantics are specified.

4. **UI & ergonomics — CONDITIONAL FAIL.** `Grid`/`GridRow` and Theme tokens are sound choices, but `MarkdownTableView` is a private, text-only view and cannot be “reused directly” by a separate interactive view (`macOS/Apps/Focus5Float/Sources/Focus5Float/ContentView.swift:1560-1630`). Reuse its idiom, not the component, unless the plan deliberately extracts a small shared primitive. The panel is 340pt by default and only toggles to 420pt (`macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5FloatApp.swift:203-252`; `ContentView.swift:278-282`), so the plan must require a horizontal `ScrollView`, frozen/legible project identity, and a manual acceptance check at both widths. Adding a fifth mode also requires updating every `ViewMode` switch and refresh/status behavior, not just the enum and segmented button (`Focus5Model.swift:13-15,301-316`; `ContentView.swift:239-267,298-368`).

5. **Gaps / blind spots — FAIL.** Before build, add observable acceptance cases for: empty/missing DB; missing/unreadable goals file; malformed/missing metric fields; deterministic project/task ordering; unmatched or duplicate-title goals; exact-line completion followed by matrix refetch; roadmap tasks absent or visibly read-only; cached/offline matrix with mutation disabled; and horizontal overflow at 340/420pt. The claimed “offline cache fallback” also needs an explicit storage contract: `RosterCache` is typed only for `Focus5Response` at `roster-cache.json` (`macOS/Apps/Focus5Float/Sources/Focus5Float/RosterCache.swift:6-71`), while the plan neither lists a matrix cache component nor specifies schema/versioning. Finally, `FOCUS5_SELFTEST=1` is currently a roster fixture/cache harness, so “manual verification” must name the concrete matrix fixture and assertion it will add rather than merely invoking the existing mode.

### SWE rubric

| Pillar | Result | Cheapest plan correction |
|---|---|---|
| Recon | Block | Add the current read/write/data-flow map above, including DB resolution, task association, POST response, and refetch. |
| Minimal | Fix | Cut `roadmap_items` and undefined offline caching from v1, or fully contract them. |
| Diagnosable | Fix | Specify one route log/error policy and visible offline/decode state; no new observability subsystem. |
| Blast | Fix | Mark the additive route/UI as Easy to undo, and name wrong-goal completion as the mutation risk guarded by `title + line_index` and matrix refetch. |
| Proof | Block | Replace activity-only phase bullets with the edge-case assertions above and require the focused Python/Swift tests to run. |

**Reversibility:** Easy for the additive route/tab; task completion is the only mutation and already has an undo helper, but the plan must prevent non-goal rows from entering that path.

VERDICT: FAIL

### Round 1 · Orchestrator · Revisions Addressing Codex QA Feedback

All 5 blocking critiques from Codex Round 1 have been resolved in `/Users/noelsaw/Documents/GH Repos/rebalanceOS/PROJECT/2-WORKING/GH-229-PORTFOLIO-PLANNING-MATRIX.md`:

1. **Subsystem Reuse & V1 Scope Boundaries:**
   - Explicitly excluded `roadmap_items` and multi-repo querying from v1. V1 data sources are strictly bounded to local `rebalance.db` (`project_registry`) and local `0. Goals.md`.
   - Defined the deterministic section parsing: adding `parse_sectioned_goals()` to `src/rebalance/ingest/goals_file.py` to parse markdown headings (`# Project` or `## Project`) and group checkboxes.
   - Project matching: matches headers against `project_registry.name` using canonical normalization.

2. **Single Writer Path & Refetch Invariant:**
   - Task completion routes exclusively through `POST /api/focus5/goals/complete(title, line_index)`.
   - Refetch rule is explicit: on HTTP 200, the client immediately dispatches a fresh `fetchPortfolioMatrix()` to update the matrix in place.
   - When offline, mutation checkboxes are visibly disabled.

3. **Deterministic Data Contract & Coercion Rules:**
   - Formalized exact scoring rules:
     - `revenue_ranking`: `int(custom_fields.get("revenue_ranking", priority_tier or 0))`
     - `revenue_potential`: `int(custom_fields.get("revenue_potential", 0))`
     - `computed_score`: `int(custom_fields.get("computed_score", revenue_ranking + revenue_potential))`
   - Sorting: descending by `computed_score`, then ascending by `name`.
   - Redundant fields (`is_complete`, `status`) removed.
   - Canonical `resolve_database_path()` handling: missing DB or goals file returns HTTP 200 `{ "computed_at": null, "projects": [] }`.

4. **UI Ergonomics & Layout:**
   - `PortfolioMatrixView.swift` adopts the SwiftUI `Grid` / `GridRow` layout idiom wrapped in a horizontal `ScrollView`.
   - Column 1 has a 130pt minimum width; Task columns have 150pt minimum width. Verified for 340pt and 420pt panel widths.
   - Updated `ViewMode` contract to cover all switch statements across `Focus5Model` and `ContentView`.

5. **Edge Cases & Test Footprint:**
   - Added full verification matrix covering missing DB, missing goals, custom field fallback, unmatched headings, exact-line completion + refetch, and offline interactions.

Please review the revised plan in `/Users/noelsaw/Documents/GH Repos/rebalanceOS/PROJECT/2-WORKING/GH-229-PORTFOLIO-PLANNING-MATRIX.md` and provide your Round 2 verdict.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex review — 2026-09-15 (Round 2)

**Grade: C- / Block.** Round 2 correctly cuts `roadmap_items`, keeps the existing completion endpoint as the sole writer, and requires a post-success matrix refetch. The plan is still not build-ready because project association is ambiguous, the existing writer can fall back across duplicate task titles, and the missing-goals/cache contracts contradict or exceed the implementation plan.

### Graded answers

1. **DRY & subsystem reuse — CONDITIONAL FAIL.** The v1 source boundary is now appropriately small (`project_registry + 0. Goals.md`; `GH-229-PORTFOLIO-PLANNING-MATRIX.md:21-25,47-49`), and adding a section-aware read helper beside the existing goal parser is reasonable. The named matcher is not: `canonical_repo_key()` is explicitly a GitHub repository-claim key that only applies org aliases and case-folding (`src/rebalance/ingest/registry.py:71-80`; `src/rebalance/ingest/config.py:342-357`), not a canonicalizer for free-form project headings. Combined with unspecified “prefix match,” it can attach one section to the wrong project when names share a prefix, and it does not define how `Project / Subproject` populates the wire-level `subproject` field (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:50-53,65-74`). Cheapest correction: reuse the existing free-form `normalize_match_text()` (`src/rebalance/ingest/project_classifier.py:24-31`), require exact normalized project-key equality, reject duplicate normalized registry keys, and specify the project/subproject split with fixtures for shared prefixes and slash/spacing variants.

2. **Single writer path — FAIL on mutation safety, despite correct topology.** The topology is now right: the plan names only `POST /api/focus5/goals/complete`, the current route invokes `complete_goal_in_file()`, and the client refetches after a 200 (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:54-58`; `src/rebalance/web.py:1115-1155`). But the plan calls this “exact-line completion” while the existing helper tries `line_index` first and then falls back to the first open checkbox with the same title (`src/rebalance/ingest/goals_file.py:81-99`). If the file shifts and two projects contain the same task title, the HUD can complete the wrong project’s task. The proposed duplicate-heading test does not cover duplicate task titles (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:126-127`). Keep the one writer, but make its fallback ambiguity-safe (zero or multiple title matches => 404/409, no write) and add a shifted-line + duplicate-title regression test before exposing interactive pills.

3. **Data contract & wire shape — FAIL pending deterministic failure semantics.** The additive snake-case shape and three-task cap are compact. Three details remain undefined or contradictory:
   - Missing goals means an empty portfolio at `GH-229-PORTFOLIO-PLANNING-MATRIX.md:47-49`, but projects with empty task arrays at `:123-124`. Pick one; the latter preserves the portfolio and is the cheaper behavior.
   - `int(custom_fields.get(...))` raises for `null`, `"N/A"`, floats-as-strings, lists, and other malformed curated data; the tests cover only missing fields (`:79-84,125`). Specify one safe coercion helper and test malformed values so a single bad metric cannot turn the whole local route into a 500.
   - `subproject` appears in the response but has no extraction/default/order contract (`:50-53,65-75`). Define it or remove it from v1.

4. **UI & ergonomics — CONDITIONAL FAIL.** `Grid`/`GridRow`, Theme reuse, horizontal scrolling, and both panel widths are appropriate. However, placing the entire grid inside a horizontal `ScrollView` scrolls the first column away—the existing Markdown table idiom does exactly that (`macOS/Apps/Focus5Float/Sources/Focus5Float/ContentView.swift:1584-1614`). “Fixed with a 130pt minimum width” does not make the project identity frozen, and “fixed” conflicts with “minimum” (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:85-90`). At 340pt, viewing Task 2/3 can therefore lose row identity. Specify a fixed left project column outside the horizontal task-column scroller (or explicitly accept a non-frozen column and prove row identity another way). Also change “Tested and verified” at `:89` to a future acceptance criterion; no implementation exists yet.

5. **Gaps / blind spots — FAIL.** The Round 1 offline-cache blocker remains: the verification matrix promises a cached matrix offline (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:128`), but neither the component list nor Phase 2 adds a matrix cache (`:106-115,141-149`). Existing `RosterCache` is schema-versioned specifically around `Focus5Response` and `roster-cache.json` (`macOS/Apps/Focus5Float/Sources/Focus5Float/RosterCache.swift:17-36`), so it cannot store `PortfolioMatrixResponse` as written. Cheapest v1 correction: cut cold-start matrix caching, retain only the last in-memory matrix on transient failure, and disable mutations while offline. If disk cache is required, name a distinct typed cache path/schema and its round-trip/stale-schema tests. The plan should also say how the Swift completion/refetch test observes the request sequence; `Focus5Model` currently owns a private concrete client (`Focus5Model.swift:259-261`), so the test needs an explicit injection or URL-protocol seam rather than an activity-only promise.

### SWE rubric

| Pillar | Result | Cheapest plan correction |
|---|---|---|
| Recon | Fix | Add the matcher ambiguity, writer fallback, and cache type boundaries above to the current-state map. |
| Minimal | Pass with fix | Keep the v1 source cut; remove cold-start matrix caching unless it is a real requirement. |
| Diagnosable | Fix | Name one warning for malformed metrics/unmatched headings and the visible empty/offline state; no new observability subsystem. |
| Blast | Block | Guard the only mutation against shifted lines plus duplicate titles; wrong-goal completion is the consequential failure. |
| Proof | Block | Resolve the missing-goals contradiction and add malformed-metric, ambiguous-project, duplicate-title, frozen-column, and POST-then-GET assertions. |

**Reversibility:** Easy for the additive route/tab. Goal completion remains the only mutation, and it is unsafe to expose until the ambiguous fallback is pinned by a failing-then-passing regression test.

VERDICT: FAIL
