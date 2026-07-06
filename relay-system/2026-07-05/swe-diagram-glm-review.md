# RELAY · SWE Diagram system review (GLM-5.2 via OpenRouter)
<!--
  Single source of truth for this two-agent relay. Read the ENTIRE file before acting.
  Scaffolded by relay-automation/new-relay.sh on 2026-07-05.
-->

NEXT: Reviewer
STATUS: Open
ROUND: 1 / 2

## ▶ TAKE YOUR TURN — read this first (works for ANY agent: Claude, Codex, agy)
1. **Read this whole file** (header, Setup, Ground rules, every block in the Log).
2. **Check it's your turn:** `NEXT` (top) names the role to act. Confirm you are bound to it and the
   last Log block isn't already yours. If not → STOP and reply "wrong window — nudge the <other> window."
3. **Do your role's work** on the artifact named in Setup:
   - **Reviewer:** review vs the Definition of Done → graded findings
     (`[Blocker]`/`[Should]`/`[Nit]`/`[Pass]`), each with a concrete fix → set a **Verdict**
     (Approved | Changes requested | Blocked). Do **not** edit the artifact; only append findings here.
   - **Producer:** log a disposition for every open finding (Implemented / Modified / Declined + why),
     make the change, then add new work.
4. **Append ONE block** at the very bottom, directly **above** the marker line. Never edit earlier turns.
5. **Update the header:** flip `NEXT`; set `STATUS` (`Approved` closes — Reviewer only; else `Open`);
   the Producer bumps `ROUND` when opening a new cycle. If the max `ROUND` ends without `Approved`,
   set `STATUS: Escalated`.
6. **Commit only the relay file** (`relay(swe-diagram-glm-review): <role> r<N>`); no push. **Stop** and report one line.

## Setup
- Artifact under review: **swe-diagram-combined.md** (embedded below — read it here).
- Reviewer: aider-glm   ·   Producer: claude-a
- Started: 2026-07-05

### Artifact — swe-diagram-combined.md
````
# Combined artifact: utils/swe-diagram (SWE Diagram system)

## FILE: utils/swe-diagram/SKILL.md
```
---
name: swe-diagram
description: Draw an interactive system architecture diagram for a repo — first from its EXISTING rendered knowledge (graphify output, codebase-memory graph, ask_self RAG docs, architecture docs), grepping the raw code only as a last resort. Produces two artifacts, a diagram JSON spec and a self-contained interactive HTML file with an xyflow-style layout (pan/zoom, draggable nodes, typed edges), rendered by a bundled dependency-free JS renderer. Trigger when the user says "draw the system diagram", "diagram this repo/architecture", "swe-diagram", "visualize the architecture", "make an xyflow diagram", or wants an architecture map as HTML/JSON. Not for data charts or dashboards (that is dataviz) and not for flowcharts of a single algorithm.
---

# swe-diagram — System Diagram from Existing Architecture Knowledge

Produce two deliverables for the target repo:

1. `ARCHITECTURE/system-diagram.json` — the diagram spec (schema below)
2. `ARCHITECTURE/system-diagram.html` — a self-contained interactive xyflow-style
   diagram built from that JSON (no network, no dependencies)

Ask the user for a different output path only if `ARCHITECTURE/` is inappropriate
for the repo; otherwise just create it.

## Step 1 — Gather architecture knowledge (in this order, STOP when sufficient)

Do NOT start by grepping source code. The repo has usually already paid the
cost of describing itself — use that first. Work down this ladder and stop as
soon as you can name the major components and the edges between them:

1. **graphify output** — if `graphify-out/` exists (or the graphify skill is
   available), query it: god nodes, communities, and cross-file relationships
   map directly onto diagram nodes/edges.
2. **codebase-memory MCP graph** — if the `codebase-memory-mcp` tools are
   available, call `get_architecture` (aspects: structure, services,
   entrypoints), then `search_graph` / `trace_path` to confirm the edges
   between major components. If the repo isn't indexed, note it but don't
   index just for this — move to the next rung.
3. **ask_self RAG docs** — if the repo has an ask-self install (`/ask_self`
   skill, `Ask_Self/` or `.ask_self/` directory), query it with questions like
   "what are the major components and how do they talk to each other?" and
   "what external services/databases does this system depend on?"
4. **Written architecture docs** — `ARCHITECTURE.md`, `docs/`, `adr/` or
   `docs/adr/`, `AGENTS.md`/`CLAUDE.md`, README architecture sections,
   existing mermaid/diagram blocks. These often name components more
   accurately than code inspection.
5. **Last resort: the code itself** — only if the above yield too little.
   Read entrypoints, routing/config files, docker-compose/infra manifests,
   and top-level directory structure. Prefer targeted reads over broad greps.

Record which sources you used — they go in the JSON's `sources` field so the
diagram is auditable.

## Step 2 — Write the diagram JSON

Target 8-25 nodes: major components, not every file. Collapse helpers into
their owning service. Every edge must be justified by something you found in
Step 1 (a doc claim, a graph edge, an import/call you saw) — no decorative
arrows.

Schema (`ARCHITECTURE/system-diagram.json`):

```json
{
  "title": "MyApp — System Architecture",
  "generated": "2026-07-04",
  "sources": ["codebase-memory get_architecture", "docs/ARCHITECTURE.md"],
  "groups": [{ "id": "backend", "label": "Backend" }],
  "nodes": [
    {
      "id": "api",
      "label": "REST API",
      "type": "api",
      "group": "backend",
      "tech": "FastAPI",
      "description": "Public HTTP surface; auth + routing"
    }
  ],
  "edges": [
    { "source": "api", "target": "db", "label": "reads/writes", "kind": "sync" }
  ]
}
```

- `type` (drives node color + legend): `service`, `ui`, `api`, `database`,
  `queue`, `external`, `job`, `storage` — anything else falls back to gray.
- `kind` (drives edge style): `sync` (solid), `async` (dashed), `data`
  (dotted). Default `sync`.
- Layout is automatic (layered left→right from edge direction); do not put
  coordinates in the JSON. Point `source → target` in the direction of the
  call/flow — layout quality depends on it.

## Step 3 — Build the HTML

Run the bundled builder (resolve the path relative to THIS skill directory,
not the CWD):

```bash
bash "<this-skill-dir>/assets/build-diagram.sh" ARCHITECTURE/system-diagram.json
```

It inlines `assets/renderer.js` and the JSON into `assets/template.html`,
producing `ARCHITECTURE/system-diagram.html`. If `bash`/`python3` is unavailable,
do the substitution yourself: copy the template and replace `__TITLE__`,
`__RENDERER_JS__` (contents of renderer.js), and `__DIAGRAM_JSON__` (the spec).

The output is a single file: open it in any browser. It supports pan (drag
background), zoom (wheel or +/− buttons), fit-to-view (▣), draggable nodes,
hover tooltips from `description`, edge labels, a type legend, and follows the
OS light/dark theme.

## Step 4 — Verify and report

1. Sanity-check the JSON: every edge's `source`/`target` matches a node `id`
   (the builder fails on invalid JSON but not on dangling edge references —
   the renderer silently drops those, so check).
2. Open or screenshot the HTML if the environment allows; otherwise state that
   it wasn't visually verified.
3. Report both file paths, the node/edge counts, which knowledge sources were
   used, and anything you were unsure about (components you inferred rather
   than found documented).
```

## FILE: utils/swe-diagram/assets/build-diagram.sh
```
#!/usr/bin/env bash
# build-diagram.sh <diagram.json> [output.html]
# Inlines renderer.js + the diagram JSON into template.html to produce a
# single self-contained HTML file. No dependencies beyond python3.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JSON="${1:?usage: build-diagram.sh <diagram.json> [output.html]}"
OUT="${2:-${JSON%.json}.html}"

python3 - "$SCRIPT_DIR/template.html" "$SCRIPT_DIR/renderer.js" "$JSON" "$OUT" <<'PY'
import json, sys, html as H
template, renderer, spec_path, out = sys.argv[1:5]
spec = json.load(open(spec_path))  # validates JSON before embedding
doc = open(template).read()
doc = doc.replace("__TITLE__", H.escape(spec.get("title", "System Diagram")))
doc = doc.replace("__RENDERER_JS__", open(renderer).read())
# ensure_ascii escapes non-ASCII; also escape "<" so a "</script>" inside any
# string can't close the embedding <script> tag early (parses back to "<").
diagram_json = json.dumps(spec, indent=2).replace("<", "\\u003c")
doc = doc.replace("__DIAGRAM_JSON__", diagram_json)
open(out, "w").write(doc)
print(f"wrote {out} ({len(spec.get('nodes', []))} nodes, {len(spec.get('edges', []))} edges)")
PY
```

## FILE: utils/swe-diagram/assets/renderer.js
```
/*
 * swe-diagram renderer — vanilla xyflow-style system diagram.
 * No dependencies. Reads a diagram spec object and renders:
 *   - layered left→right auto-layout (longest-path ranking)
 *   - draggable HTML nodes with type-colored headers
 *   - SVG bezier edges with arrowheads + optional labels
 *   - pan (drag canvas), zoom (wheel / buttons), fit-to-view
 *   - light/dark via prefers-color-scheme
 *
 * Spec shape (see SKILL.md for the authoring contract):
 * {
 *   title: string,
 *   nodes: [{ id, label, type?, group?, description?, tech? }],
 *   edges: [{ source, target, label?, kind? }],   // kind: "sync"|"async"|"data"
 *   groups?: [{ id, label }]
 * }
 */
(function () {
  'use strict';

  var NODE_W = 200;
  var NODE_MIN_H = 56;
  var COL_GAP = 120;
  var ROW_GAP = 36;

  var TYPE_COLORS = {
    service:  '#4f7cff',
    ui:       '#9a5cff',
    api:      '#00a5a5',
    database: '#e07b00',
    queue:    '#c94f7c',
    external: '#7a8699',
    job:      '#5c9a3d',
    storage:  '#b0892b',
    default:  '#6b7280'
  };

  var EDGE_DASH = { async: '6,5', data: '2,4' };

  function el(tag, cls, parent) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (parent) parent.appendChild(e);
    return e;
  }
  function svgEl(tag, parent) {
    var e = document.createElementNS('http://www.w3.org/2000/svg', tag);
    if (parent) parent.appendChild(e);
    return e;
  }

  // ---- layout: longest-path layering, groups kept adjacent within a column
  function layout(spec) {
    var nodes = spec.nodes || [];
    var edges = (spec.edges || []).filter(function (e) { return e.source !== e.target; });
    var byId = {};
    nodes.forEach(function (n) { byId[n.id] = n; });

    // Rank by longest path, but drop cycle back-edges first so a bidirectional
    // pair (A->B, B->A) stays in adjacent columns instead of drifting apart.
    var adj = {};
    nodes.forEach(function (n) { adj[n.id] = []; });
    edges.forEach(function (e) {
      if (byId[e.source] && byId[e.target]) adj[e.source].push(e.target);
    });
    var state = {}, back = {};   // DFS: flag any edge into a node still on the stack
    function walk(u) {
      state[u] = 1;
      adj[u].forEach(function (v) {
        if (state[v] === 1) (back[u] || (back[u] = {}))[v] = true;
        else if (!state[v]) walk(v);
      });
      state[u] = 2;
    }
    nodes.forEach(function (n) { if (!state[n.id]) walk(n.id); });
    var forward = edges.filter(function (e) {
      return byId[e.source] && byId[e.target] &&
             !(back[e.source] && back[e.source][e.target]);
    });

    var rank = {};
    nodes.forEach(function (n) { rank[n.id] = 0; });
    for (var pass = 0; pass < nodes.length; pass++) {   // DAG: converges in <= |V| passes
      var changed = false;
      forward.forEach(function (e) {
        if (rank[e.target] < rank[e.source] + 1) {
          rank[e.target] = rank[e.source] + 1;
          changed = true;
        }
      });
      if (!changed) break;
    }

    var cols = {};
    nodes.forEach(function (n) {
      (cols[rank[n.id]] = cols[rank[n.id]] || []).push(n);
    });

    var positions = {};
    Object.keys(cols).sort(function (a, b) { return a - b; }).forEach(function (r) {
      var col = cols[r];
      col.sort(function (a, b) {
        var ga = a.group == null ? 1 : 0, gb = b.group == null ? 1 : 0;
        return ga - gb ||
               String(a.group || '').localeCompare(String(b.group || '')) ||
               String(a.label).localeCompare(String(b.label));
      });
      var y = 0;
      col.forEach(function (n) {
        var h = nodeHeight(n);
        positions[n.id] = { x: r * (NODE_W + COL_GAP), y: y, w: NODE_W, h: h };
        y += h + ROW_GAP;
      });
      // center column vertically against tallest column later via fitView
    });
    return positions;
  }

  function nodeHeight(n) {
    var h = NODE_MIN_H;
    if (n.tech) h += 18;
    return h;
  }

  // ---- main
  window.renderDiagram = function (spec, mount) {
    mount = mount || document.getElementById('diagram');
    mount.innerHTML = '';
    mount.classList.add('swe-canvas');

    var viewport = el('div', 'swe-viewport', mount);
    var svg = svgEl('svg', viewport);
    svg.setAttribute('class', 'swe-edges');
    var defs = svgEl('defs', svg);
    ['sync', 'async', 'data'].forEach(function (kind) {
      var m = svgEl('marker', defs);
      m.setAttribute('id', 'arrow-' + kind);
      m.setAttribute('viewBox', '0 0 10 10');
      m.setAttribute('refX', '9'); m.setAttribute('refY', '5');
      m.setAttribute('markerWidth', '7'); m.setAttribute('markerHeight', '7');
      m.setAttribute('orient', 'auto-start-reverse');
      var p = svgEl('path', m);
      p.setAttribute('d', 'M 0 0 L 10 5 L 0 10 z');
      p.setAttribute('class', 'swe-arrow');
    });
    var edgeLayer = svgEl('g', svg);
    var nodeLayer = el('div', 'swe-nodes', viewport);

    var pos = layout(spec);
    var nodeEls = {};

    var groupLabels = {};   // honor spec.groups: render the human label, not the raw id
    (spec.groups || []).forEach(function (g) {
      if (g && g.id != null) groupLabels[g.id] = g.label || g.id;
    });

    (spec.nodes || []).forEach(function (n) {
      var p = pos[n.id];
      var d = el('div', 'swe-node', nodeLayer);
      d.style.left = p.x + 'px';
      d.style.top = p.y + 'px';
      d.style.width = p.w + 'px';
      var color = TYPE_COLORS[n.type] || TYPE_COLORS.default;
      d.style.setProperty('--node-color', color);
      var head = el('div', 'swe-node-head', d);
      head.textContent = n.type ? n.type.toUpperCase() : 'COMPONENT';
      var body = el('div', 'swe-node-body', d);
      el('div', 'swe-node-label', body).textContent = n.label || n.id;
      if (n.tech) el('div', 'swe-node-tech', body).textContent = n.tech;
      if (n.description) d.title = n.description;
      if (n.group) el('div', 'swe-node-group', d).textContent = groupLabels[n.group] || n.group;
      nodeEls[n.id] = d;
      makeDraggable(d, n.id);
    });

    // layout() estimated node heights before the DOM existed; a wrapped label or
    // tech line makes the real node taller. Correct pos[].h from the measured
    // heights and re-stack each column so nodes don't overlap and edge anchors
    // (which use pos.h) land on the true vertical midpoint.
    var byCol = {};
    (spec.nodes || []).forEach(function (n) {
      var p = pos[n.id];
      p.h = nodeEls[n.id].offsetHeight || p.h;
      (byCol[p.x] = byCol[p.x] || []).push(n.id);
    });
    Object.keys(byCol).forEach(function (x) {
      var ids = byCol[x].sort(function (a, b) { return pos[a].y - pos[b].y; });
      var y = 0;
      ids.forEach(function (id) {
        pos[id].y = y;
        nodeEls[id].style.top = y + 'px';
        y += pos[id].h + ROW_GAP;
      });
    });

    var edgeEls = [];
    (spec.edges || []).forEach(function (e) {
      if (!pos[e.source] || !pos[e.target]) return;
      var kind = EDGE_DASH[e.kind] ? e.kind : 'sync';
      var path = svgEl('path', edgeLayer);
      path.setAttribute('class', 'swe-edge swe-edge-' + kind);
      if (EDGE_DASH[kind]) path.setAttribute('stroke-dasharray', EDGE_DASH[kind]);
      path.setAttribute('marker-end', 'url(#arrow-' + kind + ')');
      var label = null;
      if (e.label) {
        label = svgEl('text', edgeLayer);
        label.setAttribute('class', 'swe-edge-label');
        label.textContent = e.label;
      }
      edgeEls.push({ e: e, path: path, label: label });
    });

    function edgePath(a, b) {
      var x1 = a.x + a.w, y1 = a.y + a.h / 2;
      var x2 = b.x, y2 = b.y + b.h / 2;
      if (b.x < a.x + a.w) { // backward edge: route from left side
        x1 = a.x; x2 = b.x + b.w;
      }
      var dx = Math.max(40, Math.abs(x2 - x1) / 2);
      var c1 = x1 < x2 ? x1 + dx : x1 - dx;
      var c2 = x1 < x2 ? x2 - dx : x2 + dx;
      return { d: 'M' + x1 + ',' + y1 + ' C' + c1 + ',' + y1 + ' ' + c2 + ',' + y2 + ' ' + x2 + ',' + y2,
               mx: (x1 + x2) / 2, my: (y1 + y2) / 2 - 6 };
    }

    function drawEdges() {
      edgeEls.forEach(function (ee) {
        var p = edgePath(pos[ee.e.source], pos[ee.e.target]);
        ee.path.setAttribute('d', p.d);
        if (ee.label) { ee.label.setAttribute('x', p.mx); ee.label.setAttribute('y', p.my); }
      });
    }

    // ---- pan & zoom
    var view = { x: 40, y: 40, k: 1 };
    function applyView() {
      viewport.style.transform =
        'translate(' + view.x + 'px,' + view.y + 'px) scale(' + view.k + ')';
    }
    mount.addEventListener('wheel', function (ev) {
      ev.preventDefault();
      var k = Math.min(2.5, Math.max(0.2, view.k * (ev.deltaY < 0 ? 1.1 : 0.9)));
      var r = mount.getBoundingClientRect();
      var mx = ev.clientX - r.left, my = ev.clientY - r.top;
      view.x = mx - (mx - view.x) * (k / view.k);
      view.y = my - (my - view.y) * (k / view.k);
      view.k = k;
      applyView();
    }, { passive: false });

    var panning = null;
    mount.addEventListener('mousedown', function (ev) {
      if (ev.target.closest('.swe-node')) return;
      panning = { x: ev.clientX - view.x, y: ev.clientY - view.y };
      mount.classList.add('swe-grabbing');
    });
    window.addEventListener('mousemove', function (ev) {
      if (!panning) return;
      view.x = ev.clientX - panning.x;
      view.y = ev.clientY - panning.y;
      applyView();
    });
    window.addEventListener('mouseup', function () {
      panning = null;
      mount.classList.remove('swe-grabbing');
    });

    function makeDraggable(d, id) {
      d.addEventListener('mousedown', function (ev) {
        ev.stopPropagation();
        var start = { mx: ev.clientX, my: ev.clientY, x: pos[id].x, y: pos[id].y };
        function move(mv) {
          pos[id].x = start.x + (mv.clientX - start.mx) / view.k;
          pos[id].y = start.y + (mv.clientY - start.my) / view.k;
          d.style.left = pos[id].x + 'px';
          d.style.top = pos[id].y + 'px';
          drawEdges();
        }
        function up() {
          window.removeEventListener('mousemove', move);
          window.removeEventListener('mouseup', up);
        }
        window.addEventListener('mousemove', move);
        window.addEventListener('mouseup', up);
      });
    }

    function fitView() {
      var ids = Object.keys(pos);
      if (!ids.length) return;
      var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
      ids.forEach(function (id) {
        var p = pos[id];
        minX = Math.min(minX, p.x); minY = Math.min(minY, p.y);
        maxX = Math.max(maxX, p.x + p.w); maxY = Math.max(maxY, p.y + p.h);
      });
      var r = mount.getBoundingClientRect();
      var k = Math.min(1.5, Math.max(0.2,
        Math.min((r.width - 80) / (maxX - minX), (r.height - 80) / (maxY - minY))));
      view.k = k;
      view.x = (r.width - (maxX - minX) * k) / 2 - minX * k;
      view.y = (r.height - (maxY - minY) * k) / 2 - minY * k;
      applyView();
    }

    // ---- controls + legend
    var controls = el('div', 'swe-controls', mount);
    [['+', function () { view.k = Math.min(2.5, view.k * 1.2); applyView(); }],
     ['−', function () { view.k = Math.max(0.2, view.k / 1.2); applyView(); }],
     ['▣', fitView]].forEach(function (c) {
      var b = el('button', 'swe-btn', controls);
      b.textContent = c[0];
      b.addEventListener('click', c[1]);
    });

    var usedTypes = {};
    (spec.nodes || []).forEach(function (n) { usedTypes[n.type || 'default'] = true; });
    var legend = el('div', 'swe-legend', mount);
    Object.keys(usedTypes).sort().forEach(function (t) {
      var item = el('span', 'swe-legend-item', legend);
      var dot = el('span', 'swe-legend-dot', item);
      dot.style.background = TYPE_COLORS[t] || TYPE_COLORS.default;
      item.appendChild(document.createTextNode(t));
    });

    if (spec.title) {
      el('div', 'swe-title', mount).textContent = spec.title;
    }

    drawEdges();
    fitView();
  };
})();
```

## FILE: utils/swe-diagram/assets/template.html
```
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__</title>
<style>
  :root {
    --bg: #f6f7f9; --panel: #ffffff; --ink: #1c2330; --muted: #6b7280;
    --line: #9aa4b2; --edge-label-bg: #f6f7f9; --border: #d8dee6;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #12151b; --panel: #1c212b; --ink: #e6e9ef; --muted: #9aa4b2;
      --line: #5c6675; --edge-label-bg: #12151b; --border: #333c4a;
    }
  }
  * { box-sizing: border-box; }
  html, body { height: 100%; margin: 0; }
  body { background: var(--bg); color: var(--ink);
         font: 14px/1.4 -apple-system, "Segoe UI", Roboto, sans-serif; }

  .swe-canvas { position: relative; width: 100vw; height: 100vh;
                overflow: hidden; cursor: grab; }
  .swe-canvas.swe-grabbing { cursor: grabbing; }
  .swe-viewport { position: absolute; transform-origin: 0 0; }
  .swe-edges { position: absolute; overflow: visible; width: 1px; height: 1px; }
  .swe-nodes { position: absolute; }

  .swe-node { position: absolute; background: var(--panel);
              border: 1px solid var(--border); border-radius: 8px;
              border-top: 3px solid var(--node-color, #6b7280);
              box-shadow: 0 1px 4px rgba(0,0,0,.12); cursor: move;
              user-select: none; }
  .swe-node-head { font-size: 9px; letter-spacing: .08em; font-weight: 700;
                   color: var(--node-color, #6b7280); padding: 6px 10px 0; }
  .swe-node-body { padding: 2px 10px 8px; }
  .swe-node-label { font-weight: 600; }
  .swe-node-tech { font-size: 11px; color: var(--muted); margin-top: 2px; }
  .swe-node-group { position: absolute; top: -18px; left: 0; font-size: 10px;
                    color: var(--muted); }

  .swe-edge { fill: none; stroke: var(--line); stroke-width: 1.6; }
  .swe-arrow { fill: var(--line); }
  .swe-edge-label { font-size: 11px; fill: var(--muted); text-anchor: middle;
                    paint-order: stroke; stroke: var(--edge-label-bg);
                    stroke-width: 4px; }

  .swe-title { position: absolute; top: 14px; left: 18px; font-size: 16px;
               font-weight: 700; pointer-events: none; }
  .swe-controls { position: absolute; bottom: 16px; left: 16px;
                  display: flex; flex-direction: column; gap: 4px; }
  .swe-btn { width: 30px; height: 30px; border: 1px solid var(--border);
             border-radius: 6px; background: var(--panel); color: var(--ink);
             font-size: 15px; cursor: pointer; }
  .swe-btn:hover { border-color: var(--line); }
  .swe-legend { position: absolute; bottom: 16px; right: 16px;
                background: var(--panel); border: 1px solid var(--border);
                border-radius: 8px; padding: 8px 12px; display: flex;
                flex-wrap: wrap; gap: 10px; font-size: 11px;
                color: var(--muted); max-width: 40vw; }
  .swe-legend-item { display: inline-flex; align-items: center; gap: 5px; }
  .swe-legend-dot { width: 9px; height: 9px; border-radius: 50%;
                    display: inline-block; }
</style>
</head>
<body>
<div id="diagram"></div>
<script>
__RENDERER_JS__
</script>
<script>
renderDiagram(__DIAGRAM_JSON__);
</script>
</body>
</html>
```
````
- Definition of Done: the SKILL.md schema + HTML/render requirements are internally consistent, unambiguous enough for a builder agent to implement without guessing, and the three open questions below are each explicitly addressed (either "already handled because X" or a concrete spec change proposed).

## Open questions from a prior review pass

A previous review of this same artifact (a different reviewer, informal web pass) raised three specific gaps. Address EACH of these explicitly in your findings — confirm it's already handled (cite where), or propose a concrete fix (schema field, renderer behavior, or SKILL.md wording):

1. **Group rendering** — the schema includes a `groups` array, but the HTML requirements don't explicitly state how groups should be visualized. Consider specifying that groups render as background bounding boxes (swimlanes) containing their child nodes, to make the visual hierarchy clear.
2. **Cycle handling** — left-to-right layered layouts break down with cyclical dependencies (e.g. Service A calls Service B, which calls Service A back). The renderer needs a fallback for this case (e.g. routing the edge backwards, or drawing a curved loop) instead of silently producing a broken/overlapping layout.
3. **Bidirectional edges** — the schema allows `sync`, `async`, and `data` edge types, but what represents a bidirectional interaction (e.g. a service that both reads and writes to a DB)? Consider whether a `bidirectional: true` flag on the edge schema is needed, or whether this is already expressible some other way.

## Ground rules
1. This file is the single source of truth. The agents never share memory — read the whole file.
2. Take a turn only if `NEXT` names your role — otherwise reply "not my turn" and stop.
3. One turn = one block appended at the very bottom, above the marker. Never edit earlier turns.
4. Stay tight — findings are bullets, not essays. Grade every finding.
5. **The Reviewer never edits the artifact.** It proposes graded findings; the Producer implements.
6. The relay ends on **Approved** (Reviewer only). End each turn by committing just this file; no push.

## Log

<!-- ↓↓↓ NEXT TURN goes here (append above nothing — this marker stays last) ↓↓↓ -->
