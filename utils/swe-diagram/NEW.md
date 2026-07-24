You are working in the xyz-3-agents-swarm repo. The system diagram at
ARCHITECTURE/system-diagram.html (rendered from ARCHITECTURE/system-diagram.json by the
dependency-free generator/renderer under utils/swe-diagram/) currently uses the left-to-right
layered layout, and it reads poorly. Build me an ALTERNATIVE layout that fixes the readability
failures below. Read the existing renderer and spec first; reuse what's there.

WHAT'S WRONG WITH THE CURRENT VIEW (these are your acceptance criteria — the new view must
resolve each one, verified by eye on a headless screenshot of the REAL spec, not a toy fixture):
1. Edge spaghetti in the center. relay-turn-lib.sh (the containment core) is drawn as a
   right-column leaf, but it's actually a hub: every turn shim sources it, and every agent CLI
   sends a "containment" edge back into it. That makes edges flow both directions across the
   same columns (runs-CLI rightward, containment leftward, shares-containment-core rightward),
   which a one-direction layered layout cannot route cleanly.
2. Edge labels overlap node boxes and each other (e.g. "runs CLI (--no-auto-commits) / runs
   kernel + coordination suite", "per variation (scratch repo)", "chains automatically when
   --gh-repo set"). No label may sit on top of a node border or another label.
3. The grouping is incoherent: swimlane boxes group by subsystem label (faint, irregular,
   don't tile the canvas, tiny headers) while node top-border color encodes type. The system's
   actual story — control plane vs agent-CLI edge vs external world vs off-the-live-path
   governance/audit — is not the primary visual axis.
4. Wasted canvas / bad aspect ratio (large empty quadrant).

DIRECTION (pick the cheapest thing that clears the bar; do NOT over-engineer):
- The spec ALREADY carries a per-node `trust` field and a top-level `trust_boundaries` array.
  Use them. Make the primary grouping axis the trust / control-plane structure (orchestration
  spine = relay-drive.sh + relay-turn-lib.sh + tick; the per-agent turn shims as a ring/cluster
  around that spine; agent CLIs + external services as the untrusted periphery; governance
  (pdda.sh/validate.sh) and audit (isolation-breach audit, consult.sh) as a clearly
  off-the-live-path band). The containment core must read as a hub or a central spine, never a
  leaf.
- Before writing a new layout engine, TRY the existing shipped layouts against the real spec
  (the renderer already supports layout: "top-down" and layout: "hub-ring"; see
  ARCHITECTURE/system-diagram-top-down.html and system-diagram-hub.html). If hub-ring with the
  containment core as the hub (or top-down with the spine as the top rank) clears the criteria
  above, ship that — possibly with edge-bundling for the "shares containment core" fan so it's
  one routed bundle, not N crossing lines. Only add a genuinely new layout value (e.g. a
  grouped/clustered-by-trust layout) if neither existing layout clears the bar; if you do,
  follow the same spec-driven contract the others use (positions computed by the renderer from
  the spec, nothing hardcoded).
- Route edges to minimize crossings and keep labels off nodes (offset/leader labels, or hide
  low-value edge labels behind hover if the renderer supports it; never overlap).

PRESERVE (do not regress these):
- Dependency-free, self-contained HTML (renderer inlined; no new npm deps, no lockfile — the
  repo ships no root manifest).
- The search/filter box and the type legend stay and keep working.
- Node TYPE colors stay as a secondary channel; the new trust/subsystem grouping must be the
  DOMINANT visual channel (stronger swimlane/cluster contrast, legible headers, boxes that
  tile the canvas).
- Spec-driven: ARCHITECTURE/system-diagram.json stays the single source of truth.
- Reversible + comparable: ADD the new layout as a new option and emit a NEW sibling example
  (e.g. ARCHITECTURE/system-diagram-<layout>.json/.html). Do NOT overwrite the default
  layered system-diagram.html — I want to A/B them.

VERIFY (the repo's own bar — done means verified):
- Render the REAL spec headless (headless-Chrome screenshot) in the new layout and confirm by
  eye: a human can trace relay-drive.sh -> a turn shim -> an agent CLI -> relay-turn-lib.sh
  containment -> file-scoped commit without their eye jumping across three unrelated columns,
  and no label sits on a node.
- The existing swe-diagram renderer fixtures stay green (run the focused fixture suite under
  utils/swe-diagram/ and ./validate.sh; the new layout must not break the other layouts' tests).
- Zero dangling edge endpoints in the new render.

If this grows beyond a focused spike (e.g. you end up writing a whole new layout engine), stop
and follow the repo's issue-first SOP from AGENTS.md rather than silently expanding scope.
Report which layout you chose and why, with the before/after screenshot paths.