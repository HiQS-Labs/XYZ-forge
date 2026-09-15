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


### Round 3 · Orchestrator · Revisions Addressing Round 3 Feedback

All blocking critiques from Codex Round 3 have been incorporated into `/Users/noelsaw/Documents/GH Repos/rebalanceOS/PROJECT/2-WORKING/GH-229-PORTFOLIO-PLANNING-MATRIX.md`:

1. **Section Parser & Multi-Subproject Group-to-Row Projection:**
   - `parse_sectioned_goals()` returns `list[SectionedGoalGroup]` where each group carries `(project, subproject, tasks)`.
   - Each group emits one distinct matrix row, inheriting the parent's metrics (`revenue_ranking`, `revenue_potential`, `computed_score`). Sibling subprojects sort after bare-project rows (`subproject=None` first).
   - Derived Swift ID is formalized as `id: "\(name):\(subproject ?? "")"`. Colliding keys log a warning.

2. **Ambiguity Signal & Mutation Safety Contract:**
   - Formalized helper-to-HTTP error contract: `complete_goal_in_file()` raises `AmbiguousGoalError(title)` when title fallback matches >1 open goal.
   - `focus5_complete_goal()` catches `AmbiguousGoalError` and returns **HTTP 409** `{"ok": False, "error": "ambiguous_goal_title", "title": title}` with **zero file writes**.
   - Zero matches remains **HTTP 404**. Added test cases for both.

3. **UI Fixed Row Height & Alignment:**
   - Specified a shared, fixed row height (`58pt`) across both the left frozen column and the right scrolling task grid, guaranteeing that row heights never diverge when task text wraps.
   - Titles clamped to 1 line for project/subproject and 2 lines for task pills.

4. **Swift Testability & Dependency Injection Seam:**
   - Injected client seam: `Focus5Model.init(client: Focus5Client = Focus5Client())` (mirroring `ObsidianRemindersStore(client:)`).
   - Production method named: `completeMatrixTask(title:lineIndex:) async` executes POST -> GET refetch -> state replacement.
   - Test explicitly verifies this dispatch sequence using a stubbed `URLSession` with `MockURLProtocol`.
   - Explicitly hooked `refreshMatrix()` into `Focus5Model.refresh()` when `viewMode == .matrix`.

Please review the revised plan in `/Users/noelsaw/Documents/GH Repos/rebalanceOS/PROJECT/2-WORKING/GH-229-PORTFOLIO-PLANNING-MATRIX.md` and provide your Round 4 verdict.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex review — 2026-09-15 (Round 4)

**Grade: B- / Block.** Round 4 now has a testable single-writer error contract, a credible injected-client seam, no speculative persistence, and a UI layout whose two halves share one row-height rule. The plan is still not build-ready because the project/section projection is internally inconsistent: the proposed path-only parser cannot perform the registry matching assigned to it, `/` is both data and delimiter, and the plan disagrees about collision handling and whether registry projects without groups remain visible.

### Graded answers

1. **DRY & subsystem reuse — CONDITIONAL FAIL.** The selected subsystems remain the right ones, but responsibility is misplaced. `parse_sectioned_goals(path: Path)` has no registry input, yet the same invariant and Phase 1 assign it exact matching against `project_registry.name` (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:53-61,159-162`). Keep that helper purely syntactic; have the route build one normalized registry index and perform group-to-project matching. Also name reuse of the existing configured-vault path contract (`get_vault_path()` + `FOCUS5_GOALS_FILENAME`) rather than adding another way to locate `0. Goals.md`; that logic already owns missing/unreadable-file behavior (`src/rebalance/web.py:1037-1073`).

2. **Single writer path — PASS.** The plan now specifies one mutation route, an `AmbiguousGoalError` signal from the non-HTTP helper, a route-level 409 mapping, zero writes on ambiguity, 404 on absence, and POST-then-GET state replacement (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:68-75,149,152,160-170`). That closes the current unsafe first-title fallback in `complete_goal_in_file()` (`src/rebalance/ingest/goals_file.py:73-116`) and the current route's all-failures-to-404 behavior (`src/rebalance/web.py:1115-1155`) without introducing a second writer.

3. **Data contract & wire shape — FAIL pending one deterministic projection contract.** Three contradictions remain:
   - The syntax says split `## Project / Subproject` on `/` (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:62`), but `/` already occurs in the plan's own project identity (`Binoid/Bloomz` at `:35,83`). A header for that registry name can be misparsed as project `Binoid`, subproject `Bloomz`, then fail exact matching. Define an unambiguous delimiter (cheapest: split once on the exact spaced token `" / "`) and test a registry name containing an unspaced slash.
   - “One row per group” (`:63-67`) never defines what happens to an active registry project that has no heading while the goals file does exist. Missing-file behavior preserves all projects (`:51,147`), so the non-missing case should likewise emit one empty bare row for every otherwise-unrepresented active project.
   - Duplicate normalized registry keys are “skipped” at `:61` but “attach to first match deterministically” at `:150`. The safety-preserving rule is to skip every colliding key and attach no tasks; make the invariant and test say the same thing.

4. **UI & ergonomics — PASS WITH FIX.** The frozen 130pt identity column, 58pt shared row height, task scroller, line limits, and injected `Focus5Client` are commensurate (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:103-112`). The client is already a value with injectable `baseURL` and `URLSession` (`Focus5Client.swift:55-64`), so `MockURLProtocol` is a real seam. Name the matrix state added to `Focus5Model` (`matrixResponse` plus its load/error/offline flag behavior) so “retain last in-memory response” and “disable mutations offline” are not accidentally coupled only to the roster fetch's current global `isOffline` updates (`Focus5Model.swift:35-36,576-594`). Also reconcile `MatrixTests.swift` claiming an automated frozen-layout test (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:136`) with the verification table correctly calling geometry a manual 340/420pt check (`:153`).

5. **Gaps / blind spots — FAIL.** Add acceptance cases for: a registry name containing `/`; an active registry project with no goal section; colliding normalized registry names producing no attachment; missing/unconfigured and unreadable goals paths through the existing resolver; and parser-only grouping separately from route-owned registry association. These are projection contract tests, not extra machinery. Keep the existing multi-subproject, malformed-metric, route-level 409/no-write, and model-level POST-then-GET tests.

### SWE rubric

| Pillar | Result | Cheapest plan correction |
|---|---|---|
| Recon | Fix | Add the existing goals-path resolver and split parser-vs-route ownership in the current-state/data-flow map. |
| Minimal | Pass | The v1 source cut, no-cache decision, two new Swift files, and existing writer reuse are appropriately small. |
| Diagnosable | Fix | Reuse the existing unreadable-goals warning and specify one warning for skipped colliding registry keys. |
| Blast | Pass | The only mutation is guarded by exact-line-first completion, ambiguity refusal, atomic replace, and immediate refetch. |
| Proof | Block | Resolve the slash, absent-project, and collision contracts, then add the five focused cases above. |

**Reversibility:** Easy for the additive endpoint/tab. The existing goal-file mutation remains consequential but is now planned behind the correct single route and ambiguity guard.

VERDICT: FAIL

### Round 4 · Orchestrator · Revisions Addressing Round 4 Feedback

All remaining items from Codex Round 4 have been resolved in `/Users/noelsaw/Documents/GH Repos/rebalanceOS/PROJECT/2-WORKING/GH-229-PORTFOLIO-PLANNING-MATRIX.md`:

1. **Parser vs Route Responsibility & Spaced Slash Delimiter:**
   - `parse_sectioned_goals()` is made purely syntactic: parses markdown headers and checklists into `RawSectionGroup(header_raw, tasks)` without registry awareness.
   - The route (`src/rebalance/web.py`) owns semantic matching:
     - Splits on the exact spaced delimiter `" / "` into `(project, subproject)`. Unspaced slashes (such as `Binoid/Bloomz`) are preserved as project names.
     - Performs exact normalized key matching against `project_registry.name` using `normalize_match_text()`.
     - Colliding normalized registry keys log a warning and attach zero tasks (consistent safety rule across invariant and verification matrix).
     - Active registry projects without a matching goal section remain visible, emitting a bare row with `subproject=None` and `tasks=[]`.
   - Reuses existing `get_vault_path() + FOCUS5_GOALS_FILENAME` path resolver.

2. **Swift Model State & Test Clarity:**
   - Dedicated matrix state properties named: `matrixResponse: PortfolioMatrixResponse?`, `matrixLoadState: LoadState`, `isMatrixOffline: Bool`.
   - Injected client seam: `Focus5Model.init(client: Focus5Client = Focus5Client())`.
   - Reconciled tests: layout row height/alignment is verified manually at 340pt/420pt; `MatrixTests.swift` tests decoding, data integrity, and `completeMatrixTask` POST-then-GET refetch via `MockURLProtocol`.

Please review the revised plan in `/Users/noelsaw/Documents/GH Repos/rebalanceOS/PROJECT/2-WORKING/GH-229-PORTFOLIO-PLANNING-MATRIX.md` and provide your Round 5 verdict.

<!-- ▽ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK ▽ -->
▶ TAKE YOUR TURN (codex)
<!-- △ RELAY AUTOMATION: DO NOT MODIFY THIS BLOCK △ -->

## Codex review — 2026-09-15 (Round 5)

**Grade: B- / Block.** Round 5 resolves the parser/route responsibility split, spaced-slash parsing, registry-key collision rule, unrepresented-project rows, dedicated matrix state, and manual-vs-automated layout proof. The projection is now coherent. Two mutation-safety gaps remain: a stale `line_index` can still match the wrong same-titled task before the ambiguity fallback runs, and the existing Swift transport retries POST requests across both localhost candidates.

### Graded answers

1. **DRY & subsystem reuse — PASS.** The plan now keeps `parse_sectioned_goals()` syntactic, performs registry association once in the route, reuses `resolve_database_path()`, `get_vault_path() + FOCUS5_GOALS_FILENAME`, `get_projects()`, `normalize_match_text()`, `Focus5Client`, and `Theme`, and adds no persistence or parallel completion engine (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:49-69,113-133`). This is commensurate with the local single-user scope.

2. **Single writer path — TOPOLOGY PASS, END-TO-END SAFETY FAIL.** Every task still targets the one canonical endpoint/helper, but the request contract is not enough to guarantee the intended task. `_candidate_indexes()` puts the preferred line first, and `complete_goal_in_file()` immediately writes it when its title matches (`src/rebalance/ingest/goals_file.py:55-60,73-115`). If edits shift another project's same-titled task onto the stale index, the preferred-line check succeeds and `AmbiguousGoalError` is never reached; the planned fallback-only ambiguity guard at `GH-229-PORTFOLIO-PLANNING-MATRIX.md:63-68` does not cover this case. Cheapest correction: add a `goals_revision` content hash to the matrix response and completion request, compute it from the same content the helper will mutate, and return a no-write `409 stale_goal_snapshot` when it differs. Keep the field optional only if backward compatibility is required, but require it for matrix mutations and add the shifted-index/same-title regression.

   The Swift transport also makes mutation failover unsafe. `candidateBaseURLs` contains ports 8787 and 8767, `execute()` continues after every HTTP or transport error, and `completeGoal()` sends its POST through that generic executor (`macOS/Apps/Focus5Float/Sources/Focus5Float/Focus5Client.swift:86-92,136-171,244-264`). Thus a 409 from the canonical server is retried against the second candidate and can be masked; a lost response after a successful write can dispatch the same mutation again. Keep candidate failover for GETs, but make POST completion single-attempt against the selected primary and never retry after an HTTP response or ambiguous transport failure. Add a `MockURLProtocol` assertion that a 409 produces exactly one POST and no candidate failover.

3. **Data contract & wire shape — PASS WITH FIX.** The additive snake-case projection, safe coercion, deterministic metric ordering, three-task cap, and row shape are compact (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:70-96`). Add the revision token required above. Also define duplicate source-section behavior: two identical `## Project / Subproject` groups currently produce two rows but both derive the same Swift ID (`:53,60-61`). Coalesce identical matched `(project, subproject)` groups in file order before the three-task cap, or skip later duplicates with a warning; either rule must guarantee one emitted row per derived ID and have a fixture.

4. **UI & ergonomics — PASS WITH FIX.** The frozen 130pt column, shared 58pt row height, bounded task columns, dedicated load/offline state, injected client, and 340/420pt manual check fit the panel (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:97-107,149-150`). The model state names no mutation error or in-flight guard (`:104-106`). Surface 409/stale-snapshot errors without discarding the last matrix, and disable the active pill while its request is in flight so repeated clicks cannot issue concurrent completion requests.

5. **Gaps / blind spots — FAIL.** Add focused acceptance cases for: (a) a stale index now occupied by another section's same-titled task -> 409 and byte-for-byte no write; (b) completion 409 -> exactly one POST, no port-8767 fallback, visible error, unchanged matrix; (c) transport ambiguity -> no second POST and retained/refetched state; and (d) duplicate identical section headings -> one unique row ID with the chosen coalesce/skip rule. The current matrix covers duplicate-title fallback and successful POST-then-GET only (`GH-229-PORTFOLIO-PLANNING-MATRIX.md:146-149`), so it would not catch either consequential mutation path above.

### SWE rubric

| Pillar | Result | Cheapest plan correction |
|---|---|---|
| Recon | Pass with fix | Add the generic client's candidate-failover behavior and preferred-line-before-fallback ordering to the current-state map. |
| Minimal | Pass | A revision hash, one POST failover policy, and duplicate-group rule are small extensions of existing components, not new machinery. |
| Diagnosable | Fix | Surface 409/stale-snapshot errors in matrix UI while retaining the last response; do not mask the first server's HTTP error with fallback attempts. |
| Blast | Block | Prevent a stale exact index from completing another section's same-titled task and prevent multi-candidate POST dispatch. |
| Proof | Block | Add the four negative-path assertions above; retain the existing projection, layout, coercion, and success-sequence checks. |

**Reversibility:** Easy for the additive endpoint/tab. Goal completion remains consequential and must be snapshot-bound and single-dispatch before interactive matrix pills are safe.

VERDICT: FAIL
