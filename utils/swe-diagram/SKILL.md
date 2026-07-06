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
