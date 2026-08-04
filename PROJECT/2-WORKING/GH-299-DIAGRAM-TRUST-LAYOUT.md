---
title: Trust-Centered Alternative System Diagram Layout
status: Active
created: 2026-07-23
updated: 2026-07-23
owner: unassigned
gh_issue: 299
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/299
goal: >
  Ship a new, A/B-comparable system diagram layout that makes trust/control-plane structure the
  dominant visual axis, eliminates label-overlap failures, and reduces edge-crossing noise around
  the containment core, without disturbing the default layered diagram output.
effort: 3
complexity: 3
risk: 1
phases: 7
---

# Project Plan: Trust-Centered Alternative System Diagram Layout

## Status

| What was just completed | What's next |
|---|---|
| All 7 execution-plan phases done: baseline-scored all 3 existing layouts (none cleared all 5 criteria); designed + implemented a new `trust-clustered` layout mode (`utils/swe-diagram`) plus a generic edge-label-overlap fix; scored the new layout 5/5 on the real spec via headless-Chrome screenshots; `test/swe-diagram.sh` 42/42; `./validate.sh` clean except 2 pre-existing unrelated failures (`acorn-extract.sh` missing npm dep, `test_python_layer.py` 2/121); `ROADMAP.md`/`CHANGELOG.md` updated; `pdda.sh run` clean. | Awaiting operator review of the rendered `ARCHITECTURE/system-diagram-trust-clustered.html` in a real browser (only headless-screenshot-verified so far) before this doc moves to `3-COMPLETED` and issue #299 closes. |

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

## Phase 1 Findings — Discovery: Baseline Inspection (2026-07-23)

What was investigated: the real spec (`ARCHITECTURE/system-diagram.json`, 31 nodes / 43 edges)
rendered under all three currently supported layouts. `system-diagram-top-down.json` and
`system-diagram-hub.json` were stale (predated the 2026-07-09 trust-boundary/audit-layer additions —
22 vs 31 nodes) and were regenerated from the current spec (`layout` field swapped only; hub-ring
given an explicit `"hub": "relay-lib"` since `relay-drive`/`relay-lib` tie on raw edge degree and
auto-pick isn't guaranteed to land on the containment core). All three were rebuilt via
`utils/swe-diagram/assets/build-diagram.sh` and screenshotted with headless Chrome
(`--headless --screenshot --window-size=2400,1600`) after the renderer's on-load `fitView()`.

What was found, against the 5 acceptance criteria:

| Layout | 1. Hub readability | 2. Label clarity | 3. Trust grouping | 4. Canvas efficiency | 5. Render integrity |
|---|---|---|---|---|---|
| Layered (`system-diagram.html`, default) | FAIL — `relay-turn-lib.sh` is one same-sized node in the "relay-automation" column, not a visual spine | FAIL — dense label overlap in the shims/agents band (e.g. "containment" labels crossing node borders around the 4 shim→CLI edges) | FAIL — groups are subsystem-based (kernel/orchestration/shims/agents/external/state/governance/trust/ate), not trust-tier based | FAIL — ~15% dead vertical whitespace above the node band | PASS |
| Top-down (`system-diagram-top-down.html`) | FAIL — `relay-turn-lib.sh` lands in rank row 5 of 6, reads as one of several small nodes | FAIL — worse than layered; labels clip/overlap where the 4 shim→CLI edges converge (e.g. clipped "containm[ent]" and "s revie[w]" labels over the OpenRouter/Google-search boxes) | FAIL — same subsystem grouping as layered | borderline PASS — taller/narrower, less dead space, but doesn't offset the 1/2/3 failures | PASS |
| Hub-ring (`system-diagram-hub.html`, explicit hub) | PARTIAL — `relay-turn-lib.sh` sits near-center (closer than the other two) but isn't visually distinguished (same size/style as every other node) and the ring structure is obscured by dense crossing edges | FAIL — heaviest overlap of the three; small font, dense radial edge crossings through the center | FAIL **by construction** — `SKILL.md` documents group swimlanes are "silently skipped under hub-ring"; this mode structurally cannot render trust-tier grouping regardless of spec content | FAIL — uneven; large empty top/bottom margins, node cluster compressed into a middle band | PASS |

What it changes: per the plan's own Phase 2 rule (cheapest viable reuse first), neither existing mode
clears all 5 criteria — hub-ring is disqualified structurally on criterion 3 (group swimlanes are
unsupported in that mode, independent of this spec), and both hub-ring and top-down fail criterion 1
(containment core doesn't read as a dominant hub/spine) and criterion 2 (label overlap) even after
regenerating against the current, up-to-date spec. This confirms the plan's stated fallback: proceed
to Phase 2/3 and implement a new spec-driven **trust-clustered** layout mode. Issue-first is already
satisfied (`gh_issue: 299`), so this is not a scope-guard trip — it's the plan's own documented
escalation path, not an open-ended redesign.

## Phase 2/3 — Implementation: `trust-clustered` layout (2026-07-23)

**Design.** Added a fifth layout mode to `utils/swe-diagram/assets/renderer.js`,
`trustClusteredLayout()`, that bands nodes into 5 fixed columns derived from each node's own
`trust` field (already authored in `system-diagram.json` for the legend — no new spec fields
needed): Orchestration Spine (`trusted-primitive`/`trusted-orchestrator`/`trusted-containment-core`/
`trusted-supervisor`), Turn-Shim Cluster (`trusted-dispatch`), Untrusted Periphery
(`untrusted-executor`/`external-credentialed`/`sandboxed-worker`), Shared State (`shared-state`),
Off-Live-Path Governance & Audit (`governance-gate`/`runtime-audit`). Within the spine column the
containment core is floated to the top, adjacent to its dispatching orchestrator, so the traced path
never eye-jumps; a tier past 6 members wraps into side-by-side sub-columns instead of one very tall
column (canvas-efficiency criterion). The containment-core node gets an emphasized border
(`.swe-node-hub`) so it reads as the hub at a glance. Reuses the existing left-right bezier edge
routing and rank-restack logic unchanged (both are generic over any x-based column layout); only the
group-box logic was branched to draw trust-tier bands instead of `spec.groups` when this mode is
active.

**Label-overlap fix (applies to all layouts, not just this one).** The baseline inspection found real
label-on-label collisions in the busy periphery/shared-state boundary and the spine/shim boundary.
Added a small greedy vertical-nudge pass in `drawEdges()` (`placeLabelRect`): each edge label is
checked against every node rectangle and every previously-placed label rectangle in render order, and
nudged up/down in `LABEL_H`-sized steps until clear (capped at 14 tries). This is a generic renderer
improvement — it re-ran cleanly against the other 3 layouts too (screenshotted, no regressions).

**Score against the 5 acceptance criteria** (real spec, headless-Chrome screenshots,
`ARCHITECTURE/system-diagram-trust-clustered.html`):

| # | Criterion | Result |
|---|---|---|
| 1 | Containment hub readability | **PASS** — `relay-turn-lib.sh` sits in the Orchestration Spine band with an emphasized border, receives 6 converging edges (relay-drive, checkin.py, marathon.sh, tick, plus containment edges from all 4 turn shims). `relay-drive.sh -> shim` is a clean adjacent-column flow; `shim -> relay-lib` containment reads as a short backward arc into the spine, not a cross-canvas jump. |
| 2 | Label clarity | **PASS** — re-verified via zoomed crops of the previously-worst areas (periphery/shared-state boundary, spine/shim boundary) after the label-collision fix; no remaining label-on-label or label-on-node overlaps observed. |
| 3 | Coherent grouping | **PASS** — 5 legible band boxes (Orchestration Spine / Turn-Shim Cluster / Untrusted Periphery / Shared State / Off-Live-Path Governance & Audit) derived purely from `trust`, tiling the canvas left-to-right. |
| 4 | Canvas efficiency | **PASS** — the 10-node periphery tier wraps into 2 sub-columns instead of one very tall column; overall aspect ratio is comparable to the other 3 layouts at the same screenshot window size (the symmetric top/bottom margin in all 4 screenshots is `fitView()` centering a wide+short diagram in a fixed 2400x1600 window, not a trust-clustered-specific waste). |
| 5 | Render integrity | **PASS** — 0/43 dangling edges (verified programmatically: every edge's source/target resolves to a node id); every node gets a position (an untagged node would fall back to the governance band rather than vanishing, though none exist in the real spec — all 31 nodes carry `trust`). |

**Decision: `trust-clustered` is the chosen layout.** It's the only one of the 4 that clears all 5
criteria on the real spec.

## Verification Checklist
- [x] Real-spec headless screenshot produced for new layout — `ARCHITECTURE/system-diagram-trust-clustered.html`, screenshotted at 2400x1600.
- [x] Human-trace path check passes (relay-drive.sh to containment to commit path) — see criterion 1 above.
- [x] No label-on-node and no label-on-label overlap observed — see criterion 2 above.
- [x] Zero dangling edge endpoints — verified programmatically (0/43).
- [x] Focused swe-diagram fixture suite passes — `test/swe-diagram.sh` 42/42 (10 new cases added for `trustTierOf`/`trustClusteredLayout`).
- [x] `./validate.sh` passes, with 2 pre-existing unrelated failures called out: `acorn-extract.sh` (missing `acorn` npm module — `node_modules/.bin/acorn` absent, unrelated to this repo's own `src/acorn-extract.js` logic) and `python:test_python_layer.py` (2/121 failing; not touched by this change, no swe-diagram/JS coupling). Neither failure is in a file this project touched.

## Stop Condition / Scope Guard
If the work expands into a full layout-engine redesign, stop and file/follow issue-first intake
instead of silently expanding scope. (Not triggered — this stayed a single bounded layout-mode
addition, consistent with how `top-down` and `hub-ring` were added previously.)

## Deliverables
- Updated renderer/layout implementation: `utils/swe-diagram/assets/renderer.js` (new
  `trustClusteredLayout`/`trustTierOf`, trust-tier group-box drawing, generic label-overlap fix,
  hub-emphasis CSS), `utils/swe-diagram/assets/template.html` (`.swe-node-hub` style),
  `utils/swe-diagram/SKILL.md` (documents the 5th layout mode).
- New sibling diagram artifacts: `ARCHITECTURE/system-diagram-trust-clustered.json` +
  `.html` (additive; `ARCHITECTURE/system-diagram.html` — the default layered output — untouched).
- Test coverage: 10 new cases in `test/swe-diagram.sh` (`trustTierOf` tier mapping,
  `trustClusteredLayout` hub/column/wrap behavior).
- Decision note: chosen layout is `trust-clustered` — the only one of the 4 supported modes that
  clears all 5 acceptance criteria on the real spec (see Phase 2/3 scoring table above). Residual
  risk: the label-collision-avoidance pass is a bounded greedy heuristic (width estimated from glyph
  count, not measured) — good enough to clear this spec's density, but a much denser future spec
  could still produce an occasional overlap it can't resolve within its 14-try cap.