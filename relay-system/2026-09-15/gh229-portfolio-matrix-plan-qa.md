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

### Round 2 · Orchestrator · Revisions Addressing Round 2 Feedback

All 5 critiques from Codex Round 2 have been incorporated into `/Users/noelsaw/Documents/GH Repos/rebalanceOS/PROJECT/2-WORKING/GH-229-PORTFOLIO-PLANNING-MATRIX.md`:

1. **Project Matching & Subproject Contract:**
   - Swapped out `canonical_repo_key()` for `normalize_match_text()` (`src/rebalance/ingest/project_classifier.py:24-31`), requiring exact normalized equality against `project_registry.name`. No fuzzy prefix matches.
   - Formalized subproject syntax: `## Project / Subproject` splits on `/` with whitespace trimming. If no slash, `subproject: null`.

2. **Ambiguity-Safe Mutation Guard in `complete_goal_in_file()`:**
   - In `complete_goal_in_file()`, if `line_index` has shifted and title matching is attempted:
     - Search must match exactly 1 open goal with that title across the file. If 0 or >1 open goals match the title, it **refuses with HTTP 409 (no file mutation)** rather than completing the wrong project's task.
     - Added test case `test_complete_goal_duplicate_title_refusal()`.

3. **Deterministic Coercion & Missing Goals Contract:**
   - Defined `_safe_int(val, default=0)` helper handling `None`, string numbers ("4"), floats, and malformed strings ("N/A", lists) without raising 500.
   - Missing `0. Goals.md` contract resolved: projects from `project_registry` render with empty `tasks: []` (preserves portfolio visibility).

4. **UI Frozen Project Column:**
   - Changed from a monolithic horizontal scroller to a **split-scrolling layout**:
     - **Left Column (Frozen):** Fixed 130pt width displaying Project Name, subproject caption, and Score badge. Pinned at x=0; never scrolls away.
     - **Right Scroller:** Horizontal `ScrollView` hosting Task 1, Task 2, Task 3 columns (150pt minimum width each).
   - Fully compatible with 340pt (default) and 420pt panel widths.

5. **Offline & Test Seam Discipline:**
   - Cut cold-start disk cache from v1 per Minimal/YAGNI principle. V1 retains the last in-memory response during transient failures; completion buttons are visibly disabled when offline.
   - Swift test observability: specified `URLProtocol` request interception stubbing to verify POST completion followed by GET refetch.

Please review the revised plan in `/Users/noelsaw/Documents/GH Repos/rebalanceOS/PROJECT/2-WORKING/GH-229-PORTFOLIO-PLANNING-MATRIX.md` and provide your Round 3 verdict.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex review — 2026-09-15 (Round 3)

**Grade: C+ / Block.** Round 3 has the right scope: one local projection, one existing mutation endpoint, no new persistence, no disk cache, and a frozen-column UI. Two load-bearing contracts are still missing: the section parser cannot represent the promised subproject rows as typed, and the current completion helper cannot distinguish ambiguity from absence so the route cannot reliably emit the promised HTTP 409. The Swift request-sequence proof also remains underspecified against the model's private concrete client.

### Graded answers

1. **DRY & subsystem reuse — PASS WITH FIX.** Reusing `get_projects()`, `normalize_match_text()`, the goals-file helper, `Focus5Client`, and `Theme` is commensurate and avoids parallel machinery (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:99-108`). However, `parse_sectioned_goals() -> dict[str, list[dict[str, Any]]]` cannot preserve both project and optional subproject identity when one project has multiple `## Project / Subproject` sections (`:52-55`). The single response row has only one `subproject`, but the plan never says whether multiple subprojects become separate rows, merge tasks, or displace a bare-project row (`:62-80`). Cheapest correction: return a flat ordered list of `{project, subproject, tasks}` groups, emit one matrix row per group, define where an unsectioned/bare-project group sorts, and skip/log duplicate normalized registry keys rather than attaching a heading arbitrarily. Add fixtures for two subprojects under one project and two registry names that normalize to the same key.

2. **Single writer path — TOPOLOGY PASS, ERROR CONTRACT FAIL.** There is no rogue writer: the plan correctly routes every pill through `POST /api/focus5/goals/complete` and immediately refetches the matrix (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:56-61`). But `complete_goal_in_file()` currently returns only `dict | None` (`src/rebalance/ingest/goals_file.py:73-116`), and the route maps every false result to 404 (`src/rebalance/web.py:1136-1145`). Saying the helper “refuses with HTTP 409” does not define how the non-HTTP helper communicates ambiguity. Specify one minimal distinction—for example `AmbiguousGoalError`, caught by `focus5_complete_goal()` and mapped to 409, while zero matches remains 404—and add both helper-level no-write proof and route-level 409 proof. Phase 1 must name the route change, not only the helper hardening (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:140-144`).

3. **Data contract & wire shape — CONDITIONAL FAIL.** The additive snake-case response, safe metric coercion, deterministic score sort, and three-task cap are compact and compatible (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:62-88`). It is not deterministic until multi-subproject expansion is defined: repeated parent metrics, row ordering among sibling subprojects, behavior when both `## Project` and `## Project / Child` exist, and a stable Swift row identity are all absent. No new wire ID is required if the client derives one from `(name, subproject)`, but the plan must state that uniqueness contract and its collision behavior.

4. **UI & ergonomics — PASS WITH FIX.** A fixed 130pt left column plus one horizontally scrolling task grid is the correct small-panel design (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:89-93`). Because the frozen and scrolling halves are separate layouts, wrapped task text can make right-side row heights diverge from the left-side project rows. Specify a shared/fixed row height (or another single source of row sizing) and include a long-task/multi-line manual check at 340pt and 420pt; “pinned at x=0” alone does not prove row alignment (`:132-134`).

5. **Gaps / blind spots — FAIL.** The promised POST-then-GET test still lacks a production seam. `Focus5Model` owns `private let client = Focus5Client()` (`Focus5Model.swift:259-261`), while the plan only says “URLProtocol request interception” and does not name the model method under test or how its client/session is injected (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:117,132,146-153`). Follow the existing `ObsidianRemindersStore(client:)` pattern (`ObsidianRemindersStore.swift:19-24`): inject `Focus5Client`, name one `completeMatrixTask()` production method that performs POST -> GET -> state replacement, and test that method with a stubbed `URLSession`. Also make `.matrix` selection and manual refresh explicitly call the matrix fetch; the current refresh dispatch handles only telemetry, prompt log, or roster (`Focus5Model.swift:301-316`; `ContentView.swift:256-267`).

### SWE rubric

| Pillar | Result | Cheapest plan correction |
|---|---|---|
| Recon | Fix | Define the group-to-row projection and the helper-to-HTTP ambiguity signal. |
| Minimal | Pass | Keep the current v1 cuts; the fixes need only a small result/exception contract and injected client seam. |
| Diagnosable | Fix | Log skipped ambiguous project keys and return a distinct 409 body for ambiguous completion. |
| Blast | Block | Prove ambiguity yields no write and 409; preserve 404 for zero matches. |
| Proof | Block | Add multi-subproject/colliding-key fixtures, route-level 409, and model-level POST-then-GET state replacement. |

**Reversibility:** Easy for the additive endpoint/tab. The sole consequential mutation remains goal completion; its ambiguity outcome must be explicit before build so the safety guard is testable end to end.

VERDICT: FAIL
