---
gh_issue: 200
source: https://github.com/Claude-AI-Tools-Ventura-County/xyz-3-agents-swarm/issues/200
title: "swe-diagram: add top-down layered layout"
status: Complete
created: 2026-07-14
updated: 2026-07-14
owner: noel
goal: Add a deterministic top-to-bottom layered layout and a third rendered architecture example.
doc_type: feedback
effort: 2
complexity: 2
risk: 1
phases: 1
---

# GH-200 · swe-diagram top-down layout

## Status

| What was just completed | What's next |
|---|---|
| Top-down layout, tests, skill guidance, and the 31-node/43-edge example completed and visually verified in headless Chrome on 2026-07-14. | Commit and push the completed change to `main`; issue #200 closes from the commit. |

## Scope and acceptance

- [x] `layout: "top-down"` ranks nodes from top to bottom following `source -> target` direction.
- [x] Edge anchors and paths read vertically; dragging continues to redraw them correctly.
- [x] Group swimlanes, filtering, pan/zoom, and both existing layouts remain supported.
- [x] Focused tests cover top-down rank direction and same-rank spacing.
- [x] `ARCHITECTURE/system-diagram-top-down.json` builds a third standalone rendered example at
      `ARCHITECTURE/system-diagram-top-down.html`.
- [x] The skill contract documents when to choose all three layouts.

## Verification

1. Run `test/swe-diagram.sh`. -> expect all focused fixtures to pass.
2. Build the top-down JSON with `utils/swe-diagram/assets/build-diagram.sh`. -> expect a standalone
   HTML file with the same node/edge counts as the JSON.
3. Validate JSON edge references and visually inspect the rendered HTML. -> expect no dangling
   endpoints, horizontal overlap within ranks, or incorrect edge direction.
4. Run the skill validator, `./validate.sh`, and `utils/pdda/pdda.sh run`. -> expect all applicable
   code and documentation gates to pass.

## Outcome

- `test/swe-diagram.sh`: 19 pass, 0 fail; `node --check` passed.
- Skill package validation passed.
- Builder produced 31 nodes and 43 edges; `jq` found zero dangling endpoints.
- Headless Chrome screenshot confirmed vertical ranks, readable labels, typed edges, and group boxes.
- An isolated forward test built a separate 6-node/6-edge CI example under `/tmp`; geometry and HTML
  substitution passed. It also reconfirmed the pre-existing Node-test requirement to stub
  `global.window`; the browser/builder workflow is unaffected.
- Full `./validate.sh`: 110/112 gates passed. The two failures are the repository's documented
  pre-existing environment gaps: missing npm `acorn` and missing Python `pytest`. The new
  `swe-diagram.sh` gate passed 19/19 inside that run.
