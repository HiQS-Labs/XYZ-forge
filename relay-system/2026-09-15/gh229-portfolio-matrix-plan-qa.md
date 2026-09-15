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
