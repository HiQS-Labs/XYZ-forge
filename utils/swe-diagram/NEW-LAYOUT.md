# Project Plan: Trust-Centered Alternative System Diagram Layout

## Outcome
Ship a new, A/B-comparable system diagram layout that materially improves readability for the real
spec while preserving the dependency-free renderer and existing UX features.

## Goal
Improve the readability of the architecture diagram generated from
ARCHITECTURE/system-diagram.json by making trust/control-plane structure the dominant visual axis,
eliminating label-overlap failures, and reducing edge-crossing noise around the containment core.

## Scope
In scope:
- Renderer/layout behavior under utils/swe-diagram.
- New sibling output artifact(s): ARCHITECTURE/system-diagram-<layout>.json and
  ARCHITECTURE/system-diagram-<layout>.html.
- Visual routing/label placement improvements needed to satisfy acceptance criteria.

Out of scope:
- Replacing the default layered diagram as canonical output.
- Introducing external dependencies, lockfiles, or non-self-contained rendering.
- Hardcoded node coordinates detached from spec-driven layout computation.

## Assumption, Tradeoff, Reversibility
Assumption:
- Existing layouts (hub-ring or top-down), with minimal routing/label refinements, can clear the
  bar without a brand-new layout engine.

Tradeoff:
- Prefer cheapest viable reuse first; only escalate to a new layout mode if evidence shows the
  existing modes cannot satisfy the readability requirements on the real spec.

Reversibility:
- Easy. This is additive and A/B comparable: default layered output remains untouched; new layout
  ships as a sibling option/artifact.

## Requirements To Preserve
- Dependency-free, self-contained HTML output (inline renderer; no new npm dependencies/lockfiles).
- Search/filter box and type legend remain present and working.
- Node type colors remain as a secondary channel.
- Trust/control-plane grouping becomes the dominant visual channel.
- ARCHITECTURE/system-diagram.json remains the single source of truth.
- Existing layout outputs stay available.

## Acceptance Criteria
1. Containment hub readability:
- relay-turn-lib.sh reads as hub/central spine (never a leaf).
- The path relay-drive.sh -> turn shim -> agent CLI -> relay-turn-lib.sh containment ->
  file-scoped commit is visually traceable without eye-jumping across unrelated columns.

2. Label clarity:
- No edge label overlaps a node border.
- No edge label overlaps another label.

3. Coherent grouping:
- Primary grouping reflects trust/control-plane structure:
  orchestration spine, turn-shim cluster/ring, untrusted periphery, off-live-path
  governance/audit band.
- Group containers are legible and tile canvas effectively.

4. Canvas efficiency:
- New layout eliminates obvious empty-quadrant waste and improves aspect utilization.

5. Render integrity:
- Zero dangling edge endpoints in the new render.

## Execution Plan
1. Baseline and inspect existing options -> expect evidence-backed layout choice:
- Render and inspect the real spec using current supported layout modes (top-down, hub-ring).
- Capture baseline screenshots for layered + candidate layouts.
- Record whether either existing mode already clears all acceptance criteria.

2. Choose the cheapest successful path -> expect no unnecessary engine work:
- If hub-ring (with containment core as hub) clears criteria, choose hub-ring.
- Else if top-down (with orchestration spine top-ranked) clears criteria, choose top-down.
- Else define and implement one new spec-driven layout mode (trust-clustered), then stop and
  open an issue before any broader redesign per issue-first SOP.

3. Apply minimal renderer refinements needed for criteria -> expect targeted diffs only:
- Improve edge routing to reduce crossings around containment fan-in/fan-out.
- Add label placement rules to keep labels off node borders and off one another
  (offsets/leader-label strategy and/or de-emphasize low-value labels via hover if already
  supported).
- If needed, add bundled routing for repeated containment-core share edges to reduce spaghetti.

4. Emit additive artifacts for A/B comparison -> expect default unchanged:
- Add new layout option output under ARCHITECTURE/system-diagram-<layout>.json/.html.
- Do not overwrite ARCHITECTURE/system-diagram.html.

5. Verify technical correctness -> expect all relevant gates green:
- Run focused swe-diagram fixtures/tests.
- Run ./validate.sh.
- Confirm zero dangling endpoints in generated output.

6. Verify readability by eye on real spec -> expect criteria closure:
- Render headless-Chrome screenshot(s) of the new layout output.
- Confirm all acceptance criteria with explicit pass/fail notes.

7. Report and handoff -> expect clear rationale + evidence:
- State chosen layout and why it was selected.
- Provide before/after screenshot paths.
- Note any residual risks or deferred work.

## Verification Checklist
- Real-spec headless screenshot produced for new layout.
- Human-trace path check passes (relay-drive.sh to containment to commit path).
- No label-on-node and no label-on-label overlap observed.
- Zero dangling edge endpoints.
- Focused swe-diagram fixture suite passes.
- ./validate.sh passes (or any pre-existing unrelated failures called out explicitly).

## Stop Condition / Scope Guard
If the work expands into a full layout-engine redesign, stop and file/follow issue-first intake
instead of silently expanding scope.

## Deliverables
- Updated renderer/layout implementation (only as needed).
- New sibling diagram artifacts for the selected alternative layout.
- Before/after headless screenshot evidence paths.
- Short decision note: chosen layout, rationale, and verification outcome.